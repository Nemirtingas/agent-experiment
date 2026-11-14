# Agent instructions for <repository name>

<One paragraph: what this repository builds, for whom, and the platforms it targets.>

## Workflow

This repository uses the agent workflow. Start every task with the `workflow-lead` skill; it clarifies the
request, has a plan written and split into tasks, and drives one agent per task. Task branches, plan folders
and integration merges go through the `plan-lifecycle` command, never by hand. Shared test resources are used
under the `resource-lock` command.

- Base branch: `<integration branch, also recorded with plan-lifecycle config base>`
- Plan folders: `docs/plans/<plan ID>/` (`plan-lifecycle config plans` to change)
- Task worktrees: `<directory that receives them, default: the directory above the main worktree>`
- Always reviewed: <changes a Reviewer checks whatever the user's quota: public interfaces, install paths,
  security gates, data formats, ... or `None beyond the skill's defaults`>

## Build, test, lint

- Build: `<command>`
- Unit tests: `<command, where they live and the conventions a new test follows>`
- Integration tests: `<command, where they live and what they need to run, or None yet>`
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
  changed and how it was verified, wrapped at 72 columns except trailer lines such as `Validated-by` and
  `Reviewed-by`.
