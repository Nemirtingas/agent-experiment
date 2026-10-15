# Coding and verification

Configure from repository evidence before implementation. `None` means inapplicable, not unknown.

- Languages, runtimes and versions: Not configured.
- Source/API/test paths and generated code policy: Not configured.
- Architecture, error, lifetime, concurrency and security invariants: Not configured.
- Formatting, naming and dependency policy: Not configured.

## Verification and platform settings — also read by Planner

- Setup/build commands: Not configured.
- Test commands and organization: Not configured.
- Lint/format commands: Not configured.
- Required platforms, configurations and pre-review checks: Not configured.
- Reviewer output directories and resource requirements: Not configured.

Specify command, code working directory, environment, expected result and limitations. Never build from instructions
or a bare root. Reviewer tests may write only designated generated/output directories, never edit sources, fixtures
or approved plans; acquire declared resource reservations first. If isolation is unavailable, use recorded evidence
and report the limitation. Developer records command, exit status, relevant output, environment and code SHA.
Preserve compatibility unless authorized. Use meaningful regression tests for fixes and coverage for new behavior
according to acceptance and conventions. Reuse valid checks on identical code/environment; rerun checks affected by
new code, changed dependencies, environment or integration. Unavailable required checks need a scoped recorded
waiver, or remain blocking; no waiver permits an unreviewed implementation to be approved.
