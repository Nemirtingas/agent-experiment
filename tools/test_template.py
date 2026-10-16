#!/usr/bin/env python3
"""Isolated structural and Git lifecycle checks; no external network access."""

import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


PACKAGE = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("template_doctor", PACKAGE / "agents-base/tools/doctor.py")
DOCTOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(DOCTOR)


def git(cwd, *args):
    env = dict(os.environ, GIT_CONFIG_NOSYSTEM="1", GIT_CONFIG_GLOBAL=os.devnull,
               GIT_AUTHOR_NAME="Fixture", GIT_AUTHOR_EMAIL="fixture@example.invalid",
               GIT_COMMITTER_NAME="Fixture", GIT_COMMITTER_EMAIL="fixture@example.invalid",
               LC_ALL="C")
    result = subprocess.run(["git", "-C", str(cwd), "-c", "commit.gpgsign=false",
                             "-c", "core.hooksPath=" + os.devnull, *args],
                            capture_output=True, text=True, env=env)
    if result.returncode:
        raise AssertionError(f"Git {args!r}: {result.stderr}")
    return result.stdout.strip()


def commit(cwd, *paths):
    git(cwd, "add", "--", *paths)
    return git(cwd, "commit", "-m", "Update fixture")


def fixture(parent, bare=False, configured=True, orphan=True):
    root = parent / "workspace"
    seed = parent / "seed"
    seed.mkdir()
    git(seed, "init", "-b", "integration")
    (seed / "source.txt").write_text("initial\n")
    commit(seed, "source.txt")
    if bare:
        root.mkdir()
        git(parent, "clone", "--bare", str(seed), str(root / ".git"))
        code = root / "integration-checkout"
        git(root, "--git-dir=" + str(root / ".git"), "worktree", "add", str(code), "integration")
        tree_parent = root
    else:
        shutil.copytree(seed, root)
        code = root
        tree_parent = root / ".worktrees"
        tree_parent.mkdir()
        (root / ".git/info/exclude").write_text("/.worktrees/\n/.agent-runtime/\n/AGENTS.md\n")
    base = tree_parent / "agents-base"
    args = ["worktree", "add"] + (["--orphan"] if orphan else [])
    args += ["-b", "agents-base", str(base)] + ([] if orphan else ["integration"])
    git(code, *args)
    shutil.copytree(PACKAGE / "agents-base", base, dirs_exist_ok=True)
    shutil.copy2(PACKAGE / "AGENTS.md", root / "AGENTS.md")
    if configured:
        config = {
            "Project purpose": "Fixture", "Platforms and public compatibility guarantees": "Local test only",
            "Workspace root": str(root), "Layout": "bare" if bare else "ordinary",
            "Shared Git directory": str(root / ".git"), "Worktree parent": str(tree_parent),
            "AGENT_BASE": str(base), "Integration branch": "integration", "Authoritative remote": "None",
            "Release branches": "None", "Sensitive and generated paths": "None",
            "Shared resources and constraints": "None", "Multi-machine distribution and backup": "Single host",
            "Project coding rules": "[PROJECT_CODING.md](PROJECT_CODING.md)",
        }
        path = base / "AGENTS/PROJECT/PROJECT_CONFIG.md"
        text = path.read_text()
        for key, value in config.items():
            text = re.sub(r"^- " + re.escape(key) + r":.*$", lambda m, k=key, v=value: f"- {k}: {v}",
                          text, flags=re.MULTILINE)
        path.write_text(text)
        coding = base / "AGENTS/PROJECT/PROJECT_CODING.md"
        coding.write_text(coding.read_text().replace("Not configured.", "None").replace("Not configured", "None"))
    commit(base, "AGENTS.md", "README.md", "AGENTS_custom.example.md", ".gitignore", "AGENTS", "tools")
    return root, code, base, tree_parent


