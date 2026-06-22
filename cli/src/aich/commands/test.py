"""aich test - Run AiChingCore tests locally."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from argparse import Namespace, _SubParsersAction


def register(subparsers: _SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "test",
        help="Run AiChingCore tests locally with swift test",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  aich test                    # run all tests\n"
            "  aich test --filter Hashing   # run tests matching 'Hashing'\n"
            "  aich test --list             # just list test cases\n"
            "  aich test --build-only       # build without running tests\n"
        ),
    )
    parser.add_argument("--filter", help="Run only tests matching the given substring")
    parser.add_argument("--list", action="store_true", dest="list_only",
                        help="List available test methods without running them")
    parser.add_argument("--build-only", action="store_true",
                        help="Build the package without running tests")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.set_defaults(func=run)


def run(args: Namespace) -> int:
    project_root = _find_project_root()
    if not project_root:
        print("[!!]  Could not find AiChingCore package. Are you inside the ai-ching project?",
              file=sys.stderr)
        return 1

    core_path = project_root / "ios" / "AiChingCore"
    if not core_path.exists():
        print(f"[!!]  AiChingCore not found at {core_path}", file=sys.stderr)
        return 1

    cmd = ["swift"]
    if args.build_only:
        cmd += ["build"]
    else:
        cmd += ["test"]

    cmd += ["--package-path", str(core_path)]

    if args.filter:
        cmd += ["--filter", args.filter]
    if args.list_only:
        cmd += ["--list-tests"]
    if args.verbose:
        cmd += ["--verbose"]

    print(f"[test]  {'Building' if args.build_only else 'Testing'} AiChingCore...")
    print(f"    {' '.join(cmd)}\n")

    try:
        result = subprocess.run(cmd, cwd=str(core_path))
    except FileNotFoundError:
        print("[!!]  swift command not found. Install Swift from https://swift.org/download/",
              file=sys.stderr)
        return 1

    if result.returncode != 0:
        print(f"\n[!!]  {'Build' if args.build_only else 'Tests'} failed.")
        return result.returncode

    print(f"\n[OK]  {'Build' if args.build_only else 'All tests'} passed.")
    return 0


def _find_project_root() -> Path | None:
    """Walk up from CWD looking for the ios/AiChingCore directory."""
    cwd = Path.cwd()
    for parent in [cwd] + list(cwd.parents):
        if (parent / "ios" / "AiChingCore").exists():
            return parent
    return None
