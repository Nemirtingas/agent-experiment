# Project coding and verification settings

Fill these settings from destination repository evidence before implementation. Use `None` only when a setting does
not apply. Commands must name their working directory, environment, expected result and relevant limitations.

- Languages, runtimes and versions: Not configured
- Source/API/test paths and generated code policy: Not configured
- Architecture, error, lifetime, concurrency and security invariants: Not configured
- Formatting, naming and dependency policy: Not configured
- Setup/build commands: Not configured
- Test commands and organization: Not configured
- Lint/format commands: Not configured
- Required platforms, configurations and pre-review checks: Not configured
- Reviewer output directories and resource requirements: Not configured

Run commands from the assigned code worktree. Never reuse a build tree whose source path points to another
checkout. Keep generated output in configured ignored locations. Reviewer checks may write only to designated output
directories, never edit sources, fixtures or approved plans; acquire declared resource reservations first. If
isolation is unavailable, use recorded evidence and report the limitation. Developer records command, exit status,
relevant output, environment and code SHA. Preserve compatibility unless authorized. Use meaningful regression tests
for fixes and coverage for new behavior according to acceptance and repository conventions. Reuse valid checks on
identical code/environment; rerun checks affected by new code, changed dependencies, environment or integration.
Unavailable required checks need a scoped recorded waiver or remain blocking; a waiver never permits approval
without independent review.
