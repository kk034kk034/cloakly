#!/usr/bin/env python3
"""Bump apps/mobile pubspec build number for CI uploads.

Uses max(pubspec build + 0, GITHUB_RUN_NUMBER), then ensures it is at least
pubspec_build + 1 so TestFlight / Play never see a duplicate bundle version.
Does not commit; only affects the checked-out tree for this job.
"""

from __future__ import annotations

import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PUBSPEC = ROOT / "apps" / "mobile" / "pubspec.yaml"


def main() -> None:
    text = PUBSPEC.read_text(encoding="utf-8")
    match = re.search(r"^version:\s*([^\s+]+)\+(\d+)\s*$", text, re.M)
    if not match:
        raise SystemExit(f"Could not parse version in {PUBSPEC}")
    name = match.group(1)
    current = int(match.group(2))
    run_number = int(os.environ.get("GITHUB_RUN_NUMBER", "0"))
    build = max(run_number, current + 1)
    updated = re.sub(
        r"^version:\s*.*$",
        f"version: {name}+{build}",
        text,
        count=1,
        flags=re.M,
    )
    PUBSPEC.write_text(updated, encoding="utf-8")
    print(f"CI version → {name}+{build} (pubspec was {name}+{current})")


if __name__ == "__main__":
    main()