class DiagnosticTests(unittest.TestCase):
    def test_package_is_not_an_execution_ready_installation(self):
        before = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in PACKAGE.rglob("*") if p.is_file()}
        result = DOCTOR.diagnose(PACKAGE)
        self.assertEqual(result["status"], "package", result)
        after = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in PACKAGE.rglob("*") if p.is_file()}
        self.assertEqual(before, after)

    def test_ordinary_installation_and_ignore_exceptions(self):
        with tempfile.TemporaryDirectory() as td:
            root, code, base, _ = fixture(Path(td))
            (base / "AGENTS_custom.md").write_text("Private preference\n")
            result = DOCTOR.diagnose(root, code)
            self.assertEqual(result["status"], "ready", result)
            self.assertEqual(git(base, "ls-files", "--", "AGENTS.md"), "AGENTS.md")
            self.assertEqual(git(base, "status", "--porcelain"), "")

    def test_bare_installation(self):
        with tempfile.TemporaryDirectory() as td:
            root, code, _, _ = fixture(Path(td), bare=True)
            result = DOCTOR.diagnose(root, code)
            self.assertEqual(result["status"], "ready", result)

    def test_unconfigured_installation_is_incomplete(self):
        with tempfile.TemporaryDirectory() as td:
            root, code, _, _ = fixture(Path(td), configured=False)
            result = DOCTOR.diagnose(root, code)
            self.assertEqual(result["status"], "incomplete")
            self.assertTrue(any("Unresolved setting" in e for e in result["errors"]))

    def test_wrong_canonical_branch(self):
        with tempfile.TemporaryDirectory() as td:
            root, code, base, _ = fixture(Path(td))
            git(base, "switch", "-c", "docs/unrelated")
            self.assertIn("Canonical worktree must be checked out on agents-base.", DOCTOR.diagnose(root, code)["errors"])

    def test_ambiguous_candidate_is_not_silently_adopted(self):
        with tempfile.TemporaryDirectory() as td:
            root, code, _, _ = fixture(Path(td))
            (root / "agents-base").mkdir()
            self.assertEqual(DOCTOR.diagnose(root, code)["status"], "incomplete")

    def test_foreign_code_repository_is_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            root, _, _, _ = fixture(Path(td))
            foreign = root / "foreign"
            foreign.mkdir()
            git(foreign, "init", "-b", "integration")
            result = DOCTOR.diagnose(root, foreign)
            self.assertIn("Code worktree belongs to another repository.", result["errors"])

    def test_missing_runtime_exclusion_is_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            root, code, _, _ = fixture(Path(td))
            p = root / ".git/info/exclude"
            p.write_text(p.read_text().replace("/.agent-runtime/\n", ""))
            self.assertTrue(any(".agent-runtime/" in e for e in DOCTOR.diagnose(root, code)["errors"]))

    def test_tracked_preferences_are_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            root, code, base, _ = fixture(Path(td))
            (base / "AGENTS_custom.md").write_text("Preference\n")
            git(base, "add", "-f", "--", "AGENTS_custom.md")
            git(base, "commit", "-m", "Track fixture preference")
            self.assertIn("Local preferences must never be tracked.", DOCTOR.diagnose(root, code)["errors"])

    def test_non_orphan_history_is_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            root, code, _, _ = fixture(Path(td), orphan=False)
            self.assertIn("Instruction and code histories are not isolated orphan lineages.",
                          DOCTOR.diagnose(root, code)["errors"])

    def test_deleted_setting_is_not_treated_as_configured(self):
        with tempfile.TemporaryDirectory() as td:
            root, code, base, _ = fixture(Path(td))
            p = base / "AGENTS/CODING.md"
            p.write_text(re.sub(r"^- Test commands and organization:.*\n", "", p.read_text(), flags=re.MULTILINE))
            commit(base, "AGENTS/CODING.md")
            self.assertIn("Missing CODING.md setting: Test commands and organization", DOCTOR.diagnose(root, code)["errors"])

    def test_tracked_runtime_is_rejected_even_when_ignored(self):
        with tempfile.TemporaryDirectory() as td:
            root, code, _, _ = fixture(Path(td))
            (root / ".agent-runtime").mkdir()
            (root / ".agent-runtime/state.json").write_text("{}\n")
            git(code, "add", "-f", "--", ".agent-runtime/state.json")
            git(code, "commit", "-m", "Track fixture runtime")
            self.assertIn("Runtime records and nested worktrees must not be tracked in code history.",
                          DOCTOR.diagnose(root, code)["errors"])

    def test_malformed_package_marker_is_reported(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            (root / "TEMPLATE.json").write_text("[]\n")
            self.assertIn("TEMPLATE.json must be an object.", DOCTOR.diagnose(root)["errors"])


class LifecycleScenarios(unittest.TestCase):
    def test_full_batch_archive_preserves_each_plan_blob_and_code_hash(self):
        with tempfile.TemporaryDirectory() as td:
            _, code, base, parent = fixture(Path(td))
            plans = []
            for name in ("first", "second"):
                (code / "source.txt").write_text(name + "\n")
                commit(code, "source.txt")
                integration_commit = git(code, "rev-parse", "HEAD")
                path = "AGENTS/PLANS/VALIDATED_PLANS/fix_" + name + ".md"
                (base / path).write_text("# " + name + "\n")
                commit(base, path)
                plans.append((name, path, integration_commit, git(base, "rev-parse", "HEAD:" + path)))
            branch = "docs/archive-completed-fixes-r1"
            work = parent / branch.replace("/", "_", 1)
            git(base, "worktree", "add", "-b", branch, str(work), "agents-base")
            destinations = []
            for name, path, integration_commit, blob in plans:
                git(code, "merge-base", "--is-ancestor", integration_commit, "integration")
                suffix = git(code, "rev-parse", "--short", integration_commit)
                dest = "AGENTS/PLANS/FINISHED_PLANS/fix_" + name + "-" + suffix + ".md"
                git(work, "mv", path, dest)
                destinations.append((dest, blob))
            commit(work, *(path for path, _ in destinations))
            git(base, "merge", "--ff-only", branch)
            for dest, blob in destinations:
                self.assertEqual(git(base, "rev-parse", "HEAD:" + dest), blob)

    def test_revised_plan_and_compact_archival_with_retained_branches(self):
        """Exercise the documented Git sequence, not agent approval enforcement."""
        with tempfile.TemporaryDirectory() as td:
            root, code, base, parent = fixture(Path(td))
            plan_id = "fix_example-change"
            pending = "AGENTS/PLANS/PENDING_PLANS/" + plan_id + ".md"
            validated = "AGENTS/PLANS/VALIDATED_PLANS/" + plan_id + ".md"
            attempts = []
            for number, content in ((1, "# Plan\nA1: original scope\n"), (2, "# Plan\nA1: revised scope\n")):
                branch = f"docs/plan-fix-example-change-r{number}"
                wt = parent / branch.replace("/", "_", 1)
                git(base, "worktree", "add", "-b", branch, str(wt), "agents-base")
                (wt / pending).write_text(content)
                commit(wt, pending)
                approved_blob = git(wt, "rev-parse", "HEAD:" + pending)
                if number == 1:
                    git(wt, "mv", pending, validated)
                    commit(wt, validated)
                else:
                    # Existing validated content remains untouched until the revision is approved.
                    self.assertEqual((base / validated).read_text(), "# Plan\nA1: original scope\n")
                    (wt / validated).write_text(content)
                    (wt / pending).unlink()
                    commit(wt, pending, validated)
                git(base, "merge", "--ff-only", branch)
                self.assertEqual(git(base, "rev-parse", "HEAD:" + validated), approved_blob)
                attempts.append((branch, wt))
            pinned_commit = git(base, "rev-parse", "HEAD")
            pinned_blob = git(base, "rev-parse", "HEAD:" + validated)
            git(code, "worktree", "add", "-b", "fix/example-change", str(parent / plan_id), "integration")
            implementation = parent / plan_id
            (implementation / "source.txt").write_text("changed\n")
            commit(implementation, "source.txt")
            reviewed_head = git(implementation, "rev-parse", "HEAD")
            git(code, "merge", "--ff-only", "fix/example-change")
            integration_commit = git(code, "rev-parse", "HEAD")
            self.assertEqual(integration_commit, reviewed_head)

            # Another instruction change advances canonical HEAD without changing used plan content.
            (base / "AGENTS/unrelated.md").write_text("Unrelated instruction evidence\n")
            commit(base, "AGENTS/unrelated.md")
            self.assertNotEqual(git(base, "rev-parse", "HEAD"), pinned_commit)
            self.assertEqual(git(base, "rev-parse", "HEAD:" + validated), pinned_blob)

            branch, wt = attempts[-1]
            git(wt, "merge", "--ff-only", "agents-base")
            suffix = git(code, "rev-parse", "--short", integration_commit)
            archived = "AGENTS/PLANS/FINISHED_PLANS/" + plan_id + "-" + suffix + ".md"
            git(wt, "mv", validated, archived)
            commit(wt, archived)
            git(base, "merge", "--ff-only", branch)
            self.assertEqual(git(base, "rev-parse", "HEAD:" + archived), pinned_blob)
            self.assertEqual(git(base, "show", pinned_commit + ":" + validated), "# Plan\nA1: revised scope")
            for retained, _ in attempts:
                git(base, "show-ref", "--verify", "refs/heads/" + retained)
            self.assertFalse(git(code, "ls-files", "--", "AGENTS/PLANS"))

    def test_conflict_free_integration_advance_produces_new_review_candidate(self):
        with tempfile.TemporaryDirectory() as td:
            _, code, _, parent = fixture(Path(td))
            work = parent / "fix_candidate"
            git(code, "worktree", "add", "-b", "fix/candidate", str(work), "integration")
            (work / "source.txt").write_text("candidate\n")
            commit(work, "source.txt")
            first_head = git(work, "rev-parse", "HEAD")
            (code / "other.txt").write_text("integration advanced\n")
            commit(code, "other.txt")
            new_base = git(code, "rev-parse", "HEAD")
            git(work, "merge", "--no-edit", "integration")
            new_head = git(work, "rev-parse", "HEAD")
            self.assertNotEqual(first_head, new_head)
            git(work, "merge-base", "--is-ancestor", new_base, new_head)
            self.assertEqual((work / "source.txt").read_text(), "candidate\n")
            self.assertEqual((work / "other.txt").read_text(), "integration advanced\n")


if __name__ == "__main__":
    unittest.main(verbosity=2)
