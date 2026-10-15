# Runtime state — Lead procedure

Use <Workspace root>/.agent-runtime/tasks/<plan-id>/state.json from HANDOFF.json, outside both Git histories.
Null means not reached/inapplicable, never approval. Lead alone writes state: temporary file in the same directory,
then atomic rename after each decision/submission/review/integration/handoff. Save next action before interruption.
Record task/agent/engine IDs and branches before launch; retain prior attempts in proposal_history. Resume by reading
state and checking Git checkpoints before mutations; recover completed operations rather than repeating them.
Retain state/results/logs
until explicit cleanup authorization. Keep logs referenced, not copied into state; never store secrets/conversations.

## Exact context and results

Pin instructions_commit, used-file byte SHA-256 hashes (keys relative to AGENT_BASE), bootstrap and preferences
(null when absent). On resume and final review/integration compare relevant entries; changed global HEAD alone is harmless.
Reload changed relevant files; Lead reconciles governing changes before affected work. Add newly introduced governing
files to manifests. Detect preference appearance/removal; never restore old preferences to bypass current policy.

Pin plan_commit containing validated content, repo_path, canonical absolute path and blob from
`git rev-parse <plan_commit>:<plan_repo_path>`. Verify blob membership; read Git content if canonical path differs.
A revised validated plan invalidates affected submissions/reviews until rechecked. Unrelated plans do not.
Submission: code_base/head, clean source status, environment and evidence references. Reviewer uses REVIEW.json.
Keep numbered immutable results in reviews/pass-N.json; result_path references latest. Retain prior base/head.
Finding entries: id, kind (Required/Optional), severity, location, failure, needed_change, state, closure_evidence.
Evidence entries: criterion_id, command, cwd, environment, code_head, exit_status, log_path, result (verified/unverified).
Grant entries: kind, granted, scope, plan_blob/revision, source, rationale. No source means no grant. One source may
support several grants. Waivers additionally identify criterion/check and limitation; unavailable is not passed.

Save actual integration commit/checkpoint before archival. After interruption recover through task refs, parents,
reflog and evidence, never arbitrary current tip. If ambiguous, stop for a decision. Runtime schema version is 1.
Optional metrics are defined in package TOKEN-BUDGET.md; add observations only when available, never invent them.

## Reservations

Atomic mkdir creates .agent-runtime/locks/<key>.lock/; existing means unavailable, never automatically stale.
owner.json records owner/session, task, resource, acquired_at, last_heartbeat, lease_seconds and expected_release.
Keys: task-<plan-id> for one assigned Lead; instructions for instruction updates; integration for code integration;
resource-<name> for configured shared ports/databases/devices/caches. Distinct files do not prove independence.

The persistent task ownership guard is separate from short-lived operation/resource locks. Acquire the latter in
lexical order; on failure release only locks acquired in that attempt, record Blocked and retry on event/bounded
backoff. Never hold operation/resource locks while awaiting a human decision. Heartbeat active ownership, mark session
inactive on yield; release only own locks in finally/cleanup. Lease expiry only signals investigation. Takeover needs
confirmed inactive owner and a recorded decision; uncertain means ask maintainer. For multiple hosts use configured
shared authority or serialize affected work on one host. Never remove another live owner's reservation.
