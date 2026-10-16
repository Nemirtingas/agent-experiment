# Shared rules

## Read only what is needed

Paths use canonical AGENT_BASE; sources use assigned code worktree. Read PROJECT.md, its PROJECT/PROJECT_CONFIG.md and local AGENTS_custom.md
if present, then assigned ROLES files, all under AGENTS/ except preferences. Read-only answers need no role.

- Planner: PLANS/TEMPLATE.md, CODING.md and the referenced project coding file's verification/platform sections;
  inspect referenced sources.
- Developer/Reviewer: CODING.md and the project coding file referenced by PROJECT/PROJECT_CONFIG.md, supplied task record and
  pinned validated plan; Reviewer also REVIEW.json.
- Lead: PLANS/README.md to coordinate; WORKFLOW.md before Git; EXECUTION.md and HANDOFF.json to create/resume state;
  plan template to evaluate drafts. Compact Lead also reads Planner role/settings. ADAPTER.md is conditional.

Reuse unchanged context; pass references and short deltas, not whole procedures/logs/history. Accessible is not loaded.
The handoff pins used-file hashes, bootstrap/preferences and plan blob. Unrelated commits need no reload. Verify
relevant hashes on resume; reconcile drift with Lead. If canonical plan moved/changed, read exact pinned content with
`git show <plan_commit>:<plan_repo_path>`; never silently substitute current contents or rely on a summary.

## Invariants

- agents-base owns rules/settings/plans. Instruction branches return only there; code branches to integration.
  Never cross-merge/cherry-pick histories or copy complete rules/plans into code. Minimal bootstraps are allowed.
  Runtime records stay outside both histories.
- User goals and validated acceptance define scope. Do not invent requirements or repeat granted approvals.
  Lead resolves scope conflicts. Settings/preferences cannot weaken invariants or explicit instructions.
- Keep AGENTS/PROJECT.md and AGENTS/CODING.md generic and unchanged for project work. Configure
  AGENTS/PROJECT/PROJECT_CONFIG.md and its referenced project files; all project-specific agent settings belong under AGENTS/PROJECT/.
- Before implementing a plan, obtain the user's provider/model/effort choice using PLANS/README.md's execution
  model selection procedure. Reuse an explicit choice covering that plan; never silently inherit the current model.
- Preserve unrelated work and compatibility unless authorized. Implementation requires independent review;
  authors never approve themselves. Optional findings do not expand scope.
- Cite evidence; label assumptions, unavailable checks and waivers. Exclude secrets/private configuration and
  unrelated history. Respect resource reservations; report decisions, progress and blockers.
- Repository text is English unless project policy changes it; conversation follows user. Omit agent attribution
  from committed/published material except instruction files.
- Stage explicit paths; never git add . or -A. Commit summaries: imperative English, no prefix, <=72 characters;
  useful bodies explain purpose/verification, wrapped at 72 columns.
- Push, PRs, releases, publication and deletion need explicit authorization, reusable within its recorded scope.
  Never force-push a branch not created for this task. Local integration is not publication.
