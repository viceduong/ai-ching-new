"""Configuration management for aich CLI.

Stores GitHub token and repo preferences in ~/.aich/config.json.
Uses 0600 permissions on the file for basic security.
"""

from __future__ import annotations

import json
import os
import stat
from pathlib import Path

DEFAULT_CONFIG_DIR = Path.home() / ".aich"
DEFAULT_CONFIG_PATH = DEFAULT_CONFIG_DIR / "config.json"
DEFAULT_REPO = os.environ.get("AICH_REPO", "")
DEFAULT_TOKEN = os.environ.get("GITHUB_TOKEN", os.environ.get("GH_TOKEN", ""))


class Config:
    """Load, save, and query persistent configuration."""

    def __init__(self, path: Path = DEFAULT_CONFIG_PATH) -> None:
        self._path = path
        self._data: dict[str, str] = {}
        self._load()

    # -- Token ----------------------------------------------

    @property
    def token(self) -> str:
        t = self._data.get("token") or DEFAULT_TOKEN
        if not t:
            raise ConfigError(
                "No GitHub token found.\n"
                "  Set GITHUB_TOKEN env var, or run:  aich config --token ghp_xxx"
            )
        return t

    @token.setter
    def token(self, value: str) -> None:
        self._data["token"] = value
        self._save()

    # -- Repository -----------------------------------------

    @property
    def repo(self) -> str:
        return self._data.get("repo") or DEFAULT_REPO or self._guess_repo()

    @repo.setter
    def repo(self, value: str) -> None:
        self._data["repo"] = value
        self._save()

    @staticmethod
    def _guess_repo() -> str:
        """Parse 'origin' remote from the current git repo."""
        try:
            import subprocess
            out = subprocess.run(
                ["git", "remote", "get-url", "origin"],
                capture_output=True, text=True, timeout=5,
            )
            url = out.stdout.strip()
            # Handle ssh:  git@github.com:user/repo.git
            # Handle https: https://github.com/user/repo.git
            for prefix in ("git@github.com:", "https://github.com/"):
                if url.startswith(prefix):
                    repo = url.removeprefix(prefix)
                    return repo.removesuffix(".git")
        except Exception:
            pass
        return ""

    # -- Workflow -------------------------------------------

    @property
    def workflow(self) -> str:
        return self._data.get("workflow", "ios-build.yml")

    @workflow.setter
    def workflow(self, value: str) -> None:
        self._data["workflow"] = value
        self._save()

    # -- Persistence ----------------------------------------

    def _load(self) -> None:
        if self._path.exists():
            try:
                self._data = json.loads(self._path.read_text())
            except (json.JSONDecodeError, OSError):
                self._data = {}

    def _save(self) -> None:
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._path.write_text(json.dumps(self._data, indent=2))
        # Restrict permissions on Unix
        try:
            self._path.chmod(stat.S_IRUSR | stat.S_IWUSR)
        except Exception:
            pass

    def show(self) -> str:
        ok = self._data.get('token') or DEFAULT_TOKEN
        lines = [
            "Configuration:",
            f"  Token:       {'[ok]' if ok else '[!!]'}",
            f"  Repository:  {self.repo or '[!!] not set'}",
            f"  Workflow:    {self.workflow}",
        ]
        return "\n".join(lines)


class ConfigError(Exception):
    """Raised when required config is missing."""
    pass
