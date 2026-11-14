# agent-workflow

A portable set of skills and two shell commands for making code changes with coding agents: Claude Code, Codex,
OpenCode, and any agent that reads `SKILL.md` skills and `AGENTS.md` instructions. It installs once per machine
and applies to every repository that adopts it.

What it gives you:

- One path for every change. The Lead clarifies the request with the user until nothing is ambiguous, a Planner
  writes a plan and splits it into tasks, and into slices when a task is too large, the user validates it, one
  agent implements each task or slice, the Lead validates the result and merges.
- A model and an effort matched to each task: three tiers, `light`, `standard` and `heavy`, mapped to Haiku,
  Sonnet and Opus for Claude and to Luna, Terra and Sol for Codex. Fable and Astra only when the user asks.
- Tests at three levels, always: unit tests written with each task, one integration test per plan, and a
  validation run by the Lead on the finished branch.
- Reviews where they pay: a Reviewer on another model or provider checks the tasks and the plans the Planner
  marked, according to the risk and to the quota the user recorded. On an entry subscription (Claude Pro,
  ChatGPT Plus) the workflow starts fewer agents and reviews only what is risky.
- Four roles as skills: Lead, Planner, Developer, Reviewer. Any agent can take any role.
- One task branch and one worktree per change, created and removed by the `plan-lifecycle` command. The plan
  folder lives on the task branch and is merged with the code, so the integration branch keeps every plan, its
  tasks and their evidence.
- A durable record: each task has an evidence file, and the merge commit message names the plan, the Lead's
  validation and the Reviewer's `Reviewed-by` line when there was a review.
- `resource-lock`, an exclusive lock on shared test resources, visible from every worktree and every agent.

## Contents

```text
agent-workflow/
├── README.md
├── install.sh                     install, uninstall, prepare a repository
├── install.ps1                    the same from PowerShell, for Windows
├── .claude-plugin/plugin.json     the directory is also a Claude Code plugin
├── skills/
│   ├── workflow-lead/SKILL.md     entry point: clarify, drive the roles, validate, merge, report
│   ├── workflow-planner/SKILL.md  write the plan and split it into tasks and slices
│   ├── workflow-developer/SKILL.md  implement one task or slice with its unit tests
│   ├── workflow-reviewer/SKILL.md   review one task or slice, or the whole change
│   ├── workflow-setup/SKILL.md    the quota form: low or high, per provider
│   ├── plan-lifecycle/            SKILL.md, scripts/plan.sh, assets/ (plan, task and evidence templates)
│   └── resource-lock/             SKILL.md, scripts/lock.sh
└── templates/AGENTS.md            the per-repository instruction file to fill in
```

Every skill follows the Agent Skills format: a directory with a `SKILL.md` whose front matter has `name` and
`description`, plus optional `scripts/` and `assets/`. Only `name` and `description` are used, so the skills
load in any agent that implements the format.

## Requirements

- POSIX `sh`, `git` 2.31 or later, `readlink -f` or `realpath`. On Windows, Git for Windows provides all three
  through its `sh.exe`, and PowerShell 5.1 or 7 runs the installer.
- An agent that reads skills from one of the directories below and reads the repository's `AGENTS.md`.

## Install once per machine

```sh
git clone https://github.com/Nemirtingas/agent-experiment.git ~/agent-workflow   # or copy it anywhere
~/agent-workflow/install.sh install
```

This links the seven skills into `~/.agents/skills` (read by Codex and OpenCode) and `~/.claude/skills` (read by
Claude Code and OpenCode), and links the commands `plan-lifecycle` and `resource-lock` into `~/.local/bin`.
Check that `~/.local/bin` is on your `PATH`, then:

```sh
plan-lifecycle help
resource-lock help
```

Then record your quota, once per machine and again whenever your subscription changes. In your agent:

```text
Use the workflow-setup skill.
```

