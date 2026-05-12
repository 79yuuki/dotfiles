# dotfiles

古い `bash` / `vim` / `tmux` / `git` / `lint` 設定を、2026年時点でそのまま使いやすい形に整理した個人用 dotfiles です。

主な方針:

- macOS の現行運用に合わせて `zsh` を第一候補にする
- `git pull` の事故や古い `tmux` オプションを避ける
- `Vim 9` で素直に動く最小構成に寄せる
- 旧世代の `JSHint` / `JSCS` / `.eslintrc` はやめて `eslint.config.mjs` に寄せる
- `Claude` / `Codex` は認証・履歴・キャッシュを除いた再現可能な設定だけを管理する
- Claude/Codex の開発ワークフローは Superpowers 由来の汎用 skill 名で管理し、個別プロジェクト prefix は付けない
- Trading / finance / skill portfolio の運用Tipsは、RaindropやAnthropic公式skillsを見て reusable skill と Codex AGENTS.md に昇格する

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
- `claude/settings.base.json` -> `~/.claude/settings.json` の managed base
- `claude/skills/` -> `~/.claude/skills/`
- `claude/plugins/manifest.json` -> Claude plugin 利用状況のスナップショット
- `codex/config.base.toml` -> `~/.codex/config.toml` の managed base
- `codex/AGENTS.md` -> `~/.codex/AGENTS.md`
- `codex/browser/config.toml` -> `~/.codex/browser/config.toml`

## ファイル説明

### ルート設定ファイル

- `README.md`: このリポジトリの方針、配置先、各ファイルの役割を説明するドキュメントです。
- `Brewfile`: Homebrew / cask / VSCode extension / Go / Cargo ツールの復元元です。Node 本体はここではなく `nvm` で復元します。
- `install.sh`: 既存ファイルをバックアップしながら dotfiles を一括で symlink する移行用スクリプトです。
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

- `claude/settings.base.json`: Claude Code の managed base 設定です。通知 hook、status line、言語、enabled plugin を持ちます。
- `claude/plugins/manifest.json`: 利用中 plugin の移植用スナップショットです。cache 実体ではなく、どの plugin を使っていたかを残します。
- `scripts/sync-claude-settings.sh`: `claude/settings.base.json` と `~/.claude/settings.local.json` から `~/.claude/settings.json` を生成するスクリプトです。

### Claude skills

- `claude/skills/codex/SKILL.md`: tmux 上の Codex CLI と連携して相談・レビュー・設計議論を進める skill です。
- `claude/skills/dispatching-parallel-agents/SKILL.md`: Claude 側で複数 agent へ安全に仕事を分配するための skill です。
- `claude/skills/executing-plans/SKILL.md`: 既存の実行計画を実装フェーズへ落とし込むための skill です。
- `claude/skills/finishing-a-development-branch/SKILL.md`: 作業ブランチの仕上げ、検証、commit、PR 前確認を支援する skill です。
- `claude/skills/parallel-orchestrator/SKILL.md`: 独立タスクを見つけて並列実行計画を組み、Codex レビューも絡めて進行する skill です。
- `claude/skills/quant-research-workflow/SKILL.md`: クオンツ調査で価格予測ではなくリターン分布・自己相関・ボラ・ファクターを先に検証する skill です。
- `claude/skills/strategy-validation-gate/SKILL.md`: トレード戦略を本番投入前にバックテスト/WFO/ドライラン/Go Live gate で判定する skill です。
- `claude/skills/trading-risk-controls/SKILL.md`: トレードbotの sizing、DD、相関、停止条件、破産回避を設計する skill です。
- `claude/skills/market-microstructure-execution/SKILL.md`: 板、スプレッド、約定、order flow、DEX/CEX執行を検証する skill です。
- `claude/skills/trading-ai-agent-ops/SKILL.md`: AIエージェントをトレード研究/監視に使う際の権限境界と監査ログを定義する skill です。
- `claude/skills/skill-portfolio-evolution/SKILL.md`: RaindropやAnthropic公式GitHubからskills/plugins/AGENTS.mdを改善する skill です。
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

- `codex/config.base.toml`: Codex CLI のポータブルな managed 設定です。model、reasoning、plugin 有効化だけを管理します。
- `codex/AGENTS.md`: Codex へのグローバル指示です。日本語優先などの運用ルールを置いています。
- `codex/browser/config.toml`: Codex browser plugin の挙動設定です。現状は approval mode だけを持ちます。
- `scripts/sync-codex-config.sh`: `codex/config.base.toml` から `~/.codex/config.toml` を生成・更新するスクリプトです。machine-local runtime state はできるだけ保持します。

### Node / nvm 管理

