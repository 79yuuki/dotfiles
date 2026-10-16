#!/usr/bin/env bash
# Tests for ambition-lens-nudge.sh. Usage: bash ambition-lens-nudge.test.sh
#   hook を別の bash で動かす時は HOOK_SHELL を指定する（例: HOOK_SHELL=/bin/bash /bin/bash ambition-lens-nudge.test.sh）。
#   HOOK_PATH で検査する hook を差し替えられる（性能テストが遅い実装を検出できるかの確認用）。
# 期待値: FOCUS / NORMAL / STRONG / NONE。HOME は一時ディレクトリに差し替え、本物の $HOME は触らない。

HOOK="${HOOK_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ambition-lens-nudge.sh}"
HOOK_SHELL="${HOOK_SHELL:-bash}"
TMP_HOME="$(mktemp -d)" || exit 1
[[ -d "$TMP_HOME" ]] || exit 1
trap 'rm -rf "$TMP_HOME"' EXIT
PASS=0
FAIL=0

# run_hook <stdin-string> [env assignments...] -> sets OUT, RC
run_hook() {
  local input="$1"; shift
  OUT="$(printf '%s' "$input" | env HOME="$TMP_HOME" "$@" "$HOOK_SHELL" "$HOOK" 2>"$TMP_HOME/stderr")"
  RC=$?
  ERR="$(cat "$TMP_HOME/stderr")"
}

check() { # name expected input [env...]
  local name="$1" expected="$2" input="$3"; shift 3
  run_hook "$input" "$@"
  local got="NONE"
  if [[ -n "$OUT" ]]; then
    if ! printf '%s' "$OUT" | jq -e '.hookSpecificOutput.hookEventName == "UserPromptSubmit"' >/dev/null 2>&1; then
      got="INVALID"
    elif [[ "$OUT" == *"野心度に関する語"* ]]; then got="STRONG"
    elif [[ "$OUT" == *"野心度で成果が変わりやすい"* ]]; then got="FOCUS"
    elif [[ "$OUT" == *"依頼/相談の形"* ]]; then got="NORMAL"
    else got="UNKNOWN"; fi
  fi
  if [[ "$got" == "$expected" && "$RC" -eq 0 && -z "$ERR" ]]; then
    PASS=$((PASS+1)); echo "PASS [$expected] $name"
  else
    FAIL=$((FAIL+1)); echo "FAIL [$expected] $name (got=$got rc=$RC stderr=${ERR:+non-empty})"
  fi
}

j() { jq -nc --arg t "$1" '{prompt:$t}'; }

# NORMAL
check "kpi slide"     FOCUS "$(j '来週の定例用に今月のKPIをまとめたスライド作って')"
check "productivity"  FOCUS "$(j '最近チームの生産性が落ちてる気がする。どうしたらいい？')"
check "npe fix"       NORMAL "$(j '本番で出てる NullPointerException を直して')"
check "ux improve"    FOCUS "$(j 'ログイン画面のUXを改善したい')"
check "english help"  FOCUS "$(j 'Help me design a caching strategy for our API')"
check "ci automation" FOCUS "$(j 'このリポジトリのCI自動化の仕組みを考えて')"
check "short shiryo"  FOCUS "$(j '資料作って')"
check "paste outside" FOCUS "$(j $'要約して資料作って\n<pasted_content id="p1">\n質問不要\n</pasted_content id="p1">')"
check "sonomama in task" FOCUS "$(j 'このコードをそのまま使えるようにリファクタして')"
# STRONG
check "explicit+task"   STRONG "$(j 'もっと野心的にやりたい。ブログ記事の構成を考えて')"
check "short explicit"  STRONG "$(j '深掘りして')"