It asks which providers you use and whether each subscription leaves a `low` quota (Claude Pro, ChatGPT Plus,
any plan whose limits you reach in a working session) or a `high` one (Claude Max, ChatGPT Pro, usage billing),
and stores the answer in your global git configuration. The same thing by hand:

```sh
plan-lifecycle quota claude low
plan-lifecycle quota codex high
plan-lifecycle quota              # show what is recorded
```

Until a quota is recorded the workflow assumes `low`, so that it stays usable on any subscription.

Options:

- `install.sh install opencode` adds `~/.config/opencode/skills`; `install.sh install <dir>` targets any
  directory an agent scans for `<name>/SKILL.md`. OpenCode scans several of these directories; if it reports
  duplicate skill names, keep one target and `install.sh uninstall` the others.
- `install.sh install --copy ...` copies instead of linking, for machines where the kit directory is not kept.
  Copies do not follow updates; run the same command again after updating.
- `install.sh install --project <repo>` installs into `<repo>/.agents/skills` and `<repo>/.claude/skills`
  instead of the home directory, for a repository that ships its own copy. Commit or ignore them as you prefer.
- `install.sh uninstall` removes exactly what `install` created and nothing else.
- Claude Code can also load the directory as a plugin: `claude --plugin-dir ~/agent-workflow`, or list it in a
  marketplace. Plugin skills are then named `agent-workflow:workflow-lead` and so on.

Update: `git -C ~/agent-workflow pull`. Linked installs follow immediately.

### Windows

From PowerShell, in a clone of this directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 install
```

Same commands, targets and options as `install.sh`, as PowerShell parameters: `-Copy`, `-Project <repo>`,
`-NoBin`, and `-AddToPath` to append the command directory to the user `PATH`. Skill directories are under
`%USERPROFILE%`: `.agents\skills`, `.claude\skills`, `.config\opencode\skills`. Skills are symbolic links when
the session may create them (Developer Mode or an elevated prompt), directory junctions otherwise, copies with
`-Copy`; the three agents follow all of them.

The commands are POSIX shell scripts. The installer writes `plan-lifecycle.cmd` and `resource-lock.cmd` for
PowerShell and cmd, and extensionless wrappers of the same names for Git Bash, all running through the `sh.exe`
of Git for Windows. The `.gitattributes` of this repository keeps the scripts in LF so `sh` accepts them. Under
WSL, run `install.sh` inside the distribution instead; the agents there see the Linux home directory.

## Set up a repository

Run once in a checkout of the integration branch:

```sh
~/agent-workflow/install.sh project <checkout> --base develop
```

It copies `templates/AGENTS.md` to the repository root when there is none, creates `docs/plans/.gitkeep`, and
records the base branch in the repository's git config (`workflow.base`). Then:

1. Fill in every `<placeholder>` of `AGENTS.md`: what the repository is, build commands, unit and integration
   test commands and conventions, layout and invariants, style, shared test resources and their lock names,
   production hosts, secrets rules, the changes that are always reviewed. Keep it under about 200 lines; the
   roles and the procedure are in the skills.
2. If the repository already has an `AGENTS.md`, merge the `## Workflow` section of the template into it. If it
   has a `CLAUDE.md`, add a line `@AGENTS.md` to it: Claude Code reads `AGENTS.md` on its own only when no
   `CLAUDE.md` is present.
3. Commit `AGENTS.md` and `docs/plans/.gitkeep` on the integration branch.

Settings, all optional, stored with `plan-lifecycle config <key> <value>`:

- `base`: the integration branch. Without it every command needs the base branch as an argument.
- `plans`: the directory of the plan folders, default `docs/plans`.
- `worktrees`: where task worktrees are created. Default: next to the main checkout, or, when the repository is a
  bare `<dir>/.git`, inside `<dir>`. The second layout keeps every worktree of a repository under one directory:

```sh
mkdir myrepo && git clone --bare <url> myrepo/.git
git -C myrepo/.git worktree add ../develop develop     # one worktree per branch, as children of myrepo/
```