- `node/README.md`: `nvm` / Node.js 移行の方針と復元手順です。
- `node/default-version`: 新しいマシンで default alias にする Node.js の版です。
- `node/versions.txt`: 復元対象としてまとめて install する Node.js の一覧です。
- `node/default-packages`: 新しい Node 版を入れたとき自動で入れるグローバル npm パッケージ一覧です。
- `scripts/setup-homebrew.sh`: `Brewfile` を使って Homebrew 系ツールを復元するスクリプトです。
- `scripts/setup-node.sh`: `nvm` 導入、Node 版 install、default alias 設定、`corepack enable` をまとめて行うスクリプトです。

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
ln -snf "$PWD/claude/skills" ~/.claude/skills
ln -snf "$PWD/codex/AGENTS.md" ~/.codex/AGENTS.md
ln -snf "$PWD/codex/browser/config.toml" ~/.codex/browser/config.toml
"$PWD/scripts/sync-claude-settings.sh"
"$PWD/scripts/sync-codex-config.sh"
```

または、バックアップ付きで一括反映するなら:

```bash
./install.sh
```

`install.sh` は既存ファイルを `~/.dotfiles-backups/<timestamp>/` へ退避してから symlink を張ります。
`Claude` の `settings.json` と `Codex` の `config.toml` だけは symlink ではなく、managed base からローカル生成します。

## 新マシン移行

新しい Mac では、次の順で進めるのが一番楽です。

### 0. 事前に用意するもの

- GitHub にアクセスできる SSH キーまたは token
- 1Password などに保存した `~/.config/secrets/ai-tools/.env.keys`
- 必要なら `~/.config/secrets/ai-tools/.env`
- 必要なら `~/.config/secrets/gcloud/adc.json`

### 1. Homebrew を入れる

Homebrew 未導入なら先に入れます。

### 2. この repo を clone する

```bash
git clone git@github.com:79yuuki/dotfiles.git ~/Development/dotfiles
cd ~/Development/dotfiles
```

### 3. Homebrew 系ツールを戻す

```bash
./scripts/setup-homebrew.sh
```

これで `Brewfile` に入っている formula / cask / VSCode extension / Go / Cargo ツールをまとめて復元します。

### 4. dotfiles を反映する

```bash
./install.sh
```

これで既存ファイルを `~/.dotfiles-backups/<timestamp>/` に退避しながら、必要な symlink を張ります。
`Codex` の `config.toml` だけは symlink ではなく、managed base からローカル生成します。

### 5. Node.js / nvm を戻す

```bash
./scripts/setup-node.sh
```

これで次をまとめて行います。

- `nvm` の導入
- `node/versions.txt` の各 Node 版 install
- `node/default-version` の default alias 設定
- `node/default-packages` のグローバル npm パッケージ導入
- `corepack enable`

### 6. secrets を戻す

以下をローカルに配置します。

- `~/.config/secrets/ai-tools/.env.keys`
- `~/.config/secrets/ai-tools/.env`
- `~/.config/secrets/gcloud/adc.json`

### 7. shell を再起動する

ターミナルを開き直すか、以下を実行します。

```bash
exec zsh
```

### 8. 動作確認

最低限ここまで通れば移行成功です。

```bash
brew --version
node -v
pnpm -v
tmux -V
claude --version
codex --version
```

必要なら secrets 経由での起動も確認します。

```bash
claude-sec --help
codex-sec --help
```

### 最短コマンド列

すでに Homebrew が入っている新マシンなら、実質これです。

```bash
git clone git@github.com:79yuuki/dotfiles.git ~/Development/dotfiles
cd ~/Development/dotfiles
./scripts/setup-homebrew.sh
./install.sh
./scripts/setup-node.sh
exec zsh
```

## 現在の zsh / Node.js 管理

この Mac では、`zsh` は `~/.zprofile` で Homebrew 初期化、`~/.zshenv` で Cargo、`~/.zshrc` で対話設定を読む構成です。Node.js は `nvm` を `~/.nvm` に置いて管理しており、現在の default alias は `22.14.0`、追加で `16.19.0` と `24.4.0` も入っています。

グローバル npm パッケージは、少なくとも次を常用しています。

- `@openai/codex`
- `claude`
- `@google/gemini-cli`
- `task-master-ai`
- `agent-browser`
- `pnpm`
- `safe-rm`
- `@mermaid-js/mermaid-cli`

これらは `node/default-version`、`node/versions.txt`、`node/default-packages`、`scripts/setup-node.sh` で移行しやすい形に寄せています。

Homebrew 由来のツール群は `Brewfile` と `scripts/setup-homebrew.sh` で復元できます。Node 本体は Homebrew ではなく `nvm` 側で復元する方針です。

## Codex 設定の扱い

`Codex` は `~/.codex/config.toml` に project trust や UI 状態のような machine-local runtime state を自動追記します。そのため、この repo では `codex/config.base.toml` だけを管理し、実際の `~/.codex/config.toml` は `scripts/sync-codex-config.sh` で生成します。

通常は `./install.sh` が自動で同期します。managed な base を編集したあとだけ、必要に応じて次を実行してください。

runtime section が空なら、まだ machine-local な project trust や UI 状態が記録されていないだけです。異常ではありません。

```bash
./scripts/sync-codex-config.sh
```

## Claude 設定の扱い

`Claude` の runtime state は主に `~/.claude/history.jsonl`、`sessions/`、`tasks/`、`todos/`、`plugins/cache/` などへ書かれます。`settings.json` 自体は大きく汚れにくいですが、repo 側の managed base と machine-local override を分けるため、この repo では `claude/settings.base.json` だけを管理し、実際の `~/.claude/settings.json` は `scripts/sync-claude-settings.sh` で生成します。

ローカル固有の差分を足したい場合は `~/.claude/settings.local.json` に書きます。managed base を編集したあとだけ、必要に応じて次を実行してください。

`~/.claude/settings.local.json` は必須ではありません。base 設定だけで足りるなら、ファイルが存在しない状態のままで問題ありません。

```bash
./scripts/sync-claude-settings.sh
```

## Secrets 運用

`Claude` / `Codex` などの資格情報は、repo には置かず `dotenvx` でローカル管理します。詳細は [secrets/README.md](/Users/yuki_shichiku/Development/dotfiles/secrets/README.md:1) を参照してください。

主なファイル:

- `local/zshrc.local.example`: マシン固有の上書き例です。`claude-sec` / `codex-sec` alias もここで定義しています。
- `local/claude.settings.local.example.json`: Claude の machine-local settings override 例です。
- `secrets/ai-tools/.env.example`: AI ツール向け env テンプレートです。
- `secrets/ai-tools/.env.keys.example`: `dotenvx` の鍵ファイルの雛形です。

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