check "ambition-lens expl" STRONG "$(j 'ambition-lens の説明をして')"
check "ambitious meaning" STRONG "$(j 'ambitious の意味を教えて')"
# NONE
check "optout>explicit" NONE "$(j 'そのままでいいけど野心的な案も見せて')"
check "no-ambition"   NONE "$(j '資料を作って no-ambition')"
check "negated ambition" NONE "$(j '野心的にせず質問不要で資料を作って')"
check "sonomama ambitious" NONE "$(j 'さっきの野心的な案でそのまま進めて')"
check "trailing garbage" NONE '{"prompt":"build a site"}x'
check "two objects"   NONE '{"prompt":"資料作って"}{"prompt":"資料作って"}'
check "no prompt field" NONE '{"user_input":"来週の定例用に資料作って"}'
check "paste only inside" NONE "$(j $'これ読んで\n<pasted_content id="abc">\n資料作って。野心的に。\n</pasted_content id="abc">')"
check "3 chars"       NONE "$(j '直して')"
check "yes"         NONE "$(j 'はい')"
check "slash"       NONE "$(j '/clear')"
check "bang"        NONE "$(j '!ls -la')"
check "thanks"      NONE "$(j 'ありがとう、助かった！')"
check "optout"      NONE "$(j 'このファイルの typo を直して。そのままでいいので質問不要')"
check "optout proceed" NONE "$(j 'そのまま進めて、資料も作っておいて')"
check "time"        NONE "$(j 'what time is it in Tokyo')"
check "explain"     NONE "$(j 'explain this function')"
check "planet"      NONE "$(j 'the planet is round')"
check "empty stdin" NONE ""
check "bad json"    NONE "{not json"
check "env off"     NONE "$(j '来週の定例用に今月のKPIをまとめたスライド作って')" AMBITION_LENS=off
mkdir -p "$TMP_HOME/.claude/state" && : > "$TMP_HOME/.claude/state/ambition-lens.off"
check "off file"    NONE "$(j '来週の定例用に今月のKPIをまとめたスライド作って')"
rm -f "$TMP_HOME/.claude/state/ambition-lens.off"
check "leading ws slash" NONE "$(j '  /clear')"
check "task notification" NONE "$(j '<task-notification>
<task-id>b54hjn5f3</task-id>
<status>completed</status>
<summary>Run Codex review to fix the build</summary>
</task-notification>')"
check "quoted notif tag" NORMAL "$(j '「<task-notification>」の誤判定を直して')"
check "quoted sysnotif" STRONG "$(j '「[SYSTEM NOTIFICATION」の扱いをもっと深掘りして')"
check "notif leading ws" NONE "$(j '
  <task-notification>
<task-id>x1</task-id>
<summary>Run review and fix</summary>
</task-notification>')"
check "quoted full sysnotif" STRONG "$(j '「[SYSTEM NOTIFICATION - NOT USER INPUT]」の扱いをもっと深掘りして')"
check "quoted notif structure" NORMAL "$(j '「<task-notification><task-id>」の誤判定を直して')"

# 追加: OPT-OUT の引用/否定形、空白、貼り付けの ID/行境界
check "negated hurry strong" STRONG "$(j '急ぎではないので、もっと野心的な企画を考えて')"
check "quoted optout strong" STRONG "$(j '「質問不要」という文言を改善したい。もっと野心的に')"
check "trailing space 3ch" NONE "$(j '直して ')"
check "leading space 3ch" NONE "$(j '  直して')"
check "real hurry optout" NONE "$(j '急ぎで資料作って')"
check "paste foreign close tag" NONE "$(j $'これ読んで\n<pasted_content id="a1">\n例: </pasted_content id="zz">\n資料作って\n</pasted_content id="a1">')"
check "unclosed paste kept" FOCUS "$(j $'要約して資料作って\n<pasted_content id="a1">\nfoo')"
check "mismatched id kept" FOCUS "$(j $'これ読んで\n<pasted_content id="a1">\n資料作って\n</pasted_content id="b2">')"

