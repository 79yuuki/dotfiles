#!/usr/bin/env python3
# PreToolUse (matcher: Bash) hook: 再帰 + 強制の rm（-rf / -fr / -Rf / -r -f / --recursive --force）に確認を強制する。
# 対象がすべて一時フォルダ配下だと分かる時だけ、例外として何もしない。
#
# - 一時フォルダ配下だけ: 何も出力しない（判定なし）。通常の権限フローに戻り、auto mode がコマンド全体を判断する。
# - それ以外・解析できない: permissionDecision "ask"（auto mode でも確認が出る）。
# - "allow" は返さない。返すと、同じ呼び出しに入っている rm 以外の部分（git commit --amend など）までまとめて許可してしまう。
#
# 一時フォルダ: /private/tmp /tmp /private/var/folders /var/folders $TMPDIR の配下。ルートそのものと直下の glob は含めない。
# 対象は、同じコマンド内の単純な代入（VAR=... / export VAR=...）と $TMPDIR だけを展開して求める。
# 展開しきれない $、コマンド置換、`..`、相対パス、空白、symlink をたどると外に出るパスは、一時フォルダとみなさない。
#
# shortcut: 誤操作ガードで、安全境界ではない（careful の hook と同じ）。if / || / ループの中の代入と read は追わず、
#   bash -c や ssh に渡す文字列の中、ヒアドキュメント本文の中の rm も見ない。そこは auto mode と Claude Code 組み込みの
#   critical-path チェックに任せる。取りこぼしが実害になったら bashlex などの本物のパーサに替える。
#
# Input: stdin に JSON（tool_input.command）。テスト: bash claude/hooks/tests/rm-rf-guard.test.sh

import json
import os
import re
import sys

POISON = "\0"  # 解決できない展開とリテラルの $ の印。対象に残っていたら一時フォルダとみなさない
ROOTS = ["/private/tmp", "/tmp", "/private/var/folders", "/var/folders"]
RM_WORD = re.compile(r"(?<![\w.-])rm(?![\w.-])")  # --rm や perform は拾わない
NAME = re.compile(r"[A-Za-z_]\w*")
ASSIGN = re.compile(r"([A-Za-z_]\w*)(\+?)=(.*)", re.S)
REDIRECT = re.compile(r"&?(<<<|<<-?|[<>]+)[&|]?")
DECLARE = ("export", "declare", "local", "typeset", "readonly")


class Unparsable(Exception):
    pass


def parse(src, emit):
    """src を単純コマンド（語のリスト）に分け、順に emit("cmd", words) する。

    ( ) と $( ) と ` ` の出入りは emit("push") / emit("pop")。語の中の変数参照は ${NAME} の形にそろえ、
    それ以外の $ は POISON にする。リダイレクトとその対象、コメント、ヒアドキュメント本文は捨てる。
    """
    n = len(src)
    pos = 0

    def nested(closer):
        nonlocal pos
        pos += 1
        emit("push")
        command_list(closer)
        emit("pop")
        return POISON

    def dollar():
        nonlocal pos
        pos += 1
        if src.startswith("(", pos):
            return nested(")")
        if src.startswith("{", pos):
            end = src.find("}", pos)
            if end < 0:
                raise Unparsable("${ が閉じていない")
            name, pos = src[pos + 1:end], end + 1
            return "${%s}" % name if NAME.fullmatch(name) else POISON
        m = NAME.match(src, pos)
        if m:
            pos = m.end()
            return "${%s}" % m.group()
        if pos < n and src[pos] in "@*#?$!-0123456789":
            pos += 1
        return POISON

    def command_list(closer=None):
        nonlocal pos
        words, word, skip, heredocs, depth = [], None, None, [], 0

        def end_word():
            nonlocal word, skip
            if word is not None:
                if skip is None:
                    words.append(word)
                elif skip != "redirect":
                    heredocs.append((word, skip == "<<-"))
                skip = None
            word = None

        def end_command():
            nonlocal words, skip
            end_word()
            skip = None
            if words:
                emit("cmd", words)
            words = []

        while pos < n:
            c = src[pos]
            if c == "'":
                end = src.find("'", pos + 1)
                if end < 0:
                    raise Unparsable("' が閉じていない")
                word = (word or "") + src[pos + 1:end].replace("$", POISON)
                pos = end + 1
            elif c == '"':
                word = word or ""
                pos += 1
                while True:
                    if pos >= n:
                        raise Unparsable('" が閉じていない')
                    c = src[pos]
                    if c == '"':
                        pos += 1
                        break
                    if c == "\\" and src[pos + 1:pos + 2] in ("$", "`", '"', "\\", "\n"):
                        word += src[pos + 1].replace("$", POISON).replace("\n", "")
                        pos += 2
                    elif c == "$":
                        word += dollar()
                    elif c == "`":
                        word += nested("`")
                    else:
                        word += c
                        pos += 1
            elif c == "\\":
                if src[pos + 1:pos + 2] != "\n":  # 行末の \ は行継続なので何も足さない
                    word = (word or "") + src[pos + 1:pos + 2].replace("$", POISON)
                pos += 2
            elif c == "$":
                word = (word or "") + dollar()
            elif c == "`":
                if closer == "`":
                    pos += 1
                    end_command()
                    return
                word = (word or "") + nested("`")
            elif c == "#" and word is None:
                end = src.find("\n", pos)
                pos = n if end < 0 else end
            elif c in " \t":
                end_word()
                pos += 1
            elif c in "<>" or (c == "&" and src.startswith(">", pos + 1)):
                if word is not None and word.isdigit():  # 2> の 2
                    word = None
                end_word()
                m = REDIRECT.match(src, pos)
                pos = m.end()
                if not src.startswith("(", pos):  # <( ) と >( ) は ( ) として読む
                    skip = m.group(1) if m.group(1) in ("<<", "<<-") else "redirect"
            elif c in ";&|\n()":
                end_command()
                pos += 1
                if c == "\n":
                    for delimiter, strip_tabs in heredocs:
                        while pos < n:
                            end = src.find("\n", pos)
                            line = src[pos:] if end < 0 else src[pos:end]
                            pos = n if end < 0 else end + 1
                            if (line.lstrip("\t") if strip_tabs else line) == delimiter:
                                break
                    del heredocs[:]
                elif c == "(":
                    depth += 1
                    emit("push")
                elif c == ")":
                    if depth:
                        depth -= 1
                        emit("pop")
                    elif closer == ")":
                        return
                    # 対応する ( が無い ) は case のパターンなど。区切りとして読む
            else:
                word = (word or "") + c
                pos += 1
        if closer:
            raise Unparsable("%s が閉じていない" % closer)
        end_command()

    command_list()


