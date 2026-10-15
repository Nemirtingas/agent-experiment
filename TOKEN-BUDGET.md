# Instruction context budget — optional measurement reference

This document is package material, not mandatory operational context. Counts below were reproduced against the
unconfigured local v2 and v3 packages. Tokens are rounded decoded UTF-8 characters / 4, not tokenizer, API, cache,
billing or elapsed-time measurements. Do not multiply these values by every conversation message.

## Fresh context estimates

| Profile | v2 characters | v3 characters | v2 estimated tokens | v3 estimated tokens |
| --- | ---: | ---: | ---: | ---: |
| Lead, full lifecycle | 16,560 | 21,141 | 4,140 | 5,285 |
| Planner | 7,670 | 8,321 | 1,918 | 2,080 |
| Developer | 7,381 | 7,361 | 1,845 | 1,840 |
| Reviewer | 7,381 | 7,782 | 1,845 | 1,946 |
| Four fresh contexts | 38,992 | 44,605 | 9,748 | 11,151 |
| Compact, three fresh contexts | — | 38,764 | — | 9,691 |

Full v3 is **14.4% more instruction characters** than full v2, reflecting explicit runtime/identity procedures.
Compact v3 is **0.6% fewer instruction characters** than the four-context v2 baseline. Compact combines Lead and
Planner loading sets once in the same context; Developer and Reviewer remain separate. This is a modeled loading
comparison, not proof of runtime improvement. Role reuse is not available by silently dropping independent review.

## Counted inputs

Every profile loads common bootstrap, shared AGENTS.md and PROJECT.md once. Additional v3 sets:

- Lead: its role, WORKFLOW.md, PLANS/README.md, PLANS/TEMPLATE.md, EXECUTION.md and blank HANDOFF.json format.
- Planner: its role, plan template and CODING.md. Actual routing can read just verification/platform sections;
  this conservative estimate includes the whole coding file.
- Developer: its role and CODING.md.
- Reviewer: its role, CODING.md and blank REVIEW.json result format.
- Compact Lead+Planner: union of their inputs, with shared files counted once in that context.

Paths in additional sets are under agents-base/AGENTS/. V2 uses its documented loading sets. Excluded in both:
real plans, active task records/results, code/diffs/logs, private preferences, engine/history injection, optional
ADAPTER.md, installation/readme/change documentation, utilities/tests and this report. A real task's selected plan
and record must still be loaded; their variable size is not estimated here. First initialization counts the blank
format, not subsequent unnecessary rereads. Tool output and fresh review contexts can outweigh instruction savings.

## Reproduce

From package root, Python 3.9+:

```bash
python3 -B tools/measure_context.py --baseline ../agent-repo-template-generic-v2
python3 -B tools/measure_context.py --baseline ../agent-repo-template-generic-v2 --json
```

Recalculate after changing instructions; the script is the executable loading definition. No external packages or
network access are required. Four-profile totals sum characters before rounding tokens, so rounded rows may differ
from a rounded total by one token.

## Observe whole-task outcomes

For comparable tasks, optionally record metrics alongside task state in metrics.json: task category/route, start
and integration time, input/output tokens, cached input tokens when available, agent starts, handoff rounds,
clarifications, review passes, network calls and tool-output bytes. Unknown counters remain null. Keep raw logs by
reference; do not enlarge every mandatory handoff with telemetry or private provider data.

Compare bounded fixes, multi-file features and dependent tasks separately. Record model, engine, environment and
verification coverage, and ensure each route satisfies the same acceptance and review requirements. Fewer messages
alone do not prove lower cost; shorter prompts can still cause more retries. Use observations to decide whether
compact planning, delta review, archival batching or context reuse actually help before generalizing them.
