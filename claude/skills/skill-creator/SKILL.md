---
name: skill-creator
description: >-
  Create, update, audit, and package Agent Skills / Claude Code skills with clear routing, concise SKILL.md bodies, supporting files, security review, and empirical tests. Use when adding or improving reusable skills.
---

# Skill Creator

This skill provides guidance for creating effective skills.

## About Skills

Skills are modular, self-contained packages that extend Codex's capabilities by providing
specialized knowledge, workflows, and tools. Think of them as "onboarding guides" for specific
domains or tasks—they transform Codex from a general-purpose agent into a specialized agent
equipped with procedural knowledge that no model can fully possess.

### What Skills Provide

1. Specialized workflows - Multi-step procedures for specific domains
2. Tool integrations - Instructions for working with specific file formats or APIs
3. Domain expertise - Company-specific knowledge, schemas, business logic
4. Bundled resources - Scripts, references, and assets for complex and repetitive tasks

## Core Principles

### Concise is Key

The context window is a public good. Skills share the context window with everything else Codex needs: system prompt, conversation history, other Skills' metadata, and the actual user request.

**Default assumption: Codex is already very smart.** Only add context Codex doesn't already have. Challenge each piece of information: "Does Codex really need this explanation?" and "Does this paragraph justify its token cost?"

Prefer concise examples over verbose explanations.

### Set Appropriate Degrees of Freedom

Match the level of specificity to the task's fragility and variability:

**High freedom (text-based instructions)**: Use when multiple approaches are valid, decisions depend on context, or heuristics guide the approach.

**Medium freedom (pseudocode or scripts with parameters)**: Use when a preferred pattern exists, some variation is acceptable, or configuration affects behavior.

**Low freedom (specific scripts, few parameters)**: Use when operations are fragile and error-prone, consistency is critical, or a specific sequence must be followed.

Think of Codex as exploring a path: a narrow bridge with cliffs needs specific guardrails (low freedom), while an open field allows many routes (high freedom).

### Anatomy of a Skill

Every skill consists of a required SKILL.md file and optional bundled resources:

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter metadata (required)
│   │   ├── name: (required)
│   │   └── description: (required)
│   └── Markdown instructions (required)
└── Bundled Resources (optional)
    ├── scripts/          - Executable code (Python/Bash/etc.)
    ├── references/       - Documentation intended to be loaded into context as needed
    └── assets/           - Files used in output (templates, icons, fonts, etc.)
```

#### SKILL.md (required)

Every SKILL.md consists of:

- **Frontmatter** (YAML): Contains `name` and `description` fields. These are the only fields that Codex reads to determine when the skill gets used, thus it is very important to be clear and comprehensive in describing what the skill is, and when it should be used.
- **Body** (Markdown): Instructions and guidance for using the skill. Only loaded AFTER the skill triggers (if at all).

#### Bundled Resources (optional)

##### Scripts (`scripts/`)

Executable code (Python/Bash/etc.) for tasks that require deterministic reliability or are repeatedly rewritten.

- **When to include**: When the same code is being rewritten repeatedly or deterministic reliability is needed
- **Example**: `scripts/rotate_pdf.py` for PDF rotation tasks
- **Benefits**: Token efficient, deterministic, may be executed without loading into context
- **Note**: Scripts may still need to be read by Codex for patching or environment-specific adjustments

##### References (`references/`)

Documentation and reference material intended to be loaded as needed into context to inform Codex's process and thinking.

- **When to include**: For documentation that Codex should reference while working
- **Examples**: `references/finance.md` for financial schemas, `references/mnda.md` for company NDA template, `references/policies.md` for company policies, `references/api_docs.md` for API specifications
- **Use cases**: Database schemas, API documentation, domain knowledge, company policies, detailed workflow guides
- **Benefits**: Keeps SKILL.md lean, loaded only when Codex determines it's needed
- **Best practice**: If files are large (>10k words), include grep search patterns in SKILL.md
- **Avoid duplication**: Information should live in either SKILL.md or references files, not both. Prefer references files for detailed information unless it's truly core to the skill—this keeps SKILL.md lean while making information discoverable without hogging the context window. Keep only essential procedural instructions and workflow guidance in SKILL.md; move detailed reference material, schemas, and examples to references files.

##### Assets (`assets/`)

Files not intended to be loaded into context, but rather used within the output Codex produces.

- **When to include**: When the skill needs files that will be used in the final output
- **Examples**: `assets/logo.png` for brand assets, `assets/slides.pptx` for PowerPoint templates, `assets/frontend-template/` for HTML/React boilerplate, `assets/font.ttf` for typography
- **Use cases**: Templates, images, icons, boilerplate code, fonts, sample documents that get copied or modified
- **Benefits**: Separates output resources from documentation, enables Codex to use files without loading them into context

#### What to Not Include in a Skill

A skill should only contain essential files that directly support its functionality. Do NOT create extraneous documentation or auxiliary files, including:

- README.md
- INSTALLATION_GUIDE.md
- QUICK_REFERENCE.md
- CHANNEL_ID.md
- etc.

The skill should only contain the information needed for an AI agent to do the job at hand. It should not contain auxiliary context about the process that went into creating it, setup and testing procedures, user-facing documentation, etc. Creating additional documentation files just adds clutter and confusion.

### Progressive Disclosure Design Principle

Skills use a three-level loading system to manage context efficiently:

1. **Metadata (name + description)** - Always in context (~100 words)
2. **SKILL.md body** - When skill triggers (<5k words)
3. **Bundled resources** - As needed by Codex (Unlimited because scripts can be executed without reading into context window)

#### Progressive Disclosure Patterns

Keep SKILL.md body to the essentials and under 500 lines to minimize context bloat. Split content into separate files when approaching this limit. When splitting out content into other files, it is very important to reference them from SKILL.md and describe clearly when to read them, to ensure the reader of the skill knows they exist and when to use them.

**Key principle:** When a skill supports multiple variations, frameworks, or options, keep only the core workflow and selection guidance in SKILL.md. Move variant-specific details (patterns, examples, configuration) into separate reference files.

**Pattern 1: High-level guide with references**

```markdown
# PDF Processing

