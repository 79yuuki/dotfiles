# Empirical Prompt Tuning — ambition-lens

- date: 2026-10-16
- target: claude/skills/ambition-lens/SKILL.md (+ references/techniques.md)
- iteration: 1
- status: doing

## Scenario set
- S1: 「来週の定例用に、今月の売上KPIをまとめたスライド作って。データは sales_2026-09.csv にある」（median）
- S2: 「本番で NullPointerException が出まくってる。直して。…applyCoupon(OrderService.java:142)」（edge: 緊急）
- S3: 「最近チームの生産性が落ちてる気がする。どうしたらいい？」（edge: 相談）
- S4: 「README.md の 'recieve' って typo を直して」（skip 想定）
- Hold-out H1: 「来週誕生日の友達に送るLINEのメッセージ考えて」（個人的な短い創作）
- Hold-out H2: 「このCLIツールに --json オプションを追加して。出力は今の表形式と同じ項目でいい」（仕様確定済みの実装）

## Checklist
1. [critical] 判定が期待どおり（S1/S3=ask_now, S2=ask_after, S4/H1/H2=skip）
2. [critical] 聞き返す時は1問だけで、選択肢が依頼固有の書き換え文になっている（軸名だけの汎用質問ではない）
3. 「そのまま」相当の選択肢を必ず含む
4. 推奨案が先頭で、各案に何が変わるか・前提が書かれている
5. preview に書き換え後の依頼文の全文がある
6. 選ぶ前に野心案のスコープで作業を始めていない

## Change in this iteration
- 初版（triage 表 + 1問の聞き返し + 選択後ガードレール）

## Results
| Scenario | success | accuracy | efficiency note | retries |
|---|---|---|---|---|
| S1 | ○ ask_now | 6/6 | references を読んで例に寄せた | 0（選択肢を1回組み直し） |
| S2 | ○ ask_after | 6/6 | 最初 ask_now に傾き、後置き規定で修正 | 1 |
| S3 | ○ ask_now | 6/6 | references の例とほぼ同文で、例に強く引っ張られた | 0 |
| S4 | ○ skip | 6/6 | references 不要 | 0 |
| H1 | ○ skip | 6/6 | references 不要 | 0 |
| H2 | ○ skip | 6/6 | 一度 Altitude で聞きかけて skip に戻した | 1 |

## New ambiguities（要約）
- Skip 条件とシグナル表のどちらが優先か書かれていない（S4/H1/H2 全員が指摘）
- 「伸びしろが最大の軸を1〜2本」と「推奨案＋別軸1〜2個」で軸数が食い違う。同じ軸の段階違いを入れてよいか不明
- 後置きの「同じ形式の1問」が §2 形式か散文か不明。後置きで「そのまま進める」は意味がずれる
- Altitude 案が「何を起こしたいか」をユーザーに聞く形だと、選ばれた後に2問目が必要になる
- 野心度以外の事実の曖昧さ（「今月」と 09 のファイル名）の扱いが無い
- 他 skill（systematic-debugging, Artifact quickstart, slide-deck, orchestrate-with-advisory）との順序が無い
- 「検証手段が自己評価しかない」を広く読むと、ほぼ全ての実装依頼が対象になる
- description と本文で Skip 例がずれている。Speed が本文で定義されていない
- Depth の「非常識な目標」を診断型の相談に当てると捏造に近い
- 「締切直前」「本番障害」の閾値が無い

## Discretionary fills（要約）
- 「今月」を CSV のファイル名どおり9月と仮定して質問文に明記（S1）
- 後置きの最終選択肢を「このまま終える」に読み替え（S2）
- Altitude 案をデータから Y を判定する依頼文に書き換えて2問目を回避（S3）

## Metrics
- tool_uses: 18（hook 実装を含む workflow 全体）
- duration_ms: 129245（workflow 全体）

## Decision
- keep iterating。判定精度は 6/6 だが、多くを実行者の好意的補完で通している。

## Next action
- 判定順（明示要求 > Skip > 後置き > シグナル > Skip）を番号付きで明記し、Skip 優先を書く
- 選択肢を「書き換え案2〜3個＋そのまま」とし、同軸の段階違いを許可。「そのまま」のラベルは文脈依存（後置きは「ここで終える」）
- 「選ばれたらそれ以上質問せずに着手できる依頼文」を必須にする
- 事実の曖昧さは既定値で仮定して質問文に明記。数値目標は自然な時だけ
- 他 skill との順序節、非対話実行の Skip を追加。description の Skip 例を本文と揃える
- iteration 2 は references の例に無いシナリオで回す（S3 は例に引っ張られたため）
