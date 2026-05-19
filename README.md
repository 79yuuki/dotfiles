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
- `claude/skills/` -> `~/.claude/skills/`。Claude Code が skill を自動発見するための symlink
- `claude/plugins/manifest.json` -> Claude plugin 利用状況のスナップショット
- `codex/config.base.toml` -> `~/.codex/config.toml` の managed base
- `codex/AGENTS.md` -> `~/.codex/AGENTS.md`。Claude skill のうち Codex にも必要な運用ルールを短く移植する場所
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

`claude/skills/` は `install.sh` で `~/.claude/skills` へ symlink します。Claude Code はこの配下の各 `SKILL.md` を自動発見するため、新しい skill を追加するときに `settings.json` や `install.sh` へ個別登録する必要はありません。

Claude Code では skill の `description` と `when_to_use` が常にコンテキストへ入ります。ただし長い場合は 1536 文字で切られるため、frontmatter は「いつ使うか」が伝わる短い説明に留めます。補助プロンプト、参照メモ、スクリプトなどの supporting files は `SKILL.md` から明示的に参照します。Claude 専用 skill の運用ルールを Codex CLI にも効かせたい場合は、`codex/AGENTS.md` に要点だけミラーします。

- `claude/skills/agent-friendly-publishing/SKILL.md`: Design and improve publishing surfaces so AI agents and humans can reliably discover, read, cite, and act on them. Use for docs, pub…
- `claude/skills/clarity-gate/SKILL.md`: Review writing, UI copy, docs, proposals, and public content for plain-language clarity and accessibility. Use when the output must…
- `claude/skills/codebase-indexing/SKILL.md`: Improve repository discoverability for AI coding agents and humans by adding code maps, repo manifests, indexes, and retrieval workf…
- `claude/skills/codex/SKILL.md`: Collaborate with Codex CLI for implementation planning, code review, and architectural decisions. Use when: discussing design approa…
- `claude/skills/coding-agent/SKILL.md`: Run short coding tasks, one-off scripts, small utilities, and focused code changes with a lightweight agent workflow plus review and…
- `claude/skills/component-gallery/SKILL.md`: Choose and specify UI component patterns using a gallery of proven design-system structures. Use when asking an agent to build or im…
- `claude/skills/crypto-counterparty-security/SKILL.md`: Assess crypto, wallet, exchange, market-making, DeFi, vendor, and AI-agent collaboration workflows for counterparty, social-engineer…
- `claude/skills/dispatching-parallel-agents/SKILL.md`: Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies
- `claude/skills/empirical-prompt-tuning/SKILL.md`: Empirically improve agent-facing instructions such as skills, AGENTS.md, CLAUDE.md, slash commands, task prompts, routing descriptio…
- `claude/skills/executing-plans/SKILL.md`: Use when you have a written implementation plan to execute in a separate session with review checkpoints
- `claude/skills/fact-check-gate/SKILL.md`: Verify factual claims before publishing or sending outputs: URLs, domains, dates, prices, product names, people, legal/compliance st…
- `claude/skills/finishing-a-development-branch/SKILL.md`: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of develop…
- `claude/skills/geo-seo/SKILL.md`: Optimize content and sites for AI search and generative engine visibility across ChatGPT, Perplexity, Claude, Gemini, Google AI Over…
- `claude/skills/gtm-content-ops/SKILL.md`: Design and run small-team content operations: source monitoring, social posts, articles, newsletters, press releases, repurposing lo…
- `claude/skills/harness-engineering/SKILL.md`: Design and improve AI-agent harnesses: context loading, routing, verification gates, safety boundaries, skill/tool packaging, monito…
- `claude/skills/market-microstructure-execution/SKILL.md`: トレードbotの注文執行、板情報、スプレッド、スリッページ、約定可能性、CEX/DEXアービトラージ、マーケットメイク、funding rate、オーダーフロー、レイテンシを設計・検証する時に使う。
- `claude/skills/marketing-skills/SKILL.md`: Use a compact library of marketing playbooks for CRO, SEO, positioning, copywriting, analytics, experiments, pricing, launches, ads,…
- `claude/skills/parallel-orchestrator/SKILL.md`: Automatically estimates task complexity and orchestrates parallel subagent execution with Codex review. Triggers on: complex impleme…
- `claude/skills/pentest/SKILL.md`: Run authorized web, API, and infrastructure penetration-test planning and safe verification using tiered tools and evidence capture.…
- `claude/skills/playwright-e2e/SKILL.md`: Implement and run Playwright end-to-end tests and browser UI verification efficiently. Use for web app flows, regression tests, scre…
- `claude/skills/project-account-architecture/SKILL.md`: Design account, channel, brand, and ownership architecture across projects so audiences, permissions, content formats, and operating…
- `claude/skills/prompt-design/SKILL.md`: Design and review long agent-facing prompts such as AGENTS.md, CLAUDE.md, SKILL.md, subagent tasks, system prompts, and cron prompts…
- `claude/skills/public-site-stack-decision/SKILL.md`: Choose a stack for public-facing sites such as landing pages, docs, blogs, corporate sites, campaign pages, and help centers. Use to…
- `claude/skills/quant-research-workflow/SKILL.md`: クオンツトレードやbot戦略の初期調査で、価格予測ではなくリターン、分布、ボラティリティ、自己相関、レジーム、エッジを検証する時に使う。ランダムウォーク、時系列分析、特徴量設計、ファクター調査、モメンタムや平均回帰の調査にも使う。
- `claude/skills/receiving-code-review/SKILL.md`: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questi…
- `claude/skills/requesting-code-review/SKILL.md`: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
- `claude/skills/sales-gtm-os/SKILL.md`: Build and operate a reusable sales and go-to-market system: lead intake, qualification, outreach, follow-up, proposal flow, CRM tagg…
- `claude/skills/skill-creator/SKILL.md`: Create, update, audit, and package Agent Skills / Claude Code skills with clear routing, concise SKILL.md bodies, supporting files,…
- `claude/skills/skill-portfolio-evolution/SKILL.md`: Agent Skills / Claude Code plugins / Codex AGENTS.md を更新する時に使う。Raindrop・Anthropic公式GitHub・外部workflow bundleから reusable skill 改善を抽出し、…
- `claude/skills/slide-deck/SKILL.md`: Plan, write, and review slide decks, proposals, business explainers, technical presentations, and pitch materials. Use when creating…
- `claude/skills/smart-contract-audit/SKILL.md`: Audit Solidity smart contracts for loss-of-funds vulnerabilities, access-control bugs, economic attacks, upgradeability risks, and i…
- `claude/skills/strategy-validation-gate/SKILL.md`: トレード戦略やbotを本番投入する前に、バックテスト、ウォークフォワード、リプレイ、ドライラン、実弾投入のゲートを設計・実行する時に使う。過学習、リーク、単一バックテスト依存、WFO、go live 判定、回帰テストにも使う。
- `claude/skills/subagent-driven-development/SKILL.md`: Use when executing implementation plans with independent tasks in the current session
- `claude/skills/systematic-debugging/SKILL.md`: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
- `claude/skills/test-driven-development/SKILL.md`: Use when implementing any feature or bugfix, before writing implementation code
- `claude/skills/trading-ai-agent-ops/SKILL.md`: Claude Code やLLMエージェントでトレードbot、マーケット分析、戦略生成、運用監視、AIOpsを行う時に使う。AIに投資判断を丸投げせず、ログ、可視化、レビュー、監視、権限境界を設計する。
- `claude/skills/trading-risk-controls/SKILL.md`: トレードbotの資金管理、ポジションサイズ、損切り、ATR、Kelly基準、ドローダウン制限、レバレッジ制限、日次停止、破産確率、リスク監査を設計・レビューする時に使う。
- `claude/skills/trust-privacy-pack/SKILL.md`: Create and review trust, privacy, safety, retention, compliance, and customer-assurance artifacts for products and internal operatio…
- `claude/skills/ui-accessibility-design/SKILL.md`: Review and improve UI/UX information architecture and accessibility. Use for WCAG-oriented audits, forms, navigation, error messages…
- `claude/skills/ui-design-system/SKILL.md`: Design, critique, and refine high-quality UI systems for web apps, landing pages, dashboards, and mobile interfaces. Use for layout,…
- `claude/skills/unit-economics-gate/SKILL.md`: Evaluate opportunities, proposals, hires, tools, campaigns, and operating moves using unit economics, gross margin, fixed costs, cas…
- `claude/skills/using-git-worktrees/SKILL.md`: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an iso…
- `claude/skills/using-superpowers/SKILL.md`: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response inc…
- `claude/skills/verification-before-completion/SKILL.md`: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification comma…
- `claude/skills/winning-proposal/SKILL.md`: Structure proposals and business documents so decision-makers can approve them: problem, stakes, options, budget logic, risks, proof…
- `claude/skills/writing-plans/SKILL.md`: Use when you have a spec or requirements for a multi-step task, before touching code

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


Claude skills は `settings.json` ではなく `~/.claude/skills` 配下で管理します。`install.sh` によって `claude/skills/` が symlink されるので、repo に新しい `claude/skills/<skill-name>/SKILL.md` を追加すれば Claude Code 側で自然に発見されます。

新しい skill を追加・更新するときの確認事項:

1. `SKILL.md` の frontmatter に `name` と短い `description` を置く。
2. `description` / `when_to_use` は常時コンテキストに入る前提で、合計 1536 文字以内を目安に簡潔にする。
3. 長い手順、補助プロンプト、スクリプト、参照メモは supporting files に分け、`SKILL.md` からファイル名を明示して参照する。
4. Claude Code 専用ではない運用ルールは `codex/AGENTS.md` に要点だけ移植する。
5. README の `Claude skills` 一覧へ新しい skill と supporting files を追加する。

`disable-model-invocation` を使う skill は自動呼び出し前提にしません。その場合も、人間や agent が見つけやすいように README と必要に応じて AGENTS.md に使いどころを残します。

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
