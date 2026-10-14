extends RefCounted

## Frame-budget helpers shared by frame_timing, gpu_passes, and advise.
## The GPU wait is wall-clock time. A 4 fps scene cannot finish 60 frames inside a fixed 15 s.


const GPU_WARMUP_FRAMES := 10
## renderer_viewport.cpp viewport_get_measured_render_time_gpu divides a uint64
## (time_gpu_end - time_gpu_begin) before converting nanoseconds to milliseconds.
## A missing end timestamp underflows into a value far above any real frame.
const MAX_VIEWPORT_FRAME_MS := 10000.0


static func timeout_payload(frames_collected: int, elapsed: float, limit: float, fps: float) -> Dictionary:
	if frames_collected <= 0:
		return {
			"partial": false,
			"error": "Timeout waiting for GPU data (%.1fs, limit %.1fs at %.1f fps) and no frames had arrived." % [elapsed, limit, fps],
		}
	return {"partial": true, "frame_count": frames_collected, "error": ""}


static func gpu_timeout_sec(frames: int, fps: float) -> float:
	var rate := fps
	if rate < 1.0:
		rate = 1.0
	var scaled := float(maxi(frames, 1)) / rate * 1.5 + 5.0
	return clampf(maxf(15.0, scaled), 15.0, 120.0)


static func median_overrun_percent(median_ms: float, budget_ms: float) -> float:
	if budget_ms <= 0.0 or median_ms <= budget_ms:
		return 0.0
	return (median_ms - budget_ms) / budget_ms * 100.0


static func near_fps(actual: float, target: float) -> bool:
	if target <= 1.0 or actual <= 0.0:
		return false
	return absf(actual - target) / target <= 0.12


## Over budget only past 3%: a display slightly under the target rate (59.94 Hz is 0.1% over a 60 fps budget, a 59 Hz
## panel 1.7%) is not an overrun, while a frame that misses V-Sync is 100% over.
static func over_budget(median_ms: float, budget_ms: float) -> bool:
	return budget_ms > 0.0 and median_ms > budget_ms * 1.03


## Measurements run with V-Sync and Engine.max_fps off, so frame and pass times show the real cost instead of the
## refresh interval. Returns what restore() puts back; a driver that forces V-Sync still caps the rate.
static func uncap() -> Dictionary:
	var saved := {"vsync_mode": DisplayServer.window_get_vsync_mode(), "max_fps": Engine.max_fps}
	# Only a real change: a display server without V-Sync control warns on every set call.
	if saved["vsync_mode"] != DisplayServer.VSYNC_DISABLED:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	return saved


static func restore(saved: Dictionary) -> void:
	if saved.is_empty():
		return
	if int(saved["vsync_mode"]) != DisplayServer.VSYNC_DISABLED:
		DisplayServer.window_set_vsync_mode(int(saved["vsync_mode"]))
	Engine.max_fps = int(saved["max_fps"])


## What a measurement reports about the caps uncap() lifted.
static func uncapped(saved: Dictionary, median_fps: float) -> Dictionary:
	if saved.is_empty():
		return {"vsync_and_max_fps_off": false}
	var out := {"vsync_and_max_fps_off": true, "game_vsync_mode": int(saved["vsync_mode"]), "game_max_fps": int(saved["max_fps"])}
	var refresh := DisplayServer.screen_get_refresh_rate()
	if refresh > 20.0 and median_fps > 0.0 and absf(median_fps - refresh) / refresh <= 0.02:
		out["note"] = "The median rate still matches the %.0f Hz display, so the driver may force V-Sync and frame times can be the refresh interval rather than the cost." % refresh
	return out


static func near_refresh_divisor(actual: float, refresh_hz: float) -> bool:
	if refresh_hz < 20.0:
		return false
	for n in range(1, 7):
		if near_fps(actual, refresh_hz / float(n)):
			return true
	return false


static func pacing_note(actual_fps: float, theoretical_fps: float, vsync_mode: int, max_fps: int, refresh_hz: float, process_sec: float) -> String:
	if theoretical_fps <= 1.0 or actual_fps <= 0.0:
		return ""
	if actual_fps >= theoretical_fps * 0.9:
		return ""
	var near_cap := near_refresh_divisor(actual_fps, refresh_hz)
	if max_fps > 1 and near_fps(actual_fps, float(max_fps)):
		near_cap = true
	if near_cap and (vsync_mode != 0 or max_fps > 0):
		return "vsync or frame-rate cap active (actual %.1f fps vs theoretical %.1f fps)" % [actual_fps, theoretical_fps]
	if near_cap:
		return "vsync or frame-rate cap active (actual %.1f fps vs theoretical %.1f fps)" % [actual_fps, theoretical_fps]
	return "Unattributed frame pacing or synchronization (sampled process time %.2f s). Actual %.1f fps vs theoretical %.1f fps." % [process_sec, actual_fps, theoretical_fps]


## rendering/driver/threads/thread_model 2 (Separate, experimental): RenderingDevice timestamp getters only work on the
## render thread, a viewport_get_measured_render_time_* read forces a render-thread sync, and the debugger's servers:memory
## request crashes the game (texture_debug_usage is queued with a pointer to a stack list, rendering_server_default.h).
static func separate_render_thread() -> bool:
	if not Engine.is_editor_hint():
		return not RenderingServer.is_on_render_thread()  # exact in the game, --render-thread overrides included
	# The editor itself always renders on its main thread (main.cpp); this is the model the game will start with.
	var path := "rendering/driver/threads/thread_model"  # unregistered when the editor runs with --render-thread
	return ProjectSettings.has_setting(path) and int(ProjectSettings.get_setting_with_override(path)) == 2