Personal preferences (language of the conversation, favorite provider for reviews) belong in the agent's own
user-level file, not in the repository: `~/.claude/CLAUDE.md` for Claude Code, `~/.codex/AGENTS.md` for Codex,
`~/.config/opencode/AGENTS.md` for OpenCode.

## Use

Start every task by giving the request to the Lead:

```text
Use the workflow-lead skill. <the request>
```

The Lead reads `AGENTS.md`, runs `plan-lifecycle status` and `plan-lifecycle quota`, then:

1. Clarifies. It restates the request as a brief and, when a decision that could change the result is open,
   asks its questions in one message, each with a recommendation, until nothing is ambiguous. A clear request
   gets no question.
2. Plans. `plan-lifecycle propose feature <name>` creates the branch, the worktree and the plan folder. The
   Planner, with the `workflow-planner` skill, inspects the code, writes the plan (behavior and acceptance, not
   code), splits it into tasks, and into slices when a task is too large for one agent, and gives each one a
   tier, an effort, its unit tests and a review decision.
3. Gets the plan validated. The Lead presents the plan and the list of tasks with the model each will run on;
   the user validates the content and chooses the mode, `automatic` by default.
   `plan-lifecycle validate feature <name> [mode]` records both. The validation authorizes the implementation.
4. Implements, one agent per task or slice, one at a time, in the order of the plan. Each Developer, with the
   `workflow-developer` skill, implements its unit with its unit tests, fills the unit's evidence file and
   commits. When the unit is marked for review, a Reviewer with the `workflow-reviewer` skill checks it. The
   Lead closes the unit with `plan-lifecycle close feature <name> <n> [slice]`.
5. Validates. The Lead itself runs the repository's commands and the plan's integration test on the finished
   branch, and observes each acceptance criterion as the user would. When the plan asks for a final review, a
   Reviewer reads the whole diff.
6. Merges and reports once. `plan-lifecycle merge feature/<name>` marks the plan `finished`, merges, and
   removes the branch and worktree. The plan folder is now on the integration branch, next to the code it
   describes.

A small change takes the same path: its plan has one task.

### Modes

The user always validates the plan. What follows depends on the mode chosen at that moment:

- `automatic`, the default: the Lead runs every task and slice, its validation, the final review when there is
  one and the local merge, without asking, and reports once. Answer "do not merge" to keep the branch for
  yourself at the end. Nothing is ever pushed.
- `interactive`: the Lead stops after each task or slice, before closing it, and after its validation, before
  the merge, shows what was done and waits for your agreement.

Switch at any time by telling the Lead; it records the change with `plan-lifecycle mode feature <name> <mode>`.
In both modes the Lead stops when the plan needs an amendment, when a decision that could change the result
appears, or when a usage limit interrupts the work.

### The plan folder

Every plan is a milestone: `plan-lifecycle propose` numbers it, and its folder is `M<number>_<name>`. The
branch stays `feature/<name>`. A slice is named by its task and a letter, so a unit reads `M3 Task1b`.

```text
docs/plans/
└── M3_login/                          one folder per plan: milestone number and name
    ├── M3_login.md                    the plan: goal, acceptance, scope, task list, verification
    ├── Task1/                         a task split into slices
    │   ├── Task1a/
    │   │   ├── Task1a.md              what the agent implements: goal, files, acceptance, tests
    │   │   └── Task1a_evidence.md     what it did and ran, and the review if there was one
    │   └── Task1b/
    │       ├── Task1b.md
    │       └── Task1b_evidence.md
    └── Task2/                         a small task
        ├── Task2.md
        └── Task2_evidence.md
```

`plan-lifecycle task feature login 1 a` seeds `Task1a` from the templates; `plan-lifecycle task feature login 2`
seeds `Task2`. Statuses: a plan goes `pending`, `validated`, `finished`; a task or slice goes `todo`, `done`.

