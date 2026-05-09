# dotfiles

古い `bash` / `vim` / `tmux` / `git` / `lint` 設定を、2026年時点でそのまま使いやすい形に整理した個人用 dotfiles です。

主な方針:

- macOS の現行運用に合わせて `zsh` を第一候補にする
- `git pull` の事故や古い `tmux` オプションを避ける
- `Vim 9` で素直に動く最小構成に寄せる
- 旧世代の `JSHint` / `JSCS` / `.eslintrc` はやめて `eslint.config.mjs` に寄せる
- `Claude` / `Codex` は認証・履歴・キャッシュを除いた再現可能な設定だけを管理する
- Claude/Codex の開発ワークフローは Superpowers 由来の汎用 skill 名で管理し、個別プロジェクト prefix は付けない

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

## ファイル説明

### ルート設定ファイル

- `README.md`: このリポジトリの方針、配置先、各ファイルの役割を説明するドキュメントです。
- `gitconfig`: `~/.gitconfig` 用の共通 Git 設定です。`pull.ff=only`、`fetch.prune=true`、`rerere` 有効化など、事故を減らす方向に寄せています。
- `gitignore`: `~/.config/git/ignore` 用のグローバル ignore です。OS 依存ファイルや一時ファイルを Git 管理から外します。
- `editorconfig`: エディタ共通の基本整形ルールです。UTF-8、LF、末尾改行、通常はスペース 2、`Makefile`/`Go` はタブにしています。
- `bash_profile`: login shell 用の Bash 初期化です。Homebrew 初期化と `~/.bashrc` 読込に責務を絞っています。
- `bashrc`: interactive Bash 用の共通設定です。PATH 補助、`nvm`、`gcloud`、alias、ローカル上書き読込を持ちます。
- `zprofile`: login shell 用の Zsh 初期化です。Homebrew 初期化と `~/.zprofile.local` 読込だけを担当します。
- `zshenv`: Zsh 全体で最初に読まれる最小設定です。`cargo` 環境と `~/.zshenv.local` の読込だけに留めています。
- `zshrc`: interactive Zsh の主設定です。履歴共有、PATH、`nvm`、`gcloud`、alias、ローカル上書き読込をまとめています。
- `tmux.conf`: `tmux 3.x` 前提の設定です。マウス操作、`vi` キー、RGB、pane resize、`pbcopy` 連携を入れています。
- `vimrc`: `Vim 9` で素直に動く最小構成です。`dein` や `pathogen` を前提にせず、見た目と編集挙動を整理しています。
- `eslint.config.mjs`: 共有用の ESLint flat config テンプレートです。古い `.eslintrc` / `JSHint` / `JSCS` の置き換えです。
- `.gitignore`: この dotfiles リポジトリ自身の ignore です。`vim/bundle` やローカル専用ファイルを管理外にします。

### Claude 設定

- `claude/settings.json`: Claude Code のグローバル設定です。通知 hook、status line、言語、enabled plugin を持ちます。
- `claude/plugins/manifest.json`: 利用中 plugin の移植用スナップショットです。cache 実体ではなく、どの plugin を使っていたかを残します。

### Claude skills

