"""Static audit of every Godot project under a folder (godot-demo-projects) with this checkout's addon.

Copies addons/render_lens, tests/demo_audit.gd and tests/golden/advice_invariants.gd into each project, imports it and
audits every scene headless. Fails on scan errors, advice-order invariant violations, error lines from Render Lens code,
timeouts or missing reports. With --baseline, prints the rules each project gained or lost against an earlier --out.

Usage: python tests/run_demo_audit.py <projects root> --out <dir> [--godot <console exe>] [--baseline <earlier out dir>]
"""
import argparse
import json
import os
import re
import shutil
import statistics
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# Below-normal priority on Windows, so a long sweep never starves the desktop.
PRIORITY = {"creationflags": 0x00004000} if os.name == "nt" else {}


def rules():
    return {rule["id"]: rule for path in (ROOT / "addons" / "render_lens" / "rules").glob("*.json") for rule in json.loads(path.read_text(encoding="utf-8"))}


def audit(godot, project, result_path, log_path):
    target = project / "addons" / "render_lens"
    if target.exists():
        shutil.rmtree(target)
    shutil.copytree(ROOT / "addons" / "render_lens", target)
    shutil.copy(ROOT / "tests" / "demo_audit.gd", project / "render_lens_audit.gd")
    shutil.copy(ROOT / "tests" / "golden" / "advice_invariants.gd", project / "render_lens_invariants.gd")
    with open(log_path, "w", encoding="utf-8", errors="replace") as log:
        for extra in (["--import"], ["--script", "res://render_lens_audit.gd", "--", str(result_path)]):
            subprocess.run([godot, "--headless", "--xr-mode", "off", "--path", str(project)] + extra,
                           stdout=log, stderr=subprocess.STDOUT, timeout=600, **PRIORITY)


def project_rules(report, catalog):
    ids = set()
    for found in report["scenes"].values():
        ids.update(found)
    return {i for i in ids if catalog.get(i, {}).get("kind") in ("performance", "correctness")}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("projects")
    parser.add_argument("--out", required=True)
    parser.add_argument("--godot", default=os.environ.get("GODOT", shutil.which("godot_console") or shutil.which("godot")))
    parser.add_argument("--baseline")
    args = parser.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    catalog = rules()
    projects = sorted(path.parent for path in Path(args.projects).rglob("project.godot") if ".godot" not in path.parts and "addons" not in path.parts)
    problems, reports = [], {}
    for project in projects:
        relative = project.relative_to(args.projects).as_posix()
        name = project.name if relative == "." else relative.replace("/", "__")
        result_path, log_path = out / (name + ".json"), out / (name + ".log")
        started = time.time()
        try:
            audit(args.godot, project, result_path, log_path)
        except subprocess.TimeoutExpired:
            problems.append(f"{name}: timeout")
            continue
        if not result_path.exists():
            problems.append(f"{name}: no report (see {log_path})")
            continue
        report = json.loads(result_path.read_text(encoding="utf-8"))
        reports[name] = report
        problems += [f"{name}: scan error {error}" for error in report["errors"]]
        problems += [f"{name}: {scene}: {line}" for scene, lines in report.get("violations", {}).items() for line in lines]
        # Backtrace frames ("[0] scan_path (res://addons/...)") follow errors raised by the project's own scripts while a
        # scene loads, and verbose projects log every load; only an error or warning located in Render Lens code is ours.
        addon_lines = [line.strip() for line in log_path.read_text(encoding="utf-8", errors="replace").splitlines()
                       if ("res://addons/render_lens/" in line or "res://render_lens_" in line) and re.match(r"\s*(at:|\S*ERROR|\S*WARNING)", line)]
        problems += [f"{name}: {line}" for line in addon_lines]
        print(name, len(report["scenes"]), "scenes", round(time.time() - started, 1), "s", flush=True)
    found = {name: project_rules(report, catalog) for name, report in reports.items()}
    ms = [value for report in reports.values() for value in report["ms"].values()]
    counts = [len(ids) for ids in found.values()]
    print(f"projects {len(reports)}/{len(projects)} scenes {sum(len(r['scenes']) for r in reports.values())} "
          f"median {statistics.median(ms) if ms else 0} ms per scene; performance+correctness rules per project: "
          f"median {statistics.median(counts) if counts else 0}, none in {sum(1 for c in counts if c == 0)}")
    if args.baseline:
        for name, ids in sorted(found.items()):
            earlier_path = Path(args.baseline) / (name + ".json")
            if not earlier_path.exists():
                continue
            earlier = project_rules(json.loads(earlier_path.read_text(encoding="utf-8")), catalog)
            if ids != earlier:
                print(f"CHANGED {name}: +{sorted(ids - earlier)} -{sorted(earlier - ids)}")
    for line in problems:
        print("FAIL", line)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
