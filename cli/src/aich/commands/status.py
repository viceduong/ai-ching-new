"""aich status - Show latest workflow runs."""

from __future__ import annotations

import argparse
from typing import TYPE_CHECKING

from ..config import Config
from ..github import GitHubClient, GitHubError

if TYPE_CHECKING:
    from argparse import Namespace, _SubParsersAction


def register(subparsers: _SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "status",
        help="Show the latest workflow runs and their status",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  aich status              # last 10 runs\n"
            "  aich status --watch      # watch mode (refresh every 15s)\n"
            "  aich status --run 1234   # details for a specific run\n"
        ),
    )
    parser.add_argument("--watch", "-w", action="store_true", help="Watch mode - refresh every 15s")
    parser.add_argument("--run", "-r", type=int, help="Show details for a specific run ID")
    parser.add_argument("--limit", type=int, default=10, help="Number of runs to show (default: 10)")
    parser.set_defaults(func=run)


def run(args: Namespace) -> int:
    cfg = Config()
    gh = GitHubClient(cfg.token)

    if args.run:
        return _show_run_detail(gh, cfg.repo, args.run)

    try:
        runs = gh.list_workflow_runs(cfg.repo, cfg.workflow, per_page=args.limit)
    except GitHubError as e:
        print(f"[!!]  {e}")
        return 1

    if not runs:
        print("No workflow runs found.")
        return 0

    print(f"Latest {len(runs)} runs of  {cfg.workflow}  on  {cfg.repo}\n")
    print(f"  {'Run #':<8} {'Status':<14} {'Conclusion':<12} {'Branch':<16} {'SHA':<10} {'Time'}")
    print(f"  {'-' * 7:<8} {'-' * 13:<14} {'-' * 11:<12} {'-' * 15:<16} {'-' * 9:<10} {'-' * 16}")
    for run in runs:
        conclusion = run.conclusion or "-"
        print(f"  #{run.id:<6} {run.status:<14} {conclusion:<12} {run.branch:<16} {run.head_sha:<10} {run.updated_at[:19]}")

    return 0


def _show_run_detail(gh: GitHubClient, repo: str, run_id: int) -> int:
    try:
        run = gh.get_run(repo, run_id)
    except GitHubError as e:
        print(f"[!!]  {e}")
        return 1

    def p(s: str) -> None:
        try:
            print(s)
        except UnicodeEncodeError:
            print(_safe(s))
    p(f"\nRun #{run.id}  -  {run.name}")
    p(f"{'-' * 40}")
    p(f"  Status:      {run.status}")
    p(f"  Conclusion:  {run.conclusion or '-'}")
    p(f"  Branch:      {run.branch}")
    p(f"  Commit:      {run.head_sha}")
    p(f"  Created:     {run.created_at}")
    p(f"  Updated:     {run.updated_at}")
    p(f"  URL:         {run.html_url}")
    return 0
