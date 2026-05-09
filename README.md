# dotfiles

古い `bash` / `vim` / `tmux` / `git` / `lint` 設定を、2026年時点でそのまま使いやすい形に整理した個人用 dotfiles です。

主な方針:

- macOS の現行運用に合わせて `zsh` を第一候補にする
- `git pull` の事故や古い `tmux` オプションを避ける
- `Vim 9` で素直に動く最小構成に寄せる
- 旧世代の `JSHint` / `JSCS` / `.eslintrc` はやめて `eslint.config.mjs` に寄せる
- `Claude` / `Codex` は認証・履歴・キャッシュを除いた再現可能な設定だけを管理する

## 管理ファイル

- `gitconfig` -> `~/.gitconfig`
- `gitignore` -> `~/.config/git/ignore`
- `editorconfig` -> `~/.editorconfig`
- `bash_profile` -> `~/.bash_profile`
- `bashrc` -> `~/.bashrc`
- `zprofile` -> `~/.zprofile`
- `zshrc` -> `~/.zshrc`
- `zshenv` -> `~/.zshenv`
- `tmux.conf` -> `~/.tmux.conf`
- `vimrc` -> `~/.vimrc`
- `vim/` -> `~/.vim`
- `eslint.config.mjs` -> プロジェクト側で参照する共有テンプレート
- `claude/settings.json` -> `~/.claude/settings.json`
- `claude/skills/` -> `~/.claude/skills/`
- `claude/plugins/manifest.json` -> Claude plugin 利用状況のスナップショット
- `codex/config.toml` -> `~/.codex/config.toml`
- `codex/AGENTS.md` -> `~/.codex/AGENTS.md`
- `codex/browser/config.toml` -> `~/.codex/browser/config.toml`

## セットアップ例

```bash
mkdir -p ~/.config/git ~/.claude ~/.codex/browser

ln -snf "$PWD/gitconfig" ~/.gitconfig
ln -snf "$PWD/gitignore" ~/.config/git/ignore
ln -snf "$PWD/editorconfig" ~/.editorconfig
ln -snf "$PWD/bash_profile" ~/.bash_profile
ln -snf "$PWD/bashrc" ~/.bashrc
ln -snf "$PWD/zprofile" ~/.zprofile
ln -snf "$PWD/zshrc" ~/.zshrc
ln -snf "$PWD/zshenv" ~/.zshenv
ln -snf "$PWD/tmux.conf" ~/.tmux.conf
ln -snf "$PWD/vimrc" ~/.vimrc
ln -snf "$PWD/vim" ~/.vim
ln -snf "$PWD/claude/settings.json" ~/.claude/settings.json
ln -snf "$PWD/claude/skills" ~/.claude/skills
ln -snf "$PWD/codex/config.toml" ~/.codex/config.toml
ln -snf "$PWD/codex/AGENTS.md" ~/.codex/AGENTS.md
ln -snf "$PWD/codex/browser/config.toml" ~/.codex/browser/config.toml
```

## ローカル上書き

秘密情報やマシン固有値は本体に直書きせず、以下で上書きします。

- `~/.bash_profile.local`
- `~/.bashrc.local`
- `~/.zprofile.local`
- `~/.zshenv.local`
- `~/.zshrc.local`

例えば以下はローカル側へ置く想定です。

- `GOOGLE_APPLICATION_CREDENTIALS`
- `TURSO_AUTH_TOKEN`
- API キー類
- プロジェクト固有の `PATH`

## 持ち込まないもの

グローバル設定からは次を意図的に除外しています。

- `~/.claude/history.jsonl` などの履歴
- `~/.claude/cache/` `~/.claude/backups/` などのキャッシュ
- `~/.claude/plugins/cache/` の実体
- `~/.codex/auth.json` などの認証情報
- `~/.codex/history.jsonl` `sessions` `sqlite` `state` などの実行状態
- `Codex` の project trust や marketplace のローカルキャッシュ情報

## 補足

`vim/` には昔の vendored runtime が残っていますが、現行の `vimrc` は `dein` や `pathogen` 前提ではありません。`vimrc` 単体でも動作し、`vim/` を置いた場合だけ追加 runtime が読み込まれる構成です。
