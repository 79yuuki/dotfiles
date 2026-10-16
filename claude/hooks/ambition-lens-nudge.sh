#!/usr/bin/env bash
# UserPromptSubmit hook: ambition-lens nudge.
#
# Felix Rieseberg "How to be more ambitious" に基づく ambition-lens skill の発動率を上げるため、
# プロンプトが「依頼/相談」の形なら Skill 起動を促す短い additionalContext を注入する。
#
# Design principles:
# - Nudge only. 最終判断は skill 側の triage（取りこぼしより拾いすぎ寄りで判定）。
# - Always exit 0 so the prompt is never blocked. 通常時に stderr へ出さない。
# - No LLM calls. 判定は jq 内の regex のみ（Oniguruma）。bash は 3.2 互換。jq は判定と出力生成の2回起動する。
#
# Input: Claude Code passes JSON on stdin.
#   - prompt（公式ドキュメント UserPromptSubmit input）にプロンプト本文。
#   - stdin は単一の JSON オブジェクトのみ許可（jq -s で読み、要素1つかつ object の時だけ処理。
#     末尾ゴミ・オブジェクト複数連結・jq 非0終了は無出力）。
#   - 貼り付けテキストは <pasted_content id="..."> から </pasted_content id="..."> の間に展開されて届くため、
#     その囲み（開始タグ行〜同じ ID の終了タグ行、最短一致・行境界必須、対応なしは残す）を除いた本文で判定する。
#   文字数は前後の空白を除いて数える。OPT-OUT のみ、さらに引用（「」『』""）の中身と否定形（急ぎではない等）を除いた本文で判定する。
#   貼り付けが 20 個を超える 2 万文字超の本文は判定しない（貼り付け除去が遅くなるため。旧版はこの規模で timeout していた）。
#   CONT/MECH/TASK は、進め方の定型句（Codex へのレビュー/相談依頼、/workflows 等の編成指定）を除いた本文で判定する。
#   新しい依頼にも続きの指示にも付く定型句なので、どちらの判定にも使わない（除去で作業の語まで消えた時はその除去を取り消す）。
#   4,000文字を超える本文は除去せずにそのまま判定する。
#
# Output: マッチ時のみ stdout に1行 JSON (hookSpecificOutput.additionalContext)。
#   FOCUS: 設計・分析・資料・改善・自動化など、野心度で成果が変わりやすい語がある依頼。起動を強く促す。
#   NORMAL: 依頼/相談の形だが FOCUS の語が無い。明らかな Speed なら起動不要と伝える。
#   STRONG: 野心度に関する語がある。
#
# 無効化: AMBITION_LENS=off、または ~/.claude/state/ambition-lens.off の存在。
#
# 判定順: 先頭が / か ! のコマンド・バックグラウンド完了通知(無出力) > OPT-OUT(無出力) > EXPLICIT(STRONG)
#   > プラン承認(無出力) > 4文字未満(無出力) > 60文字以下の続き/選択(CONT・新規作業の語なし)(無出力)
#   > 60文字以下の「お願い」(新規作業・FOCUS の語なし)(無出力) > 60文字以下の機械的操作(MECH・TASK の語なし)(無出力)
#   > TASK/依頼形(FOCUS か NORMAL) > 無出力
# 語彙はローカルのプロンプト履歴（1,364件・ラベル付き）で調整した。
#
# 正規表現メモ: 英語の単語境界は (^|[^a-z])...([^a-z]|$) で表現（フラグ i）。

set -u
set +e  # never break UserPromptSubmit. exit 0 everywhere.

[[ "${AMBITION_LENS:-}" == "off" ]] && exit 0
[[ -e "${HOME:-/nonexistent}/.claude/state/ambition-lens.off" ]] && exit 0

JQ="$(command -v jq 2>/dev/null)"
[[ -n "$JQ" ]] || exit 0

