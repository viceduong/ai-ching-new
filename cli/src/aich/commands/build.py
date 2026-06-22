"""aich build - Trigger a workflow dispatch."""

from __future__ import annotations

import argparse
import sys
import time
from typing import TYPE_CHECKING

from ..config import Config
from ..github import GitHubClient, GitHubError

if TYPE_CHECKING:
    from argparse import Namespace, _SubParsersAction


def register(subparsers: _SubParsersAction) -> None:
    parser = subparsers.add_parser(
        "build",
        help="Trigger the iOS build workflow on GitHub Actions",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  aich build                  # trigger default workflow on main\n"
            "  aich build --branch dev     # trigger on a different branch\n"
            "  aich build --wait           # trigger and wait for completion\n"
            "  aich build --input mode=release  # pass custom inputs\n"
        ),
    )
    parser.add_argument("--branch", default="main", help="Target branch (default: main)")
    parser.add_argument("--wait", "-w", action="store_true", help="Wait for the build to finish")
    parser.add_argument("--input", "-i", action="append", dest="inputs",
                        help="Workflow input in KEY=VALUE format (repeatable)")
    parser.add_argument("--workflow", help=f"Workflow filename (default: from config)")
    parser.set_defaults(func=run)


def run(args: Namespace) -> int:
    cfg = Config()
    gh = GitHubClient(cfg.token)
    repo = cfg.repo
    workflow = args.workflow or cfg.workflow

    inputs: dict[str, str] = {}
    if args.inputs:
        for item in args.inputs:
            if "=" not in item:
                print(f"[!!]  Invalid input format: {item!r} - expected KEY=VALUE", file=sys.stderr)
                return 1
            k, v = item.split("=", 1)
            inputs[k.strip()] = v.strip()

    print(f"[go] Triggering  {workflow}  on  {repo}:{args.branch}")
    if inputs:
        for k, v in inputs.items():
            print(f"   input  {k}={v}")

    try:
        run = gh.trigger_workflow(repo, workflow, branch=args.branch, inputs=inputs or None)
    except GitHubError as e:
        print(f"[!!]  {e}", file=sys.stderr)
        return 1

    print(f"[OK]  Run #{run.id} created - {run.html_url}")
    print(f"   Status: {run.status}")

    if args.wait:
        return _poll_until_done(gh, repo, run.id)
    return 0


def _poll_until_done(gh: GitHubClient, repo: str, run_id: int) -> int:
    """Poll every 10s until the run completes."""
    done_states = {"completed", "skipped", "cancelled", "failure"}
    spinner = ["-", "\\", "|", "/"]
    idx = 0

    print(f"\n[wait]  Waiting for run #{run_id} to finish...")
    try:
        while True:
            run = gh.get_run(repo, run_id)
            status = run.status or "queued"
            conclusion = run.conclusion or ""

            if run.status == "completed":
                symbol = "[OK]" if conclusion == "success" else "[!!]"
                print(f"\n{symbol}  Run #{run_id} {conclusion}")
                return 0 if conclusion == "success" else 1

            print(f"\r   {spinner[idx % len(spinner)]}  {status}  *  {conclusion if conclusion else 'running'}", end="")
            idx = (idx + 1) % len(spinner)
            time.sleep(10)
    except KeyboardInterrupt:
        print("\n\n[stop]  Interrupted. Run is still running:", run.html_url)
        return 130
