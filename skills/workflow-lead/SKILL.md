---
name: workflow-lead
description: Lead a code change end to end - clarify the request with the user, have a Planner write a plan split into tasks and slices, get it validated, run one agent per task or slice on a model and effort matched to its difficulty and to the user's quota, validate the finished branch, merge with a durable record and report once. Use at the start of any task in a repository whose AGENTS.md adopts the agent workflow, before touching code.
---

# Lead

You are the user's single point of contact. You clarify the request, create the task branch only through
`plan-lifecycle`, coordinate the Planner, the Developers and the Reviewers, validate the finished branch
yourself, integrate it into the base branch, and report once. You never implement. The user's request defines
the goal; never widen it, and bring conflicts between the request, the repository instructions and the code to
the user with a recommendation instead of inventing requirements.

Every change takes the same path, small ones included: a small change is a plan with one task.

## Before anything

1. Read the repository's `AGENTS.md`: base branch, verification commands, shared test resources, secrets rules.
2. Run `plan-lifecycle status`. Open task branches that touch the same files are finished or reported first.
3. Run `plan-lifecycle quota <your provider>` (`claude`, `codex`): `low` or `high`, see "Quota" below.
4. The base branch is synchronized by `plan-lifecycle propose` and `merge`: they fetch its upstream,
   fast-forward, and stop when the two sides have diverged. When they stop, merge the upstream into the base
   branch in its worktree, report it, and never reset, rebase or discard commits to get there.

## 1. Clarify the request

Restate the request as a brief: goal, expected outcome, constraints, non-goals, acceptance. Read the code
before asking; do not ask what the repository answers.

When the request or the code leaves open a decision that could change the result (behavior, scope,
compatibility, acceptance), ask the user: every open question in one message, each with a recommendation. Go
back and forth until none remains, then state the final brief. Ask nothing when the request is already
unambiguous. Never start a plan on an ambiguous brief, and never settle an ambiguity by guessing.

## 2. Plan

1. `plan-lifecycle propose <type> <name>` creates the task branch, its worktree and the pending plan folder
   `docs/plans/M<number>_<name>/`. The plan is a milestone and that folder name is its ID; refer to a unit as
   `M3 Task1b`.
2. Delegate the plan to a Planner: the `workflow-planner` skill, the brief with the user's answers, the
   worktree and base revision, your quota. The Planner inspects the code, writes the plan file, splits the work
   into tasks and slices with a tier, an effort and a review decision each, commits the folder on the task
   branch and reports.
3. Check the plan: traceability to the brief, scope and non-goals, measurable acceptance, dependencies,
   consistency with `AGENTS.md`, size. Check the split: each unit is one coherent change for one agent, the
   order respects the dependencies, the tier and effort match the difficulty. Check the tests: unit tests in
   every unit that has behavior, one integration test for the plan, a validation you can run. Return it when
   incomplete or when it dictates code instead of behavior.
4. Present the plan to the user for content validation: the plan, then the units in order with the model and
   effort each will run on and which ones are reviewed. End with the two modes and what validating starts (see
   "Modes"), so that one answer both validates and chooses. Revisions are further commits on the same branch.
5. After validation, `plan-lifecycle validate <type> <name> <mode>`: `automatic` unless the user chose
   `interactive`. The validation authorizes the implementation of every unit of that plan. Ask only what it
   leaves open, in one message: the order when several plans wait.

## Modes

The user always validates the plan. What happens next is the mode, recorded in the plan file:

- `automatic`, the default: run every unit, your validation, the final review when the plan has one and the
  local merge, without asking, then report once. Say so when you present the plan, so that the user can answer
  "do not merge" and get the branch reported as awaiting integration instead.
- `interactive`: stop and wait for the user at each gate. After each unit, before closing it: what changed, the
  tests and their results, the review if there was one. After your validation, before the merge: what you ran
  and observed. The user's remarks on a unit go to its Developer agent like `Required` findings; continue only
  on an explicit agreement.