# 判定は jq 1回に寄せる（Oniguruma + Unicode で日本語・後方参照を正しく扱うため）。
# 出力: none / strong / focus / normal のいずれか。
KIND="$("$JQ" -s -r '
  def ci(re): test(re; "i");
  # 末尾側は空白の連続の先頭からだけ試す（"\\s+$" のままだと長い空白の連続で2乗の時間がかかる）
  def trim: sub("^\\s+"; "") | sub("(?<!\\s)\\s+$"; "");
  # jq 1.7 の match/gsub は一致1件ごとに本文を先頭からたどるので、一致が多いと長さの2乗で遅い（引用符の多い JSON 等）。
  # 全文にかける置換は split で分けて add でつなぐ（どちらも線形。join は要素数の2乗で遅い）。
  # 種類ごとに順に処理するので、種類の違う引用符が閉じずに交差する時だけ旧版の一括置換と結果が違うことがある
  # （入れ子の「"…"」などは同じ）。
  def concat: add // "";
  # 「…」の中身を空白1つにする。閉じ括弧で区切り、区間に開き括弧があれば最初の開き括弧から後ろを置き換える
  # （正規表現 「[^」]*」 を左から順に置換した結果と同じ。閉じていない括弧は残す）
  def unquote($o; $c):
    split($c) as $s
    | ($s[:-1] | map(if contains($o) then (split($o)[0] + " ") else . + $c end) | concat) + ($s[-1] // "");
  # "…" の中身を空白1つにする（"[^"]*" を左から順に置換した結果と同じ。最後の閉じていない引用符は残す）
  def unquote_dq:
    split("\"") as $s | ($s | length) as $n
    | [range(0; $n) as $k | if $k % 2 == 0 then $s[$k] elif $k < $n - 1 then " " else "\"" + $s[$k] end] | concat;
  # 語を空白1つに置き換える（split/join 相当）
  def replace_word($w): split($w) | (.[:1] + (.[1:] | map(" " + .))) | concat;
  "野心|アンビシャス|ambitio|もっと上|一段上|もっと深|深掘り|視座を上げ|ambition-lens" as $explicit
  # 「方針はそのままでいい」のように対象を保つ意味の「そのままで」は opt-out にしない（文頭・句読点・改行の直後だけ）
  | "no-ambition|(^|[、。,.!！?？\\n])[ \\t　]*そのままで|そのまま進|そのままやって|そのままお願い|質問不要|聞かずに|確認不要|至急|急ぎ|さくっと|サクッと" as $optout
  # 進め方の定型句。$pcodex は Codex へのレビュー/相談依頼の節、$pother は承認待ち（OK が出るまで〜）と編成の指定。
  # 活用形は長い方から並べる（Oniguruma は左の選択肢を先に採るので、「して」より先に「し」が当たると「て」が残る）
  | "(codex|コーデックス)[\\sa-z0-9._-]{0,12}?(に|と|へ|二|で|から)?(も|は)?[^。、\\n]{0,12}?(レビュー|相談|依頼|聞いて|聞く|決めて|決断|判断)(を|が|も)?(依頼)?(してもらいながら|してもらって|してもらう|してもらい|しながら|しつつ|して|し|もらいながら|もらって|貰いながら|貰って|返して|入れて|お願い|頼んで)?(ください|下さい|てね|ね|ほしい|欲しい)?" as $pcodex
  | "(ok|ＯＫ)が?(出る|でる|もらう|貰う|貰える|もらえる|出た|貰った|もらった)(まで|ら|なら|から)[^。、\\n]{0,24}|ステップバイステップ(で)?|step ?by ?step|/workflows|dynamic workflows?|ultracode|オーケストレーション|サブタスク|sub-?agents?|サブエージェント" as $pother
  | "続き|続けて|つづけて|進めて|進んで|進もう|進めよう|進めること|再開|次の|次ステップ|次に進|一旦|いったん|一回|もう一度|もう一回|再度|とりあえず|実装(しよう|まで|に進|を進|を始|はじめ|開始|に入)|やってみ|^やって|^(うん|ok|おk|おｋ|はい|了解|いいね|いいよ|よし|ごめん|あ、|いや|ありがとう)|^(じゃあ|では)?それで|^[a-zＡ-Ｚａ-ｚ0-9０-９]{1,2}(案)?\\s?(で|に|を|が|は|、|,|。|$)" as $cont
  | "(^|[^a-z])(push|pull|commit|merge|update|pr(を)?(出|作))([^a-z]|$)|プッシュ|コミット|マージ|開いて|起動|閉じて|保存して|インストール|アップデート|ログイン|デプロイして|確認して(ください|下さい|ほしい)?[。.]?$|教えて|説明して|解説して" as $mech
  | "デザイン|ui|ux|刷新|一新|リデザイン|改修|作り直|スキル|skill|自動化|仕組み|資料|スライド|レポート|ダッシュボード|分析|調査|検証|設計|戦略|企画|提案|仕様を|プロトタイプ|再発防止|機能|claude\\.md|計画|共通化|新しい|どう|べき|方法|なぜ|でしょうか" as $newwork
  | "相談|どうしたら|どうすれば|どうやったら|どうやって|どう思う|どうするべき|どう(なると|すると)?(いい|良い)|はどう|アドバイス|悩ん|迷って|検討|べき|方法|代替|選択肢|作って|作りたい|作成|作れる|書いて|書き換え|書き出|まとめて|考えて|直して|修正|改善|改修|刷新|一新|リデザイン|リニューアル|ブラッシュアップ|洗練|最適化|高速化|効率化|自動化|仕組み|スキル|skill|反映|取り入れ|導入|構築|開発|移行|対処|対応して|調整|分析|調査|調べ|検証|確かめ|比較|評価|チェックして|ファクトチェック|バックテスト|シミュレーション|企画|提案|計画|戦略|設計|仕様|spec|起票|資料|レポート|スライド|デッキ|ドキュメント|readme|ダッシュボード|デザイン|プロトタイプ|ui|ux|定例|振り返り|再発防止|レビュー|アイデア|リファクタ|実装|追加|整理して|見直して|作り直|したい|やりたい|わかりやすく|分かりやすく|使いやすく|見やすく|満たして|原因|なぜ|(でき|出来)るように|ないように|見直し|案(を)?(出|ください|下さい|ほしい|欲しい)" as $task_ja
  | "下さい|ください|ほしい|欲しい|もらえ(る|ます|ない)|いただけ|頂け|てみて|ようにして|にして|でしょうか|ですかね|ませんか|ないかな|のかな|かな[？?]|(できる|出来る|できない|出来ない|ある|ない|だめ|ダメ|いい|良い|通じる|わかる|ありそう)[？?]|できますか|出来ますか|ありますか|なぜ|何で|てくれる|たい(です|んだ|んで|けど|が|。|、|！|!|？|\\?|$)" as $req_ja
  | "(^|[^a-z])(help me|how (do|can|should) (i|we)|build|create|make|write|draft|improve|optimi[sz]e|automate|analy[sz]e|investigate|plan|strategy|design|review|refactor|fix|implement|redesign|migrate|set ?up|(can|could|would) you|is there|why)([^a-z]|$)" as $task_en
  | "相談|どうしたら|どうすれば|どう思う|べき|アドバイス|検討|作って|作りたい|作成|作れる|書き換え|まとめて|考えて|改善|改修|刷新|一新|リデザイン|リニューアル|ブラッシュアップ|洗練|最適化|高速化|効率化|自動化|仕組み|スキル|skill|取り入れ|導入|構築|開発|移行|分析|調査|検証|確かめ|比較|評価|ファクトチェック|バックテスト|シミュレーション|企画|提案|計画|戦略|設計|仕様|spec|資料|レポート|スライド|デッキ|ドキュメント|ダッシュボード|デザイン|プロトタイプ|定例|振り返り|再発防止|ないように|アイデア|リファクタ|したい|やりたい|ブレスト|原因|見直し|作り直|案(を)?(出|ください|下さい|ほしい|欲しい)|(^|[^a-z])(help me|how should|build|create|design|strategy|plan|analy[sz]e|investigate|automate|improve|optimi[sz]e|redesign)([^a-z]|$)" as $focus
  | if length == 1 and (.[0] | type) == "object" then
      (.[0].prompt // empty) | select(type == "string")
      # 貼り付けが 20 個を超える 2 万文字超の本文は、下の gsub が長さの2乗で遅くなるので判定しない（無出力）
      | select((length <= 20000) or ((split("<pasted_content id=\"") | length) <= 21))
      # 貼り付け除去: 開始タグ行から同じ ID の終了タグ行まで（行境界必須・対応なしは残す）
      | gsub("(?<![^\n])<pasted_content id=\"(?<i>[^\"]*)\">(?:\n.*?)?\n</pasted_content id=\"\\k<i>\">(?![^\n])"; ""; "p")
      | . as $body
      | ($body | trim) as $t
      # バックグラウンド処理の完了通知もこのイベントで届くが、ユーザーの依頼ではない。
      # 実測では本文が "<task-notification>\n<task-id>…" で始まるので、先頭がその形の時だけ除外する（語として話題にした依頼は残す）
      | if ($t | test("^[/!]")) or ($t | test("^<task-notification>\\s*<task-id>")) then "none"
        else
          ($t
            | unquote("「"; "」") | unquote("『"; "』") | unquote_dq
            | reduce ("急ぎではない", "急ぎじゃない", "至急ではない", "至急じゃない") as $w (.; replace_word($w))
            | trim) as $oo
          # 定型句は2段で取り除く。
          # 1段目の Codex の節は対象が語の中に入りやすい（「Codexへの移行を相談したい」）ので、広い語彙（$content）が
          #   除去で全て消えた時はこの段を取り消す。
          # 2段目の承認待ち（「OKが出るまで改善して」）と編成の指定は続きの指示なので取り除き、最後に、元の本文にあった
          #   新規作業の語（デザイン・設計など）が全て消えていたら除去全体を取り消す（「Codexで作ったデザインをレビューして、OKが出るまで改善して」）。
          # 続き・機械的操作の除外は60文字以下にしか効かず、gsub は一致が多いと遅いので、4,000文字を超える本文は除去しない
          | ($newwork + "|移行|最適化|高速化|効率化|改善|リファクタ|導入|構築|開発|比較|評価") as $content
          | (if ($t | length) > 4000 then $t
             else
               ($t | gsub($pcodex; " "; "i")) as $a
               | (if ($t | ci($content)) and ($a | ci($content) | not) then $t else $a end)
               | gsub($pother; " "; "i") as $c
               | (if ($t | ci($newwork)) and ($c | ci($newwork) | not) then $t else $c end)
             end | trim) as $r
          | if ($oo | ci($optout)) then "none"
            elif ($t | ci($explicit)) then "strong"
            # プランモードで承認したプランの実行。依頼の中身は承認前に決まっている
            elif ($t | test("^Implement the following plan")) then "none"
            elif ($r | length) < 4 then "none"
            elif ($r | length) <= 60 and ($r | ci($cont)) and ($r | ci($newwork) | not) then "none"
            # 「〜お願いします」は続きにも新しい依頼にも付く。新規作業の語も FOCUS の語（最適化・移行など）も無い時だけ続きとみなす
            elif ($r | length) <= 60 and ($r | ci("お願い")) and ($r | ci($newwork) | not) and ($r | ci($focus) | not) then "none"
            elif ($r | length) <= 60 and ($r | ci($mech)) and ($r | ci($task_ja) | not) and ($r | ci($task_en) | not) then "none"
            elif ($r | ci($task_ja)) or ($r | test($req_ja)) or ($r | ci($task_en)) then
              (if ($r | ci($focus)) then "focus" else "normal" end)
            else "none" end
        end
    else empty end' 2>/dev/null)"
[[ $? -eq 0 ]] || exit 0

case "$KIND" in
  strong|focus|normal) ;;
  *) exit 0 ;;
