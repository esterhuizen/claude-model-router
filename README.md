# claude-model-router

Cost-tiered model routing for Claude Code. A **native plugin** — no proxy, no extra process — that dispatches each kind of work to the right Claude tier via pinned subagents and a session-start routing policy. (Not to be confused with proxy-based routers, which rewrite API traffic to route across vendors; this routes between Claude tiers inside Claude Code itself.)

## model-router

Cost-tiered model routing for Claude Code. Ships two things:

1. **Six role agents** with pinned `model:` + `effort:` frontmatter, so delegated work runs on the cheapest adequate tier:

   | Agent | Model | Effort | Job |
   |---|---|---|---|
   | `designer` | Opus 5 | xhigh | Architecture, UX, solution design |
   | `marathon` | Fable 5 | high | Long-horizon autonomous runs (the only Fable pin — gated by the policy's Fable trigger) |
   | `coder` | Opus 5 | high | Code implementation once specified |
   | `reviewer` | Opus 5 | high | Coverage-first routine review |
   | `auditor` | Opus 5 | max | Security-sensitive and fund-moving diffs — mandatory gate |
   | `searcher` | Sonnet 5 | medium | Web/docs/codebase research, summarize-back |
   | `mechanic` | Haiku 4.5 | low | Exactly-specified mechanical work |
   | `Explore` | Haiku 4.5 | low | Read-only codebase scouting |

2. **A SessionStart hook** that injects the routing policy (delegation rules, hard floors, per-stage models for multi-agent runs, cache/settings discipline) into every session — the CLAUDE.md-equivalent that plugins can't otherwise ship.

Rationale (researched & adversarially verified July 2026, post-Opus-5-launch): Opus 5 wins or ties the large majority of published head-to-head benchmarks against Fable 5 at half the price (e.g. Frontier-Bench +9.6pp, GDPval-AA v2 +114 Elo, ARC-AGI-3 ~+10pp), while Fable's verified wins are sub-2pp. Fable's remaining edges — long-horizon multi-day autonomy and low-hallucination recall — are exactly what the `marathon` trigger reserves it for. Security work is deliberately routed *away* from Fable: its safety classifiers refuse benign security-adjacent work (~20% refusal-fallback observed on Terminal-Bench), whereas Opus 5 intervenes ~85% less and is Anthropic's most-aligned model to date.

## Install on any machine

```
/plugin marketplace add esterhuizen/claude-model-router
/plugin install model-router@esterhuizens
```

Or headless: `claude plugin install model-router@esterhuizens`.

## Try locally without installing

```
claude --plugin-dir /path/to/claude-model-router/plugins/model-router
```

## Caveats

- **Explore override:** plugin agents have the lowest precedence and are namespaced (`model-router:Explore`), so the plugin copy may not replace the *built-in* Explore agent (which inherits the expensive main model). To guarantee the override on a machine, also copy `plugins/model-router/agents/explore.md` to `~/.claude/agents/`.
- **One delivery mechanism per machine:** the plugin is the source of truth. Don't also keep copies of these agents or the policy in `~/.claude/agents/` / `~/.claude/CLAUDE.md` (user-level agents would shadow plugin updates, and the policy would load twice). Exception: the Explore override shim above.
- **Web sessions (claude.ai/code):** plugins don't load there. For repos you work on via web, commit the agents into the project instead: `cp plugins/model-router/agents/*.md <repo>/.claude/agents/`.
- **Haiku prompt overflow:** under very heavy MCP tool loads, Haiku-pinned agents (200K context) can fail with "prompt too long" — bump that agent's `model:` to `sonnet` if it happens.
- **Settings traps the policy warns about:** don't type `/model <name>` directly (persists to settings since v2.1.153); never put `CLAUDE_CODE_SUBAGENT_MODEL` in settings.json (it overrides every per-agent pin).
