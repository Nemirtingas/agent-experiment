#!/usr/bin/env python3
"""Estimate fresh instruction context using decoded characters / 4; no billing claims."""

import argparse
import json
from pathlib import Path


BASE = ["AGENTS.md", "agents-base/AGENTS.md", "agents-base/AGENTS/PROJECT.md"]
PREFIX = "agents-base/AGENTS/"
V2 = {
    "Lead": ["ROLES/LEAD.md", "WORKFLOW.md", "PLANS/README.md", "PLANS/TEMPLATE.md"],
    "Planner": ["ROLES/PLANNER.md", "PLANS/TEMPLATE.md"],
    "Developer": ["ROLES/DEVELOPER.md", "CODING.md"],
    "Reviewer": ["ROLES/REVIEWER.md", "CODING.md"],
}
V3 = {
    "Lead": V2["Lead"] + ["EXECUTION.md", "HANDOFF.json"],
    "Planner": V2["Planner"] + ["CODING.md"],
    "Developer": V2["Developer"],
    "Reviewer": V2["Reviewer"] + ["REVIEW.json"],
}


def profiles(root, definitions):
    sets = {role: set(BASE + [PREFIX + p for p in additions]) for role, additions in definitions.items()}
    counts = {role: sum(len((root / p).read_text(encoding="utf-8")) for p in paths)
              for role, paths in sets.items()}
    counts["Four fresh contexts"] = sum(counts.values())
    if definitions is V3:
        merged = sets["Lead"] | sets["Planner"]
        counts["Compact: three fresh contexts"] = (
            sum(len((root / p).read_text(encoding="utf-8")) for p in merged)
            + counts["Developer"] + counts["Reviewer"]
        )
    return counts


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, help="Optional unconfigured v2 package")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    current = profiles(root, V3)
    baseline = profiles(args.baseline.resolve(), V2) if args.baseline else None
    if args.json:
        print(json.dumps({"unit": "decoded UTF-8 characters", "v3": current, "v2": baseline}, indent=2))
    else:
        print("Profile | v3 characters | estimated tokens (characters / 4)")
        for name, chars in current.items():
            print(f"{name} | {chars:,} | {round(chars / 4):,}")
        if baseline:
            print("v2 four fresh contexts:", baseline["Four fresh contexts"], "characters")
            for name in ("Four fresh contexts", "Compact: three fresh contexts"):
                delta = 100 * (current[name] / baseline["Four fresh contexts"] - 1)
                print(f"v3 {name} vs v2 four: {delta:+.1f}% characters")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
