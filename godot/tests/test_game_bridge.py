"""Real editor -> debugger -> game checks, confined to a disposable project."""
import json
import os
from pathlib import Path
import socket
import shutil
import subprocess
import sys
import threading
import time
import urllib.request
import uuid

if os.name == "nt":
    import _winapi


def custom_user_dir(name):
    """Where Godot puts a project's user data with application/config/use_custom_user_dir (OS get_data_path)."""
    if os.name == "nt":
        return Path(os.environ["APPDATA"]) / name
    if sys.platform == "darwin":
        return Path.home() / "Library/Application Support" / name
    return Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / name


def check_game_bridge(godot, project, graphics=False, screen=None, heavy=False, separate=False, coverage=None):
    """heavy: run heavy_test.tscn at 1920x1080 without the fps cap and check full-size captures.
    separate: the same scene on the Separate render thread model, where Godot's own servers:memory request crashes the game.
    coverage: a renderer id; runs tests/pass_coverage.tscn on it and returns gpu_passes' pass list."""
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        debug_port = probe.getsockname()[1]
    server = project / "addons/render_lens/mcp_server.gd"
    server.write_text(server.read_text(encoding="utf-8").replace("const PORT := 43788", f"const PORT := {port}"), encoding="utf-8")
    config = project / "project.godot"
    settings = config.read_text(encoding="utf-8")
    user_dir = None
    if heavy:
        # Godot 4.4+ stores the main scene as uid://. The UID is added after the import step, so the editor learns it only
        # in its startup scan; run_game used to call play_main_scene before that ("Unrecognized UID", no game).
        scene_file = project / "heavy_test.tscn"
        scene_file.write_text(scene_file.read_text(encoding="utf-8").replace("format=3]", 'format=3 uid="uid://hvytest2026"]', 1), encoding="utf-8")
        settings = settings.replace('run/main_scene="res://main.tscn"', 'run/main_scene="uid://hvytest2026"')
        if separate:
            settings = settings.replace("[rendering]\n", "[rendering]\n\ndriver/threads/thread_model=2\n", 1)
    elif coverage:
        # Two viewports and every timed feature pass Godot's default 256 timestamps per frame; later labels would be dropped.
        settings = settings.replace('run/main_scene="res://main.tscn"', 'run/main_scene="res://tests/pass_coverage.tscn"')
        settings = settings.replace('renderer/rendering_method="forward_plus"', f'renderer/rendering_method="{coverage}"')
        settings += "\n[debug]\nsettings/profiler/max_timestamp_query_elements=2048\n"
    else:
        # The editor opens main.tscn from its command line (below) after the restored session scene, but skips it when it
        # is the main scene and a session is restored (editor_node.cpp, main.cpp), so heavy_test.tscn is the main scene here.
        settings = settings.replace('run/main_scene="res://main.tscn"', 'run/max_fps=5\nrun/main_scene="res://heavy_test.tscn"')
        # Its own user data folder (created just before the editor starts, removed below), so the editor's startup lock
        # (<user data dir>/.recovery_mode_lock, os.cpp) is not shared with other runs or projects.
        user_dir = custom_user_dir(f"render-lens-test-{uuid.uuid4().hex[:12]}")
        assert "[application]\n" in settings
        settings = settings.replace("[application]\n", f'[application]\n\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="{user_dir.name}"\n', 1)
    # Heavy frames still reach Godot's 256-timestamp cap at 1280x720; the 60 fps cap keeps the machine responsive.
    game_args = "--resolution 1280x720 --max-fps 60" if heavy else "--resolution 640x360" if coverage else "--resolution 128x128" if graphics else "--headless"
    if graphics and screen is not None:
        game_args += f" --screen {screen}"
    # Godot 4.4 can launch the child on its default port despite --debug-server.
    game_args += f" --remote-debug tcp://127.0.0.1:{debug_port}"
    config.write_text(settings + '\n[editor]\nrun/main_run_args="' + game_args + ' --log-file game-integration.log"\n[editor_plugins]\nenabled=PackedStringArray("res://addons/render_lens/plugin.cfg")\n', encoding="utf-8")
    log = open(project / "editor-integration.log", "w", encoding="utf-8")
    startup = None
    if os.name == "nt":
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
    # The Windows console wrapper exits separately from the editor it spawns.
    executable = Path(godot).resolve()
    if os.name == "nt":
        executable = executable.with_name(executable.name.replace("_console.exe", ".exe"))
    # Keep debugger ports and editor preferences out of the user's installation.
    portable = project / ".test-editor"
    portable.mkdir()
    binary = portable / executable.name
    try:
        os.link(executable, binary)
    except OSError:
        shutil.copy2(executable, binary)
    (portable / "._sc_").touch()
    settings_dir = portable / "editor_data"
    settings_dir.mkdir()
    version = subprocess.check_output([str(executable), "--version"], text=True, timeout=10).strip().split(".")
    settings_file = settings_dir / f"editor_settings-{version[0]}.{version[1]}.tres"
    settings_file.write_text('[gd_resource type="EditorSettings" format=3]\n[resource]\nnetwork/debug/remote_port = ' + str(debug_port) + '\n', encoding="utf-8")
    executable = binary
    # The plain run plays the scene the editor opens at startup (run_game use_main_scene false) as soon as the MCP server
    # answers: the editor opens it only after its layout load, which run_game used to beat (no game, a 30 s timeout).
    current = not heavy and not coverage
    if current:
        # The restored session scene is current before the command-line one opens (editor_node.cpp _sources_changed), so
        # run_game must wait for main.tscn rather than play heavy_test.tscn.
        layout = project / ".godot/editor/editor_layout.cfg"
        layout.parent.mkdir(parents=True, exist_ok=True)
        layout.write_text('[EditorNode]\nopen_scenes=PackedStringArray("res://heavy_test.tscn")\ncurrent_scene="res://heavy_test.tscn"\n', encoding="utf-8")
    if user_dir is not None:
        # Godot writes its startup lock only into an existing folder (main.cpp creates the lock before the folder). A new
        # random name, never an existing folder, so the cleanup below removes only what this run made.
        user_dir.mkdir(parents=True)
    try:
        process = subprocess.Popen([str(executable), "--headless", "--editor", "--debug-server", f"tcp://127.0.0.1:{debug_port}", "--path", str(project), "--log-file", str(project / "editor-godot.log"), "res://main.tscn" if current else "res://heavy_test.tscn"], stdout=log, stderr=subprocess.STDOUT, startupinfo=startup,
                                   creationflags=subprocess.BELOW_NORMAL_PRIORITY_CLASS if os.name == "nt" else 0,
                                   env={key: value for key, value in os.environ.items() if key != "ENABLE_VULKAN_RENDERDOC_CAPTURE"})
    except BaseException:
        if user_dir is not None:
            shutil.rmtree(user_dir, ignore_errors=True)
        raise
    serial = 0
    game_handle = None

    def call(name, arguments=None):
        nonlocal serial
        serial += 1
        body = json.dumps({"jsonrpc": "2.0", "id": serial, "method": "tools/call", "params": {"name": name, "arguments": arguments or {}}}).encode()
        request = urllib.request.Request(f"http://127.0.0.1:{port}/mcp", data=body, headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(request, timeout=75) as response:
            result = json.load(response)["result"]
        if result.get("isError"):
            raise AssertionError(f"{name}: {result}")
        return json.loads(result["content"][0]["text"])

    try:
        deadline = time.monotonic() + 25
        while True:
            try:
                call("ping_render_lens")
                break
            except (OSError, KeyError):
                if time.monotonic() > deadline or process.poll() is not None:
                    raise AssertionError("Disposable editor did not start its MCP server")
                time.sleep(0.1)
        if current:
            # run_game waits while the editor's startup lock exists (run_game.current_scene_open). Once the editor has
            # removed its own, put it back for 5 s: run_game must not start the game before it is gone.
            lock = user_dir / ".recovery_mode_lock"
            deadline = time.monotonic() + 30
            while lock.exists() and time.monotonic() < deadline:
                time.sleep(0.1)
            assert not lock.exists(), "the editor kept its startup lock"
            lock.touch()
            # The game creates its log file early in its startup (main.cpp, before rendering starts), so a game launched under
            # the lock has written it by the time the lock goes 5 s later.
            game_log = project / "game-integration.log"
            game_log.unlink(missing_ok=True)
            early = []

            def release():
                early.append(game_log.exists())
                lock.unlink(missing_ok=True)
            threading.Timer(5.0, release).start()
        started = call("run_game", {"use_main_scene": False} if current else None)
        assert started["debugger_ready"], started
        if current:
            assert early == [False], "run_game started the game while the editor's startup lock existed"
        if coverage:
            time.sleep(8)  # SDFGI, volumetric fog and pipeline compiles settle first
            passes = call("gpu_passes", {"frames": 60})
            assert not passes["partial"] and not passes["timestamp_truncated"], passes
            call("stop_game")
            with open(project / passes["path"].removeprefix("res://"), encoding="utf-8") as saved:
                return json.load(saved)["passes"]
        if heavy:
            time.sleep(5)
            if separate:
                try:
                    call("gpu_passes", {"frames": 60})
                    raise RuntimeError("gpu_passes should refuse the Separate render thread model")
                except AssertionError as refused:
                    assert "Separate" in str(refused), refused
                assert call("vram_report")["source"] == "game_resource_estimate"
                assert call("render_stats")["context"]["source"] == "game"  # the game survived the VRAM request
                call("stutter_report", {"seconds": 5})
                call("stop_game")
                print("PASS", project.name, "Separate render thread model")
                return
            before = time.monotonic()
            passes = call("gpu_passes", {"frames": 120})
            elapsed = time.monotonic() - before
            # All frames in one message exceeded Godot's 8 MiB debugger packet, so the capture timed out as partial.
            assert not passes["partial"] and passes["frame_count"] == 120 and elapsed < 30, (passes["partial"], passes["frame_count"], elapsed)
            # --max-fps 60 and the project's V-Sync are lifted while recording, then restored for the next capture.
            assert passes["uncapped"]["game_max_fps"] == 60, passes["uncapped"]
            advice = call("advise", {"target_fps": 60, "pass_frames": 60})
            assert not advice["inputs"]["gpu_passes_error"] and advice["inputs"]["pass_count"] > 0, advice["inputs"]
            assert advice["inputs"]["gpu_passes_uncapped"]["game_max_fps"] == 60, advice["inputs"]
            assert advice["inputs"]["gpu_passes_uncapped"]["game_vsync_mode"] == passes["uncapped"]["game_vsync_mode"], advice["inputs"]
            # Omni-light shadows are about half of this scene's GPU frame (MEASURED_EFFECTS.md: 2.8 of 6.0 ms at 1080p). A
            # failed restore would leave the second "before" capture as fast as the change and read as noise, not "faster".
            # With the shadows on, every frame here passes Godot's 256 timestamps and its viewport GPU counter fails, so
            # the GPU total may not compare; the frame time and the omni shadow pass must.
            tried = call("measure_change", {"finding": "shadows.omni_shadow_count", "frames": 60})
            assert not tried["applied_to_project"] and tried["changes"][0]["objects"] == 8, tried
            assert tried["frame_ms"]["verdict"] == "faster" and tried["frame_ms"]["saving_ms"] > 0.5, tried
            assert "gpu_frame_ms" in tried or "gpu_frame_note" in tried, tried
            assert tried.get("gpu_frame_ms", {"verdict": "faster"})["verdict"] == "faster", tried
            assert any("OmniLight" in row["name"] and row["saving_ms"] > 0.5 for row in tried["pass_changes"]), tried["pass_changes"]
            try:
                call("measure_change", {"changes": [{"setting": "rendering/driver/depth_prepass/enable", "value": False}]})
                raise RuntimeError("measure_change should refuse a setting read at startup")
            except AssertionError as refused:
                assert "startup" in str(refused), refused
            vram = call("vram_report")
            # Counters come from the game, not the editor's own device, and a capped list says so.
            assert vram.get("counters_source") == "game" and "device" in vram and "truncated" in vram, vram
            call("stop_game")
            try:
                call("vram_report")
                raise RuntimeError("vram_report should fail without a running game")
            except AssertionError:
                pass  # call() raises only on isError; the message depends on how far the session has closed
            print("PASS", project.name, "heavy scene captures at 1280x720")
            return
        stats = call("render_stats")
        assert stats["context"]["source"] == "game", stats
        assert stats["context"]["process_id"] != process.pid, stats
        if os.name == "nt":
            game_handle = _winapi.OpenProcess(_winapi.SYNCHRONIZE, False, int(stats["context"]["process_id"]))
        assert stats["context"]["scene"] == "res://main.tscn", stats
        # run/max_fps=5 holds the game at 200 ms frames; frame_timing samples without the cap and puts it back.
        timing = call("frame_timing", {"frames": 10, "warmup": 2})
        assert timing["source"] == "game" and timing["scene"] == "res://main.tscn", timing
        assert timing["median_frame_ms"] < 150 and timing["uncapped"]["game_max_fps"] == 5, timing
        again = call("frame_timing", {"frames": 10, "warmup": 2})
        assert again["uncapped"]["game_max_fps"] == 5, again
        with open(project / timing["path"].removeprefix("res://"), encoding="utf-8") as saved:
            capture = json.load(saved)
        assert capture["context"]["process_id"] == stats["context"]["process_id"]
        assert capture["process_source"] == "EngineProfiler._tick", capture["process_source"]
        if graphics:
            screenshot = call("capture_viewport")
            assert (project / screenshot["path"].removeprefix("res://")).is_file(), screenshot
            with open(project / screenshot["metadata_path"].removeprefix("res://"), encoding="utf-8") as saved:
                metadata = json.load(saved)
            assert metadata["context"]["source"] == "game", metadata
        scan = call("scan_scene")
        assert scan["scenes"] == ["scene:res://main.tscn"], scan["scenes"]
        # The game scans its nodes; the editor adds the project files (they no longer stall the game).
        assert int(scan["file_walk"].get("entries", 0)) > 0 and "scripts" in scan["script_scan"], (scan["file_walk"], scan["script_scan"])
        before = time.monotonic()
        stutters = call("stutter_report", {"seconds": 5})
        elapsed = time.monotonic() - before
        assert elapsed < 12 and stutters["duration_seconds"] < 7, (elapsed, stutters)
        advice = call("advise", {"timing_frames": 10, "pass_frames": 10})
        assert advice["inputs"]["metrics_source"] == "game", advice["inputs"]
        assert advice["headroom"]["median_frame_ms"] < 150 and advice["inputs"]["frame_timing_uncapped"]["game_max_fps"] == 5, (advice["headroom"], advice["inputs"])
        assert set(advice["area_counts"]) == {"performance", "visual", "missing", "to_check", "info"}, advice["area_counts"]
        assert isinstance(advice.get("godot_warned_count"), int), advice.keys()
        if graphics:
            assert advice["inputs"]["pass_count"] > 0, advice["inputs"]
            assert not advice["inputs"]["gpu_passes_error"], advice["inputs"]
            assert advice["inputs"]["gpu_passes_uncapped"]["game_max_fps"] == 5, advice["inputs"]
        call("stop_game")
        print("PASS", project.name, "real editor/game bridge", "with GPU screenshot" if graphics else "headless")
    except BaseException:
        log.flush()
        print(config.read_text(encoding="utf-8"))
        print((project / "editor-integration.log").read_text(encoding="utf-8", errors="replace")[-6000:])
        game_log = project / "game-integration.log"
        if game_log.exists():
            print(game_log.read_text(encoding="utf-8", errors="replace")[-6000:])
        raise
    finally:
        try:
            call("stop_game")
        except Exception:
            pass
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)
        try:
            if game_handle is not None:
                # Editor play state can clear before the game releases its files.
                assert _winapi.WaitForSingleObject(game_handle, 5000) == _winapi.WAIT_OBJECT_0, "Disposable game did not exit"
        finally:
            if game_handle is not None:
                _winapi.CloseHandle(game_handle)
            log.close()
            if user_dir is not None:
                shutil.rmtree(user_dir, ignore_errors=True)  # this run's own folder (render-lens-test-<random>)
