#!/usr/bin/env python3
"""Read-only structural checks for the template package or an installation."""

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess


def git(cwd, *args):
    env = dict(os.environ, GIT_OPTIONAL_LOCKS="0", LC_ALL="C")
    result = subprocess.run(
        ["git", "-C", str(cwd), *args], text=True, capture_output=True, env=env
    )
    return result.returncode, result.stdout.strip()


def diagnose(workspace, code_worktree=None):
    root = Path(workspace).resolve()
    report = {"status": "incomplete", "workspace": str(root), "errors": [], "warnings": []}
    errors, warnings = report["errors"], report["warnings"]
    if not root.is_dir():
        errors.append("Workspace does not exist or is not a directory.")
        return report
    if not shutil.which("git"):
        errors.append("Git is required to distinguish a payload from a registered worktree.")
        return report

    candidates = [p for p in (root / "agents-base", root / ".worktrees/agents-base") if p.exists()]
    marker = root / "TEMPLATE.json"
    if marker.is_file():
        try:
            metadata = json.loads(marker.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            errors.append("TEMPLATE.json is unreadable or invalid JSON.")
            return report
        if not isinstance(metadata, dict):
            errors.append("TEMPLATE.json must be an object.")
            return report
        registered = []
        for candidate in candidates:
            code, top = git(candidate, "rev-parse", "--show-toplevel")
            if code == 0 and Path(top).resolve() == candidate.resolve():
                registered.append(candidate)
        if not registered:
            if (metadata.get("kind"), metadata.get("version")) != ("installation-package", 3):
                errors.append("Unrecognized package kind/version.")
            elif len(candidates) != 1 or not (candidates[0] / "AGENTS.md").is_file():
                errors.append("Package payload is missing or ambiguous.")
            elif code_worktree is not None:
                errors.append("A package is not an installed workspace; omit --code-worktree.")
            else:
                report["status"] = "package"
                warnings.append("Installation payload only; not configured for project execution.")
            return report
        errors.append("Installed workspace must not contain the package-only TEMPLATE.json marker.")

    if len(candidates) != 1:
        errors.append("Expected exactly one agents-base/ or .worktrees/agents-base/ candidate.")
        return report
    base = candidates[0].resolve()
    report["agent_base"] = str(base)
    if not base.is_relative_to(root):
        errors.append("Canonical worktree resolves outside the common workspace root.")
    rc, top = git(base, "rev-parse", "--show-toplevel")
    if rc or Path(top).resolve() != base:
        errors.append("Canonical directory is not the root of a real Git worktree.")
        return report
    rc, branch = git(base, "symbolic-ref", "--quiet", "--short", "HEAD")
    if rc or branch != "agents-base":
        errors.append("Canonical worktree must be checked out on agents-base.")
    rc, common = git(base, "rev-parse", "--path-format=absolute", "--git-common-dir")
    if rc:
        errors.append("Cannot resolve shared Git directory.")
        return report
    common = Path(common).resolve()
    rc, listing = git(base, "worktree", "list", "--porcelain")
    registered_paths = [Path(line[9:]).resolve() for line in listing.splitlines() if line.startswith("worktree ")]
    if rc or base not in registered_paths:
        errors.append("Canonical worktree is not registered in its repository.")

    required = ["AGENTS.md", "AGENTS/PROJECT.md", "AGENTS/CODING.md", "AGENTS/WORKFLOW.md",
                "AGENTS/EXECUTION.md", "AGENTS/HANDOFF.json", "AGENTS/REVIEW.json",
                "AGENTS/PLANS/README.md", "AGENTS/PLANS/TEMPLATE.md"]
    required += ["AGENTS/ROLES/" + role + ".md" for role in ("LEAD", "PLANNER", "DEVELOPER", "REVIEWER")]
    for name in required:
        if not (base / name).is_file():
            errors.append("Missing canonical file: " + name)
        elif git(base, "ls-files", "--error-unmatch", "--", name)[0]:
            errors.append("Canonical instruction file is not tracked: " + name)
    for name in ("PENDING_PLANS", "VALIDATED_PLANS", "FINISHED_PLANS"):
        if not (base / "AGENTS/PLANS" / name).is_dir():
            errors.append("Missing plan lifecycle directory: " + name)
    for name in ("HANDOFF.json", "REVIEW.json"):
        try:
            json.loads((base / "AGENTS" / name).read_text(encoding="utf-8"))
        except (OSError, ValueError):
            errors.append("Invalid or unreadable JSON template: " + name)

    settings = {}
    coding_settings = set()
    for name in ("PROJECT.md", "CODING.md"):
        path = base / "AGENTS" / name
        if not path.is_file():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            match = re.match(r"^- ([^:]+):\s*(.*?)\s*$", line)
            if match:
                key, value = match.groups()
                if "Not configured" in value or not value or re.search(r"<[^>]+>", value):
                    errors.append("Unresolved setting in " + name + ": " + key)
                if name == "PROJECT.md":
                    settings[key] = value
                else:
                    coding_settings.add(key)

    for key in ("Languages, runtimes and versions", "Source/API/test paths and generated code policy",
                "Architecture, error, lifetime, concurrency and security invariants",
                "Formatting, naming and dependency policy", "Setup/build commands", "Test commands and organization",
                "Lint/format commands", "Required platforms, configurations and pre-review checks",
                "Reviewer output directories and resource requirements"):
        if key not in coding_settings:
            errors.append("Missing CODING.md setting: " + key)

    mandatory = ("Project purpose", "Platforms and public compatibility guarantees", "Repository file language",
                 "Workspace root", "Layout", "Shared Git directory", "Worktree parent", "AGENT_BASE",
                 "Integration branch", "Authoritative remote", "Release branches", "Sensitive and generated paths",
                 "Shared resources and constraints", "Multi-machine distribution and backup")
    for key in mandatory:
        if key not in settings:
            errors.append("Missing PROJECT.md setting: " + key)
    for key, expected in (("Workspace root", root), ("AGENT_BASE", base), ("Shared Git directory", common)):
        value = settings.get(key, "")
        if value and "Not configured" not in value:
            if not Path(value).is_absolute() or Path(value).resolve() != expected:
                errors.append("Configured path does not match installation: " + key)
    parent = settings.get("Worktree parent", "")
    if parent and "Not configured" not in parent:
        if not Path(parent).is_absolute() or not Path(parent).resolve().is_relative_to(root):
            errors.append("Worktree parent must be absolute and below the workspace root.")
    rc, bare = git(base, "--git-dir=" + str(common), "rev-parse", "--is-bare-repository")
    expected_layout = "bare" if bare == "true" else "ordinary"
    layout = settings.get("Layout", "")
    if layout not in ("bare", "ordinary"):
        errors.append("Layout must be bare or ordinary.")
    elif layout != expected_layout:
        errors.append("Configured layout differs from repository structure.")
    if layout == "ordinary":
        rc, root_common = git(root, "rev-parse", "--path-format=absolute", "--git-common-dir")
        if rc or Path(root_common).resolve() != common:
            errors.append("Canonical worktree does not belong to the common-root repository.")

    prefs = "AGENTS_custom.md"
    if git(base, "ls-files", "--error-unmatch", "--", prefs)[0] == 0:
        errors.append("Local preferences must never be tracked.")
    if git(base, "check-ignore", "--no-index", "-q", "--", prefs)[0] != 0:
        errors.append("Local preferences are not ignored.")
    if git(base, "check-ignore", "--no-index", "-q", "--", "AGENTS.md")[0] == 0:
        errors.append("Canonical AGENTS.md is hidden by ignore rules; retain its unignore exception.")
    rc, status = git(base, "status", "--porcelain", "--untracked-files=normal")
    if rc or status:
        errors.append("Canonical worktree must be clean after installation/configuration.")
    if git(base, "rev-parse", "--verify", "HEAD")[0]:
        errors.append("Canonical instructions need an initial commit.")
    if git(base, "rev-parse", "--abbrev-ref", "@{upstream}")[0] == 0:
        warnings.append("Instructions have an upstream; confirm explicit sharing authorization.")
    if not (root / "AGENTS.md").is_file():
        errors.append("Common-root bootstrap is missing.")
    if layout == "ordinary":
        if git(root, "ls-files", "--", ".worktrees", ".agent-runtime")[1]:
            errors.append("Runtime records and nested worktrees must not be tracked in code history.")
        for name in (".worktrees/probe", ".agent-runtime/probe"):
            if git(root, "check-ignore", "--no-index", "-q", "--", name)[0] != 0:
                errors.append("Common-root local excludes must cover " + name.split("/")[0] + "/.")

    integration = settings.get("Integration branch", "")
    if integration and "Not configured" not in integration:
        if git(base, "show-ref", "--verify", "--quiet", "refs/heads/" + integration)[0]:
            errors.append("Configured local integration branch is absent.")
        elif git(base, "merge-base", "agents-base", integration)[0] == 0:
            errors.append("Instruction and code histories are not isolated orphan lineages.")
    remote = settings.get("Authoritative remote", "")
    if remote and remote != "None" and "Not configured" not in remote:
        rc, remotes = git(base, "remote")
        if rc or remote not in remotes.splitlines():
            errors.append("Configured authoritative remote does not exist.")

    if code_worktree is not None:
        checkout = Path(code_worktree).resolve()
        if not checkout.is_dir():
            errors.append("Code worktree does not exist.")
        elif checkout == base or not checkout.is_relative_to(root):
            errors.append("Code worktree must be distinct and below the common root.")
        else:
            rc, code_top = git(checkout, "rev-parse", "--show-toplevel")
            if rc or Path(code_top).resolve() != checkout or checkout not in registered_paths:
                errors.append("Code checkout must be a registered worktree root.")
            rc, code_common = git(checkout, "rev-parse", "--path-format=absolute", "--git-common-dir")
            if rc or Path(code_common).resolve() != common:
                errors.append("Code worktree belongs to another repository.")
            if git(checkout, "ls-files", "--", "AGENTS/PLANS")[1]:
                errors.append("Code history contains agent plan files.")
            if git(checkout, "status", "--porcelain")[1]:
                warnings.append("Code checkout contains changes; preserve them before implementation.")
    else:
        warnings.append("Pass --code-worktree to verify a source checkout's repository and bootstrap reachability.")
    warnings.append("Manually confirm actual bootstrap loading in each engine; static Git checks cannot prove it.")
    if not errors:
        report["status"] = "ready"
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--workspace", required=True, type=Path)
    parser.add_argument("--code-worktree", type=Path)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    try:
        report = diagnose(args.workspace, args.code_worktree)
    except (OSError, ValueError) as exc:
        report = {"status": "incomplete", "errors": [str(exc)], "warnings": []}
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print("Status: " + report["status"])
        for key, prefix in (("errors", "ERROR"), ("warnings", "NOTE")):
            for message in report[key]:
                print(prefix + ": " + message)
    return 1 if report["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