### Models, effort and quota

| Tier | For | Claude | Codex |
| --- | --- | --- | --- |
| `light` | mechanical, fully specified work | Haiku | Luna |
| `standard` | ordinary implementation in existing patterns | Sonnet | Terra |
| `heavy` | design choices, concurrency, security, data formats, cross-component changes | Opus | Sol |

Effort is `low`, `medium` or `high`. Fable and Astra, and efforts above `high`, are used only at the user's
request. Developers run on the Lead's provider; a Reviewer runs on the other provider when the harness offers
it and its quota is not lower.

| | `low` quota | `high` quota |
| --- | --- | --- |
| Planner | `standard` tier | `heavy` tier |
| Split | whole tasks, slices only when needed | slices small enough to review well |
| Review of a task | only where a mistake is costly and tests would not show it | every task except trivial ones |
| Final review | one; none when every task is `light` | one, `heavy` tier |

The tests do not depend on the quota. For one change the user can always say "review everything" or "no
review".

### Amendments and the merge message

To change a validated plan, its task list included, the Planner edits it in place with a dated `Amendment`
note, sets its status back to `pending`, and the user validates again.

The merge message, always on stdin:

```sh
plan-lifecycle merge feature/<name> <<'MSG'
Merge the <what>

<plan ID>
Validated-by: Lead <provider/model>; <what was run and observed>
Reviewed-by: <provider/model>, pass <n>: approved; verified <what was run>
MSG
```

Without a final review, the last line is `Not reviewed: <reason>`.

### Delegation

Delegation works with whatever the harness offers: a subagent, a delegated task, a second session, another
provider. The Lead gives each delegate the role skill name, the model and effort, the unit file or plan path,
the worktree and, for the Reviewer, the revision the diff starts from. A delegate prompt looks like:

```text
Use the workflow-developer skill. Unit: docs/plans/M3_login/Task1/Task1a/Task1a.md, plan
docs/plans/M3_login/M3_login.md. Worktree: /path/to/feature_login, branch feature/login. Implement
this unit only, with its unit tests, fill its evidence file, commit and report the commit range.
```

### Shared test resources and status

```sh
resource-lock take <resource>      # before deploying or testing on it
resource-lock release <resource>   # before handing off
resource-lock status
```

Resume or inspect at any time with `plan-lifecycle status`: every task branch, its plan status, its tasks and
slices done out of the total, whether its worktree is clean, and its position relative to the base. A branch
shown as `merged, drop it` is removed with `plan-lifecycle drop <branch>`.

## Safety rules built into the commands

- `propose` and `merge` fetch the base branch's upstream and fast-forward it; when the two sides have diverged
  they stop and leave the reconciliation to a human-reviewed merge.
- `task` works only in a pending plan: the task list of a validated plan changes through an amendment.
- `close` refuses an evidence file the Developer did not fill, uncommitted work, and, for a task marked for
  review, an evidence file without a `Reviewed-by` line.
- `merge` refuses a branch without a plan, a pending plan, a plan with a task that is not done, a dirty base
  worktree and a missing message. A conflicting merge is aborted and the base worktree left clean; the task
  branch is kept.
- `drop` removes only a branch that is an ancestor of the base, and never a worktree with uncommitted changes.
- Nothing is pushed, forced, rebased or reset. Pushing is a separate, explicit decision.

## Customizing

- Project rules go in the repository's `AGENTS.md`, not in the skills. The skills read it and refer to it.
- To change the procedure for everyone, edit the kit, commit, and let the links follow. Keep skill names stable:
  the repositories' `AGENTS.md` files refer to them. The tier table and the quota rules are in
  `skills/workflow-lead/SKILL.md`; the templates of the plan, task and evidence files are in
  `skills/plan-lifecycle/assets/`.
- A harness-specific layer (Claude Code hooks that block `git add -A`, subagent definitions, OpenCode agents)
  can be added next to the skills without changing them; the skills do not depend on it.
