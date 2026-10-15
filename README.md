# agent-workflow

A portable set of skills and two shell commands for making code changes with coding agents: Claude Code, Codex,
OpenCode, and any agent that reads `SKILL.md` skills and `AGENTS.md` instructions. It installs once per machine
and applies to every repository that adopts it.

What it gives you:

- Two paths for a change. The light path for small changes: the Lead implements, one independent review, merge,
  one report, no question in between. The plan path for everything else: a plan file written by a Planner,
  validated by the user, implemented by a Developer, reviewed, merged.
- Four roles as skills: Lead, Planner, Developer, Reviewer. Any agent can take any role; the Reviewer is meant to
  run on another model or provider than the implementer when the harness offers one.
- One task branch and one worktree per change, created and removed by the `plan-lifecycle` command. The plan
  file lives on the task branch and is merged with the code, so the integration branch keeps every plan.
- A durable review record: the merge commit message names the plan or brief, the Reviewer's `Reviewed-by` line
  and the verification that was run.
- `resource-lock`, an exclusive lock on shared test resources, visible from every worktree and every agent.

## Contents

```text
agent-workflow/
├── README.md
├── install.sh                     install, uninstall, prepare a repository
├── install.ps1                    the same from PowerShell, for Windows
├── .claude-plugin/plugin.json     the directory is also a Claude Code plugin
├── skills/
│   ├── workflow-lead/SKILL.md     entry point: choose the path, drive the roles, merge, report
│   ├── workflow-planner/SKILL.md  write the plan file on the task branch
│   ├── workflow-developer/SKILL.md
│   ├── workflow-reviewer/SKILL.md
│   ├── plan-lifecycle/            SKILL.md, scripts/plan.sh, assets/PLAN.md (plan template)
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

This links the six skills into `~/.agents/skills` (read by Codex and OpenCode) and `~/.claude/skills` (read by
Claude Code and OpenCode), and links the commands `plan-lifecycle` and `resource-lock` into `~/.local/bin`.
Check that `~/.local/bin` is on your `PATH`, then:

```sh
plan-lifecycle help
resource-lock help
```

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

1. Fill in every `<placeholder>` of `AGENTS.md`: what the repository is, build and test commands, layout and
   invariants, style, shared test resources and their lock names, production hosts, secrets rules, the changes
   that always take the plan path. Keep it under about 200 lines; the roles and the procedure are in the skills.
2. If the repository already has an `AGENTS.md`, merge the `## Workflow` section of the template into it. If it
   has a `CLAUDE.md`, add a line `@AGENTS.md` to it: Claude Code reads `AGENTS.md` on its own only when no
   `CLAUDE.md` is present.
3. Commit `AGENTS.md` and `docs/plans/.gitkeep` on the integration branch.

Settings, all optional, stored with `plan-lifecycle config <key> <value>`:

- `base`: the integration branch. Without it every command needs the base branch as an argument.
- `plans`: the plan directory, default `docs/plans`.
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

The Lead reads `AGENTS.md`, runs `plan-lifecycle status`, and says which path applies.

Light path, a change of about fifty lines in one or two files with no public interface, install path, security
gate or data format involved:

1. The Lead states the brief: goal, files, acceptance, verification.
2. `plan-lifecycle branch fix <name>` creates `fix/<name>` and its worktree; the Lead implements, commits and
   verifies there.
3. The Lead delegates the review to another agent with the `workflow-reviewer` skill, fixes `Required` findings,
   resubmits until the `Reviewed-by` line.
4. `plan-lifecycle merge fix/<name>` with the message on stdin merges with `--no-ff` and removes the branch and
   worktree.
5. One report. The request was the authorization; nothing was asked in between.

Plan path, everything else:

1. `plan-lifecycle propose feature <name>` creates the branch, the worktree and `docs/plans/feature_<name>.md`
   with `Status: pending`. The Planner, with the `workflow-planner` skill, inspects the code, writes the plan
   (behavior and acceptance, not code, under about 150 lines) and commits it on the task branch.
2. The Lead presents the plan; the user validates its content. `plan-lifecycle validate feature <name>` sets
   `Status: validated` and commits.
3. The validation authorizes the implementation. The Lead asks one question only for what it leaves open: the
   order when several plans wait, and local integration when the validation did not mention it.
4. The Developer, with the `workflow-developer` skill, implements on the task branch, runs the verification and
   the checks on shared test resources under `resource-lock`, and hands the diff and the evidence to the Lead.
5. The Reviewer, with the `workflow-reviewer` skill, reviews each pass; the last one ends with the `Reviewed-by`
   line.
6. `plan-lifecycle merge feature/<name>` marks the plan `finished`, merges, and removes the branch and worktree.
   The plan file is now on the integration branch, next to the code it describes.

To change a validated plan, the Planner edits it in place with a dated `Amendment` note, sets its status back to
`pending`, and the user validates again.

The merge message, always on stdin:

```sh
plan-lifecycle merge fix/<name> <<'MSG'
Merge the <what>

<plan ID or brief>
Reviewed-by: <provider/model>, pass <n>: approved; verified <what was run>
<verification run, shared resources included>
MSG
```

Delegation works with whatever the harness offers: a subagent, a delegated task, a second session, another
provider. The Lead gives each delegate the role skill name, the brief or plan path, the worktree, the base
revision and, for the Reviewer, the verification output. A delegate prompt looks like:

```text
Use the workflow-reviewer skill. Brief: <...>. Worktree: /path/to/fix_name, branch fix/name, base develop at
<revision>. Verification output follows. Review read-only and end with the Reviewed-by line or the number of
open Required findings.
```

Shared test resources:

```sh
resource-lock take <resource>      # before deploying or testing on it
resource-lock release <resource>   # before handing off
resource-lock status
```

Resume or inspect at any time with `plan-lifecycle status`: every task branch, its plan status, whether its
worktree is clean, and its position relative to the base. A branch shown as `merged, drop it` is removed with
`plan-lifecycle drop <branch>`.

## Safety rules built into the commands

- `branch`, `propose` and `merge` fetch the base branch's upstream and fast-forward it; when the two sides have
  diverged they stop and leave the reconciliation to a human-reviewed merge.
- `merge` refuses a pending plan, a dirty base worktree and a missing message. A conflicting merge is aborted and
  the base worktree left clean; the task branch is kept.
- `drop` removes only a branch that is an ancestor of the base, and never a worktree with uncommitted changes.
- Nothing is pushed, forced, rebased or reset. Pushing is a separate, explicit decision.

## Customizing

- Project rules go in the repository's `AGENTS.md`, not in the skills. The skills read it and refer to it.
- To change the procedure for everyone, edit the kit, commit, and let the links follow. Keep skill names stable:
  the repositories' `AGENTS.md` files refer to them.
- A harness-specific layer (Claude Code hooks that block `git add -A`, subagent definitions, OpenCode agents)
  can be added next to the skills without changing them; the skills do not depend on it.
