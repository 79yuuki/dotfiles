#!/usr/bin/env python3
# PreToolUse (matcher: Bash) hook: 再帰 + 強制の rm（-rf / -fr / -Rf / -r -f / --recursive --force）に確認を強制する。
# 対象がすべて一時フォルダ配下だと分かる時だけ、例外として何もしない。
#
# - 一時フォルダ配下だけ: 何も出力しない（判定なし）。通常の権限フローに戻り、auto mode がコマンド全体を判断する。
# - それ以外・解析できない: permissionDecision "ask"（auto mode でも確認が出る）。
# - "allow" は返さない。返すと、同じ呼び出しに入っている rm 以外の部分（git commit --amend など）までまとめて許可してしまう。
#
# 一時フォルダ: /private/tmp /tmp /private/var/folders /var/folders $TMPDIR の配下。ルートそのものと直下の glob は含めない。
# 対象は、同じコマンド内で必ず実行される代入（VAR=... / export VAR=...）と $TMPDIR だけを展開して求める。
# 次はどれも一時フォルダとみなさない（ask）:
# - 展開しきれない $、コマンド置換、`..`、相対パス、空白、実行前の時点で symlink をたどると外に出るパス
# - if / ループ / 関数 / { } の中や、|| の後、パイプ、& での代入。&& の後の代入は、同じ && の並びの中でだけ信用する
# - xargs や find -exec のように、rm の引数が実行時に決まる呼び出し
#
# shortcut: 誤操作ガードで、安全境界ではない（careful の hook と同じ）。次は見ないので、auto mode と Claude Code 組み込みの
#   critical-path チェックに任せる: bash -c / eval / ssh に渡す文字列の中の rm、ヒアドキュメント本文の中の rm、
#   source や関数呼び出しによる変数の書き換え、同じコマンドの中で作った symlink、glob が symlink に一致する場合。
#   取りこぼしが実害になったら bashlex などの本物のパーサに替える。
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
BRACED = re.compile(r"\{([A-Za-z_]\w*)(:?\?[^}$`\\]*)?\}")  # ${S} と ${S:?}。${S:?} は未設定・空なら rm まで進まない
ANSI_C = re.compile(r"'(?:[^'\\]|\\.)*'", re.S)  # $'...' は \' を含められる
ASSIGN = re.compile(r"([A-Za-z_]\w*)(\+?)=(.*)", re.S)
REDIRECT = re.compile(r"&?(<<<|<<-?|[<>]+)[&|]?")
SEPARATOR = re.compile(r"&&|\|\||\|&|;;|[;&|\n()]")
BLOCK_OPEN = ("{", "if", "while", "until")  # 先頭から外して、続きをコマンドとして読む
BLOCK_WORD = ("then", "else", "elif", "do", "!", "time")
BLOCK_HEAD = ("for", "select", "case", "function")  # 続きはコマンドではない
BLOCK_CLOSE = ("}", "fi", "done", "esac")
DECLARE = ("export", "declare", "local", "typeset", "readonly")
REBIND = ("unset", "read")  # 引数の変数を書き換える
PREFIX = ("sudo", "doas", "command", "exec", "env", "nohup", "nice", "time", "timeout", "builtin", "noglob", "nocorrect")
INERT = ("git", "echo", "printf", "grep", "rg")  # rm という語を実行しないコマンド（git rm は対象外）


class Unparsable(Exception):
    pass


