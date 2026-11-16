"""Restore the demo project into a local CVAT and score it. Used by restore.sh and quality_report.sh."""
import json, os, subprocess, sys, time
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parent.parent
URL = os.environ["CVAT_URL"].rstrip("/")
AUTH = (os.environ["DEMO_USER"], os.environ["DEMO_PASS"])
PROJECT_NAME = "NiSource | Vegetation Management"
TASK_NAME = "NiSource | Vegetation Management | live task"          # the main task: photos, model first pass, answer key
RUN_TASK_NAME = "NiSource | Vegetation Management | run the model"  # optional empty task for scripts/auto_annotate.sh
LIVE_JOB_KEY, LIVE_JOB_INDEX, MODEL_JOB_INDEX = "", 0, 1
S = requests.Session()
S.auth = AUTH


def api(method, path, ok=(200, 201, 202, 204), **kw):
    r = S.request(method, f"{URL}/api/{path}", timeout=300, **kw)
    if r.status_code not in ok:
        raise SystemExit(f"{method} {path} failed ({r.status_code}): {r.text[:400]}")
    return r.json() if r.content else None


def everything(path, **params):
    out, page = [], 1
    while True:
        d = api("GET", path, params={**params, "page": page, "page_size": 100})
        out += d["results"]
        if not d.get("next"):
            return out
        page += 1


def find():
    projects = [p for p in everything("projects") if p["name"] == PROJECT_NAME]
    if not projects:
        return None, None, []
    project = projects[-1]
    tasks = everything("tasks", project_id=project["id"])
    named = [t for t in tasks if t["name"] == TASK_NAME]
    task = named[0] if named else sorted(tasks, key=lambda t: t["id"])[0]
    return project, task, everything("jobs", task_id=task["id"])


def run_task(project):
    if not RUN_TASK_NAME:
        return None
    tasks = [t for t in everything("tasks", project_id=project["id"]) if t["name"] == RUN_TASK_NAME]
    return tasks[0] if tasks else None


def wait(rq_id):
    for _ in range(600):
        r = api("GET", f"requests/{rq_id}")
        if r["status"] == "finished":
            return r
        if r["status"] == "failed":
            raise SystemExit(f"CVAT reported a failure: {r.get('message')}")
        time.sleep(2)
    raise SystemExit("Timed out waiting for CVAT.")


def restore():
    project, task, jobs = find()
    if project:
        print(f"Project already restored (#{project['id']}).")
    else:
        cli = [str(ROOT / ".venv" / "bin" / "cvat-cli"), "--server-host", URL, "--auth", AUTH[0],
               "project", "create-from-backup", str(ROOT / "demo" / "backup.zip")]
        subprocess.run(cli, check=True, env={**os.environ, "PASS": AUTH[1]})
        project, task, jobs = find()
        if not project:
            raise SystemExit("The backup was imported but the project was not found.")

    # The answer key only counts once its job is marked finished.
    gt = [j for j in jobs if j["type"] == "ground_truth"]
    if not gt:
        raise SystemExit("The restored task has no ground truth job.")
    if (gt[0]["stage"], gt[0]["state"]) != ("acceptance", "completed"):
        api("PATCH", f"jobs/{gt[0]['id']}", json={"stage": "acceptance", "state": "completed"})

    # Backups do not carry quality rules, so apply them again.
    rules = json.loads((ROOT / "demo" / "quality.json").read_text())
    objs = [o for o in everything("quality/settings", task_id=task["id"]) if o.get("task_id") == task["id"]]
    qs = objs[0]
    reqs = qs["requirements"]
    base = {r["annotation_type"]: r for r in reqs if r["is_base"]}
    used = {r["annotation_type"] for r in rules["requirements"]}
    keep = []
    for r in reqs:
        if r["is_base"]:
            r["enabled"] = r["annotation_type"] in used
            keep.append(r)
    for rule in rules["requirements"]:
        if rule["is_base"]:
            base[rule["annotation_type"]].update(name=rule["name"], metric=rule["metric"], required_score=rule["required_score"], enabled=True)
        else:
            old = [r for r in reqs if not r["is_base"] and r["name"] == rule["name"]]
            child = old[0] if old else {}
            child.update(name=rule["name"], metric=rule["metric"], required_score=rule["required_score"], enabled=True,
                         filter=rule["filter"], parent_requirement=base[rule["annotation_type"]]["id"], is_base=False)
            keep.append(child)
    drop = {"settings_id", "task_id", "project_id", "created_date", "updated_date"}
    api("PATCH", f"quality/settings/{qs['id']}", json={
        "inherit": False, "max_validations_per_job": rules["max_validations_per_job"],
        "requirements": [{k: v for k, v in r.items() if k not in drop} for r in keep]})

    ann = sorted((j for j in jobs if j["type"] == "annotation"), key=lambda j: j["start_frame"])
    t = task["id"]
    rt = run_task(project)
    ids = [f"project_id={project['id']}", f"task_id={t}"] + ([f"run_task_id={rt['id']}"] if rt else [])
    lines = [f"project={URL}/projects/{project['id']}", f"task={URL}/tasks/{t}"]
    if LIVE_JOB_KEY and LIVE_JOB_INDEX != MODEL_JOB_INDEX:
        lines.append(f"{LIVE_JOB_KEY}={URL}/tasks/{t}/jobs/{ann[LIVE_JOB_INDEX]['id']}")
    lines += [f"model_job={URL}/tasks/{t}/jobs/{ann[MODEL_JOB_INDEX]['id']}",
              f"answer_key={URL}/tasks/{t}/jobs/{gt[0]['id']}"]
    if rt:
        lines.append(f"run_task={URL}/tasks/{rt['id']}")
    (ROOT / "demo" / "local-urls.txt").write_text("\n".join(ids + lines) + "\n")
    print("\nRestored. Open these in your browser:")
    for line in lines:
        print("  " + line.replace("=", ": ", 1))
    print("\nNext: bash scripts/quality_report.sh")


def report():
    project, task, jobs = find()
    if not project:
        raise SystemExit("Run: bash scripts/restore.sh first.")
    r = api("POST", "quality/reports", json={"task_id": task["id"]})
    wait(r["rq_id"])
    names = {j["id"]: f"job {j['id']} (frames {j['start_frame']} to {j['stop_frame']})" for j in jobs}
    reports = api("GET", "quality/reports", params={"task_id": task["id"], "target": "job", "page_size": 100})["results"]
    latest = {}
    for rep in sorted(reports, key=lambda x: x["created_date"]):
        latest[rep["job_id"]] = rep
    print(f"\nScores against the answer key ({task['name']}):\n")
    whole = api("GET", "quality/reports", params={"task_id": task["id"], "target": "task", "page_size": 100})["results"]
    if whole:
        latest = {"task": max(whole, key=lambda x: x["created_date"]), **dict(sorted(latest.items()))}
        names = {**names, "task": "whole task (all jobs)"}
    else:
        latest = dict(sorted(latest.items()))
    for jid, rep in latest.items():
        print(names.get(jid, f"job {jid}"))
        for item in rep["summary"]["requirements"]["items"]:
            score = item.get("score")
            shown = "not applicable" if score is None else f"{score * 100:5.1f}%"
            mark = "" if score is None else ("  pass" if score >= item["threshold"] else "  below the bar")
            print(f"    {item['name']:<40} {shown}  (needs {item['threshold'] * 100:.0f}%){mark}")
    print("\nThese scores come from CVAT's quality report. The score screens in the browser are a CVAT Online feature.")


if __name__ == "__main__":
    {"restore": restore, "report": report}[sys.argv[1]]()
