---
name: workflow-setup
description: Record how much quota the user's AI subscriptions leave for the agent workflow - low for an entry plan such as Claude Pro or ChatGPT Plus, high for a larger plan or usage billing - so the Lead sizes agents, effort and reviews accordingly. Use right after installing the agent workflow, when the user changes subscription, hits usage limits during a plan, or asks to make the workflow cheaper or more thorough.
---

# Workflow setup

The agent workflow spends quota on every agent it starts. This skill asks the user what their subscriptions
allow and records it once per machine; the Lead and the Planner read it at the start of every change. It can be
run again at any time: it only replaces the recorded levels.

## The form

Show the current values first: `plan-lifecycle quota`. Then ask the user, in one message, with your harness's
question form when it has one:

1. Which providers they use with the workflow: Claude, Codex, others.
2. For each one, the level:
   - `low`: an entry subscription, such as Claude Pro or ChatGPT Plus, or any plan whose limits they reach
     within a session of sustained work.
   - `high`: a larger subscription, such as Claude Max or ChatGPT Pro, a team or enterprise plan with ample
     limits, or usage billing they do not want to ration.

Recommend `low` when the user hesitates: it is the default, and the level can be raised later. Do not guess the
level from the model you run on, and do not ask for account details, keys or invoices.

## Recording

```bash
plan-lifecycle quota claude low      # one line per provider the user named
plan-lifecycle quota codex high
plan-lifecycle quota                 # show what is recorded
```

The provider is one lowercase word: `claude`, `codex`, or the name the user gives another provider. The levels
are stored in the user's global git configuration (`workflow.quota.<provider>`), for every repository on the
machine; nothing is written in a repository. A provider that is not recorded counts as `low`.

## What the level changes

Tell the user in two or three lines what they chose. The tests never change: unit tests in every unit, one
integration test per plan, the Lead's validation before the merge.

- `low`: the Planner runs on the standard model; plans keep whole tasks and slice only when needed; effort stays
  low or medium except on hard units; a unit is reviewed only where a mistake is costly and tests would not show
  it; one final review, none for a change made only of trivial units.
- `high`: the Planner runs on the strongest regular model; tasks are sliced for reviewability; every unit but
  trivial ones is reviewed; a final review on the strongest regular model.

The level of the provider the Lead runs on decides. A Reviewer goes to the other provider only when that
provider's quota is not lower. For one change, the user can still say "review everything" or "no review".

## Boundaries

- Record only what the user answered. Do not change the level on your own when a limit is reached during a
  plan: report it, and suggest running this skill.
- Do not edit the workflow's skills or a repository's `AGENTS.md` to change these rules for one user.
