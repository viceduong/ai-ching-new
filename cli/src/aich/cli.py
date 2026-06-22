"""AiChing CLI - main entry point and top-level command dispatch."""

from __future__ import annotations

import argparse
import sys
from typing import NoReturn

from . import __version__
from .commands import build, status, log, artifact, test
from .config import Config


def main(argv: list[str] | None = None) -> NoReturn:
    parser = argparse.ArgumentParser(
        prog="aich",
        description="AiChing CLI - trigger iOS builds, check status, download artifacts, run tests.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Configuration:\n"
            "  Config stored in ~/.aich/config.json\n"
            "  GITHUB_TOKEN env var is read automatically.\n"
            "\n"
            "Quick start:\n"
            "  aich config --token ghp_xxx --repo user/ai-ching\n"
            "  aich build\n"
            "  aich status --watch\n"
        ),
    )
    parser.add_argument(
        "--version", action="version",
        version=f"aich {__version__}",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    # Built-in subcommands
    build.register(subparsers)
    status.register(subparsers)
    log.register(subparsers)
    artifact.register(subparsers)
    test.register(subparsers)

    # -- config ---------------------------------------------
    cfg_p = subparsers.add_parser("config", help="View or set configuration")
    cfg_p.add_argument("--token", help="Set GitHub token")
    cfg_p.add_argument("--repo", help="Set repository (user/repo)")
    cfg_p.add_argument("--workflow", help="Set workflow filename")
    cfg_p.add_argument("--show", action="store_true", help="Show current config (default if no flags)")
    cfg_p.set_defaults(func=_config)

    args = parser.parse_args(argv)

    try:
        status_code = args.func(args)
    except Exception as e:
        print(f"[!!]  {e}", file=sys.stderr)
        if args.command and args.command != "config":
            print("   Run:  aich config --token ghp_xxx --repo user/repo", file=sys.stderr)
        sys.exit(1)

    sys.exit(status_code if isinstance(status_code, int) else 0)


def _config(args: argparse.Namespace) -> int:
    cfg = Config()

    changed = False
    if args.token:
        cfg.token = args.token
        print("[ok]  Token saved")
        changed = True
    if args.repo:
        cfg.repo = args.repo
        print("[ok]  Repository saved")
        changed = True
    if args.workflow:
        cfg.workflow = args.workflow
        print("[ok]  Workflow saved")
        changed = True

    if changed:
        print()
    print(cfg.show())
    return 0


if __name__ == "__main__":
    main()
