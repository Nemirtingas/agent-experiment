# Shared project configuration rules

Do not modify AGENTS/PROJECT.md to configure a project or implement a project task.
This file is the reusable entry point; project-specific agent files belong in the
tracked `AGENTS/PROJECT/` directory in canonical AGENT_BASE. Configure the separate
[PROJECT_CONFIG.md](PROJECT/PROJECT_CONFIG.md) there when setting up a project. Changes to this
shared policy require an explicit request to maintain the common policy itself.

## Load the project configuration

Read PROJECT/PROJECT_CONFIG.md before dependent planning, implementation, review or Git work.
It owns the project purpose, language, platforms, compatibility, workspace paths,
repository layout, integration/remote/release settings, sensitive/generated paths,
shared resources and distribution policy. Its `Project coding rules` Markdown link
selects the separate project coding file, resolved relative to PROJECT_CONFIG.md;
CODING.md remains the common coding policy. Configuration and referenced coding files
must be tracked under AGENTS/PROJECT/ in canonical AGENT_BASE and distinct from these shared files.

If configuration or a required reference is missing, report the missing setup before
dependent work. Never infer another project's paths, commands or permissions. Project
configuration cannot weaken shared invariants or grant publication by itself.
Include this file, PROJECT/PROJECT_CONFIG.md and any loaded project coding file in the task's
used-file hash manifest. Reconcile changes on resume before using affected settings.

## Reuse and compatibility

Keep PROJECT.md and CODING.md unchanged when copying the common rules to another
project. Adapt AGENTS/PROJECT/PROJECT_CONFIG.md and its referenced project files from destination
repository evidence; verify paths and commands rather than reusing old host settings.
Existing plans referring to PROJECT.md settings resolve through PROJECT_CONFIG.md;
keep pinned plan contents and acceptance criteria unchanged.
