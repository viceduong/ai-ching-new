"""Thin GitHub REST API client.

Minimal, no external dependencies - uses urllib from stdlib.
Rate-limit aware, pagination via Link header, JSON only.
"""

from __future__ import annotations

import json
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any
from urllib.parse import urlencode

API_ROOT = "https://api.github.com"


class GitHubError(Exception):
    """Wraps a non-2xx API response."""

    def __init__(self, status: int, body: Any, url: str) -> None:
        self.status = status
        self.body = body
        super().__init__(f"GitHub API {status} for {url}: {body}")


@dataclass
class WorkflowRun:
    """A single workflow run from the API."""
    id: int
    name: str
    branch: str
    status: str
    conclusion: str | None
    html_url: str
    created_at: str
    updated_at: str
    head_sha: str


@dataclass
class Artifact:
    """A build artifact."""
    id: int
    name: str
    size: int
    download_url: str
    created_at: str
    expires_at: str


class GitHubClient:
    """Stateless API client. Every request reads the latest token from Config."""

    def __init__(self, token: str) -> None:
        self._token = token
        self._headers = {
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "User-Agent": "aich-cli/0.1",
        }

    # -- Workflows -----------------------------------------

    def trigger_workflow(
        self, repo: str, workflow: str, branch: str = "main",
        inputs: dict[str, str] | None = None,
    ) -> WorkflowRun:
        """Dispatch a workflow_dispatch event and return the created run."""
        url = f"{API_ROOT}/repos/{repo}/actions/workflows/{workflow}/dispatches"
        body = {"ref": branch}
        if inputs:
            body["inputs"] = inputs
        self._post(url, body)

        # The dispatch endpoint returns 204 - poll for the new run.
        for attempt in range(15):
            time.sleep(1.5)
            runs = self.list_workflow_runs(repo, workflow, branch, per_page=1)
            if runs:
                return runs[0]
        raise GitHubError(0, "Timed out waiting for workflow run to appear", url)

    def list_workflow_runs(
        self, repo: str, workflow: str, branch: str | None = None,
        status: str | None = None, per_page: int = 10,
    ) -> list[WorkflowRun]:
        """Fetch recent workflow runs."""
        url = f"{API_ROOT}/repos/{repo}/actions/workflows/{workflow}/runs"
        params: dict[str, str | int] = {"per_page": per_page}
        if branch:
            params["branch"] = branch
        if status:
            params["status"] = status
        url += "?" + urlencode(params)

        data = self._get(url)
        return [
            WorkflowRun(
                id=r["id"],
                name=r["name"],
                branch=r["head_branch"],
                status=r["status"],
                conclusion=r["conclusion"],
                html_url=r["html_url"],
                created_at=r["created_at"],
                updated_at=r["updated_at"],
                head_sha=r["head_sha"][:8],
            )
            for r in data.get("workflow_runs", [])
        ]

    def get_run(self, repo: str, run_id: int) -> WorkflowRun:
        """Get a single workflow run by ID."""
        url = f"{API_ROOT}/repos/{repo}/actions/runs/{run_id}"
        r = self._get(url)
        return WorkflowRun(
            id=r["id"],
            name=r["name"],
            branch=r["head_branch"],
            status=r["status"],
            conclusion=r["conclusion"],
            html_url=r["html_url"],
            created_at=r["created_at"],
            updated_at=r["updated_at"],
            head_sha=r["head_sha"][:8],
        )

    # -- Logs ----------------------------------------------

    def stream_logs(self, repo: str, run_id: int, tail: int = 0) -> str:
        """Fetch (optionally tail) the full log for a workflow run."""
        url = f"{API_ROOT}/repos/{repo}/actions/runs/{run_id}/logs"
        req = urllib.request.Request(url, headers=self._headers)
        try:
            with urllib.request.urlopen(req) as resp:
                return resp.read().decode("utf-8", errors="replace")
        except urllib.error.HTTPError as e:
            raise GitHubError(e.code, e.read().decode(), url) from e

    # -- Artifacts -----------------------------------------

    def list_artifacts(
        self, repo: str, run_id: int | None = None, per_page: int = 20,
    ) -> list[Artifact]:
        """List artifacts for a run, or latest across the repo."""
        if run_id:
            url = f"{API_ROOT}/repos/{repo}/actions/runs/{run_id}/artifacts"
        else:
            url = f"{API_ROOT}/repos/{repo}/actions/artifacts"
        url += "?" + urlencode({"per_page": per_page})

        data = self._get(url)
        return [
            Artifact(
                id=a["id"],
                name=a["name"],
                size=a["size_in_bytes"],
                download_url=a["archive_download_url"],
                created_at=a["created_at"],
                expires_at=a["expires_at"],
            )
            for a in data.get("artifacts", [])
        ]

    def download_artifact(
        self, repo: str, artifact_id: int, output_dir: str = ".",
    ) -> str:
        """Download a zip artifact to a local directory."""
        url = f"{API_ROOT}/repos/{repo}/actions/artifacts/{artifact_id}/zip"
        req = urllib.request.Request(url, headers=self._headers)
        out_path = f"{output_dir}/artifact_{artifact_id}.zip"

        try:
            with urllib.request.urlopen(req) as resp:
                data = resp.read()
                with open(out_path, "wb") as f:
                    f.write(data)
        except urllib.error.HTTPError as e:
            raise GitHubError(e.code, e.read().decode(), url) from e
        return out_path

    # -- Low-level HTTP ------------------------------------

    def _get(self, url: str) -> dict[str, Any]:
        req = urllib.request.Request(url, headers=self._headers)
        try:
            with urllib.request.urlopen(req) as resp:
                return json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            body = e.read().decode()
            raise GitHubError(e.code, body, url) from e

    def _post(self, url: str, body: dict[str, Any]) -> None:
        data = json.dumps(body).encode()
        req = urllib.request.Request(url, data=data, headers=self._headers, method="POST")
        try:
            urllib.request.urlopen(req)
        except urllib.error.HTTPError as e:
            body = e.read().decode()
            raise GitHubError(e.code, body, url) from e
