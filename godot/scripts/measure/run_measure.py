"""Measure sample_project/heavy_test.tscn once per single-toggle variant (docs/MEASURED_EFFECTS.md).

Usage: python scripts/measure/run_measure.py <godot console executable> <work dir> [screen]
Each run opens a 1920x1080 window on the given screen (default 1) with V-Sync off, warms up 300 frames, records 600,
and writes <work dir>/out/NN_<variant>.json. Three baselines are interleaved to measure the run-to-run noise.
"""
import json
import shutil
import subprocess
import sys
from pathlib import Path

GODOT = sys.argv[1]
WORK = Path(sys.argv[2])
SCREEN = sys.argv[3] if len(sys.argv) > 3 else "1"
OUT = WORK / "out"
HERE = Path(__file__).parent
PROJECT = WORK / "proj"
SOURCE = HERE.parents[1] / "sample_project"

FIRST = ["sdfgi_off", "ssil_off", "ssao_off", "ssr_off", "ssr_steps_64", "glow_off", "volumetric_fog_off"]
SECOND = ["fog_gi_inject_0", "dof_off", "omni_shadows_off", "spot_shadows_off", "directional_distance_100", "gi_half_resolution"]
ALL = "+".join(FIRST + SECOND).replace("ssr_steps_64+", "")
ORDER = ["warm", "baseline"] + FIRST + ["baseline"] + SECOND + [ALL, "baseline"]


def run(variant, index):
    override = PROJECT / "override.cfg"
    override.unlink(missing_ok=True)
    if "gi_half_resolution" in variant:
        override.write_text("[rendering]\n\nglobal_illumination/gi/use_half_resolution=true\n", encoding="utf-8")
    name = "baseline" if variant == "warm" else variant
    out = OUT / ("%02d_%s.json" % (index, "all" if "+" in variant else variant))
    args = [GODOT, "--path", str(PROJECT), "--screen", SCREEN, "--resolution", "1920x1080", "--script", "res://measure_variant.gd",
            "--", "variant=" + name, "out=" + str(out), "warmup=300", "frames=600"]
    process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace")
    try:
        log, _ = process.communicate(timeout=180)
    except subprocess.TimeoutExpired:
        process.kill()
        log, _ = process.communicate()
        print("TIMEOUT", variant)
    override.unlink(missing_ok=True)
    (OUT / (out.stem + ".log")).write_text(log, encoding="utf-8")
    if not out.exists():
        print("NO RESULT", variant, "exit", process.returncode)
        return
    result = json.loads(out.read_text(encoding="utf-8"))
    print("%-24s gpu %.3f ms  frame %.3f ms  cpu %.3f ms  window %s screen %s half %s" % (
        variant[:24], result["gpu_ms"]["median"], result["interval_ms"]["median"], result["cpu_ms"]["median"],
        result["window"], result["screen"], result["gi_half_resolution"]), flush=True)


if not PROJECT.exists():
    # The measured project runs without the addon so its own work is not in the timing.
    shutil.copytree(SOURCE, PROJECT, ignore=shutil.ignore_patterns(".godot", ".render_lens", "addons"))
    config = PROJECT / "project.godot"
    config.write_text(config.read_text(encoding="utf-8").replace("[editor_plugins]", "").replace('enabled=PackedStringArray("res://addons/render_lens/plugin.cfg")', ""), encoding="utf-8")
    subprocess.run([GODOT, "--headless", "--path", str(PROJECT), "--import"], timeout=300, capture_output=True)
for name in ("measure_variant.gd", "variants.gd"):
    shutil.copy(HERE / name, PROJECT / name)
OUT.mkdir(parents=True, exist_ok=True)
for index, variant in enumerate(ORDER):
    run(variant, index)
