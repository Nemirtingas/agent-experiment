# Plan lifecycle — Lead procedure

Location is content lifecycle: PENDING_PLANS awaits validation; VALIDATED_PLANS holds approved content;
FINISHED_PLANS holds reviewed/integrated work. No execution Status in plans. Stable ID/filename: <type>_<name>;
archival alone appends integration hash. EXECUTION.md owns runtime state; WORKFLOW.md owns Git.

## Route, write once, validate

1. Read-only question: inspect/answer, no plan branch. Vague idea: inspect read-only, offer evidenced choices and
   resolve scope/acceptance questions. Precise requests skip redundant questions, never validation gates.
2. Compact: bounded, understood work without compatibility change, unresolved product choices or shared-resource/
   dependency complexity; Lead also plans in same context. Otherwise full with dedicated Planner when useful.
   Record route/reason. Both require validated plan, execution selection, independent review and integration grant.
3. Capture synchronized source snapshot. Create numbered proposal/worktree from agents-base BEFORE drafting.
   Planner writes pending file there, returns path and short decisions. Lead reads/revises and commits reviewed
   pending content before presenting exact revision for user validation. Do not circulate duplicate full drafts.

Record decision source, scope and approved revision. One reply may grant several decisions:

| Grant | Effect |
| --- | --- |
| Content validation | Promote exact plan and merge proposal into agents-base. |
| Execution selection | Implement selected scope after integrated prerequisites. |
| Parallel execution | Run explicitly covered independent tasks concurrently. |
| Local integration | Integrate independently approved work within covered scope. |

Content approval alone does not select execution or allow code integration. Reuse applicable grants; ask only a
missing decision. Publication/release/cleanup require separate explicit grants.

Record approved pending blob/commit, git mv to validated and commit only move. Under instructions lock incorporate
current agents-base, preserving approved content, then merge proposal. Pin canonical plan commit/path/blob.
Compact RETAINS active proposal branch/worktree for archival; full uses separate archival. Retain rejected proposals.
Unselected stays validated. Selected waits for integrated prerequisites; code starts from current integration.

Scope/criteria changes: pause affected work, next numbered pending proposal from current agents-base, keep current
validated content intact until renewed approval; replace it in promotion commit, retaining old content in Git.
Refresh identity/dependent context; recheck grants against scope. Within-scope fixes use review, not a new plan.

## Choose the execution model

When the user requests implementation of a plan, ask which provider, exact model and reasoning effort to use
before implementation starts or is delegated. This applies to compact and full routes. Reuse an explicit choice
already covering this plan; ask only for missing settings. Plan validation or "implement it" alone does not select
a model. Read-only inspection needed to prepare the choices may continue while waiting; silence is not a choice.

Offer both Claude (Anthropic) and Codex (OpenAI). Discover available models and supported effort values from the
engine's provider/model catalog, including configured custom models; consult ADAPTER.md for discovery/dispatch.
Use the engine's exposed capabilities, not external websites or online provider APIs, to prepare this choice.
Reuse catalog information already available in the session; refresh it when missing or when availability changes.
Show exact model IDs and only supported effort values. Mark unavailable providers/models and unknown or
non-configurable effort explicitly; do not invent equivalences, silently substitute models, or imply that selecting
a model changes the current session automatically. Before dispatch, verify that the chosen settings are supported.
If execution cannot use them, explain the limitation and obtain a revised choice before starting.

Present a concise comparison in the user's language: provider, model, supported efforts and suitability for the task.
Recommend one exact provider/model/effort combination and explain briefly how it fits the plan's complexity,
uncertainty, scope and verification needs. For a small, well-understood change, favor a capable model with a lower
supported effort. For broad changes, difficult debugging, concurrency or compatibility risks, favor stronger
reasoning and a higher supported effort. These are task-based judgments, not fixed equivalences across providers;
state uncertainty when the available model information does not support a confident comparison.

Wait for the user's choice; the recommendation is not authorization to start. Ask together with any still-missing
execution decision to avoid redundant approval rounds. Reuse an explicit choice already covering the task.

Record the chosen provider instance, exact model, effort, scope and decision source in the task's adapter and
authorizations fields. Apply the choice to implementation; independent review retains its own role/settings unless
the user also selected them. Reuse the recorded choice on resume; ask again only when the user changes it, its scope
does not cover the work, or the selected configuration is no longer available. Existing validation, independent
review, integration and publication requirements still apply.

## Execute, review, integrate

Persist transitions/next action: Drafting, Awaiting Validation, Not Selected, Ready, In Progress, In Review, Reviewed,
Awaiting Integration, Integrated, Archived, Blocked. Dispatch only the action allowed by current state; never restart
implementation from Blocked/Archived. Blocked records reason/action/resume state; dependencies resume
Ready, integration conflicts In Progress. Unavailable required checks block unless explicitly waived for named
criterion/check with rationale; waivers never fabricate success or remove independent review.

Developer submits clean committed base/head and evidence. Reviewer approves that head and pinned plan blob.
Lead confirms criterion/evidence mapping and approval identity; reuse unchanged valid checks. Changed code requires
new approval. Missing integration grant means Awaiting Integration with exact missing decision. Changed integration
base handling is in WORKFLOW.md. Keep plan validated until authorized integration completes.

## Archive without redundant network work

Record actual full code integration commit: merge commit, reviewed fast-forward tip or approved squash candidate.
Verify reachable from local integration; obtain suffix with git rev-parse --short <integration-commit> in code.
Never use proposal/archive commit or arbitrary later tip. Archival itself needs no fetch.

Compact reuses active proposal after merging current agents-base into it. Full creates numbered docs/finish branch;
optionally batch completed plans in numbered docs/archive-<batch-name>-rN, checking each plan's evidence/grants.
Under instructions lock git mv exact validated blobs to FINISHED_PLANS/<plan-id>-<short-integration-hash>.md,
commit only moves and merge to agents-base without content changes. Mark Archived only when canonical. Keep
records/evidence until authorized cleanup. Resume interrupted steps from recorded checkpoints and Git, no duplicate
merges or arbitrary tip recovery.
