#!/usr/bin/env bash
# Emits the model-routing policy as SessionStart additionalContext.
# The policy text deliberately contains no double quotes or backslashes,
# so the only JSON escaping needed is newline -> \n.
set -euo pipefail

policy=$(cat <<'EOF'
Model routing - cost policy (model-router plugin)

Treat premium-model tokens as scarce. Keep the main loop for thinking, decisions, and synthesis; delegate execution to the plugin role agents (each pins its own model + effort):
- designer (Opus 5, xhigh): architecture, UX, and solution-design decisions.
- marathon (Fable 5, high): long-horizon autonomous runs only - see the Fable trigger below.
- coder (Opus 5, high): code implementation once the task is specified.
- reviewer (Opus 5, high): routine review after non-trivial changes.
- auditor (Opus 5, max): security-sensitive review and any diff that can move funds.
- searcher (Sonnet 5, medium): web/docs/codebase research and summarize-back.
- mechanic (Haiku 4.5, low): exactly-specified mechanical work.
- Explore (Haiku 4.5, low): read-only codebase scouting.

Fable 5 trigger. Route to Fable 5 (the marathon agent) only when BOTH hold: the run is expected to proceed autonomously for roughly an hour or more of wall-clock work without a human turn (overnight, cross-session, or multiday goal-directed work), AND the brief is underspecified in a way the model must resolve alone because no human is available mid-run. Additionally at least one of: the run sustains several concurrent long-lived subagents with two-way coordination, or Opus 5 at max effort has already produced two or more correction cycles on the same defect without new information. A task that is merely difficult, important, or expensive to get wrong does NOT qualify - difficulty is answered by raising effort on Opus 5, not by changing model. Prefer explicit user confirmation before launching a marathon run: Fable draws from a pool capped at 50 percent of weekly plan limits and burns them fastest.

Never route to Fable 5: security-, exploit-, malware- or bio-adjacent work (its safety classifiers decline benign instances and a mid-run refusal is unrecoverable - use auditor on Opus 5 instead); prompts that ask the model to reproduce or explain its own reasoning as output text; work that turns on very recent facts (Opus 5 has the newer knowledge cutoff); interactive or latency-sensitive work (Fable thinking cannot be disabled and single turns can run for minutes). If Fable is unavailable or refuses, fall back to Opus 5 at max effort and proceed - no work waits for Fable.

Fund-moving and security-sensitive changes (hard process floor): implementation stays in the main loop on Opus 5, and no such change ships without ALL of: an auditor pass at effort max on the diff, a passing test or dry-run whose output is quoted, and explicit human confirmation. Safety here is bought with review and gating, never traded away for speed.

Escalation ladder: raise effort before changing model - Opus 5 high, then xhigh, then max, and only then Fable 5 via marathon. Move up one rung at a time on evidence (the previous rung actually produced a wrong or incomplete result on this task), not anticipation. Model changes happen only at a subagent or session boundary, never mid-conversation (prompt caches are model-scoped). Escalating to marathon means a written hand-off - goal, constraints, what was tried, what it produced - not continuing the current thread on a different model. De-escalate afterwards: once marathon returns, execution goes back to coder on Opus 5.

Multi-agent runs (Workflow/ultracode): set per-stage model and effort - scan/search/inventory stages sonnet (medium) or haiku (low); implementation stages opus (high); verify/judge stages opus (high); design/synthesis stages opus (xhigh). Use fable for a stage only if that stage itself meets the Fable trigger above.

Discipline: never change the main-session model mid-conversation. Never type /model NAME directly - since v2.1.153 it silently persists to user settings; use claude --model ... at launch (session-only) or the bare /model picker with the s key. Never put CLAUDE_CODE_SUBAGENT_MODEL in settings.json - it overrides every per-agent pin; use it only per-launch to cap a huge fan-out.
EOF
)

esc=${policy//$'\n'/\\n}
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$esc"
