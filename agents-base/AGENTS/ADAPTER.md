# Engine adapter — optional, Lead loads only when needed

Keep provider APIs out of role/lifecycle rules. For the actual engine record these capabilities in the task's
adapter field: provider/model discovery, task launch/resume/cancel, task IDs/status/events, context inheritance,
filesystem visibility, agent messaging and ancestor-instruction discovery. Follow explicit user model preferences;
never assume a model or provider exists. Missing delegation keeps work unapproved if independent review is impossible.

Launch only required roles; compact reuses Lead for planning. Prefer focused context over inherited history when
supported: brief, task-state path, role references, source snapshot and relevant evidence. Record which files were
actually loaded. Cross-machine agents need authorized artifact transport; do not send private preferences/secrets.
Do not duplicate an existing active task after a timeout: inspect its recorded ID/status first. Use a stable request
ID per launch/review round where supported. Some engines resume an agent; others require a fresh review task with
original brief, previous findings/responses and unresolved objections. Preserve review continuity either way.

Wait for engine events when supported; otherwise use bounded backoff, expose blockers and avoid busy polling.
Retry transient errors at most twice per operation before reporting/escalating; never infer approval from timeout.
An adapter maps lifecycle decisions to tools; it cannot weaken approval, independent review or publication boundaries.
No preconfigured engine integration is shipped. Fill this capability map from live tool evidence during setup/use.