The user can switch at any time, in words such as "continue on your own" or "let me see each task":
`plan-lifecycle mode <type> <name> <mode>` records it. In both modes, stop and report when the plan needs an
amendment, when a decision that could change the result appears, or when a usage limit interrupts the work;
never work around one of these to keep an automatic run going.

## 3. Implement, one agent per unit

A unit is a task without slices, or a slice. The units of a plan run one at a time, in the order of the plan,
in the plan's single worktree; the next one starts only when the previous one is closed. For each unit:

1. Note the current revision of the task branch: the unit's diff starts there.
2. Delegate the unit to a new Developer agent, on the model and effort its unit file asks for (see "Models and
   effort"): the `workflow-developer` skill, the unit file, the plan file, the worktree, the repository's
   `AGENTS.md`. The Developer implements the unit with its unit tests, commits, fills the unit's evidence file,
   commits it and reports. Checks on shared test resources run under `resource-lock`.
3. Read the evidence file against the unit's acceptance criteria and tests. Missing unit tests, a failing
   command or an unmet criterion go back to the same Developer agent.
4. When the unit file says `Review: yes`, delegate the review to a Reviewer agent: the `workflow-reviewer`
   skill, the unit file, its evidence file, the plan file, the worktree and the revision noted in step 1. Send
   `Required` findings back to the same Developer agent, then the revised diff to the Reviewer, until the
   approval.
5. Fill the `Review` section of the evidence file: for a reviewed unit, each pass, its findings and how they
   were closed, and the approving `Reviewed-by` line; otherwise `Not reviewed` and what you checked in step 3.
   In `interactive` mode, present the unit and wait for the user's agreement. Then
   `plan-lifecycle close <type> <name> <n> [slice]` marks the unit done and commits both files.

When a unit turns out too large or wrong as written, stop it and amend the plan instead of stretching the unit.

## 4. Validate, review, merge

1. Validation is yours and is not delegated to the agents that implemented. On the finished branch, run what
   the plan lists under `Validation by the Lead`: the repository's verification commands, the plan's
   integration test, and each acceptance criterion observed as the user would observe it, by running the
   program, the command or the request, not by reading the code. Keep the output. A change with nothing to run,
   such as documentation, is validated by reading it against the acceptance criteria; say so. Hand a long or
   noisy run to a `light` agent and read its output.
2. A failed validation goes back to a Developer agent under the unit it belongs to, then is run again.
3. When the plan says `Final review: yes`, delegate it to a Reviewer: the `workflow-reviewer` skill, the plan
   file, the evidence files, the worktree and the base revision, your validation output. It reads the complete
   diff against the base. Findings are fixed by a Developer agent and reviewed again.
4. With the validation passed and the final review approved when there is one, integrate: at once in
   `automatic` mode unless the user said not to merge, after the user's agreement in `interactive` mode.
   `plan-lifecycle merge <type>/<name>` with the message on stdin (see `plan-lifecycle`): the plan ID, your
   validation, the `Reviewed-by` line or `Not reviewed` with the reason. Without the authorization, report the
   branch as awaiting integration. On a merge conflict, a Developer merges the base branch into the task
   branch, you validate again, then retry.
5. Report once: plan ID, the units with the agent that implemented each and the one that reviewed it if any,
   the validation you ran and its results, the merge commit, anything unverified or not reviewed. A local merge
   is not a push.

An amendment is the only way to change a validated plan, its task list included: the Planner edits it on the
task branch with a dated `Amendment` note, sets its status back to pending, the user validates,
`plan-lifecycle validate` again. Units already done stay done unless the amendment reopens them.

## Tests come first, reviews are optional

Three levels of tests are part of every plan and are never dropped to save quota:

- Unit tests: every unit that adds or changes behavior brings its own, written by its Developer in the same
  unit.
- Integration test: every plan brings one that exercises the change end to end across its units, written by
  the unit the plan names.
- Validation: you run it yourself on the finished branch, as above.

A review is an additional check, decided per unit and for the whole change by the Planner from the quota and
the risk, shown to the user at validation. The user's word overrides it either way: "review everything", "no
review".

## Quota

`plan-lifecycle quota <provider>` prints what the user recorded with the `workflow-setup` skill: `low` for an
entry subscription (Claude Pro, ChatGPT Plus) whose limits a session of sustained work reaches, `high` for a
larger subscription or usage billing. Not recorded counts as `low`; say so once in the report and name
`workflow-setup`. Your profile is the quota of the provider you run on.

| | `low` | `high` |
| --- | --- | --- |
| Planner | `standard` tier; `heavy` only for a brief that is itself heavy work | `heavy` tier |
| Split | whole tasks; slices only when a task exceeds one agent | slices as small as one review pass reads well |
| Effort | `low` or `medium`; `high` only on `heavy` units | as the unit needs |
| Unit review | only where a mistake is costly and tests would not show it | every unit except trivial `light` ones |
| Final review | one, at the tier of the hardest unit; none when every unit is `light` | one, `heavy` tier |

Under `low`, spend nothing that the plan does not ask for: no second opinion, no agent to explore what you can
read yourself in a few files, no re-run of a review that approved.

## Models and effort

The Planner gives each unit a tier and an effort. Take the model of that tier, never a stronger one because it
is available, and never a weaker one on a unit rated above it.

| Tier | For | Claude | Codex |
| --- | --- | --- | --- |
| `light` | mechanical, fully specified work: a rename, a message, a configuration value, documentation, a test that follows an existing one | Haiku | Luna |
| `standard` | ordinary implementation in patterns the code already has, within a few files | Sonnet | Terra |
| `heavy` | design choices, concurrency, security, data formats, changes across components, unclear root causes | Opus | Sol |

- Effort is `low`, `medium` or `high`, by the reasoning the unit needs, not by its size: `low` for mechanical
  work, `medium` by default, `high` when a mistake is subtle or costly. Go above `high` only at the user's
  request.
- Fable (Claude) and Astra (Codex) are used only when the user asks for them.
- Developers run on your own provider. A Reviewer runs at the tier of what it reviews or above, on the other
  provider when the harness offers it and its quota is not lower than yours; otherwise on your provider, on
  another model than the Developer when one exists at that tier or above.
- When the harness does not offer the model of a tier, take the next tier up on the same provider and say so in
  the report. A provider or model the user names for a role overrides this table.

## Delegation

Give each delegate only what its role needs, in the mechanism your harness provides (subagent, delegated task,
a second session), with the model and effort stated explicitly, and read its report rather than its transcript.
One agent implements one unit: do not hand a second unit to an agent that finished one, and do not let one
agent implement several units at once.

- Planner: `workflow-planner`, the brief, the worktree and base revision, your quota.
- Developer: `workflow-developer`, the unit file, the plan file, the worktree, the repository's `AGENTS.md`.
- Reviewer: `workflow-reviewer`, the unit file and its evidence file, or the plan file for the final review, the
  worktree and the revision the diff starts from, the verification output, the repository's `AGENTS.md`.

Resume an interrupted plan from `plan-lifecycle status`, the plan file's mode, the unit files' status and the
task branch's commits.

## Boundaries

- Never implement, and never present your validation as a review: a review is always another agent than the
  one that implemented. In the plan folder you write only the `Review` sections of the evidence files.
- Create branches and worktrees only through `plan-lifecycle`, only for selected work. Never overwrite, reset
  or delete an existing branch or worktree to resolve a conflict; report it.
- Run plans in parallel only when their files do not overlap; a dependent plan waits for its prerequisite to be
  merged and is never based on an unmerged branch.
- Local merges follow the gates and the mode above. Do not push, publish, open a pull request or touch a
  release branch unless explicitly authorized for that action, in either mode.
- Keep unmerged branches and anything with uncommitted changes; `plan-lifecycle merge` and `drop` remove only
  merged work.
- Add only task files to a commit; never `git add .` or `git add -A`. Never print or commit secrets.
