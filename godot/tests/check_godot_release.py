"""Check Render Lens against a new Godot release: what in the rule catalog no longer matches its sources, then the suites.

1. Every project setting a rule reads must still be documented in the release's ProjectSettings.xml.
2. Every rule node_property must still be a member of its class (or a parent) in the release's class reference.
3. Every rule pass name must still be a RENDER_TIMESTAMP label of the release, on some renderer; new labels since the
   newest verified release (scripts/godot_versions.py) are listed for review.
4. The regression suites run with the release's Godot (--integration, plus --graphics when asked).
5. With --demos, the demo audit runs with it too (--baseline compares with an earlier run).

--download TAG fetches the Windows editor and the source tarball from github.com/godotengine/godot-builds into .tmp
(about 100 MB) and only extracts the folders these checks read.

Usage: python tests/check_godot_release.py --source <godot source dir> --godot <console exe> [--graphics] [--demos <dir> --out <dir> [--baseline <dir>]]
       python tests/check_godot_release.py --download 4.8-beta1
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tarfile
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
from build_rules import has_member, node_property_members, walk_paths  # noqa: E402
from godot_versions import CHECKOUTS, SERIES  # noqa: E402
from run_regressions import MOBILE_NO_TIMESTAMP, _pass_name_matches, condition_names, renderer_labels  # noqa: E402
import xml.etree.ElementTree as ET  # noqa: E402

RELEASES = "https://github.com/godotengine/godot-builds/releases/download"
SOURCE_DIRS = ("doc/classes", "modules", "servers/rendering")


def download(tag):
    target = ROOT / ".tmp" / f"godot-{tag}"
    target.mkdir(parents=True, exist_ok=True)
    for name in (f"Godot_v{tag}_win64.exe.zip", f"godot-{tag}.tar.xz"):
        archive = target / name
        if not archive.exists():
            print("downloading", f"{RELEASES}/{tag}/{name}", flush=True)
            urllib.request.urlretrieve(f"{RELEASES}/{tag}/{name}", archive)
    with zipfile.ZipFile(target / f"Godot_v{tag}_win64.exe.zip") as editor:
        editor.extractall(target)
    source = ROOT / ".tmp" / "upstream" / f"godot-{tag}"
    extract_sources(target / f"godot-{tag}.tar.xz", source)
    print("source:", source, "\ngodot:", next(target.glob("*_console.exe"), "(no console exe in the zip)"))


def extract_sources(archive, source):
    """The folders these checks read, from a Godot source tarball, without its top folder."""
    source = Path(source).resolve()
    with tarfile.open(archive) as tarball:
        members = [m for m in tarball.getmembers() if m.isfile() and any(f"/{d}/" in m.name for d in SOURCE_DIRS)]
        for member in members:
            # Strip the archive's top folder. Only plain names: no drive (D:x), no backslash, no "..", and the result
            # must stay inside the target.
            parts = member.name.split("/")[1:]
            if any(not part or part == ".." or ":" in part or "\\" in part for part in parts):
                continue
            destination = source.joinpath(*parts).resolve()
            if not destination.is_relative_to(source):
                continue
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(tarball.extractfile(member).read())


def catalog_problems(source):
    source = Path(source)
    rules = [rule for path in (ROOT / "addons/render_lens/rules").glob("*.json") for rule in json.loads(path.read_text(encoding="utf-8"))
             if SERIES[-1] in rule["applies_to"]["versions"]]
    settings = {m.get("name") for m in ET.parse(source / "doc/classes/ProjectSettings.xml").getroot().iter("member")}
    classes = {}
    for path in list((source / "doc/classes").glob("*.xml")) + list((source / "modules").glob("*/doc_classes/*.xml")):
        root = ET.parse(path).getroot()
        classes[root.get("name")] = (root.get("inherits"), {item.get("name") for tag in ("member", "method") for item in root.iter(tag)})
    problems = []
    for rule in rules:
        paths = set()
        walk_paths(rule["condition"], paths)
        if rule.get("setting"):
            paths.add(rule["setting"])
        problems += [f"{rule['id']}: setting {path} is gone" for path in sorted(paths) if "/" in path and path not in settings]
        for owner, member in node_property_members(rule.get("node_property")):
            if not has_member(classes, owner, member):
                problems.append(f"{rule['id']}: node property {owner}.{member} is gone")
    live = {r: renderer_labels("release:" + str(source), r, source) for r in ("forward_plus", "mobile")}
    newest = CHECKOUTS[SERIES[-1]].removeprefix("godot-").removesuffix("-stable")
    if not renderer_labels(newest, "forward_plus"):
        raise SystemExit(f"Renamed or removed pass names are found against {CHECKOUTS[SERIES[-1]]}, which is not in .tmp/upstream; "
                         "check it out there (scripts/godot_versions.py) before checking a new release.")
    # Every name that matches a label of the newest verified version on a renderer the rule applies to must still match
    # one in the release: losing any of them (fog's three passes) loses part of the measurement.
    for rule in rules:
        names = condition_names(rule["condition"], set()) | set(rule.get("when_pass") or [])
        for renderer in live:
            if renderer not in rule["applies_to"]["renderers"] or (renderer == "mobile" and rule["id"] in MOBILE_NO_TIMESTAMP):
                continue
            for name in sorted(names):
                # Every label the name matched in the newest verified version must still exist: a substring name can
                # match two labels on different paths (with and without GI), and losing one breaks that path.
                matched = {label for label in renderer_labels(newest, renderer) if _pass_name_matches(name, label, renderer)}
                for label in sorted(matched - live[renderer]):
                    problems.append(f"{rule['id']}: pass name {name!r} matched the {renderer} label {label!r}, which is gone")
    new_labels = {r: sorted(live[r] - renderer_labels(newest, r)) for r in live}
    return sorted(set(problems)), new_labels


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--download")
    parser.add_argument("--source")
    parser.add_argument("--godot")
    parser.add_argument("--graphics", action="store_true")
    parser.add_argument("--demos")
    parser.add_argument("--out")
    parser.add_argument("--baseline")
    args = parser.parse_args()
    if args.download:
        download(args.download)
        return 0
    if not args.source or not args.godot:
        parser.error("--source and --godot are required (or --download TAG)")
    failed = False
    problems, new_labels = catalog_problems(args.source)
    for line in problems:
        print("CATALOG", line)
    failed |= bool(problems)
    for renderer, names in new_labels.items():
        if names:
            print(f"REVIEW new {renderer} timestamp labels since {SERIES[-1]}: {names}")
    print("PASS catalog matches the release sources" if not problems else f"FAIL {len(problems)} catalog entries no longer match")
    suites = [sys.executable, str(ROOT / "tests/run_regressions.py"), "--godot", args.godot, "--integration"] + (["--graphics"] if args.graphics else [])
    # The live pass-name check (--graphics) reads this release's labels from its source tree.
    failed |= subprocess.run(suites, env=dict(os.environ, RENDER_LENS_GODOT_SOURCE=str(Path(args.source).resolve()))).returncode != 0
    if args.demos:
        audit = [sys.executable, str(ROOT / "tests/run_demo_audit.py"), args.demos, "--out", args.out or str(ROOT / ".tmp/demo_audit"), "--godot", args.godot]
        failed |= subprocess.run(audit + (["--baseline", args.baseline] if args.baseline else [])).returncode != 0
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
