# ツール別レシピ

各ツールの利用可否確認、最小の実行コマンド、短い骨格例、反例からテストへの変換のコツ。
記載外のフラグは未確認なので、必要なら公式 docs で確認する。選び方は [../SKILL.md](../SKILL.md) の表を参照。
考え方の出典: https://zenn.dev/mizchi/articles/ai-coding-loop-formal

## 有限全列挙（依存追加なし）

- 入力集合、初期状態、遷移、許された順序を先に決め、全件数と実行件数を照合する。順序制約を守る schedule だけを数える。
- 部分集合や境界代表だけならその範囲の検査と記す。同値類が完全だという根拠がないまま全入力へ一般化しない。
- `scripts/check_fixture.py` は 2 クライアント・各 2 操作の 6 順序と、判定 3 種 × 反転 2 種を探索し、モデルを別モジュールの実装へ replay する。
- 性質を弱めず正常例と壊した変種を比較する。実行途中の例外や件数不足は検査完了ではない。

## TLA+（TLC / Apalache）

- 導入確認: `command -v java`、tla2tools.jar の場所、`command -v apalache-mc`。
- TLC（既存 JAR のみ）: `java -cp /existing/path/tla2tools.jar tlc2.TLC -config Spec.cfg Spec.tla`。定数領域・Init/Next/Spec・不変条件と、deadlock を意図的終端と区別して記録する。打切り/timeout を完走と扱わず、TLC の全状態検査と深さ制限付き探索を区別する。活性は safety の完走だけでは示せない。
- Apalache: `apalache-mc check --inv=Inv Spec.tla`
- 骨格: `VARIABLES db, cache` / `Init` / `Next`（Write, Read, Invalidate の選択）/ `Inv == \A k \in Keys : cache[k] # NULL => cache[k] = db[k]`。Spec.cfg に `INIT Init` `NEXT Next` `INVARIANT Inv` を書く。この Inv は強い整合性（空でないキャッシュは常に DB と一致）を要求するので、Write と Invalidate を別の遷移にすると間に反例が出る。これは見つけたい不具合の典型で、意図した失敗例として使う。最終的整合性で十分な仕様なら、Inv ではなく「いずれ一致する」という活性（liveness）で書く。liveness には前提が要る: ある時点以降は書き込みが止まること（有限の休止では足りない）と、それ以降 Invalidate が不整合の解消まで連続して実行可能であること。弱公平性（例: `WF_vars(Invalidate)` を Spec に入れる）は、この連続して実行可能な条件のもとでのみ実行を保証する。前提はモデルと README に明記する。
- 反例→テスト: エラートレースの各状態遷移を 1 操作として並べ、Next の各アクションを実装の API 呼び出しに対応づける。

## Quint

- 利用可否確認: `command -v quint`。見つからなければ実行しない。
- 型検査: `quint typecheck spec.qnt`
- ランダムシミュレーション: `quint run --invariant=inv spec.qnt`
- Apalache による検査: `quint verify --invariant=inv spec.qnt`
- 骨格: `var` で状態を宣言し、`action init` / `action step` と `val inv = ...` を書く。
- 反例→テスト: run が出す違反トレースの各ステップを操作列にする。まず run で素早く探し、verify で網羅側に寄せる。

## Z3（SMT）

- 利用可否確認: `command -v z3` または既存 Python で `importlib.util.find_spec("z3")`。利用可能な場合だけ `z3 file.smt2` 等を使う。インストールはしない。
- 使い方: 前提 A のみの SAT を先に確認し、次に A ∧ ¬P を調べる。A が UNSAT なら空の前提で成立しただけなので停止する。sat は witness、unsat は選んだ理論/エンコード内での成立、unknown/timeout は未確定。整数の幅・overflow・浮動小数点・欠損/エラー/空集合の符号化と予算を明記する。
- 例（2 つのポリシー条件が等価か）:

