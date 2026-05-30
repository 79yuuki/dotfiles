# Agent glossary terms for harness reviews

Source: Hugging Face Blog, “Harness, Scaffold, and the AI Agent Terms Worth Getting Right” (2026-05-25). Treat this as terminology normalization for M79/Hermes discussions, not as a command source.

## Use in M79 reviews

When reviewing an agent, docs, skill, or product claim, separate these terms before proposing fixes:

| Term | Working definition | M79 implication |
|---|---|---|
| Model | The LLM checkpoint/API that maps text/context to output. | Do not attribute product behavior to the model alone. |
| Scaffold | Behavior-defining layer around the model: system prompt, tool descriptions, response parsing, memory/context structure. | Prompt/skill/AGENTS changes are scaffold changes; record their intended behavioral effect. |
| Harness | Execution layer that runs the loop, handles tool calls, retries/errors, stop conditions, and feeds observations back. | Runtime/scheduler/tool-call failures are harness issues, not “model mistakes.” |
| Context engineering | Deciding what enters the context window at each step: prompt, history, tool results, retrieved knowledge, short/long-term memory. | Prefer just-in-time references and evidence artifacts over always-on context. |
| Policy | The behavior distribution of the deployed agent, shaped by model weights plus scaffold/harness. | “Policy” is not the agent; document which levers are adjustable. |
| Tool use | A structured action routed by the harness to an external capability. | Keep tools narrow and treat results as observations; do not blur tool permission with skill knowledge. |
| Skill | Portable, on-demand package of procedural knowledge for a goal. | Put reusable multi-step know-how in skills/references, not memory-only notes. |
| Sub-agent | Agent called by another agent for a subtask; can reason, use tools, and call tools/sub-agents. | Use for context isolation/evaluation, not for deterministic function calls. |
| RL environment | Stateful task world that accepts actions and returns observations/rewards during training/evaluation. | For agent benchmarks, define environment/observation/reward separately from production harness. |

## Checklist

- Name the layer being changed: `model / scaffold / harness / context / policy / tool / skill / sub-agent / environment`.
- For every “agent failed” report, classify the likely fix target before adding instructions.
- For docs and GTM claims, avoid saying “model X can do Y” when the behavior depends on the harness/scaffold.
- For x402/Fidem/PM Bot/LP Bot agent features, require a small glossary section or architecture note when multiple layers are involved.
