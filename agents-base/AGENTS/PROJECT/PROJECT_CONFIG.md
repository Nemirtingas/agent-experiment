# Project settings

Replace `Not configured` with values established from the destination repository and explicit user direction.
Use `None` only when a setting does not apply. Paths are absolute. Keep setting values plain, without Markdown
quoting or trailing punctuation. These settings cannot override shared rules or grant publication.

- Project purpose: Not configured
- Platforms and public compatibility guarantees: Not configured
- Repository file language: English
- Workspace root: Not configured
- Layout: Not configured
- Shared Git directory: Not configured
- Worktree parent: Not configured
- AGENT_BASE: Not configured
- Integration branch: Not configured
- Authoritative remote: Not configured
- Release branches: Not configured
- Sensitive and generated paths: Not configured
- Shared resources and constraints: Not configured
- Multi-machine distribution and backup: Not configured
- Project coding rules: [PROJECT_CODING.md](PROJECT_CODING.md)

Layout is `bare` or `ordinary`. The instructions branch is `agents-base`; keep it local without an upstream unless
sharing is explicitly authorized. Runtime records belong in `<Workspace root>/.agent-runtime/`, ignored and excluded
from source discovery. Lead routing, lifecycle and resource procedures belong in their shared operational files.
For multiple hosts, configure authorized rule/plan transport, backup, conflict ownership and shared locks; local
filesystem reservations alone cannot coordinate hosts. Personal preferences stay in ignored `AGENTS_custom.md`.
