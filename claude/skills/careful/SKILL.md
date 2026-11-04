---
name: careful
description: 破壊的操作の多い作業（本番 DB・履歴書き換え・一括削除）の前に使う。起動後セッション終了まで rm -rf・force push・DROP/TRUNCATE を PreToolUse hook で止める。通常の開発作業や読み取り中心の調査では使わない（hook が不要な確認を増やす）。
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "$HOME/.claude/skills/careful/scripts/block-destructive.sh"
---

# Careful

起動したセッションで、Bash の破壊的コマンドを deny する。

## 止めるもの

- `rm` の再帰 + 強制の組み合わせ（`-rf` / `-fr` / `-r -f` / `--recursive --force` など）
- `git push` の `--force` / `-f` / `--force-with-lease` / `--force-if-includes` / `+refspec`
- SQL の `DROP TABLE|DATABASE|SCHEMA` と `TRUNCATE TABLE`（大文字小文字不問）

## 運用

- hook は起動した時点で登録され、**セッション終了まで有効**。解除は新しいセッションを始める（途中で外せない）。
- 止められたら、ユーザーに意図を確認してから別の手段（対象を絞る・確認付きで実行する等）を取る。hook の回避（コマンドの分割・エンコード・別ツール経由）は試みない。
- 検出は文字列ベースで迂回できる。**安全境界ではなく誤操作ガード**。本当に守りたいものは権限・バックアップ側で守る。