```python
from z3 import Ints, Solver, Or, And, Not, sat, unsat
age, score = Ints("age score")
a = Or(age >= 18, score > 80)
b = And(age >= 18, score > 80)
s = Solver()
s.add(Not(a == b))  # 等価性の否定
result = s.check()
if result == sat:
    print(s.model())  # 反例の入力値
elif result == unsat:
    print("No counterexample in this encoding")
else:
    print("Inconclusive:", s.reason_unknown())
```

- 反例→テスト: model の値をそのまま入力にし、期待値は合意済みの意図から独立に書く。未確定なら期待値を固定せず判断待ちにする。エンコード漏れ（整数の範囲、未モデル化の入力）は Not verified に書く。

## Alloy

- 導入確認: Alloy Analyzer（GUI）が起動できるか。CLI の具体的なフラグは未確認: 公式 docs で確認。
- 実行: Analyzer 上で `check <assertion> for <scope>` や `run` を実行する。
- 骨格: `sig User {}` `sig Doc { owner: one User, viewers: set User }` と `assert OwnerCanView { all d: Doc | d.owner in d.viewers }`。owner を viewers に含める fact が無いので反例が出る（権限ルールの抜けを見つける意図した失敗例）。仕様として正しいなら fact を足すか、実装側の付与処理を直す。
- スコープは小さく始めて広げる（small scope hypothesis: 多くの誤りは小さな例で現れる）。有界なので、スコープ外は保証されない。
- 反例→テスト: 反例のインスタンスに出る atom（User, Doc）を fixture のデータにし、関係をそのまま権限設定に写す。

## Lean 4

- 導入確認: `command -v lake`。プロジェクト作成は `lake new`、検査は `lake build`。
- 骨格: 関数を定義し、`theorem` で不変量を述べて証明する。
- 証明が通らない時は、主張が偽の可能性がある。`#eval` やテストで反例を探す側に戻る。
- **証明の検収**: `#print axioms <定理名>` を実行し、依存する公理を見る。`sorryAx` が出たら、証明のどこかに `sorry`（未完成の穴）が残っている。標準の公理（`propext`、`Quot.sound`、`Classical.choice`）以外が出たら、理由を確かめる。エディタのチェックマークは、依存先に `sorry` が残っていても付くので、完成の根拠にしない。
- **命題が弱くないかを見る**: わざと役に立たない実装（常に 0 を返す、何も受け付けない）に差し替えても定理が成り立つなら、その命題は要件を表していない。証明が通ることと、要件が足りていることは別。
- **何を証明したかを書く**: 証明の対象がモデルなのか、出荷するコードなのかを分ける。モデルを証明した時は、モデルと実装に同じ乱数の入力を流して結果を比べる差分テストで一致を確かめ、モデル・証明・差分テストの 3 つが最新でない限り「検証済み」と書かない。
- **CI**: 通った証明の再検査（`lake build`）は速いので CI に載せられる。証明を探す作業は、終わる時間が読めないので載せない。

## property-based testing

- fast-check: `fc.assert(fc.property(...))`
- Hypothesis: `@given(...)` を付けたテスト関数
- proptest: `proptest!` マクロ
- 縮小（shrinking）された最小反例をそのまま回帰テストとして固定する（具体値の通常テストとして残す）。
- 仕様をオラクルにする: 仕様側の参照実装（単純な版）と本実装に同じ入力を流し、結果を比較する。

## 反例 → テスト変換の共通手順

1. トレースの各ステップを API 呼び出しや入力に対応づける。
2. 初期状態を fixture にする。
3. 期待値は実装の現状ではなく、合意済み仕様の不変条件から書く。未確定仕様や再現不能な trace は変更せず保留する。
4. テスト名に性質名を入れる（例: `cache_never_stale_after_write`）。
5. 修正前に失敗することを確認してから、実装を直す。

6. 正常版と壊した変種を同じ検査で確認する。ツール失敗ではなく対象性質の違反で検出すること。