def check(cmd, env):
    """確認が要る理由を返す。要らなければ None。"""
    scopes = [{}]  # 変数名 -> 値。( ) と $( ) の中の代入は外に出さない
    roots = list(ROOTS)
    tmpdir, home = env.get("TMPDIR", ""), env.get("HOME", "")
    if tmpdir.startswith("/") and ".." not in tmpdir:
        root = os.path.normpath(tmpdir)
        # TMPDIR が / や HOME の親を指していたら、一時フォルダとして信用しない
        if root != "/" and not (home + "/").startswith(root + "/"):
            roots.append(root)
            scopes[0]["TMPDIR"] = tmpdir
    roots += [os.path.realpath(r) for r in roots]
    reasons = []

    def expand(word):
        return re.sub(r"\$\{(\w+)\}", lambda m: scopes[-1].get(m.group(1), POISON), word)

    def assign(name, plus, value):
        # 2回目の代入と += は、どちらの値が効くか追わないので解決不能にする
        scopes[-1][name] = POISON if plus or name in scopes[-1] else value

    def under_root(path):
        firsts = [path[len(r) + 1:].split("/")[0] for r in roots if path.startswith(r + "/")]
        # 直下が glob / brace だと、ルートの中身を丸ごと消せる（/tmp/* や /tmp/{a,}）
        return bool(firsts) and path not in roots and not any(re.search(r"[*?\[{]", f) for f in firsts)

    def is_temp(target):
        if POISON in target or not target.startswith("/") or ".." in target or re.search(r"\s", target):
            return False
        path = os.path.normpath(target)
        return under_root(path) and under_root(os.path.realpath(path))

    def rm_reason(raw_args, args):
        recursive = force = False
        targets, options = [], True
        for raw, arg in zip(raw_args, args):
            if options and arg == "--":
                options = False
            elif options and arg.startswith("--"):
                recursive |= arg == "--recursive"
                force |= arg == "--force"
            elif options and arg.startswith("-") and len(arg) > 1:
                recursive |= "r" in arg or "R" in arg
                force |= "f" in arg
            else:
                targets.append((raw, arg))
        if not (recursive and force):
            return None
        if not targets:
            return "rm -rf の対象が分かりません"
        for raw, arg in targets:
            if not is_temp(arg):
                return "rm -rf の対象 %s が一時フォルダ配下だと確認できません" % raw.replace(POISON, "$…")
        return None

    def on_command(words):
        lead = 0
        while lead < len(words) and ASSIGN.fullmatch(words[lead]):
            lead += 1
        args = [expand(w) for w in words[lead:]]
        if not args:
            for word in words:  # A=1 B=$A は順に効く
                name, plus, value = ASSIGN.fullmatch(word).groups()
                assign(name, plus, expand(value))
        elif args[0] in DECLARE:
            # export A=1 B=$A の B は、export が動く前の A で展開される
            for name, plus, value in [m.groups() for m in map(ASSIGN.fullmatch, args[1:]) if m]:
                assign(name, plus, value)
        # コマンドの前に付けた代入（A=1 cmd）はそのコマンドの環境にしか効かないので、記録しない
        for i, arg in enumerate(args):
            if arg == "rm" or arg.endswith("/rm"):
                if "git" not in args[:i]:  # git rm は対象外
                    reason = rm_reason(words[lead + i + 1:], args[i + 1:])
                    if reason:
                        reasons.append(reason)
                break

    def emit(kind, words=None):
        if kind == "push":
            scopes.append(dict(scopes[-1]))
        elif kind == "pop":
            if len(scopes) > 1:
                scopes.pop()
        else:
            on_command(words)

    parse(cmd, emit)
    return reasons[0] if reasons else None


def main():
    try:
        cmd = json.loads(sys.stdin.buffer.read())["tool_input"]["command"]
    except Exception:
        return  # 入力が読めない時は判定しない
    if not isinstance(cmd, str) or not RM_WORD.search(cmd):
        return
    try:
        reason = check(cmd, os.environ)
    except Exception as error:  # 解析できない rm は安全側に倒す
        reason = "rm を含むコマンドを解析できません（%s）" % (error or type(error).__name__)
    if reason:
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": "rm-rf-guard: %s。" % reason,
        }}))


if __name__ == "__main__":
    main()
