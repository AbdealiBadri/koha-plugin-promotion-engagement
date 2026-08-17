#!/usr/bin/env python3
"""Build a Koha Plugin Zip (KPZ) from tracked files under Koha/.

The resulting archive has Koha/ at the archive root, as required by Koha's
plugin uploader. Only git-tracked files are packaged so local/editor files are
never accidentally shipped.
"""

from __future__ import annotations

import hashlib
import pathlib
import re
import subprocess
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
PLUGIN_PM = ROOT / "Koha/Plugin/Com/AJSN/PromotionEngagement.pm"
DIST = ROOT / "dist"


def run(*args: str) -> str:
    return subprocess.check_output(args, cwd=ROOT, text=True).strip()


def version() -> str:
    text = PLUGIN_PM.read_text(encoding="utf-8")
    match = re.search(r"our\s+\$VERSION\s*=\s*['\"]([^'\"]+)['\"]\s*;", text)
    if not match:
        raise SystemExit("Could not read $VERSION from PromotionEngagement.pm")
    return match.group(1)


def tracked_plugin_files() -> list[pathlib.Path]:
    output = run("git", "ls-files", "Koha")
    files = [ROOT / line for line in output.splitlines() if line]
    if not files:
        raise SystemExit("No tracked files found under Koha/")
    missing = [path for path in files if not path.is_file()]
    if missing:
        raise SystemExit(f"Tracked plugin files missing from working tree: {missing}")
    return files


def validate(files: list[pathlib.Path]) -> None:
    relative = {path.relative_to(ROOT).as_posix() for path in files}
    required = {
        "Koha/Plugin/Com/AJSN/PromotionEngagement.pm",
        "Koha/Plugin/Com/AJSN/PromotionEngagement/openapi.json",
        "Koha/Plugin/Com/AJSN/PromotionEngagement/API/Health.pm",
        "Koha/Plugin/Com/AJSN/PromotionEngagement/dashboard.tt",
        "Koha/Plugin/Com/AJSN/PromotionEngagement/configure.tt",
        "Koha/Plugin/Com/AJSN/PromotionEngagement/new_promotion.tt",
    }
    missing = sorted(required - relative)
    if missing:
        raise SystemExit("Cannot build KPZ; required files are missing:\n  " + "\n  ".join(missing))


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> int:
    ver = version()
    files = tracked_plugin_files()
    validate(files)

    DIST.mkdir(exist_ok=True)
    kpz = DIST / f"PromotionEngagement-v{ver}.kpz"
    checksum_file = DIST / f"PromotionEngagement-v{ver}.kpz.sha256"

    if kpz.exists():
        kpz.unlink()

    with zipfile.ZipFile(kpz, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(files, key=lambda p: p.relative_to(ROOT).as_posix()):
            archive.write(path, arcname=path.relative_to(ROOT).as_posix())

    checksum = sha256(kpz)
    checksum_file.write_text(f"{checksum}  {kpz.name}\n", encoding="utf-8")

    print(f"Built: {kpz.relative_to(ROOT)}")
    print(f"SHA256: {checksum}")
    print(f"Files: {len(files)}")
    print("Archive root: Koha/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
