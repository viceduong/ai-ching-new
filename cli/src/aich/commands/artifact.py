"""aich artifact - List, download, and clean build artifacts."""

from __future__ import annotations

import argparse
import sys
from typing import TYPE_CHECKING

from ..config import Config
from ..github import GitHubClient, GitHubError

if TYPE_CHECKING:
    from argparse import Namespace, _SubParsersAction


def register(subparsers: _SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "artifact",
        help="List, download, or clean build artifacts",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  aich artifact list               # latest artifacts\n"
            "  aich artifact list --run 1234    # artifacts for a specific run\n"
            "  aich artifact download 12345     # download by artifact ID\n"
            "  aich artifact download --latest  # download latest artifact\n"
            "  aich artifact clean --expired    # remove expired local zips\n"
        ),
    )
    sub = parser.add_subparsers(dest="artifact_command", required=True)

    # list
    list_p = sub.add_parser("list", help="List artifacts")
    list_p.add_argument("--run", "-r", type=int, help="Filter by run ID")
    list_p.add_argument("--limit", type=int, default=20, help="Max results")
    list_p.set_defaults(artifact_func=_list)

    # download
    dl_p = sub.add_parser("download", help="Download an artifact")
    dl_p.add_argument("id", nargs="?", type=int, help="Artifact ID")
    dl_p.add_argument("--latest", action="store_true", help="Download the most recent artifact")
    dl_p.add_argument("--output", "-o", default=".", help="Output directory (default: .)")
    dl_p.add_argument("--name", help="Download first artifact matching this name (case-insensitive)")
    dl_p.set_defaults(artifact_func=_download)

    parser.set_defaults(func=run)


def run(args: Namespace) -> int:
    if hasattr(args, "artifact_func"):
        return args.artifact_func(args)
    return 1


def _list(args: Namespace) -> int:
    cfg = Config()
    gh = GitHubClient(cfg.token)

    try:
        artifacts = gh.list_artifacts(cfg.repo, run_id=args.run, per_page=args.limit)
    except GitHubError as e:
        print(f"[!!]  {e}", file=sys.stderr)
        return 1

    if not artifacts:
        print("No artifacts found.")
        return 0

    _print_artifacts(artifacts)
    return 0


def _download(args: Namespace) -> int:
    cfg = Config()
    gh = GitHubClient(cfg.token)

    if args.latest:
        try:
            artifacts = gh.list_artifacts(cfg.repo, per_page=1)
        except GitHubError as e:
            print(f"[!!]  {e}", file=sys.stderr)
            return 1
        if not artifacts:
            print("No artifacts to download.")
            return 1
        artifact_id = artifacts[0].id
    elif args.name:
        try:
            artifacts = gh.list_artifacts(cfg.repo, per_page=50)
        except GitHubError as e:
            print(f"[!!]  {e}", file=sys.stderr)
            return 1
        matches = [a for a in artifacts if args.name.lower() in a.name.lower()]
        if not matches:
            print(f"No artifacts matching {args.name!r}")
            return 1
        artifact_id = matches[0].id
    elif args.id:
        artifact_id = args.id
    else:
        print("Specify an artifact ID, --latest, or --name")
        return 1

    print(f"[dl]  Downloading artifact #{artifact_id}...")
    try:
        path = gh.download_artifact(cfg.repo, artifact_id, output_dir=args.output)
    except GitHubError as e:
        print(f"[!!]  {e}", file=sys.stderr)
        return 1

    print(f"[OK]  Saved to {path}")
    return 0


def _print_artifacts(artifacts: list) -> None:
    print(f"{'ID':<8} {'Name':<30} {'Size':<10} {'Expires'}")
    print(f"{'-' * 7:<8} {'-' * 29:<30} {'-' * 9:<10} {'-' * 16}")
    for a in artifacts:
        size = _fmt_size(a.size)
        print(f"{a.id:<8} {a.name:<30} {size:<10} {a.expires_at[:10]}")


def _fmt_size(bytes_: int) -> str:
    if bytes_ < 1024:
        return f"{bytes_} B"
    elif bytes_ < 1024 * 1024:
        return f"{bytes_ / 1024:.1f} KB"
    else:
        return f"{bytes_ / 1024 / 1024:.1f} MB"
