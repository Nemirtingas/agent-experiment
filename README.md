# Generic Agent Repository Template — v3

This package provides a project-neutral workflow with a Lead, Planner, Developer, and independent Reviewer.
It includes shared rules, project configuration templates, coding rules, and a plan lifecycle. It contains no
project implementation, skills, private configuration, preselected provider, or existing plans.

## Load only the instructions needed

The common bootstrap and `agents-base/AGENTS.md` route each role to its required files. All agents read compact
project settings and their applicable role; Developers and Reviewers add coding rules and the supplied plan.
The Planner reads the plan template and relevant coding verification/platform settings. The Lead loads Git procedures
before Git operations and lifecycle rules for coordination/transitions. A read-only question needs no full workflow.

Do not recursively load the whole instruction tree or reread unchanged instructions already present in the same
context. New agents still need their own required context; changed instruction revisions require reloading affected
files. Installation documentation and token estimates are not mandatory operational instructions. See
`TOKEN-BUDGET.md` for measured file-loading comparisons; no whole-task savings are assumed.

## What changes in v3

See `CHANGES.md` for all 14 audit resolutions. V3 adds a persistent local handoff, exact plan/code identities,
numbered proposal attempts, one-write planning, compact/full routes, delta review and explicit offline/resource
procedures. It is still an instruction template, not an autonomous orchestrator. Roles execute these procedures;
only the supplied diagnostic and measurement tools are automated. No external service is configured or contacted.

Read-only questions need no plan. Compact tasks let Lead also plan and reuse the proposal branch for archival.
Full tasks keep dedicated roles/archival branches; completed plans may be archived as a batch. Both routes retain
content validation, execution selection, independent implementation review and local integration authorization.
An unclear idea starts with read-only inspection and scope decisions, not guessed implementation requirements.

Package marker `TEMPLATE.json` enables package audit/maintenance before installation. Do not copy this marker to
the installed common root. Tools require Python 3.9+ and Git; they use only the Python standard library.

## Mandatory architecture

Installation requires a Git branch named **`agents-base`** and a real, dedicated Git worktree checked out on that
branch. A directory called `agents-base` without the matching branch/worktree is not an installation.

- `agents-base` is the canonical source of shared instructions, project settings, coding rules, roles, and plans.
- Personal preferences live in ignored `AGENTS_custom.md` inside that worktree. They are local, not committed.
- Execution records/logs/reservations live in ignored `<WORKSPACE_ROOT>/.agent-runtime/`, outside both histories.
- Proposal and archival branches start from and merge back only into `agents-base`.
- Code implementation branches start from and merge into the repository's configured integration branch.
- Never merge or cherry-pick between the instructions lineage and the code lineage. Do not copy complete
  instructions or plans into a code branch. Keep `agents-base` local with no upstream by default.

The packaged `agents-base/` directory is installation payload, not a ready-made Git worktree. Extract the ZIP to a
staging directory outside the destination repository, create the real worktree, then copy the payload into it.
Do not commit the extracted package as a subdirectory of a code branch.

## One common-root bootstrap

The package-root `AGENTS.md` is the **bootstrap**. The separate `agents-base/AGENTS.md` contains the shared rules.
The bootstrap locates the canonical worktree and requires agents to read its instructions before any task.

Place the bootstrap at the common workspace root containing all task worktrees. In the recommended bare layout,
this is the directory containing the bare `.git/`. In an ordinary repository, it can be the repository root beside
its `.git/`, with additional worktrees below `.worktrees/`.

There is no requirement to duplicate the bootstrap in every worktree. A single parent bootstrap works only when
the agent tool discovers ancestor `AGENTS.md` files up to that common root, or is explicitly configured to load it.
Git's common directory does not itself cause instruction discovery. Check this behavior with the tools in use;
some stop at the current checkout root. Configure an explicit instruction path or load the common bootstrap when
necessary. A worktree outside the common root requires an explicit entry point; never silently assume inheritance.

The supplied bootstrap resolves `agents-base/` or `.worktrees/agents-base/` relative to its own directory, not the
agent's current working directory. Exactly one must exist, and it must be checked out on branch `agents-base`.

## Package contents

- Root `AGENTS.md`: discovery entry point; `TEMPLATE.json`: package-only marker.
- `agents-base/`: instruction worktree payload, including rules, settings, roles and plans.
- `agents-base/AGENTS/EXECUTION.md`: task-state, identity and reservation protocol.
- `agents-base/AGENTS/HANDOFF.json` and `REVIEW.json`: blank runtime/result formats, not live records.
- `agents-base/AGENTS/ADAPTER.md`: optional engine capability map; no provider is selected.
- `agents-base/tools/doctor.py`: read-only package/installation diagnostic, copied with the payload.
- `tools/test_template.py`: isolated Git regression scenarios, package development only.
- `tools/measure_context.py`: reproducible role/compact-context character estimates.
- `CHANGES.md` and `TOKEN-BUDGET.md`: optional release/measurement documentation, not mandatory agent context.

