# Git coordination — Lead, load on demand

Use PROJECT/PROJECT_CONFIG.md settings loaded through PROJECT.md and EXECUTION.md reservations. Preserve unrelated work; never switch/reset/clean it.

## Identity and retry

Code <type>/<name> starts/returns to integration; type fix/feature/docs, lowercase kebab-case name. Plan ID is
<type>_<name>; never reuse it for another deliverable. Worktree directory replaces separating slash with underscore.
Instruction branches start/return only to agents-base: proposals docs/plan-<type>-<name>-rN; full archival
docs/finish-<type>-<name>-rN; batch archival docs/archive-<batch-name>-rN; other maintenance docs/<name>.

N starts at 1. Under instructions lock choose next unused number across retained refs, worktrees and attempt history.
Record allocation; retry of that SAME attempt resumes its verified branch/worktree. New scope needs new attempt.
Inspect branches, destination paths and worktree list --porcelain before creating. Never reset/adopt an unrelated
attempt, overwrite a rejected proposal or delete evidence to free a name.

## Synchronization boundaries

Synchronize for planning snapshot and before CODE integration, not every documentary branch/archive. Use configured
authoritative remote; otherwise discover only an unambiguous upstream/candidate or ask. Explicit None is local-only.
Fetch failure blocks fresh-source claims and remote-based code integration, not existing local documentary work.
Offline continuation requires a recorded user/maintainer grant; offline local integration needs explicit coverage
of that operation and stale snapshot. Never infer it from selection or a failed network call.

Use clean integration checkout: fast-forward fetched history, or merge divergence preserving local work only with
applicable integration authorization. Never reset/rebase it away; stop on conflicts. If local integration is absent,
create from authoritative remote branch, or authorized synchronized release source; ask if neither exists.
Record snapshot SHA, remote, fetch time/local-only/offline decision. Reuse for local proposal/archive operations;
refresh before implementation when known relevant source changes or material staleness require it.

Before merging instructions, hold instructions lock, inspect clean current agents-base and incorporate its history
into task branch. Keep canonical worktree on agents-base. Verify approved plan blob after conflict resolution;
changed meaning needs renewed validation. Unrelated commits do not invalidate all contexts. Never import code
history. Instructions upstream/transport needs explicit authorization.

## Integrate exact reviewed code

Hold integration lock across final sync/base checks/integration. Check clean source HEAD equals approved code_head,
plan blob still applies, no Required findings remain, acceptance has evidence/scoped waivers and authorization covers
scope. Any mismatch blocks. Do not hold the lock while running reviews or waiting for permission.

If integration advanced beyond reviewed base, Developer prepares candidate in task checkout by merging current
integration, commits it and reruns affected checks. Independent Reviewer approves NEW head, including conflict-free
merges, using delta/interactions review; reuse unaffected valid checks with rationale. Never resolve conflicts in
shared integration checkout. Set code_base to that integration tip; retain prior base/head for review delta.
Recheck integration tip under lock; another advance repeats base check, not planning.

Default fast-forward or preserving merge needs applicable authorization. For explicitly chosen squash, Developer
prepares one clean candidate commit on current integration with intended resulting tree; Reviewer approves that
exact SHA BEFORE integration. Never create an unreviewed squash result on integration. Record actual integration
commit/mode. Conflicts set Blocked/resume In Progress and return to Developer plus independent review.

## Publication and cleanup

Release promotion goes from integration to explicitly authorized configured release branch. PR descriptions state
final change, purpose and verification. Push/PR/release need separate authorization. A bounded cleanup grant names
task artifacts/retention; before deletion verify integrated/archived, clean, no live assignment and required evidence
retained. No implicit/forced deletion or publication follows integration. Retain unfinished/rejected work by default.