static func viewport_counter_note(frame_ms: float, viewport_ms: float) -> String:
	if separate_render_thread():
		return "Viewport render times are not read with rendering/driver/threads/thread_model = Separate: each read would force a render-thread sync every frame."
	if viewport_ms > 0.05 or frame_ms <= 0.05:
		return ""
	return "median_viewport_gpu_ms is 0 because viewport_get_measured_render_time_gpu stayed 0. That counter is the previous presented frame and is often 0 in an embedded editor game, including after viewport_set_measure_render_time. Pass shares use the timestamp span (%.3f ms), not this counter." % frame_ms


static func sane_viewport_ms(raw: float) -> float:
	if is_nan(raw) or is_inf(raw):
		return -1.0
	if raw < 0.0 or raw > MAX_VIEWPORT_FRAME_MS:
		return -1.0
	return raw


## Godot's RenderingDevice keeps at most debug/settings/profiler/max_timestamp_query_elements timestamps per frame
## (rendering_device.cpp capture_timestamp); everything after the limit is dropped with an error.
static func timestamp_truncation_note(truncated_frames: int, frame_count: int, limit: int) -> String:
	if truncated_frames <= 0:
		return ""
	return "%d of %d frames reached Godot's limit of %d GPU timestamps per frame (debug/settings/profiler/max_timestamp_query_elements), so every pass recorded after the limit, including the end of the viewport, is missing from this breakdown and from the timestamp-span frame time; the game log shows \"Tried capturing more timestamps than the configured maximum\". Raise the setting (for example to 1024) and capture again." % [truncated_frames, frame_count, limit]


static func viewport_rejected_note(frame_ms: float, rejected_max: float) -> String:
	if rejected_max < 0.0:
		return ""
	return "median_viewport_gpu_ms was omitted. viewport_get_measured_render_time_gpu returned %.3f, outside 0..%.0f ms. renderer_viewport.cpp subtracts uint64 timestamps before converting nanoseconds to milliseconds, so a missing end timestamp underflows. Pass shares use the timestamp span (%.3f ms), not this counter." % [rejected_max, MAX_VIEWPORT_FRAME_MS, frame_ms]


static func bound_label(frame_ms: float, gpu_ms: float) -> String:
	# A process/frame duration includes GPU waits. A large gap cannot prove CPU work.
	if frame_ms > 0.05 and is_finite(frame_ms) and sane_viewport_ms(gpu_ms) > 0.05 and gpu_ms >= frame_ms * 0.85:
		return "gpu"
	return "unknown"


static func embedded_play_note_for(mode: int, metadata_embed: bool, feature_embedding: bool) -> String:
	## Mirrors GameView embed selection in Godot 4.7.2 editor/plugins/game_view_plugin.cpp.
	## Mode -1 is disabled. Mode 0 uses project metadata game_view/embed_on_play, which
	## defaults to true. Modes 1 and 2 both embed (mode 2 is a floating Game workspace).
	if not feature_embedding:
		return ""
	if mode == -1:
		return ""
	if mode == 0 and not metadata_embed:
		return ""
	if mode != 0 and mode != 1 and mode != 2:
		return ""
	return "The editor is configured to embed the game window (EditorSettings run/window_placement/game_embed_mode; default per-project metadata embed_on_play is true). EngineProfiler process time includes RenderingServer::sync and ::draw (main.cpp); TIME_PROCESS is a periodic maximum and is not used as a frame median. Embedding reparents the game window (editor/run/embedded_process.cpp) and can stall that wait. Compare embedding disabled, or a standalone `godot --path <project> res://heavy_test.tscn`, before treating the gap as scene work."


static func current_embedded_play_note() -> String:
	if not Engine.is_editor_hint():
		return ""
	if not Engine.has_singleton("EditorInterface"):
		return ""
	var ei = Engine.get_singleton("EditorInterface")
	var settings = ei.call("get_editor_settings")
	if settings == null:
		return ""
	var mode := int(settings.call("get_setting", "run/window_placement/game_embed_mode"))
	var metadata_embed := true
	var got = settings.call("get_project_metadata", "game_view", "embed_on_play", true)
	if typeof(got) == TYPE_BOOL:
		metadata_embed = bool(got)
	var feature := false
	if DisplayServer.get_name() != "headless":
		feature = DisplayServer.has_feature(DisplayServer.FEATURE_WINDOW_EMBEDDING)
	if feature and bool(ProjectSettings.get_setting_with_override("display/window/subwindows/embed_subwindows")):
		feature = false
	var window_mode := int(ProjectSettings.get_setting_with_override("display/window/size/mode"))
	if window_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or window_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN or window_mode == DisplayServer.WINDOW_MODE_MAXIMIZED or window_mode == DisplayServer.WINDOW_MODE_MINIMIZED:
		feature = false
	var driver := str(ProjectSettings.get_setting_with_override("display/display_server/driver"))
	if driver == "headless":
		feature = false
	return embedded_play_note_for(mode, metadata_embed, feature)
