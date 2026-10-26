#!/usr/bin/env python3
"""Check Cloakly store metadata against App Store and Play character limits.

Pass --strict to fail while REPLACE_ME placeholders are still present.
The public metadata workflow uses --strict so a listing cannot upload early.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
IOS = ROOT / "apps/mobile/ios/fastlane/metadata"
ANDROID = ROOT / "apps/mobile/android/fastlane/metadata/android"

IOS_LOCALES = ("en-US", "zh-Hant")
ANDROID_LOCALES = ("en-US", "zh-TW")

LIMITS = {
    "name": 30,
    "subtitle": 30,
    "keywords": 100,
    "promotional_text": 170,
    "description": 4000,
    "release_notes": 4000,
    "title": 30,
    "short_description": 80,
    "full_description": 4000,
    "changelog": 500,
}

REQUIRED_PHRASES = {
    "ios-description": (
        "19.99",
        "199.99",
        "cloakly_pro_monthly",
        "cloakly_pro_yearly",
        "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/",
        "http",
    ),
    "android-description": (
        "19.99",
        "199.99",
        "cloakly_pro_monthly",
        "cloakly_pro_yearly",
        "http",
    ),
}


def stripped(path: Path) -> str:
    return path.read_text(encoding="utf-8").strip()


def check_length(errors: list[str], path: Path, limit: int) -> None:
    if not path.is_file():
        errors.append(f"missing {path.relative_to(ROOT)}")
        return
    length = len(stripped(path))
    if length == 0:
        errors.append(f"empty {path.relative_to(ROOT)}")
    elif length > limit:
        errors.append(f"{path.relative_to(ROOT)} is {length} characters (limit {limit})")
    else:
        print(f"ok {length:4}/{limit:<4} {path.relative_to(ROOT)}")


def check_positioning(errors: list[str], path: Path) -> None:
    if not path.is_file():
        return
    text = stripped(path)
    if "agreed" not in text and "同意" not in text:
        errors.append(f"{path.relative_to(ROOT)} must say participants have to agree before recording")
    if "hidden" not in text.lower() and "隱藏" not in text:
        errors.append(f"{path.relative_to(ROOT)} must keep the visible-assistant positioning")


def check_phrases(errors: list[str], path: Path, phrases: tuple[str, ...]) -> None:
    if not path.is_file():
        return
    text = stripped(path)
    for phrase in phrases:
        if phrase not in text:
            errors.append(f"{path.relative_to(ROOT)} is missing {phrase!r}")


def placeholder_hits(roots: list[Path]) -> list[Path]:
    hits = []
    for root in roots:
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            if "REPLACE_ME" in path.read_text(encoding="utf-8"):
                hits.append(path)
    return hits


def main() -> int:
    sys.stdout.reconfigure(line_buffering=True)
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--strict",
        action="store_true",
        help="fail if any metadata file still contains REPLACE_ME",
    )
    args = parser.parse_args()
    errors: list[str] = []

    for locale in IOS_LOCALES:
        folder = IOS / locale
        for name in (
            "name",
            "subtitle",
            "keywords",
            "promotional_text",
            "description",
            "release_notes",
            "privacy_url",
            "support_url",
            "marketing_url",
        ):
            path = folder / f"{name}.txt"
            if name in LIMITS:
                check_length(errors, path, LIMITS[name])
            elif not path.is_file() or not stripped(path):
                errors.append(f"missing {path.relative_to(ROOT)}")
        check_phrases(errors, folder / "description.txt", REQUIRED_PHRASES["ios-description"])
        check_positioning(errors, folder / "description.txt")
        promo = folder / "promotional_text.txt"
        if promo.is_file() and "consent" not in stripped(promo).lower() and "同意" not in stripped(promo):
            errors.append(f"{promo.relative_to(ROOT)} must mention participant consent")

    for name in ("copyright", "primary_category", "secondary_category"):
        path = IOS / f"{name}.txt"
        if not path.is_file() or not stripped(path):
            errors.append(f"missing {path.relative_to(ROOT)}")

    for locale in ANDROID_LOCALES:
        folder = ANDROID / locale
        check_length(errors, folder / "title.txt", LIMITS["title"])
        check_length(errors, folder / "short_description.txt", LIMITS["short_description"])
        check_length(errors, folder / "full_description.txt", LIMITS["full_description"])
        check_length(errors, folder / "changelogs" / "default.txt", LIMITS["changelog"])
        check_phrases(
            errors,
            folder / "full_description.txt",
            REQUIRED_PHRASES["android-description"],
        )
        check_positioning(errors, folder / "full_description.txt")
        short = folder / "short_description.txt"
        if short.is_file():
            text = stripped(short)
            if "meeting" not in text.lower() and "會議" not in text:
                errors.append(f"{short.relative_to(ROOT)} lost the meeting positioning")

    hits = placeholder_hits([IOS, ANDROID])
    if hits:
        print(f"placeholders remaining: {len(hits)} file(s)")
        for path in hits:
            print(f"  {path.relative_to(ROOT)}")
        if args.strict:
            errors.append("metadata still contains REPLACE_ME; fill those files before uploading")
    elif args.strict:
        print("no REPLACE_ME placeholders in store metadata")

    if errors:
        print("store metadata check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("store metadata check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
