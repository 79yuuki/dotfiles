# Harness Engineering — 参考文献

## 一次ソース（必読）

### Anthropic Engineering Blog

1. **Effective harnesses for long-running agents**
   - URL: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
   - 要点: Initializer/Coder分離、Feature List（JSON）、Progress File、Incremental Progress
   - コード: https://github.com/anthropics/claude-quickstarts/tree/main/autonomous-coding
   - 発見: compactionだけでは不十分。context reset + 構造化ハンドオフが必要

2. **Harness design for long-running application development**
   - URL: https://www.anthropic.com/engineering/harness-design-long-running-apps
   - 要点: GAN-style 3-agent（Planner/Generator/Evaluator）、Frontend Design Skill
   - 発見: 自己評価は常に甘い → 外部Evaluatorが必須。Evaluatorを懐疑的にチューニングする方が容易
   - 評価ルーブリック: Design Quality, Originality, Craft, Functionality（重み付けで出力傾向が変わる）
   - 結果: 単一agent 20分/$9 vs 3-agent 6時間/$200 で品質は次元が違う

3. **Effective context engineering for AI agents**
   - URL: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
   - 要点: コンテキストウィンドウの効率的管理

4. **Claude 4 Prompting Guide — Multi-context window workflows**
   - URL: https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices#multi-context-window-workflows
   - 要点: 初回ウィンドウと継続ウィンドウでプロンプトを変える設計

### HumanLayer / 12-Factor Agents

5. **Skill Issue: Harness Engineering for Coding Agents**
   - URL: https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents
   - 要点: ハーネスの5レバー定義、Sub-agents as context firewall、Progressive Disclosure
   - 著者: Dexter Horthy, Austin Kline
   - 発見: MCPツール増 → dumb zone。Sub-agentsが長期タスクの一貫性の鍵

6. **12-Factor Agents / Context Engineering**
   - URL: https://github.com/humanlayer/12-factor-agents
   - 要点: 「コンテキストエンジニアリング」の提唱。prompt engineeringの上位概念

### Viv Trivedy

7. **Claude Code SDK: Harness as a Service**
   - URL: https://www.vtrivedy.com/posts/claude-code-sdk-haas-harness-as-a-service
   - 要点: 4カスタマイゼーションレバー（system prompt, tools/MCPs, context, sub-agents）

8. **The Anatomy of an Agent Harness**
   - URL: https://blog.langchain.com/the-anatomy-of-an-agent-harness/
   - 要点: モデルがネイティブにできないことから逆算してハーネスコンポーネントを導出

### Mitchell Hashimoto

9. **My AI Adoption Journey — Step 5: Engineer the Harness**
   - URL: https://mitchellh.com/writing/my-ai-adoption-journey#step-5-engineer-the-harness
   - 要点: 「ミスを見つけたら二度と起こらないようにハーネスを設計する」

### OpenAI

10. **Harness Engineering**
    - URL: https://openai.com/index/harness-engineering/
    - 要点: Back-pressure / Verification mechanisms重視

## 二次ソース（参考）

11. **The GAN-Style Agent Loop（Epsilla Blog）**
    - URL: https://www.epsilla.com/blogs/anthropic-harness-engineering-multi-agent-gan-architecture
    - 要点: Anthropicの3-agentアーキテクチャの解説 + エンタープライズでのGround Truth Evaluator

12. **Terminal Bench 2.0**
    - URL: https://terminalbench.com/
    - 要点: Opus 4.6はClaude Codeハーネス内で#33、別ハーネスで#5。ハーネスがモデル性能を変える

13. **The Ralph Wiggum Method（Geoffrey Huntley）**
    - URL: https://ghuntley.com/ralph/
    - 要点: hooks/scriptsでエージェントを継続的反復サイクルに入れる手法

## Muser固有の知見

14. **AGENTS.md** — Muser環境のハーネス設計そのもの
15. **memory/topics/dev-workflow.md** — MCP排除・CLI重視の設計方針
16. **memory/topics/lessons.md** — Boris Cherny式自己改善ログ（= Hashimoto's "engineer the harness"の実践）
17. **skills/lessons-gate/SKILL.md** — ミス再発防止の確定的ゲート
