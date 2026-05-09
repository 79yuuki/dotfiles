# Node Migration

このディレクトリは、マシン移行時の Node.js / `nvm` 復元用メタデータです。

## 現在の前提

- `nvm` は `~/.nvm` にインストールする
- shell では `~/.zshrc` / `~/.bashrc` から `nvm.sh` を読む
- Homebrew の `node` / `yarn` ではなく `nvm` を正とする
- default Node は `node/default-version`
- 追加で入れておきたい Node 版は `node/versions.txt`
- 新しい Node 版へ自動で入れたいグローバル npm パッケージは `node/default-packages`

## 復元

```bash
./scripts/setup-node.sh
```

これで次をまとめて実行します。

1. `nvm` が無ければ `~/.nvm` に導入
2. `node/versions.txt` の各 Node を install
3. `node/default-version` を default alias に設定
4. default Node を use
5. `corepack enable` を実行

`nvm` upstream は Homebrew 経由を公式サポートしていないため、この repo では `~/.nvm` への標準導入を前提にしています。
