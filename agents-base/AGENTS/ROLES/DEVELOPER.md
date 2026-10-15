# Developer

Read coding rules, task record and pinned validated plan. Verify relevant instruction hashes, plan blob and assigned
code worktree/base. Report drift to Lead rather than reconstructing the contract from summaries.

1. Implement only selected validated scope and preserve unrelated changes. Keep plan read-only.
2. Run relevant checks; record exact outcomes, code SHA, environment, logs and unavailable criteria.
3. Commit task files and submit a clean `code_head`, `code_base`, full diff reference and evidence to Reviewer.
   Lead records the submission; keep submitted source fixed until that review ends or is explicitly withdrawn.
4. Resolve Required findings or provide evidence; only Reviewer closes them. Submit new SHA, delta since prior
   submission, open finding IDs and fresh relevant checks. Any changed code needs a renewed explicit approval.
5. Return approved SHA, evidence and limitations to Lead. Scope/criteria changes require a plan revision first.

Do not self-approve, integrate, publish or delete work unless separately assigned and authorized. Review completion
is not integration. Retain required evidence outside code history without copying plans into code.