def parse(src, emit):
    """src を単純コマンド（語のリスト）に分け、順に emit("cmd", words, before, after) する。

    before / after は前後の区切り（; && || | & ( ) 改行）。( ) と $( ) と ` ` と <( ) の出入りは emit("push") / emit("pop")。
    語の中の変数参照は ${NAME} の形にそろえ、それ以外の $ は POISON にする。
    リダイレクトとその対象、コメント、ヒアドキュメント本文、(( )) は捨てる。
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

    def arithmetic():  # pos が (( ... )) の先頭なら読み飛ばす
        nonlocal pos
        depth, end = 0, pos
        while end < n:
            depth += (src[end] == "(") - (src[end] == ")")
            end += 1
            if depth == 0:
                break
        if depth or not src.endswith("))", pos, end):
            return False
        pos = end
        return True

    def dollar():
        nonlocal pos
        pos += 1
        if src.startswith("((", pos) and arithmetic():
            return POISON
        if src.startswith("(", pos):
            return nested(")")
        if src.startswith("'", pos):
            m = ANSI_C.match(src, pos)
            if not m:
                raise Unparsable("$' が閉じていない")
            pos = m.end()
            return POISON
        if src.startswith("{", pos):
            m = BRACED.match(src, pos)
            if m:
                pos = m.end()
                return "${%s}" % m.group(1)
            # 単純でない展開は解決しない。中のコマンド置換と、${S:=x} が起こす代入だけ拾う
            m = NAME.match(src, pos + 1)
            if m and src.startswith(("=", ":="), m.end()):
                emit("unset", [m.group()])
            pos += 1
            while pos < n:
                c = src[pos]
                if c == "}":
                    pos += 1
                    return POISON
                if c == "$":
                    dollar()
                elif c == "`":
                    nested("`")
                else:
                    pos += 2 if c == "\\" else 1
            raise Unparsable("${ が閉じていない")
        m = NAME.match(src, pos)
        if m:
            pos = m.end()
            # zsh は $S:h（親ディレクトリ）や $S[1]（1文字目）も展開するので、続きがあれば解決不能にする
            return POISON if src.startswith((":", "["), pos) else "${%s}" % m.group()
        if pos < n and src[pos] in "@*#?$!-0123456789":
            pos += 1
        return POISON

    def command_list(closer=None):
        nonlocal pos
        words, word, skip, heredocs, depth, before = [], None, None, [], 0, ";"

        def end_word():
            nonlocal word, skip
            if word is not None:
                if skip is None:
                    words.append(word)
                elif skip != "redirect":
                    heredocs.append((word.replace(POISON, "$"), skip == "<<-"))
                skip = None
            word = None

        def end_command(sep):
            nonlocal words, skip, before
            end_word()
            skip = None
            if words:
                emit("cmd", words, before, sep)
            if words or sep != "\n":  # && の後の改行は続きなので、前の区切りを保つ
                before = sep
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
                    end_command(";")
                    return
                word = (word or "") + nested("`")
            elif c == "#" and word is None:
                end = src.find("\n", pos)
                pos = n if end < 0 else end
            elif c in " \t":
                end_word()
                pos += 1
            elif c in "<>" and src.startswith("(", pos + 1):  # <( ) と >( ) は1語
                pos += 1
                word = (word or "") + nested(")")
            elif c in "<>" or (c == "&" and src.startswith(">", pos + 1)):
                if word is not None and word.isdigit() and src.endswith(word, 0, pos):  # 2> の 2。引用した "2" は語
                    word = None
                end_word()
                m = REDIRECT.match(src, pos)
                pos = m.end()
                skip = m.group(1) if m.group(1) in ("<<", "<<-") else "redirect"
            elif c == "(" and word is None and src.startswith("((", pos) and arithmetic():
                pass
            elif c in ";&|\n()":
                m = SEPARATOR.match(src, pos)
                end_command(m.group()[0] if m.group() in ("|&", ";;") else m.group())
                pos = m.end()
                if c == "\n":
                    for delimiter, strip_tabs in heredocs:
                        while True:
                            if pos >= n:
                                raise Unparsable("ヒアドキュメント %s が閉じていない" % delimiter)
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
        if closer or depth:
            raise Unparsable("%s が閉じていない" % (closer or "("))
        end_command(";")

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
    pending = set()  # && の後で代入した名前。その && の並びが終わったら解決不能にする
    blocks = 0  # if / ループ / 関数 / { } の深さ。中の代入は、実行されるとは限らないので信用しない

    def expand(word):
        return re.sub(r"\$\{(\w+)\}", lambda m: scopes[-1].get(m.group(1), POISON), word)

    def poison(names):
        for scope in scopes:
            scope.update((name, POISON) for name in names)

    def under_root(path):
        firsts = [path[len(r) + 1:].split("/")[0] for r in roots if path.startswith(r + "/")]
        # 直下が glob / brace だと、ルートの中身を丸ごと消せる（/tmp/* や /tmp/{a,}）
        return bool(firsts) and path not in roots and not any(re.search(r"[*?\[{]", f) for f in firsts)

    def is_temp(target):
        if POISON in target or not target.startswith("/") or ".." in target or re.search(r"\s", target):
            return False
        path = os.path.normpath(target)
        return under_root(path) and under_root(os.path.realpath(path))

    def rm_targets(raw_args, args):
        """再帰 + 強制の rm なら対象 [(元の語, 展開後)] を返す。違えば None。"""
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
        return targets if recursive and force else None

    def transparent(word):  # 残りの引数をそのまま実行するだけの語
        return (os.path.basename(word) in PREFIX or word.startswith("-") or ASSIGN.fullmatch(word)
                or re.fullmatch(r"\d+(\.\d+)?[smhd]?", word))

    def run(words, before, after):
        nonlocal blocks
        while words and words[0] in BLOCK_OPEN + BLOCK_WORD:
            blocks += words[0] in BLOCK_OPEN
            words = words[1:]
        if not words:
            return
        if words[0] in BLOCK_CLOSE:
            blocks = max(0, blocks - 1)
            return
        if words[0] in BLOCK_HEAD:
            blocks += 1
            if words[0] in ("for", "select"):
                poison(words[1:2])
            return
        lead = 0
        while lead < len(words) and ASSIGN.fullmatch(words[lead]):
            lead += 1
        args = [expand(w) for w in words[lead:]]
        certain = not blocks and before != "||" and "|" not in (before, after) and after != "&"
        assigned = []
        if not args:
            for word in words:  # A=1 B=$A は順に効く
                name, plus, value = ASSIGN.fullmatch(word).groups()
                scopes[-1][name] = expand(value) if certain and not plus else POISON
                assigned.append(name)
        else:
            # コマンドの前に付けた代入（A=1 cmd）は、その後どちらの値になるかがシェルで違うので信用しない
            poison(ASSIGN.fullmatch(w).group(1) for w in words[:lead])
            if args[0] in DECLARE:
                # export A=1 B=$A の B は、export が動く前の A で展開される
                for name, plus, value in [m.groups() for m in map(ASSIGN.fullmatch, args[1:]) if m]:
                    scopes[-1][name] = value if certain and not plus else POISON
                    assigned.append(name)
            elif args[0] in REBIND:
                poison(a for a in args[1:] if NAME.fullmatch(a))
        if certain and before == "&&":
            pending.update(assigned)

        i = next((k for k, a in enumerate(args) if a == "rm" or a.endswith("/rm")), None)
        targets = None if i is None else rm_targets(words[lead + i + 1:], args[i + 1:])
        if targets is None:
            return
        head = os.path.basename(args[0]).replace(POISON, "$…")
        if not all(transparent(a) for a in args[:i]):
            if head not in INERT:
                reasons.append("%s 経由の rm -rf は対象を特定できません" % head)
        elif not targets:
            reasons.append("rm -rf の対象が分かりません")
        else:
            reasons.extend("rm -rf の対象 %s が一時フォルダ配下だと確認できません" % raw.replace(POISON, "$…")
                           for raw, arg in targets if not is_temp(arg))

    def emit(kind, words=None, before=None, after=None):
        if kind == "push":
            scopes.append(dict(scopes[-1]))
        elif kind == "pop":
            if len(scopes) > 1:
                scopes.pop()
        elif kind == "unset":
            poison(words)
        else:
            run(words, before, after)
            if after != "&&":
                poison(pending)
                pending.clear()

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