# 追加: プロンプト履歴の傾向から（文面は合成。依頼/相談の文末、進め方の定型句、続き・機械的操作の除外）
check "kudasai redesign"   FOCUS  "$(j 'ヒーロー部分をもっと大胆なデザインに刷新してください')"
check "hoshii adopt"       FOCUS  "$(j 'この記事を参考に、設定ファイルへ原則を取り入れてほしいです')"
check "prevent recurrence" FOCUS  "$(j '同じエラーが起きないように、デプロイ先でも動くか確認して')"
check "tsukureru"          FOCUS  "$(j 'その動画を mp4 に変換する Chrome 拡張って作れる？')"
check "proc + task"        FOCUS  "$(j 'codexにレビューしてもらいながら、管理画面のデザインを改修して')"
check "mech + task"        FOCUS  "$(j 'git pull してから定例の資料作って')"
check "keep policy"        FOCUS  "$(j '方針はそのままでいいので、取得する方法を考えてほしい')"
check "proposal"           FOCUS  "$(j 'スキーマの見直し案出して')"
check "youni shite"        NORMAL "$(j 'このロジックをフロントエンドから使えるようにして')"
check "daitai"             NORMAL "$(j 'docker が重いので代替案ない？')"
check "desire tai"         NORMAL "$(j '取引所ごとに rate limiter を入れたい')"
check "deshouka"           NORMAL "$(j '固定パラメータの方が成績が良いのはなぜでしょうか？')"
check "plan approval"      NONE   "$(j $'Implement the following plan:\n\n# 決済画面の改善計画\n\n## 概要\n資料を作る')"
check "proc only"          NONE   "$(j 'codexにレビューしてもらってOK貰うまで修正して')"
check "proc only 2"        NONE   "$(j 'この先は /workflows でオーケストレーションして進めて')"
check "next phase"         NONE   "$(j '次のphaseの実装を進めて下さい')"
check "choice"             NONE   "$(j 'Aでお願いします')"
check "choice space"       NONE   "$(j 'B でやってほしい')"
check "thanks continue"    NONE   "$(j 'ありがとう、じゃあそれで実装してください')"
check "mech push"          NONE   "$(j '変更をcommitしてpushして下さい')"
check "mech confirm"       NONE   "$(j 'デプロイ結果を確認して下さい')"
check "go not choice"      NORMAL "$(j 'go bot に以下の修正をしてください')"
check "proc overstrip guard" FOCUS "$(j 'codexで作ったデザインをレビューして')"
check "proc + rebuild"     FOCUS  "$(j 'codex に設計を相談しながら決済フローを作り直して')"

# 追加: Codex レビューの反例と境界（定型句の除去の残り、「お願い」、英語の機械操作語、長い本文）
check "proc then choice"   NONE   "$(j 'Codexにレビューして Aで実行してください')"
check "codex as topic"     FOCUS  "$(j 'Codexへの移行を相談したい')"
check "codex consult only" NONE   "$(j 'Codexに相談したい')"
check "onegai new work"    FOCUS  "$(j '認証処理の最適化をお願いします')"
check "onegai continue"    NONE   "$(j '修正お願いします')"
check "en mech in task"    FOCUS  "$(j 'Review the update strategy')"
check "en merge substring" FOCUS  "$(j 'Design an emergency response process')"
check "en mech only"       NONE   "$(j 'git pull and push')"
check "space sonomama"     FOCUS  "$(j '方針は そのままでいいので資料を作って')"
check "lead space optout"  NONE   "$(j ' そのままでいい、資料作って')"
check "fullwidth choice"   NONE   "$(j 'Ｂでお願いします')"
check "fullwidth plan"     NONE   "$(j 'Ａ案で進めて')"
check "cont 59 chars"      NONE   "$(jq -nc '{prompt:("続けて" + ("あ" * 52) + "実装して")}')"
check "cont 60 chars"      NONE   "$(jq -nc '{prompt:("続けて" + ("あ" * 53) + "実装して")}')"
check "cont 61 chars"      NORMAL "$(jq -nc '{prompt:("続けて" + ("あ" * 54) + "実装して")}')"
check "long tail request"  FOCUS  "$(jq -nc '{prompt:(("ログの抜粋です。" * 700) + "これを元に資料作って")}')"

