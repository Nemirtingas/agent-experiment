---
name: plan-lifecycle
description: Create the task branch, worktree and plan folder of a change, seed its task and slice files, validate the plan, close finished tasks and integrate the validated branch into the base branch with one script - fetch and fast-forward, merge --no-ff with a durable record, removal of merged branches and worktrees. Use for every task branch, plan transition, task closure and integration merge of the agent workflow; never do these steps by hand.
---

# Plan lifecycle

The command is `plan-lifecycle` when the installer put it on PATH, otherwise `scripts/plan.sh` next to this file.
It runs from any checkout of the repository and never forces anything; only `propose` and `merge` contact a
remote, to fetch the base branch's upstream.

```bash
plan-lifecycle propose  <type> <name> [base]        # branch, worktree, pending plan folder
plan-lifecycle task     <type> <name> <n> [slice]   # seed task <n>, or one of its slices
plan-lifecycle validate <type> <name> [mode]        # pending -> validated, committed
plan-lifecycle mode     <type> <name> [mode]        # show or change: automatic, interactive
plan-lifecycle close    <type> <name> <n> [slice]   # finished unit: todo -> done, committed
plan-lifecycle merge    <branch> [base] <<'MSG'     # integrate and drop the branch
Merge the <what>

<plan ID>
Validated-by: Lead <provider/model>; <what was run and observed>
Reviewed-by: <provider/model>, pass <n>: approved; verified <what was run>
MSG
plan-lifecycle drop     <branch> [base]             # remove a merged branch and worktree
plan-lifecycle status   [base]                      # open task branches, their plans and units
plan-lifecycle config   [key [value]]               # base, plans, worktrees
plan-lifecycle quota    [provider [low|high]]       # the user's quota per provider
```

`<type>` is `fix`, `feature` or `docs`; `<name>` is lowercase kebab-case. The branch is `<type>/<name>` and its
worktree `<type>_<name>`. `[base]` defaults to `git config workflow.base`. `<n>` is a task number and `[slice]`
one lowercase letter: `task feature login 1 a` is `Task1a`, slice a of task 1.

Every plan is a milestone. Its ID is `M<number>_<name>`: `propose` takes the next number after every plan on
the base branch and on the open task branches, so the plan folders sort in the order the plans were proposed.
The commands take the type and name of the branch and find the plan ID themselves; `status` prints it. Refer to
a unit by milestone and unit: `M3 Task1b`.

## The plan folder

One folder per plan, on the task branch, merged with the code. A unit is what one agent implements in one go:
a task, or a slice of a task that was too large. A sliced task has no file of its own.

```text
docs/plans/
└── M3_login/                          branch feature/login, worktree feature_login
    ├── M3_login.md                    the plan: goal, acceptance, scope, task list, mode
    ├── Task1/
    │   ├── Task1a/
    │   │   ├── Task1a.md              the unit: goal, files, acceptance, tests, tier, effort, status
    │   │   └── Task1a_evidence.md
    │   └── Task1b/
    │       ├── Task1b.md
    │       └── Task1b_evidence.md
    └── Task2/
        ├── Task2.md
        └── Task2_evidence.md
```

## Commands

- `propose` synchronizes the base branch with its upstream (fetch, fast-forward only; it stops when the two have
  diverged), creates the branch from it and its worktree under the worktree directory, gives the plan its
  milestone number, and seeds `<plans>/<id>/<id>.md` from the template with `Status: pending`, uncommitted: the
  Planner writes it.
- `task` seeds a unit file with `Status: todo` and its evidence file from the templates, uncommitted, in a
  pending plan only. A task is either whole or sliced, never both.
- `validate` requires a clean worktree, a committed pending plan and at least one unit. It sets
  `Status: validated` and commits `Validate the <words> plan`. An amendment sets the status back to `pending`
  and is validated again. With `automatic` or `interactive` it also records the mode the user chose in the
  plan file's `Mode` line; without it the line keeps its value, `automatic` in a new plan.
- `mode` prints the plan's mode, or changes it and commits `Run the <words> plan in <mode> mode`, when the user
  switches during the implementation.
- `close` marks one unit `done` in a validated plan and commits the unit file with its evidence file as
  `Close <unit> of the <words> plan`. It requires an evidence file the Developer filled, nothing else
  uncommitted in the worktree, and, unless the unit file says `- Review: no`, a line starting with
  `Reviewed-by: ` in the evidence file: the unit's code is committed first, the review recorded second.
- `merge` reads the merge message on stdin, requires the base branch checked out in a clean worktree, synchronizes
  it, refuses a branch without a plan, a pending plan and a plan with a unit that is not `done`, marks the plan
  `finished` with a commit on the task branch, merges with `--no-ff`, aborts a conflicting merge and says what
  to do, then removes the task branch and its worktree. The merge message is the durable record of the whole
  change: name the plan ID, state the Lead's validation on a `Validated-by` line, and copy the final Reviewer's
  `Reviewed-by` line, or write `Not reviewed: <reason>` when the plan has no final review. These lines are
  trailers: each stays on one line and is exempt from the 72-column wrap of the body.
- `drop` removes a branch and its worktree only when the branch is an ancestor of the base; a worktree with
  uncommitted changes stops it.
- `status` lists every `fix/`, `feature/` and `docs/` branch with its plan status, its units done out of the
  total, whether its worktree is clean, and its position relative to the base (`merged, drop it` when already
  integrated).
- `config` shows the effective `base`, `plans` and `worktrees` settings, defaults marked, or sets one of them
  in the repository's git config (`workflow.base`, `workflow.plans`, default `docs/plans`,
  `workflow.worktrees`, default: the directory above the main worktree).
- `quota` shows or records, in the user's global git config (`workflow.quota.<provider>`), whether a provider's
  subscription leaves a `low` or a `high` quota; not recorded counts as `low`. It needs no repository. The
  `workflow-setup` skill asks the user and records it; the Lead reads it to size agents, effort and reviews.

New worktrees have no submodule content and no ignored local files; the repository's `AGENTS.md` says what a
fresh worktree lacks.
