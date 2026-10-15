---
name: resource-lock
description: Take, check and release an exclusive lock on a shared test resource (a device, test hardware, a staging host) across every worktree and agent of a repository. Use before any deploy, flash, reboot or test run on a resource that other agents may be using, and release it when done.
---

# Resource lock

The command is `resource-lock` when the installer put it on PATH, otherwise `scripts/lock.sh` next to this file.
The lock is a directory in the repository's git common directory, created atomically, so every worktree and
every agent of the repository sees the same lock. The owner is the branch of the worktree that took it.

```bash
resource-lock take    <resource>   # fails and names the owner when already held
resource-lock check   <resource>   # exit 0 when the current branch holds it
resource-lock release <resource>   # by the owning branch; --force breaks another owner's lock
resource-lock status               # every lock of the repository
```

Resource names are listed in the repository's `AGENTS.md` under shared test resources. Take the lock before
touching the resource, run the deploy or the check from the worktree that holds it, and release it before handing
off. A held lock is a fact to report, never a reason to work on the resource anyway; break a lock with
`--force` only when its owner's work is known to be finished, and say so in the report.
