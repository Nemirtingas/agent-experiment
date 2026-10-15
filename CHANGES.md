# V3 audit resolutions

This release implements the four P1 and ten P2 proposals from the v2 audit. It changes the generic package only;
it does not install into a project or configure a provider. Operational material stays in English, as in v2.

## P1 — reliable revisions, resumption and approval

| Audit item | V3 resolution | Authoritative material |
| --- | --- | --- |
| 01 — proposal-name collisions | Number proposal/archive attempts `-r1`, `-r2`; keep stable Plan ID, retain rejected attempts, resume an existing recorded attempt instead of resetting it. | `agents-base/AGENTS/WORKFLOW.md` |
| 02 — execution state without a home | One Lead-owned `.agent-runtime/tasks/<plan-id>/state.json`; atomic replacement, checkpoints, next action, retention and recovery. | `agents-base/AGENTS/EXECUTION.md`, `HANDOFF.json` |
| 03 — approval without an exact code commit | Clean committed base/head, frozen submission, explicit Reviewer SHA/plan identity, changed-code invalidation and a new candidate when integration advances, including conflict-free changes. | `agents-base/AGENTS/WORKFLOW.md`, Developer/Reviewer roles, `REVIEW.json` |
| 04 — mutable canonical plan/instructions | Pin plan commit/path/blob and used-file byte hashes; include bootstrap and preference presence/hash. Read pinned Git content if the path changes. Reload only affected files; reconcile relevant policy/scope changes. | `agents-base/AGENTS.md`, `agents-base/AGENTS/EXECUTION.md` |

## P2 — fewer redundant operations and explicit runtime contracts

| Audit item | V3 resolution | Authoritative material |
| --- | --- | --- |
| 05 — unclear decision effects | Separate content/selection/parallel/integration grants with source and scope, reusable from one reply. Scope changes revalidate; within-scope fixes iterate. Unavailable required checks stay blocked or receive a named explicit waiver. | `agents-base/AGENTS/PLANS/README.md`, `EXECUTION.md` |
| 06 — fetch at every documentary step | Synchronize planning snapshot and before code integration; local proposals/archive reuse it. Explicit local-only/offline policy; archival verifies local commit reachability without a new fetch. | `agents-base/AGENTS/WORKFLOW.md` |
| 07 — duplicate complete plan drafts | Create proposal worktree first, write the pending plan once, then Lead reviews/commits it before validation. Agent returns path and short decisions. | `agents-base/AGENTS/PLANS/README.md`, Planner role |
| 08 — four roles treated as four fresh agents | Read-only, compact and full routes. Compact Lead also plans; independent implementation Reviewer remains mandatory. Route selection is based on uncertainty/compatibility/dependencies/resources. | `agents-base/AGENTS/PLANS/README.md`, Lead/Planner roles |
| 09 — three branches/worktrees for every small plan | Compact reuses active proposal branch/worktree for archival. Full preserves separate archival and permits a batch of separately completed plans. Bounded cleanup grants require clean/inactive integrated artifacts and evidence retention. | `agents-base/AGENTS/PLANS/README.md`, `WORKFLOW.md` |
| 10 — Planner rediscovers verification commands | Explicit targeted reading of CODING.md verification/platform section and source verification. Project settings stay facts/parameters rather than execution logs. | `agents-base/AGENTS.md`, `CODING.md`, Planner role |
| 11 — parallelism ignores shared resources | Lead-owned task state and atomic local resource reservations, ordered operation locks, owner/lease metadata, conservative takeover and serialized instruction/code integrations. Multi-host work requires shared authority. | `agents-base/AGENTS/EXECUTION.md`, `PROJECT.md` |
| 12 — repeated review lacks a stable result | Stable finding IDs, exact verdict/base/head/plan identity, closure only by Reviewer, delta resubmission and escalation after two passes without progress. Reviewer may use designated output directories; source remains read-only. | Reviewer/Developer roles, `REVIEW.json`, `CODING.md` |
| 13 — engine orchestration contract implicit | Optional provider-neutral capability map, focused context, task IDs, idempotent launch handling, engine-dependent review-round continuation and bounded retries/waits. | `agents-base/AGENTS/ADAPTER.md` |
| 14 — manual installation diagnostics | Explicit package marker and package-maintenance entry path; read-only diagnostic distinguishes package/incomplete/ready, checks actual Git/configuration/exclusions and flags manual engine discovery checks. | Root `AGENTS.md`, `TEMPLATE.json`, `agents-base/tools/doctor.py`, root README |

## Scope and tradeoffs

Both task routes preserve plan-content validation, execution selection, independent implementation review and
local-integration authorization. Authorization reuse reduces prompts; it does not infer missing permission.
Publication, releases and destructive cleanup remain explicitly scoped decisions.

The package supplies executable diagnostics and context measurements, plus regression fixtures. Branch transitions,
review, resource reservations and state updates are procedures executed by agents, not an installed automation
service. A project must still configure settings/commands and its engine adapter when needed. Empty JSON formats
are not approved submissions or live task state. Actual engine discovery and multi-host coordination require setup.

V3's complete four-context startup is larger than v2 because runtime/identity contracts are explicit. Compact
startup is slightly smaller than v2's four-context baseline; see TOKEN-BUDGET.md for exact scope/counts. Main
expected savings come from avoiding a fresh Planner context, duplicate plans, irrelevant reloads and needless
fetches/checks. No whole-task token, latency or cost improvement has been benchmarked.

## Verification

Run `python3 -B tools/test_template.py` for isolated Git/diagnostic scenarios and
`python3 -B tools/measure_context.py --baseline ../agent-repo-template-generic-v2` for reproducible counts.
Fixtures exercise ordinary/bare layouts, configuration failures, privacy/exclusion mistakes, retained numbered
proposals, exact plan blobs, compact/batch archival and a changed integration-base candidate. They do not simulate
an LLM, constitute independent implementation review, or prove that an agent follows the procedures.

For a v2 installation, review and update instructions through its instruction-only history; do not overwrite its
canonical worktree or reset active tasks. Adopt numbered names for new attempts, preserve previous refs/evidence,
create a task record from observed state and reconcile its plan/code identities before resuming. Configure runtime
exclusions and complete the diagnostic before new implementation. Never fabricate historic approvals or SHAs.
