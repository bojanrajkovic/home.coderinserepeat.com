#!/usr/bin/env python3
import os
import subprocess
import json
import requests
from typing import Tuple, Optional, List, Dict
from enum import Enum

# Set environment variables
os.environ["AWS_SECRET_ACCESS_KEY"] = "${secret_key}"
os.environ["AWS_ACCESS_KEY_ID"] = "${access_key}"
os.environ["AWS_REGION"] = "us-east-1"
os.environ["RESTIC_PASSWORD"] = "${restic_password}"
os.environ["XDG_CACHE_HOME"] = "/etc/sanoid/"

class Task(Enum):
    NONE = 0
    INDEX_SNAPSHOTS = 1
    PRUNE = 2
    CHECK = 3
    STATS = 4
    UNLOCK = 5

# Constants
BUKKIT: str = "bojans-backups"
BACKREST_URL: str = "https://backrest.services.coderinserepeat.com"
PVC_DATA: Dict[str,Dict[str, str]] = json.loads('${jsonencode(pvc_to_target_map)}')

def send_post_request(url: str, data, timeout: int = 10) -> Tuple[str, int]:
    """Send a POST request and return the response text and status code (0 for success)."""
    try:
        # Convert data to JSON if required
        headers = { "Content-Type": "text/plain" if isinstance(data, str) else "application/json" }
        data = data if isinstance(data, str) else json.dumps(data)
        print(f"Posting to {url} with data: {data}, headers: {headers}")
        response = requests.post(url, data=data, timeout=timeout, headers=headers)
        return response.text, 0 if response.status_code == 200 else response.status_code
    except Exception as e:
        print(f"Error posting to {url}: {e}")
        return str(e), -1

def trigger_backrest_task(repo_id: str, task: Task) -> Tuple[str, int]:
    """Trigger backrest task.

    Task values:
        0: TASK_NONE
        1: TASK_INDEX_SNAPSHOTS
        2: TASK_PRUNE
        3: TASK_CHECK
        4: TASK_STATS
        5: TASK_UNLOCK
    """
    return send_post_request(
        url=f"{BACKREST_URL}/v1.Backrest/DoRepoTask",
        data={"task": task, "repo_id": repo_id}
    )

def run_command(cmd: List[str], cwd: Optional[str] = None) -> Tuple[str, int]:
    """Run a command and return output and return code."""
    result: Optional[subprocess.CompletedProcess] = None
    try:
        result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, check=False)
        return result.stdout, result.returncode
    except Exception as e:
        print(f"Error running command {cmd}: {e}")
        return str(e), (-1 if result is None else result.returncode)

def main() -> None:
    # Get datasets and snapshots from environment variables
    datasets: List[str] = os.environ.get("SANOID_TARGETS", "").split(",")
    snaps: List[str] = os.environ.get("SANOID_SNAPNAMES", "").split(",")
    tempdir: str = os.environ.get("TMPDIR", "/tmp")

    for dataset in datasets:
        if dataset == "tank/docker/kubernetes":
            continue

        for snapshot in snaps:
            ds_with_snapshot: str = f"{dataset}@{snapshot}"
            ds_basename: str = os.path.basename(dataset)

            if ds_basename not in PVC_DATA:
                print(f"Warning: {ds_basename} not found in mapping")
                continue

            target: Optional[str] = PVC_DATA.get(ds_basename, {}).get('target')
            hc_url: Optional[str] = PVC_DATA.get(ds_basename, {}).get('hc_id')

            if not target or not hc_url:
                print(f"Warning: {ds_basename} not found in PVC data")
                continue

            repo: str = f"s3:s3.amazonaws.com/{BUKKIT}/{target}"
            mountdir: str = f"{tempdir}/{target}"

            # Run sanoid check
            sanoid_output, sanoid_code = run_command(["sanoid", "--monitor-snapshots"])
            send_post_request(f"{hc_url}/{sanoid_code}", f"Finished snapshot {snapshot} of {dataset}:\n\n{sanoid_output}")

            # Create mount directory
            os.makedirs(mountdir, exist_ok=True)

            # Release and hold ZFS snapshot
            run_command(["zfs", "release", "restic", ds_with_snapshot])
            run_command(["zfs", "hold", "restic", ds_with_snapshot])

            # Mount ZFS snapshot
            run_command(["mount", "-t", "zfs", ds_with_snapshot, mountdir])

            # Start upload notification
            send_post_request(f"{hc_url}/start", f"Starting upload of snapshot {ds_with_snapshot} to {repo}")

            # Initialize restic repository if needed
            _, return_code = run_command(["restic", "-r", repo, "cat", "config"])
            if return_code != 0:
                run_command(["restic", "-r", repo, "init"])

            # Backup with restic
            restic_output, restic_return = run_command(
                ["restic", "-r", repo, "--compression", "max", "backup", "."],
                cwd=mountdir
            )

            # Post backup completion
            send_post_request(
                f"{hc_url}/{restic_return}",
                f"Finished upload of snapshot {ds_with_snapshot} to {repo}:\n\n{restic_output}"
            )

            # Start pruning notification
            send_post_request(f"{hc_url}/start", f"Starting pruning of snapshot {ds_with_snapshot} to {repo}")

            # Prune old snapshots
            prune_output, prune_return = run_command([
                "restic", "-r", repo, "forget",
                "--keep-hourly", "48",
                "--keep-daily", "7",
                "--keep-weekly", "8",
                "--keep-monthly", "6",
                "--keep-yearly", "1",
                "--prune"
            ])

            # Post pruning completion
            send_post_request(
                f"{hc_url}/{prune_return}",
                f"Finished pruning of restic repo {repo}:\n\n{prune_output}"
            )

            # Start backrest indexing
            send_post_request(f"{hc_url}/start", f"Asking Backrest to index {repo} snapshots")

            # Trigger backrest indexing
            backrest_output, backrest_return = trigger_backrest_task(target, Task.INDEX_SNAPSHOTS)

            # Post backrest indexing completion
            send_post_request(
                f"{hc_url}/{backrest_return}",
                f"Backrest finished indexing {repo} snapshots:\n\n{backrest_output}"
            )

            # Start backrest stats
            send_post_request(f"{hc_url}/start", f"Asking Backrest to update stats for {repo}")

            # Trigger backrest indexing
            backrest_output, backrest_return = trigger_backrest_task(target, Task.STATS)

            # Post backrest indexing completion
            send_post_request(
                f"{hc_url}/{backrest_return}",
                f"Backrest finished updating stats for {repo}:\n\n{backrest_output}"
            )

            # Unmount and cleanup
            run_command(["umount", mountdir])

            try:
                os.rmdir(mountdir)
            except Exception as e:
                print(f"Error removing mount dir {mountdir}: {e}")

            run_command(["zfs", "release", "restic", ds_with_snapshot])

    # Unset environment variables
    for var in ["AWS_SECRET_ACCESS_KEY", "AWS_ACCESS_KEY_ID", "AWS_REGION"]:
        if var in os.environ:
            del os.environ[var]

if __name__ == "__main__":
    main()
