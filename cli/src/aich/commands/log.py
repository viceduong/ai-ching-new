"""aich log - Stream or fetch workflow logs."""

from __future__ import annotations

import argparse
import io
import re
import sys
import time
from typing import TYPE_CHECKING

from ..config import Config
from ..github import GitHubClient, GitHubError

if TYPE_CHECKING:
    from argparse import Namespace, _SubParsersAction


def register(subparsers: _SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "log",
        help="Fetch or stream logs from a workflow run",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  aich log                # log from the latest run\n"
            "  aich log --run 1234     # log for a specific run\n"
            "  aich log --tail 50      # last 50 lines from latest run\n"
            "  aich log --watch        # live tail (poll every 10s)\n"
        ),
    )
    parser.add_argument("--run", "-r", type=int, help="Run ID (default: latest)")
    parser.add_argument("--tail", "-t", type=int, default=0,
                        help="Show only the last N lines (0 = all)")
    parser.add_argument("--watch", "-w", action="store_true",
                        help="Live watch mode (poll every 10s)")
    parser.set_defaults(func=run)


def run(args: Namespace) -> int:
    cfg = Config()
    gh = GitHubClient(cfg.token)
    repo = cfg.repo

    if args.run is None:
        runs = gh.list_workflow_runs(repo, cfg.workflow, per_page=1)
        if not runs:
            print("No workflow runs found.")
            return 1
        run_id = runs[0].id
    else:
        run_id = args.run

    if args.watch:
        return _watch_logs(gh, repo, run_id)
    else:
        return _fetch_logs(gh, repo, run_id, args.tail)


def _sanitize(text: str) -> str:
    """Strip characters that Windows console (cp1252) can't display."""
    # Keep common printable ASCII + newlines
    safe = re.sub(r'[^\x20-\x7e\n\r\t]', '', text)
    return safe


def _fetch_logs(gh: GitHubClient, repo: str, run_id: int, tail: int = 0) -> int:
    try:
        text = gh.stream_logs(repo, run_id)
    except GitHubError as e:
        print(f"[!!]  {e}", file=sys.stderr)
        return 1

    text = _sanitize(text)
    lines = text.splitlines()
    if tail > 0 and len(lines) > tail:
        lines = lines[-tail:]

    for line in lines:
        try:
            print(line)
        except UnicodeEncodeError:
            print(line.encode('ascii', errors='replace').decode('ascii'))

    print(f"\n-- {len(lines)} lines --")
    print(f"Run #{run_id}: https://github.com/{repo}/actions/runs/{run_id}")
    return 0


def _watch_logs(gh: GitHubClient, repo: str, run_id: int) -> int:
    """Poll for new log lines every 10s."""
    last_len = 0
    print(f"[wait]  Watching run #{run_id}... (Ctrl+C to stop)\n")

    try:
        while True:
            text = _sanitize(gh.stream_logs(repo, run_id))
            lines = text.splitlines()

            if len(lines) > last_len:
                for line in lines[last_len:]:
                    try:
                        print(line)
                    except UnicodeEncodeError:
                        print(line.encode('ascii', errors='replace').decode('ascii'))
                last_len = len(lines)

            run = gh.get_run(repo, run_id)
            if run.status == "completed":
                print(f"\n[OK]  Run completed: {run.conclusion}")
                break

            time.sleep(10)
    except KeyboardInterrupt:
        print("\n\n[stop]  Stopped watching.")
    except GitHubError as e:
        print(f"[!!]  {e}", file=sys.stderr)
        return 1

    return 0