The root README is installation documentation; do not overwrite a project's README with it.

## Installation

Use an existing repository without changing its code history. Choose either layout below. The examples assume a
Git version that supports `git worktree add --orphan`; check `git worktree add -h`. If unavailable, upgrade Git or
arrange an equivalent isolated orphan worktree with the maintainer. Do not create `agents-base` from a code branch
and remove source files as a shortcut.

Before creating anything, inspect existing branches and worktrees. If `agents-base` already exists, inspect and
reuse its correct worktree after review; do not overwrite it or run the creation commands blindly. Preserve existing
`AGENTS.md` files and merge their intended constraints deliberately rather than overwriting them.

### Option A: bare repository under a common root

```text
workspace/
├── .git/                     # existing bare repository
├── AGENTS.md                 # the only common bootstrap
├── agents-base/              # worktree on agents-base
├── integration-checkout/     # worktree on the configured integration branch
└── fix_example-change/       # worktree on fix/example-change
```

The common root is not a source checkout. Run source/build/test commands from the assigned code worktree.
Use the actual path if the bare Git directory has a name other than `.git`.

Set these shell variables to real absolute paths; the values below are examples to replace:

```bash
TEMPLATE_DIR='/absolute/path/to/extracted/agent-repo-template-generic-v3'
WORKSPACE_ROOT='/absolute/path/to/workspace'
REPO_GIT_DIR="$WORKSPACE_ROOT/.git"
AGENT_BASE="$WORKSPACE_ROOT/agents-base"

git --git-dir="$REPO_GIT_DIR" branch --list agents-base
git --git-dir="$REPO_GIT_DIR" worktree list
```

Only when the branch and destination are absent, create the isolated worktree:

```bash
git --git-dir="$REPO_GIT_DIR" worktree add --orphan -b agents-base "$AGENT_BASE"
```

### Option B: existing ordinary repository

No conversion to a bare repository is required. Keep additional worktrees inside a locally ignored directory:

```text
repository/
├── .git/                     # existing repository Git directory
├── AGENTS.md                 # common bootstrap, beside .git
├── ...                       # existing checkout's project files
└── .worktrees/               # excluded from the existing checkout
    ├── agents-base/          # worktree on agents-base
    └── fix_example-change/   # worktree on fix/example-change
```

```bash
TEMPLATE_DIR='/absolute/path/to/extracted/agent-repo-template-generic-v3'
WORKSPACE_ROOT='/absolute/path/to/repository'
AGENT_BASE="$WORKSPACE_ROOT/.worktrees/agents-base"

git -C "$WORKSPACE_ROOT" branch --list agents-base
git -C "$WORKSPACE_ROOT" worktree list
git -C "$WORKSPACE_ROOT" rev-parse --path-format=absolute --git-path info/exclude
```

Before creating nested worktrees, add `/.worktrees/` and `/.agent-runtime/` to the local exclude file reported above.
Keep the new bootstrap local by also excluding `/AGENTS.md` when no such file is already tracked. Do not untrack or
overwrite an existing bootstrap without reviewing it. These local excludes do not modify committed project ignore
rules. The instruction payload's `.gitignore` explicitly unignores its own `/AGENTS.md`, so this shared local exclude
does not hide the canonical instruction file. Preserve that exception. Build tools may not respect Git excludes:
exclude `.worktrees/` and `.agent-runtime/` from project file discovery as needed.

Only when the branch and destination are absent:

```bash
mkdir -p "$WORKSPACE_ROOT/.worktrees"
git -C "$WORKSPACE_ROOT" worktree add --orphan -b agents-base "$AGENT_BASE"
```

### Populate and configure the worktree

For either option, continue with the variables already set. Check that the new worktree contains no source files:

```bash
git -C "$AGENT_BASE" symbolic-ref --short HEAD
git -C "$AGENT_BASE" status --short
cp -R "$TEMPLATE_DIR/agents-base/." "$AGENT_BASE/"
```

The branch output must be `agents-base`. Review and configure `AGENTS/PROJECT.md` and `AGENTS/CODING.md` using
repository evidence before implementation. Record absolute paths, the actual integration branch, release branches
or `None`, authoritative remote/upstream information, supported platforms, project constraints, and verification
commands. Use plain values without Markdown quoting/trailing punctuation in setting lines. `Not configured` means
setup is incomplete, not optional. Use explicit `Authoritative remote: None` for a local-only repository.
For multiple machines configure authorized instruction/plan distribution, backup and shared lock authority; local
runtime locks alone are for one shared filesystem host. Do not distribute private preference files by default.

After checking that the common-root destination `AGENTS.md` is absent, copy the bootstrap:

```bash
cp "$TEMPLATE_DIR/AGENTS.md" "$WORKSPACE_ROOT/AGENTS.md"
```

