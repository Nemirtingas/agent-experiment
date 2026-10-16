# Shared coding and verification rules

## Keep the shared base reusable

Do not modify AGENTS/CODING.md to configure a project or implement a project task.
Keep project-specific languages, formatting, architecture constraints, dependencies,
host paths, build commands and verification/platform settings in a separate tracked
instruction file referenced by the `Project coding rules` entry in AGENTS/PROJECT/PROJECT_CONFIG.md.
Create that file and reference when setting up a project; do not duplicate this shared
file. Changes to the shared policy itself require an explicit request to maintain
that common policy, not merely a project requirement.

## Load project rules

Resolve the project file relative to AGENTS/PROJECT/PROJECT_CONFIG.md in canonical AGENT_BASE.
Read it together with this file before planning, implementation or review; load its
verification/platform sections when only those settings are needed. Include both
files, PROJECT.md and PROJECT/PROJECT_CONFIG.md in the task's used-file hash manifest. If the reference or file
is missing, report the missing configuration before dependent work; never infer
commands from another project. Project rules supplement the shared invariants and
cannot weaken explicit user instructions, validation or independent review.

## Verification and platform settings

The referenced project file owns concrete commands, toolchains and coverage targets.
Older plans referring to CODING.md commands resolve through that reference; preserve
pinned plan content and existing acceptance criteria. On migration or resume, the
Lead reconciles instruction hashes and loads the referenced file before continuing.
Run checks against the assigned code worktree, keep generated output in its configured
ignored locations, and report actual results and unavailable checks honestly.

## Reuse in another project

Keep this shared file unchanged. Configure PROJECT/PROJECT_CONFIG.md and its referenced project
coding file for the destination project; do not reuse another project's host paths,
commands or validation evidence without verification.
