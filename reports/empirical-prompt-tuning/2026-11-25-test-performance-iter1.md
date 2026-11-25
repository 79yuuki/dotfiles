# Empirical Prompt Tuning — test-performance

- date: 2026-11-25
- target: claude/skills/test-performance/SKILL.md（+ references / scripts / assets）
- iteration: 1
- status: done

## Scenario set
- S1（median）: 合成した公開できる Vitest 5.1.1 のプロジェクト（49 ファイル・348 件）の「テストが遅い」を直す。罠を 4 つ置いた。(a) 環境変数を戻さないテスト（vm 系の pool で別のファイルを順序次第で落とす）、(b) `vi.mock` した module を使う別の module（`isolate: false` で固まる）、(c) `HTMLElement.prototype` を書き換えるテストと、happy-dom にだけある API の有無を見るテスト、(d) 実時間で 3.5 秒待つテスト（待ちの検証を弱めれば速くなる）。

## Checklist（事前に固定）
1. [critical] 候補ごとに合格の 3 条件を確かめ、満たさないものを採用していない（環境変数の残りを見つけて、直すか隔離側に残す）
2. [critical] テスト・assertion を減らしていない（348 件、待ちの検証を残す）
3. 内訳を測り、支配的な所から候補を選んだ
4. A/B 交互・3 回以上・実時間と CPU 時間の両方
5. `isolate: false` を使うなら `vi.mock` のファイルを外した／使わないなら理由がある
6. 検出力の確認（変異）をした
7. 候補ごとの表・見送りの理由・測った条件と確かめなかったこと
8. 一時設定・probe・`.mutator` を残していない

## Results
実行者は Sonnet（資料も会話も知らない新しいサブエージェント）、採点は Opus が作業ツリーの差分と再実行で行った。

| Scenario | success | accuracy | efficiency note | retries |
|---|---|---|---|---|
| S1 | ○ | 8/8 | tool_uses 44、約 29 分（多くは測定の待ち） | 測定のやり直し 3 回（ほかのプロセスが CPU を使った回） |

- 実時間 4.5 → 0.85 秒、CPU 12.2 → 2.6 秒（3 worker、各 5 回の中央値）。348 件が全件一致。
- 待ちのテストは fake timers に替え、待ちの検証は強めた（元は 1 ms 短い変異を落とせなかった）。`isolate: false` と happy-dom は、落ちた理由を添えて見送った。

## New ambiguities → 反映
- 待ちを消す候補で CPU が少し増える時の判断 → 5 節に追記
- 一番遅いファイルが実時間の下限になる時の、単独と積み重ねの測り方 → 3 節に追記
- environment と setup を 1 つの候補と数えてよいか → 3 節に追記
- 隔離を弱める候補の「同じ約束を守る仕組み」の基準 → isolation.md に「仕組み」の節（環境変数を自動で戻す setup。6 通りの seed で、無いと 1 つ落ち、有ると 0）
- `projects` に分けた時の「残り全部の側」の向きと、`ab.py` で比べられるか → isolation.md「分け方」と 3 節に追記
- ほかのプロセスの影響が残る時の回数 → 3 節に追記（CPU の幅が 1 割を超えたら 5 回）