## Quick start

Extract text with pdfplumber:
[code example]

## Advanced features

- **Form filling**: See [FORMS.md](FORMS.md) for complete guide
- **API reference**: See [REFERENCE.md](REFERENCE.md) for all methods
- **Examples**: See [EXAMPLES.md](EXAMPLES.md) for common patterns
```

Codex loads FORMS.md, REFERENCE.md, or EXAMPLES.md only when needed.

**Pattern 2: Domain-specific organization**

For Skills with multiple domains, organize content by domain to avoid loading irrelevant context:

```
bigquery-skill/
├── SKILL.md (overview and navigation)
└── reference/
    ├── finance.md (revenue, billing metrics)
    ├── sales.md (opportunities, pipeline)
    ├── product.md (API usage, features)
    └── marketing.md (campaigns, attribution)
```

When a user asks about sales metrics, Codex only reads sales.md.

Similarly, for skills supporting multiple frameworks or variants, organize by variant:

```
cloud-deploy/
├── SKILL.md (workflow + provider selection)
└── references/
    ├── aws.md (AWS deployment patterns)
    ├── gcp.md (GCP deployment patterns)
    └── azure.md (Azure deployment patterns)
```

When the user chooses AWS, Codex only reads aws.md.

**Pattern 3: Conditional details**

Show basic content, link to advanced content:

```markdown
# DOCX Processing

## Creating documents

Use docx-js for new documents. See [DOCX-JS.md](DOCX-JS.md).

## Editing documents

For simple edits, modify the XML directly.

