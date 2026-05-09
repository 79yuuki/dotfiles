# Secrets Layout

このリポジトリには実シークレットを含めません。`dotenvx` を前提に、次のマシンでも同じ置き場所で復元できるようにします。

## 方針

- 暗号化されていない実 `.env` や `.env.keys` は Git に入れない
- 必要なら暗号化済み `.env` は private repo 側で管理する
- この public dotfiles repo には example と運用ルールだけ置く
- `Claude` / `Codex` は常時 `export` せず、`dotenvx run` で必要時だけ注入する

## 推奨配置

- `~/.config/secrets/ai-tools/.env`
- `~/.config/secrets/ai-tools/.env.keys`
- `~/.config/secrets/gcloud/adc.json`

## 基本手順

1. `brew install dotenvx/brew/dotenvx`
2. `~/.config/secrets/ai-tools/.env` を作成
3. `dotenvx set KEY value -f ~/.config/secrets/ai-tools/.env` で値を入れる
4. 生成された `~/.config/secrets/ai-tools/.env.keys` は 1Password など別経路で保管する
5. `claude-sec` または `codex-sec` で起動する

## 実行例

```bash
dotenvx run -f "$HOME/.config/secrets/ai-tools/.env" -- claude
dotenvx run -f "$HOME/.config/secrets/ai-tools/.env" -- codex
```

## 注意

- `.env.keys` は source control に commit しない
- `dotenvx run --debug` は値をログへ出すので通常は使わない
- service account JSON は暗号化 `.env` ではなくファイルとして持ち、パスだけ環境変数で渡す方が扱いやすい