- `claude/skills/codex/SKILL.md`: tmux 上の Codex CLI と連携して相談・レビュー・設計議論を進める skill です。
- `claude/skills/dispatching-parallel-agents/SKILL.md`: Claude 側で複数 agent へ安全に仕事を分配するための skill です。
- `claude/skills/executing-plans/SKILL.md`: 既存の実行計画を実装フェーズへ落とし込むための skill です。
- `claude/skills/finishing-a-development-branch/SKILL.md`: 作業ブランチの仕上げ、検証、commit、PR 前確認を支援する skill です。
- `claude/skills/parallel-orchestrator/SKILL.md`: 独立タスクを見つけて並列実行計画を組み、Codex レビューも絡めて進行する skill です。
- `claude/skills/receiving-code-review/SKILL.md`: 受け取ったコードレビュー指摘を整理し、対応方針を詰める skill です。
- `claude/skills/requesting-code-review/SKILL.md`: レビュー依頼時の観点整理や依頼文構成を支援する skill です。
- `claude/skills/requesting-code-review/code-reviewer.md`: 上記 skill がレビュー依頼文を作る際に使う reviewer 向け補助プロンプトです。
- `claude/skills/subagent-driven-development/SKILL.md`: subagent を前提に実装を分割し、役割分担して進める skill です。
- `claude/skills/subagent-driven-development/code-quality-reviewer-prompt.md`: subagent 実装の品質観点レビュー用プロンプトです。
- `claude/skills/subagent-driven-development/implementer-prompt.md`: subagent 実装担当向けプロンプトです。
- `claude/skills/subagent-driven-development/spec-reviewer-prompt.md`: 実装前の仕様レビュー用プロンプトです。
- `claude/skills/systematic-debugging/SKILL.md`: 再現、切り分け、原因特定を系統立てて進めるデバッグ skill です。
- `claude/skills/systematic-debugging/CREATION-LOG.md`: systematic-debugging skill を作る過程のメモです。
- `claude/skills/systematic-debugging/condition-based-waiting-example.ts`: 条件待ちの実装例です。
- `claude/skills/systematic-debugging/condition-based-waiting.md`: 条件待ち戦略の解説です。
- `claude/skills/systematic-debugging/defense-in-depth.md`: 多層防御的なデバッグ観点のメモです。
- `claude/skills/systematic-debugging/find-polluter.sh`: テスト汚染源の探索補助スクリプトです。
- `claude/skills/systematic-debugging/root-cause-tracing.md`: 根本原因追跡の手順メモです。
- `claude/skills/systematic-debugging/test-academic.md`: デバッグ観点の補助ノートです。
- `claude/skills/systematic-debugging/test-pressure-1.md`: デバッグ skill の検証メモ 1 です。
- `claude/skills/systematic-debugging/test-pressure-2.md`: デバッグ skill の検証メモ 2 です。
- `claude/skills/systematic-debugging/test-pressure-3.md`: デバッグ skill の検証メモ 3 です。
- `claude/skills/test-driven-development/SKILL.md`: TDD ベースで実装を進めるための skill です。
- `claude/skills/test-driven-development/testing-anti-patterns.md`: TDD/テスト設計で避けるべきパターン集です。
- `claude/skills/using-git-worktrees/SKILL.md`: Git worktree を使った並行作業のやり方をまとめた skill です。
- `claude/skills/using-superpowers/SKILL.md`: Claude plugin `superpowers` を使う前提の運用 skill です。
- `claude/skills/using-superpowers/references/codex-tools.md`: `superpowers` から見た Codex 系ツールの参照メモです。
- `claude/skills/using-superpowers/references/copilot-tools.md`: `superpowers` から見た Copilot 系ツールの参照メモです。
- `claude/skills/using-superpowers/references/gemini-tools.md`: `superpowers` から見た Gemini 系ツールの参照メモです。
- `claude/skills/verification-before-completion/SKILL.md`: 完了報告前に何を検証すべきかを定義する skill です。
- `claude/skills/writing-plans/SKILL.md`: 実装前の計画書を構造化して書くための skill です。
- `claude/skills/writing-plans/plan-document-reviewer-prompt.md`: 計画書レビュー用の補助プロンプトです。

### Codex 設定

- `codex/config.toml`: Codex CLI のポータブルなグローバル設定です。model、reasoning、plugin 有効化だけを管理します。
- `codex/AGENTS.md`: Codex へのグローバル指示です。日本語優先などの運用ルールを置いています。
- `codex/browser/config.toml`: Codex browser plugin の挙動設定です。現状は approval mode だけを持ちます。

### 旧 Vim 資産

- `vim/.netrwhist`: netrw の履歴ファイルです。現状は歴史的な残存物です。
- `vim/Makefile`: `zencoding.vim` 周辺の古いメンテナンス用 Makefile です。
- `vim/README.mkd`: vendored `zencoding.vim` の古い説明書です。
- `vim/TODO`: vendored `zencoding.vim` の未完了メモです。
- `vim/TUTORIAL`: vendored `zencoding.vim` のチュートリアルです。
- `vim/autoload/zencoding.vim`: `zencoding.vim` の autoload 本体です。
- `vim/doc/zencoding.txt`: Vim help 形式の `zencoding.vim` ドキュメントです。
- `vim/plugin/zencoding.vim`: `zencoding.vim` の plugin エントリポイントです。
- `vim/unittest.vim`: `zencoding.vim` の古いテスト補助です。
- `vim/zencoding.vim.vimup`: `zencoding.vim` の配布・更新メタデータです。

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