**For tracked changes**: See [REDLINING.md](REDLINING.md)
**For OOXML details**: See [OOXML.md](OOXML.md)
```

Codex reads REDLINING.md or OOXML.md only when the user needs those features.

**Important guidelines:**

- **Avoid deeply nested references** - Keep references one level deep from SKILL.md. All reference files should link directly from SKILL.md.
- **Structure longer reference files** - For files longer than 100 lines, include a table of contents at the top so Codex can see the full scope when previewing.

## Skill Creation Process

Skill creation involves these steps:

1. Understand the skill with concrete examples
2. Plan reusable skill contents (scripts, references, assets)
3. Initialize the skill (run init_skill.py)
4. Edit the skill (implement resources and write SKILL.md)
5. Package the skill (run package_skill.py)
6. Iterate based on real usage

Follow these steps in order, skipping only if there is a clear reason why they are not applicable.

### Skill Naming

- Use lowercase letters, digits, and hyphens only; normalize user-provided titles to hyphen-case (e.g., "Plan Mode" -> `plan-mode`).
- When generating names, generate a name under 64 characters (letters, digits, hyphens).
- Prefer short, verb-led phrases that describe the action.
- Namespace by tool when it improves clarity or triggering (e.g., `gh-address-comments`, `linear-address-issue`).
- Name the skill folder exactly after the skill name.

### Step 1: Understanding the Skill with Concrete Examples

Skip this step only when the skill's usage patterns are already clearly understood. It remains valuable even when working with an existing skill.

To create an effective skill, clearly understand concrete examples of how the skill will be used. This understanding can come from either direct user examples or generated examples that are validated with user feedback.

For example, when building an image-editor skill, relevant questions include:

- "What functionality should the image-editor skill support? Editing, rotating, anything else?"
- "Can you give some examples of how this skill would be used?"
- "I can imagine users asking for things like 'Remove the red-eye from this image' or 'Rotate this image'. Are there other ways you imagine this skill being used?"
- "What would a user say that should trigger this skill?"

To avoid overwhelming users, avoid asking too many questions in a single message. Start with the most important questions and follow up as needed for better effectiveness.

Conclude this step when there is a clear sense of the functionality the skill should support.

### Step 2: Planning the Reusable Skill Contents

To turn concrete examples into an effective skill, analyze each example by:

1. Considering how to execute on the example from scratch
2. Identifying what scripts, references, and assets would be helpful when executing these workflows repeatedly

Example: When building a `pdf-editor` skill to handle queries like "Help me rotate this PDF," the analysis shows:

1. Rotating a PDF requires re-writing the same code each time
2. A `scripts/rotate_pdf.py` script would be helpful to store in the skill

Example: When designing a `frontend-webapp-builder` skill for queries like "Build me a todo app" or "Build me a dashboard to track my steps," the analysis shows:

1. Writing a frontend webapp requires the same boilerplate HTML/React each time
2. An `assets/hello-world/` template containing the boilerplate HTML/React project files would be helpful to store in the skill

Example: When building a `big-query` skill to handle queries like "How many users have logged in today?" the analysis shows:

1. Querying BigQuery requires re-discovering the table schemas and relationships each time
2. A `references/schema.md` file documenting the table schemas would be helpful to store in the skill

To establish the skill's contents, analyze each concrete example to create a list of the reusable resources to include: scripts, references, and assets.

### Step 3: Initializing the Skill

At this point, it is time to actually create the skill.

Skip this step only if the skill being developed already exists, and iteration or packaging is needed. In this case, continue to the next step.

When creating a new skill from scratch, always run the `init_skill.py` script. The script conveniently generates a new template skill directory that automatically includes everything a skill requires, making the skill creation process much more efficient and reliable.

Usage:

```bash
scripts/init_skill.py <skill-name> --path <output-directory> [--resources scripts,references,assets] [--examples]
```

Examples:

```bash
scripts/init_skill.py my-skill --path skills/public
scripts/init_skill.py my-skill --path skills/public --resources scripts,references
scripts/init_skill.py my-skill --path skills/public --resources scripts --examples
```

The script:

- Creates the skill directory at the specified path
- Generates a SKILL.md template with proper frontmatter and TODO placeholders
- Optionally creates resource directories based on `--resources`
- Optionally adds example files when `--examples` is set

After initialization, customize the SKILL.md and add resources as needed. If you used `--examples`, replace or delete placeholder files.

### Step 4: Edit the Skill

When editing the (newly-generated or existing) skill, remember that the skill is being created for another instance of Codex to use. Include information that would be beneficial and non-obvious to Codex. Consider what procedural knowledge, domain-specific details, or reusable assets would help another Codex instance execute these tasks more effectively.

#### Learn Proven Design Patterns

Consult these helpful guides based on your skill's needs:

- **Multi-step processes**: If `references/workflows.md` exists in this skill package, consult it for sequential workflows and conditional logic; if it is absent, proceed from the workflow guidance already in this SKILL.md rather than blocking on a missing optional reference
- **Specific output formats or quality standards**: If `references/output-patterns.md` exists, consult it for template and example patterns; if absent, keep examples concise in SKILL.md or add a focused reference file when needed

These files contain established best practices for effective skill design.

#### Start with Reusable Skill Contents

To begin implementation, start with the reusable resources identified above: `scripts/`, `references/`, and `assets/` files. Note that this step may require user input. For example, when implementing a `brand-guidelines` skill, the user may need to provide brand assets or templates to store in `assets/`, or documentation to store in `references/`.

Added scripts must be tested by actually running them to ensure there are no bugs and that the output matches what is expected. If there are many similar scripts, only a representative sample needs to be tested to ensure confidence that they all work while balancing time to completion.

If you used `--examples`, delete any placeholder files that are not needed for the skill. Only create resource directories that are actually required.

#### Update SKILL.md

**Writing Guidelines:** Always use imperative/infinitive form.

##### Frontmatter

Write the YAML frontmatter with `name` and `description`:

- `name`: The skill name
- `description`: This is the primary triggering mechanism for your skill, and helps Codex understand when to use the skill.
  - Include both what the Skill does and specific triggers/contexts for when to use it.
  - Include all "when to use" information here - Not in the body. The body is only loaded after triggering, so "When to Use This Skill" sections in the body are not helpful to Codex.
  - Example description for a `docx` skill: "Comprehensive document creation, editing, and analysis with support for tracked changes, comments, formatting preservation, and text extraction. Use when Codex needs to work with professional documents (.docx files) for: (1) Creating new documents, (2) Modifying or editing content, (3) Working with tracked changes, (4) Adding comments, or any other document tasks"

Do not include any other fields in YAML frontmatter.

##### Body

Write instructions for using the skill and its bundled resources.

### Step 5: Packaging a Skill

Once development of the skill is complete, it must be packaged into a distributable .skill file that gets shared with the user. The packaging process automatically validates the skill first to ensure it meets all requirements:

#### Distribution Route Rule（重要）

配布先は毎回同じにしない。**誰に・どこで・どれくらい再現可能に配りたいか** で決める。

| Route | 使う場面 | 向いているもの | 向いていないもの |
|---|---|---|---|
| Local folder | この workspace / 単一マシンで即使いたい | 個人用・試作・高速反復 | チーム配布、バージョン固定 |
| `gh skill` | **GitHub上の既存skillを preview/install/update したい** | provenance確認、tree SHA pin、update dry-run、外部skillの安全導入 | GitHub外の配布物、依存込みの完全再現パッケージ |
| `.skill` archive / ClawHub | 人に渡す、レビューして配る、単発共有 | 配布物としてのスキル、手動インストール前提 | 由来追跡、継続更新の監査、依存込みの再現性 |
| APM package | **チーム標準として再現可能に配る** | org共通skill、依存/バージョン管理、オンボーディング | まだ仕様が固まってない試作品 |

判断ルール:
- **まず local** で中身を固める
- GitHub由来の外部skillは **`gh skill preview` → staging install → security scan → promote** を基本フローにする
- 他人に配る単発アーカイブは `.skill` / ClawHub を使う
- **複数人・複数repo・継続運用** なら APM を第一候補にする
- 「インストール手順を口頭で説明しないと再現できない」なら APM 化を検討する
- APM 化する時は、skill 単体ではなく **依存する instructions / MCP / hooks / config まで含めて再現可能か** を見る
- `gh skill` を使う時は provenance / pin / dry-run を活かし、`SKILL.md` だけ見て即 install しない

#### Public repo benchmark（Google Skills系の学び）

公開配布を前提にするなら、**配布導線と探索導線を README に分離して置く** と強い。
最低限そろえると良い要素:
- install 導線（1コマンド）
- available skills 一覧
- support / issue 受付先
- contributing 導線

つまり `SKILL.md` 本文を太らせるより、**repo/registry 側で discoverability を持たせる**。
単体skillの完成度だけでなく、「どう見つけて、どう安全に入れて、どこに問い合わせるか」まで設計する。

#### External workflow bundle migration

Superpowers など外部の開発ワークフロー bundle を dotfiles / Claude / Codex へ移植する時は、`references/external-workflow-skill-bundles.md` を読む。全量コピーではなく、公式 plugin・AGENTS.md 要約・per-skill security scan の組み合わせで安全に移す。

```bash
scripts/package_skill.py <path/to/skill-folder>
```

Optional output directory specification:

```bash
scripts/package_skill.py <path/to/skill-folder> ./dist
```

The packaging script will:

1. **Validate** the skill automatically, checking:
   - YAML frontmatter format and required fields
   - Skill naming conventions and directory structure
   - Description completeness and quality
   - File organization and resource references

2. **Package** the skill if validation passes, creating a .skill file named after the skill (e.g., `my-skill.skill`) that includes all files and maintains the proper directory structure for distribution. The .skill file is a zip file with a .skill extension.

   Security restriction: symlinks are rejected and packaging fails when any symlink is present.

If validation fails, the script will report the errors and exit without creating a package. Fix any validation errors and run the packaging command again.

### Step 6: Security Audit（必須）

スキルの作成・更新が完了したら、**パッケージング後に必ずセキュリティスキャンを実行する。** スキップ不可。

```bash
./scripts/skill-security-scan.sh /path/to/skill-folder
```

#### 判定基準

| 結果 | アクション |
|------|-----------|
| CRITICAL / HIGH | **即修正。** 該当パターンを除去してから再スキャン。修正完了まで納品しない |
| MEDIUM | 内容を精査。誤検知なら続行、実リスクなら修正 |
| LOW / INFO | 問題なし。続行 |
| ✓ No suspicious patterns | パス。次のステップへ |

#### フロー

```
パッケージング完了 → skill-security-scan.sh 実行
→ CRITICAL/HIGH検出 → 修正 → 再スキャン → クリアまでループ
→ クリア → ホワイトリスト更新（新規スキルの場合）→ 完了報告
```

#### 新規スキルの場合の追加手順

1. スキャンクリア後、`skill-security/whitelist.json` の `approved` に追加
2. ハッシュを記録:
   - Linux: `sha256sum skill-folder/SKILL.md > skill-security/hashes/<skill-name>.sha256`
   - macOS/BSD: `shasum -a 256 skill-folder/SKILL.md > skill-security/hashes/<skill-name>.sha256`

#### Scanner false-positive hygiene

- セキュリティ系 skill の例文で prompt-injection 文字列を扱う時も、既知の攻撃フレーズをそのまま引用しない。scanner が HIGH として拾うことがある。
- 例文は「rules を上書きしようとする指示」などに安全に言い換え、意味は残しつつ危険な文字列一致を避ける。
- 外部由来の skill bundle を取り込む時は、bundle 親ディレクトリではなく **各 skill ディレクトリごと**に scan する。親だけ渡すと `SKILL.md not found` になり、子 skill の判定としては使えない。
- Cisco scanner が詳細行を出さず `Max Severity: HIGH/CRITICAL` だけを返す場合でも、CRITICAL/HIGH は通過扱いにしない。該当 skill は一旦除外するか、原因箇所を安全に言い換えて再スキャンする。
- 既存の検証済み外部 workflow（例: Superpowers）をローカル移植する時も、全量コピーを優先しない。`brainstorming` や `writing-skills` のように scanner が HIGH/CRITICAL を出すものは、公式 plugin 側に任せる・Codex AGENTS.md に要約する・安全な隣接 skill だけ入れる、の順で扱う。

**このステップを飛ばしてスキルを納品してはいけない。**

### Step 6.5: Skill Routing Audit（推奨）

スキルが10個以上ある環境では、新規スキル追加時に **ルーティング競合チェック** を行う。

#### なぜ必要か
- スキルのdescriptionは互いにAttentionを奪い合う（ゼロサム）
- あるスキルのdescriptionを「押し強め」にすると、別スキルの発火率が下がる
- 論文「Tool Preferences in Agentic LLMs are Unreliable」: description最適化だけでツール使用率が7倍変動

#### チェック項目
1. **競合検出:** 新スキルのdescriptionと既存スキルのdescriptionを比較。トリガーキーワードが重複していないか
2. **境界明確化:** 隣接スキル（adjacent/overlapping）があれば、descriptionに「NOT for: ○○（→ そちらはXXスキルを使う）」を明記
3. **Attention密度:** description内の主張的表現（MUST, ALWAYS, CRITICAL等）が過剰でないか確認

#### 実施方法
```
# 既存スキル一覧のdescription抽出
grep -A2 'description:' ~/.agent-runtime/workspace/skills/*/SKILL.md

# 新スキルのトリガーワードと既存スキルの重複チェック（手動 or サブエージェント）
```

スキル数が多い環境では `skill-auditor` ツール（逆瀬川氏設計）の導入も検討。

#### Description / prompt changes は実測で比べる

description や prompt を改善する時は、**文言を強くしたか** ではなく **実使用でどう変わったか** で判定する。

最低限の比較ループ:
1. **評価セットを作る:** 実際の依頼パターンを3〜5件集める。加えて、隣接skillと迷いやすい **hold-out / 境界ケース** を1〜3件入れる
2. **現行 vs 候補を比較する:** description / trigger wording / routing guidance の変更前後で、どのskillが発火するか・どの手順を選ぶかを見る
3. **success を見る:** そのケースで正しいskill選択・必要十分な成果物・誤ルーティング減少につながったか確認する
4. **efficiency を見る:** 同じ成功率なら、余計なcontext・不要な手順・無駄な往復が減っている方を優先する
5. **hold-out を見る:** 本命ケースだけ良くなっても、隣接skillを食い始めたら採用しない
6. **Pareto改善を優先する:** success維持でefficiency改善、またはefficiency維持でsuccess改善をまず狙う。片方が悪化するなら明示的にトレードオフを書く

実務ルール:
- **主張を盛る前に scenario を足す。** MUST / ALWAYS / CRITICAL を増やすだけの改善は最後の手段
- 可能なら **白紙実行者**（そのskillをまだ読んでいない別セッション / サブエージェント）で試し、作者バイアスを減らす
- 改善案は `latest.md` / queue / references で handoff し、standing rule に昇格させるのは実測で効いた後にする

### Step 6.75: High-Frequency Skill Empirical Gate（必須）

以下のいずれかを満たす skill は **high-frequency** とみなす。
- 週次以上で繰り返し使う
- 他 skill の routing / review / quality gate に効く
- cron / automation / org-wide rule の中核に入る
- `hot.md` に上げたい、または company-wide に再利用したい

high-frequency skill は、納品前に **`../empirical-prompt-tuning/SKILL.md` を読んで empirical test を最低1 iteration 実施** する。

必須項目:
1. Iteration 0（description と body の整合チェック）
2. 白紙実行者テスト（中央値1本 + edge1本を基本）
3. 結果を `reports/empirical-prompt-tuning/` に保存
   - `YYYY-MM-DD-<skill-name>-iterN.md`
   - `latest.md`
   - `latest.json`
4. `next action` を残す

例外:
- dispatch 不可環境では自己再読で代替しない
- `empirical evaluation skipped: dispatch unavailable` と明記して止める

low-frequency / throwaway skill では推奨止まりだが、routing-sensitive なら frequency に関係なくこの gate を優先する。

### Step 7: Iterate

After testing the skill, users may request improvements. Often this happens right after using the skill, with fresh context of how the skill performed.

**Iteration workflow:**

1. Use the skill on real tasks
2. Notice struggles or inefficiencies
3. Identify how SKILL.md or bundled resources should be updated
4. Implement changes and test again
5. **再度 Step 6（Security Audit）を実行** — 変更のたびにスキャン必須
6. If the update was made through `skill_manage`, still verify by re-reading the patched SKILL.md/reference. Run the repository-specific scanner when available; if unavailable or no terminal/shell tool is exposed in the current environment, report that validation was limited to tool success + re-read instead of claiming a scan. When a user asks to update the skill library after a session, prefer concise patching of the loaded class-level skill(s) and report only what changed plus validation; do not create one-off session skills.
7. When patching a namespaced/local skill, verify the active path shown by `skill_view`/`skill_manage` before scanning or reporting. The same skill name may exist in both `~/.hermes/skills/...` and an agent runtime workspace; `skill_manage` may write a different installed copy than the one `skill_view` resolves in the current session. If `skill_view` still shows the old content after a `skill_manage` patch/write, patch the `skill_view.skill_dir` copy directly with normal file tools or report the split-path limitation rather than claiming the loaded skill was updated. If repo-local `search_files` cannot find a bundled script or reference, use the `skill_dir` and `linked_files` paths from `skill_view` as the source of truth. If this split happens during session-review updates, fix the active `skill_view.skill_dir` copy before finalizing; do not leave only the non-active installed copy updated.
8. If memory writes are unavailable in the active environment, do not block skill-library updates on memory persistence. Record reusable procedural learning in the skill/reference itself and mention memory unavailability only if it materially affects the user's request.
9. For session-review skill updates, avoid loading unrelated broad skills just because the update touches the Hermes skill system. Prefer the skill(s) already used in the session plus `skill-creator`; load `hermes-agent` only when the user asks to configure, troubleshoot, or extend Hermes itself.
10. Do not write memory entries just to remember where an active skill lives after `skill_view`; use the `skill_dir` returned by `skill_view`/`skill_manage` for validation in the current session. Persist only durable user/environment facts, not routine skill-edit bookkeeping.
11. For session-review turns, do not save memory as a proxy for a skill update. If memory is unavailable or the learning is procedural, patch the relevant skill/reference and mention memory unavailability only when it materially affects the request.
12. When a session-review request follows a run that already updated skills/artifacts, avoid duplicate or one-off skill churn. Verify the active skill content, add the smallest missing pitfall/checklist item to a loaded class-level skill if one exists, and report “no additional patch” only after verification. If a file-search helper returns no matches for an exact active skill path, fall back to the active `skill_dir` plus direct file reads or shell grep before concluding the patch is absent.