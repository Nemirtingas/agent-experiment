---
name: plan-lifecycle
description: Create task branches and worktrees, seed and validate plan files, and integrate approved branches into the base branch with one script - fetch and fast-forward, merge --no-ff with a review record, removal of merged branches and worktrees. Use for every task branch, plan transition and integration merge of the agent workflow; never do these steps by hand.
---

# Plan lifecycle

The command is `plan-lifecycle` when the installer put it on PATH, otherwise `scripts/plan.sh` next to this file.
It runs from any checkout of the repository and never forces anything; only `branch`, `propose` and `merge`
contact a remote, to fetch the base branch's upstream.

```bash
plan-lifecycle branch   <type> <name> [base]    # light path: branch and worktree
plan-lifecycle propose  <type> <name> [base]    # plan path: branch, worktree, pending plan
plan-lifecycle validate <type> <name>           # pending -> validated, committed
plan-lifecycle merge    <branch> [base] <<'MSG' # integrate and drop the branch
Merge the <what>

<plan ID or brief>
Reviewed-by: <provider/model>, pass <n>: approved; verified <what was run>
<verification run, shared resources included>
MSG
plan-lifecycle drop     <branch> [base]         # remove a merged branch and worktree
plan-lifecycle status   [base]                  # open task branches and their plans
plan-lifecycle config   [key [value]]           # base, plans, worktrees
```

`<type>` is `fix`, `feature` or `docs`; `<name>` is lowercase kebab-case. The plan ID and the worktree name are
`<type>_<name>`; the branch is `<type>/<name>`. `[base]` defaults to `git config workflow.base`.

- `branch` and `propose` synchronize the base branch with its upstream (fetch, fast-forward only; they stop when
  the two have diverged), then create the branch from it and its worktree under the worktree directory.
  `propose` also seeds `<plans>/<type>_<name>.md` from the template with `Status: pending`, uncommitted: the
  Planner writes and commits it.
- `validate` requires a clean worktree and a committed pending plan. It sets `Status: validated` and commits
  `Validate the <words> plan`. An amendment sets the status back to `pending` and is validated again.
- `merge` reads the merge message on stdin, requires the base branch checked out in a clean worktree, synchronizes
  it, refuses a pending plan, marks a validated plan `finished` with a commit on the task branch, merges with
  `--no-ff`, aborts a conflicting merge and says what to do, then removes the task branch and its worktree. The
  merge message is the durable review record: name the plan ID or the brief, copy the Reviewer's `Reviewed-by`
  line, and state the verification that was run. The `Reviewed-by` line is a trailer: it stays on one line and
  is exempt from the 72-column wrap of the body.
- `drop` removes a branch and its worktree only when the branch is an ancestor of the base; a worktree with
  uncommitted changes stops it.
- `status` lists every `fix/`, `feature/` and `docs/` branch with its plan status, whether its worktree is clean,
  and its position relative to the base (`merged, drop it` when already integrated).
- `config` shows the effective `base`, `plans` and `worktrees` settings, defaults marked, or sets one of them
  in the repository's git config (`workflow.base`, `workflow.plans`, default `docs/plans`, `workflow.worktrees`,
  default: the directory above the main worktree).

New worktrees have no submodule content and no ignored local files; the repository's `AGENTS.md` says what a
fresh worktree lacks.
