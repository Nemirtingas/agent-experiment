# Agent instructions for <repository name>

<One paragraph: what this repository builds, for whom, and the platforms it targets.>

## Workflow

This repository uses the agent workflow. Start every task with the `workflow-lead` skill; it chooses between the
light path and the plan path and drives the other roles. Task branches, plan files and integration merges go
through the `plan-lifecycle` command, never by hand. Shared test resources are used under the `resource-lock`
command.

- Base branch: `<integration branch, also recorded with plan-lifecycle config base>`
- Plan files: `docs/plans/` (`plan-lifecycle config plans` to change)
- Task worktrees: `<directory that receives them, default: the directory above the main worktree>`
- Reviewer: <another provider or model than the implementer when the harness offers one, or `any`>
- Always the plan path: <changes that never take the light path: public interfaces, install paths, security
  gates, data formats, ... or `None beyond the skill's defaults`>

## Build, test, lint

- Build: `<command>`
- Tests: `<command and where the test conventions are documented>`
- Lint or format: `<command, or None>`
- A fresh worktree lacks: `<submodules, generated files, local configuration to copy, or Nothing>`

## Layout and invariants

- `<path>`: <what lives there>
- Invariant: <a rule the code must keep, with the file or function that enforces it>

## Style

- <Language, indentation, naming, error handling and logging rules; link the authoritative document if any>

## Shared test resources and production

- `<resource name>`: <what it is, how to reach it, what may be done to it, and the lock to take:
  `resource-lock take <resource name>`>
- Production hosts: <how to recognize them and what is forbidden there, or `None`>

## Secrets and sensitive material

- <Where credentials live, how to read them (absolute path, environment), and the rule: never commit, embed, or
  print them; compare hashes instead of values>

## Conventions

- Language of files, code, comments, commits and documentation: English unless stated otherwise here.
- Commit summaries: imperative, no prefix, at most 72 characters; body explains what was wrong, why, how it
  changed and how it was verified, wrapped at 72 columns except trailer lines such as `Reviewed-by`.