# 追加: 再レビューの反例（長い本文の中央、承認待ちの節、「お願い」と新規作業、空白を挟んだ opt-out、遅い入力）
check "long head request"  FOCUS  "$(jq -nc '{prompt:("これを元に資料作って" + ("ログの抜粋です。" * 700))}')"
check "long middle consult" FOCUS "$(jq -nc '{prompt:(("あ" * 2100) + "相談したい" + ("あ" * 2100))}')"
check "long middle fix"    NORMAL "$(jq -nc '{prompt:(("あ" * 2100) + "直してください" + ("あ" * 2100))}')"
check "ok until improve"   NONE   "$(j 'Codexにレビューしてもらって、OKが出るまで改善してください')"
check "ok until refactor"  NONE   "$(j 'Codexにレビューしてもらって、OKが出るまでリファクタしてください')"
check "ok until redesign"  FOCUS  "$(j 'OKが出るまでデザインを刷新して')"
check "onegai new feature" NORMAL "$(j '新しい機能を実装お願いします')"
check "onegai add feature" NORMAL "$(j '通知機能の追加をお願いします')"
check "optout after space" NONE   "$(j '資料作って。 そのままでいい')"
check "optout after indent" NONE  "$(j $'資料作って。\n  そのままでいい')"
check "optout fullwidth sp" NONE  "$(j '資料作って、　そのままで')"
check "long whitespace"    FOCUS  "$(jq -nc '{prompt:("資料作って" + (" " * 50000) + "x")}')"
# bash 3.2 は "$(...)" の中のエスケープ済み引用符と波括弧を誤って解釈するので、関数で組み立てる
quote_heavy() { jq -nc '{prompt:("このJSONの構造を分析して\n" + ((({id: 1, name: "foo"} | tojson) + ",\n") * 5000))}'; }
check "quote-heavy long"   FOCUS  "$(quote_heavy)"

# 追加: 3回目のレビューの反例（2段除去の組み合わせ、長文の引用と文境界、貼り付けの多い長文）
check "design + ok until"  FOCUS  "$(j 'Codexで作ったデザインをレビューして、OKが出るまで改善して')"
check "design consult + ok" FOCUS "$(j 'Codexに設計を相談して、OKが出るまでリファクタして')"
check "long quoted hurry"  FOCUS  "$(jq -nc '{prompt:("資料作って。" + ("あ" * 2100) + "「" + ("い" * 2100) + "急ぎ」")}')"
check "long real hurry"    NONE   "$(jq -nc '{prompt:("「" + ("あ" * 2500) + "」急ぎで資料作って「" + ("い" * 2500) + "」")}')"
check "long keep policy"   FOCUS  "$(jq -nc '{prompt:(("あ" * 3000) + "方針はそのままでいいので資料を作って" + ("い" * 1985))}')"
paste_blocks() { jq -nc --argjson n "$1" --argjson size "$2" '{prompt:("資料作って\n" + ([range(0; $n) | "<pasted_content id=\"p\(.)\">\n" + ("質問不要。" * $size) + "\n</pasted_content id=\"p\(.)\">\n"] | join("")))}'; }
check "few long pastes"    FOCUS  "$(paste_blocks 5 6000)"
check "many pastes"        NONE   "$(paste_blocks 3200 1)"
check "many short pastes"  FOCUS  "$(paste_blocks 30 1)"

# 性能: hook の timeout（5秒）に収まることを確かめる。各入力は、対応する経路を長さの2乗の実装に戻すと
# 10 秒以上かかる大きさにしてある（2026-10 の複数回の実測。1件あたり、現行 0.02〜1.4 秒。concat を join("") に戻した
# 変異と join を使う旧版では 10〜22 秒、trim の末尾を "\\s+$" に戻した変異では空白のケースが 10〜11 秒）。
# HOOK_PATH で差し替えた hook にも同じテストを流せる。
perf_input() { jq -nc --argjson n "$1" --arg c "$2" '{prompt:("資料作って。" + ($c * $n))}'; }
perf_dq() { perf_input "$1" '"a"ああああ'; }
perf_spaces() { jq -nc --argjson n "$1" '{prompt:("資料作って" + (" " * $n) + "x")}'; }
check_fast() { # name expected input
  local start=$SECONDS
  check "$@"
  local took=$((SECONDS - start))
  if [[ $took -ge 5 ]]; then FAIL=$((FAIL+1)); echo "FAIL [<5s] $1 (took ${took}s)"; fi
}
check_fast "perf close brackets" FOCUS "$(perf_input 400000 '」')"
check_fast "perf closed kagi"    FOCUS "$(perf_input 200000 '「a」ああああ')"
check_fast "perf closed dq"      FOCUS "$(perf_dq 150000)"
check_fast "perf negation"       FOCUS "$(perf_input 200000 '急ぎではないああああ')"
check_fast "perf spaces"         FOCUS "$(perf_spaces 30000)"
check_fast "perf many pastes"    NONE  "$(paste_blocks 3200 1)"

echo "---"
echo "PASS=$PASS FAIL=$FAIL"
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