Review an existing file instead of running that copy over it. There is no automatic source-code modification.
Stage only the instruction payload and commit on the instruction branch:

```bash
git -C "$AGENT_BASE" add -- AGENTS.md README.md AGENTS_custom.example.md .gitignore AGENTS tools
git -C "$AGENT_BASE" diff --cached --stat
git -C "$AGENT_BASE" commit -m "Initialize shared agent instructions"
```

Optionally copy `AGENTS_custom.example.md` to `AGENTS_custom.md` inside `AGENT_BASE` and edit local preferences.
The local file is ignored and must never be added to a commit. No provider or model is required by this starter.

Verify installation:

```bash
git -C "$AGENT_BASE" branch --show-current
git -C "$AGENT_BASE" worktree list
git -C "$AGENT_BASE" status --short
git -C "$AGENT_BASE" ls-files
```

Confirm that `agents-base` has no project source files or unauthorized upstream; preferences are untracked/ignored;
code branches contain no plans or complete instructions; and the engine loads the common-root bootstrap from each
task worktree. Finish configuration before starting plan-based implementation.

## Structural diagnostic and engine check

Before installation, this reports `package` (not execution-ready):

```bash
python3 "$TEMPLATE_DIR/agents-base/tools/doctor.py" --workspace "$TEMPLATE_DIR" --json
```

After configuration/commit, use an actual registered code checkout:

```bash
python3 "$AGENT_BASE/tools/doctor.py" --workspace "$WORKSPACE_ROOT" --code-worktree '/absolute/code/worktree' --json
```

Results: `package` = recognized installation payload; `incomplete` = setup errors (exit 1); `ready` = static
installation checks pass (exit 0). The tool performs no fetch, writes, installation or repair. It verifies canonical
branch/worktree/repository, required tracked files, unresolved settings, path consistency, local exclusions, plan
directories, JSON syntax, lineage isolation and a supplied code checkout. `ready` does not prove runtime approval,
resource availability or the engine's instruction loading. It does not audit all project source files.

In each engine, start a read-only session inside a task code worktree and ask it to identify the common bootstrap,
canonical instruction branch/path and required role files before edits. Record the successful discovery or configure
an explicit entry path and repeat. Consult ADAPTER.md only when connecting engine capabilities. No adapter may weaken
authorization/review boundaries. Never infer a tool's capabilities from a provider name.

## Task names and compact/full lifecycle

```text
Code branch/worktree:       fix/example-change / fix_example-change/
Stable Plan ID:             fix_example-change
Proposal attempt 1:         docs/plan-fix-example-change-r1
Proposal attempt 2:         docs/plan-fix-example-change-r2
Proposal worktree:          docs_plan-fix-example-change-r1/
Full archival branch:       docs/finish-fix-example-change-r1
Optional batch archival:   docs/archive-completed-fixes-r1
Runtime task state:         .agent-runtime/tasks/fix_example-change/state.json
```

Proposal attempt numbers survive retained/rejected branches; retries resume their recorded attempt. A scope change
creates the next numbered proposal, preserves current validated content until renewed approval, then promotes the
new content. New deliverables use new Plan IDs. Worktrees follow branch names by replacing the separating slash.

Lead creates the proposal worktree first. Planner writes the pending plan once; Lead reviews and commits the file
before requesting exact-content validation. Validation, selection, parallelism and integration grants are recorded
separately and may share one user reply. Code starts only from integrated prerequisites and current integration.

Compact reuses Lead for planning and its active proposal branch for archival; full can use a separate Planner and
archival branch. Scope/acceptance and independent review gates are identical. Reviewer approves exact code SHA and
plan blob. A changed integration base produces a new Developer candidate plus independent delta review before merge.
Archival uses the actual full code integration commit and a short-hash suffix, preserving plan contents.

Runtime state is written only by Lead through atomic replacement. On resume verify used-file hashes, pinned plan,
recorded branches and checkpoints. Unrelated instruction commits do not reload every context. Keep logs/results by
reference. Reserve configured shared resources; serialize instruction and code integrations. See the operational
files rather than copying these procedures into delegation prompts.

Publication/release/cleanup are separate explicit grants. A bounded cleanup grant can cover named finished, clean,
inactive task artifacts with evidence retention. Neither route silently deletes rejected work or publishes code.

## Validation of this package

Run from the package root, using Python 3.9+ and Git supporting `worktree add --orphan`:

```bash
python3 -B tools/test_template.py
python3 -B tools/measure_context.py --baseline ../agent-repo-template-generic-v2
```

Tests create temporary repositories without external network access. They do not install the template into a real
project or prove agent behavior/performance. Context measurements use characters/4, not tokenizer/billing data.

## Maintaining the generic package

Ship no configured settings, live task records, local preferences, Git metadata, secrets or project implementation.
Keep lifecycle directories, both entry-point files and blank JSON formats. Keep package development tests/tools at
root and the installable diagnostic under the payload. Use portable ZIP paths. Do not package runtime caches.
