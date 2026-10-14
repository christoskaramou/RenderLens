"""Run Render Lens gpu_passes on sample_project/heavy_test.tscn variants through a disposable headless editor (docs/MEASURED_EFFECTS.md).

Windows only. Usage: python scripts/measure/crosscheck.py <godot console executable> <work dir> <variant> [<variant>...]
The game window opens on display 1; results go to <work dir>/passes. Set TS_LIMIT (for example 1024) to raise
debug/settings/profiler/max_timestamp_query_elements so heavy frames are not truncated.
"""
import json
import os
import shutil
import socket
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from build_packages import copy_project  # noqa: E402

GODOT = Path(sys.argv[1]).resolve()
WORK = Path(sys.argv[2])
OUT = WORK / "passes"
VARIANTS = sys.argv[3:]
HERE = Path(__file__).parent
PROJECT = WORK / "xproj"


def free_port():
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        return probe.getsockname()[1]


if PROJECT.exists():
    shutil.rmtree(PROJECT)
copy_project(PROJECT)
for name in ("variants.gd", "variant_root.gd", "variant.tscn"):
    shutil.copy(HERE / name, PROJECT / name)
(PROJECT / "variant.txt").write_text("baseline", encoding="utf-8")
port, debug_port = free_port(), free_port()
server = PROJECT / "addons/render_lens/mcp_server.gd"
server.write_text(server.read_text(encoding="utf-8").replace("const PORT := 43788", f"const PORT := {port}"), encoding="utf-8")
config = PROJECT / "project.godot"
game_args = ("--headless" if os.environ.get("XCHECK_HEADLESS") else "--resolution 1920x1080 --screen 1") + f" --remote-debug tcp://127.0.0.1:{debug_port}"
config.write_text(config.read_text(encoding="utf-8").replace('run/main_scene="res://main.tscn"', 'run/main_scene="res://variant.tscn"')
                  + '\n[display]\nwindow/vsync/vsync_mode=0\n[editor]\nrun/main_run_args="' + game_args + '"\n'
                  + ('[debug]\nsettings/profiler/max_timestamp_query_elements=%s\n' % os.environ["TS_LIMIT"] if os.environ.get("TS_LIMIT") else ""), encoding="utf-8")
subprocess.run([str(GODOT), "--headless", "--path", str(PROJECT), "--import"], timeout=300, capture_output=True)

editor = GODOT.with_name(GODOT.name.replace("_console.exe", ".exe"))
portable = PROJECT / ".test-editor"
portable.mkdir()
binary = portable / editor.name
shutil.copy2(editor, binary)
(portable / "._sc_").touch()
(portable / "editor_data").mkdir()
version = subprocess.check_output([str(editor), "--version"], text=True, timeout=10).strip().split(".")
(portable / "editor_data" / f"editor_settings-{version[0]}.{version[1]}.tres").write_text(
    '[gd_resource type="EditorSettings" format=3]\n[resource]\nnetwork/debug/remote_port = ' + str(debug_port) + '\n', encoding="utf-8")
startup = subprocess.STARTUPINFO()
startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = 0
log = open(PROJECT / "editor.log", "w", encoding="utf-8")
process = subprocess.Popen([str(binary), "--headless", "--editor", "--debug-server", f"tcp://127.0.0.1:{debug_port}", "--path", str(PROJECT)],
                           stdout=log, stderr=subprocess.STDOUT, startupinfo=startup)
serial = 0


def call(name, arguments=None):
    global serial
    serial += 1
    body = json.dumps({"jsonrpc": "2.0", "id": serial, "method": "tools/call", "params": {"name": name, "arguments": arguments or {}}}).encode()
    request = urllib.request.Request(f"http://127.0.0.1:{port}/mcp", data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=120) as response:
        result = json.load(response)["result"]
    if result.get("isError"):
        raise RuntimeError(f"{name}: {result}")
    return json.loads(result["content"][0]["text"])


def game_alive(pid):
    return str(pid) in subprocess.run(["tasklist", "/FI", f"PID eq {pid}", "/NH"], capture_output=True, text=True).stdout


OUT.mkdir(parents=True, exist_ok=True)
try:
    deadline = time.monotonic() + 40
    while True:
        try:
            call("ping_render_lens")
            break
        except (OSError, KeyError):
            if time.monotonic() > deadline or process.poll() is not None:
                raise RuntimeError("editor did not start its MCP server")
            time.sleep(0.2)
    for variant in VARIANTS:
        (PROJECT / "variant.txt").write_text(variant, encoding="utf-8")
        override = PROJECT / "override.cfg"
        override.unlink(missing_ok=True)
        if "gi_half_resolution" in variant:
            override.write_text("[rendering]\n\nglobal_illumination/gi/use_half_resolution=true\n", encoding="utf-8")
        call("run_game")
        pid = call("render_stats")["context"]["process_id"]
        time.sleep(8)  # shader compilation and SDFGI convergence before the capture
        summary = call("gpu_passes", {"frames": 120})
        saved = json.loads((PROJECT / summary["path"].removeprefix("res://")).read_text(encoding="utf-8"))
        name = "all" if "+" in variant else variant
        (OUT / f"passes_{name}.json").write_text(json.dumps(saved, indent=1), encoding="utf-8")
        top = [(p["name"], round(p["exclusive_median_ms"], 3)) for p in saved.get("top_passes", [])[:5]]
        print("%-22s frame_gpu %.3f ms viewport %.3f ms truncated %s/%s limit %s  top %s" % (name, saved.get("median_frame_gpu_ms", -1), saved.get("median_viewport_gpu_ms", -1), saved.get("timestamp_truncated_frames"), saved.get("frame_count"), saved.get("timestamp_limit"), top), flush=True)
        if summary.get("timestamp_truncation_note"):
            print("  note:", summary["timestamp_truncation_note"][:170], flush=True)
        call("stop_game")
        for _ in range(50):
            if not game_alive(pid):
                break
            time.sleep(0.2)
        else:
            subprocess.run(["taskkill", "/F", "/PID", str(pid)], capture_output=True)
        override.unlink(missing_ok=True)
finally:
    try:
        call("stop_game")
    except Exception:
        pass
    process.terminate()
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        process.kill()