esac

LOADED='（この会話で既に ambition-lens を読み込んでいれば、再起動せずその手順で判断してよい）'
if [[ "$KIND" == "strong" ]]; then
  CTX='[ambition-lens] プロンプトに野心度に関する語があります。野心度を上げてほしいという依頼なら、Skill ツールで ambition-lens を起動し、書き換え案を選択肢にした1問を出してください。語の説明・否定・選択済みの案の続行なら不要です。'
elif [[ "$KIND" == "focus" ]]; then
  CTX="[ambition-lens] 依頼/相談の形で、設計・分析・資料・改善・自動化など野心度で成果が変わりやすい仕事です。着手前に Skill ツールで ambition-lens を起動して triage してください${LOADED}。Skip と判定したら何も言わずに進めます。triage 自体を省略してよいのは、同じタスクで triage 済みの時だけです。"
else
  CTX="[ambition-lens] 依頼/相談の形のプロンプトです。新しい依頼なら、着手前に Skill ツールで ambition-lens を起動して triage してください${LOADED}。明らかな Speed（typo・単発のコマンド・事実や概念の質問）や、同じタスクで triage 済みなら起動せずに進めて構いません。"
fi

"$JQ" -nc --arg ctx "$CTX" '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":$ctx}}' 2>/dev/null
exit 0
