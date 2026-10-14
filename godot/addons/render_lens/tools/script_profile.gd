extends Node

## script_profile
## Enables the debugger profiler named "servers". Godot folds GDScript samples
## and physics/rendering/audio server times into that profiler
## (servers/debugger/servers_debugger.cpp). There is no separate "scripts" profiler.
## Does not change the project.

const FileHelper = preload("res://addons/render_lens/file_helper.gd")
const Parse = preload("res://addons/render_lens/debugger_parse.gd")
const Pacing = preload("res://addons/render_lens/pacing.gd")

static func execute(params: Dictionary) -> Dictionary:
	var gathered: Dictionary = await gather(params)
	if str(gathered.get("error", "")) != "":
		return _error(str(gathered.error))
	var path := FileHelper.write_json(gathered, "script_profile")
	if path.is_empty():
		return _error("Failed to write script_profile JSON")
	gathered["path"] = path
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify(_summary(gathered), "\t")
		}]
	}


static func gather(params: Dictionary) -> Dictionary:
	var frames := int(params.get("frames", 20))
	if frames < 1:
		frames = 1
	if frames > 120:
		frames = 120
	var max_functions := int(params.get("max_functions", 32))
	if max_functions < 16:
		max_functions = 16
	if max_functions > 512:
		max_functions = 512
	var include_visual := bool(params.get("include_visual", false))
	var debugger_plugin = params.get("_debugger_plugin")
	if debugger_plugin == null or not debugger_plugin.has_method("request_game_profile"):
		return {"error": "Not available: the Render Lens debugger plugin is missing"}
	if not debugger_plugin.has_method("get_debug_status"):
		return {"error": "Not available: the Render Lens debugger plugin is missing"}
	var status: Dictionary = debugger_plugin.get_debug_status()
	if int(status.get("active_sessions", 0)) <= 0:
		return {"error": "No active debugger session. Run the game from the editor, then call script_profile again."}
	# A paused game would not ack before the profilers are switched back off, so the user's own Profiler would stop.
	var paused_now = debugger_plugin._get_active_session()
	if paused_now != null and paused_now.is_breaked():
		return {"error": "The game is paused in the debugger (breakpoint or error); continue it and profile again."}
	var listener := bool(debugger_plugin.attach_session_debug_data())
	if not debugger_plugin.request_game_profile(frames):
		return {"error": str(debugger_plugin.last_error)}
	var servers_started := bool(debugger_plugin.start_servers_profiler(max_functions, include_visual))
	var started := Time.get_ticks_msec()
	var fps := Engine.get_frames_per_second()
	if fps < 1.0:
		fps = 1.0
	# The game's fps is unknown here (partial_gpu_fps belongs to the last GPU capture); budget for a 5 fps game.
	var limit_ms := int(Pacing.gpu_timeout_sec(frames, minf(fps, 5.0)) * 1000.0)
	while Time.get_ticks_msec() - started < limit_ms:
		await Engine.get_main_loop().process_frame
		var game_now: Dictionary = debugger_plugin.take_game_profile()
		var game_n := 0
		if typeof(game_now.get("frames", [])) == TYPE_ARRAY:
			game_n = game_now.get("frames", []).size()
		if debugger_plugin.profile_frame_count() >= frames:
			break
		if game_n >= frames and (not listener or Time.get_ticks_msec() - started > 1500):
			break
		var session = debugger_plugin._get_active_session()
		if session == null or session.is_breaked():
			break
	if servers_started:
		debugger_plugin.stop_servers_profiler(include_visual)
	var taken: Dictionary = debugger_plugin.take_profile()
	var server_frames: Array = taken.get("frames", [])
	var game: Dictionary = debugger_plugin.take_game_profile()
	var game_frames: Array = game.get("frames", [])
	var summary: Dictionary = {}
	var source := ""
	if not server_frames.is_empty():
		summary = Parse.summarize_profile(server_frames)
		source = "servers:profile_frame"
	elif not game_frames.is_empty():
		summary = Parse.summarize_profile(game_frames)
		source = str(game.get("source", "engine_profiler_tick"))
	var paused_session = debugger_plugin._get_active_session()
	if int(summary.get("frame_count", 0)) <= 0 and paused_session != null and paused_session.is_breaked():
		return {"error": "The game is paused in the debugger (breakpoint or error); continue it and profile again."}
	if int(summary.get("frame_count", 0)) <= 0 and paused_session == null:
		return {"error": "The game stopped before script_profile finished."}
	if int(summary.get("frame_count", 0)) <= 0:
		return {"error": "The running game did not return render_lens:profile and no servers:profile_frame arrived. The debugger session was active. Script timing is collected in the game (EngineProfiler._tick on render_lens_scripts), not by searching the editor UI for the debugger panel."}
	var note := str(game.get("note", ""))
	if source == "servers:profile_frame":
		note = "Per-function rows are ServersProfilerFrame values. Script self/total times are seconds (microseconds / 1000000 in servers_debugger.cpp). servers:profile_frame is consumed by ScriptEditorDebugger before EditorDebuggerPlugin._capture on 4.4 and 4.7; the session tab's parent debugger emits debug_data for that message. Header times also match EngineProfiler._tick."
	return {
		"applied": false,
		"error": "",
		"profiler": source,
		"scripts_profiler": "included in the servers profiler when those frames arrived; EngineProfiler._tick has no per-function script times",
		"include_visual": include_visual,
		"requested_frames": frames,
		"max_functions": max_functions,
		"session_listener": listener,
		"servers_profiler_started": servers_started,
		"summary": summary,
		"visual_frames": taken.get("visual_frames", []),
		"note": note,
	}


static func _summary(payload: Dictionary) -> Dictionary:
	var summary: Dictionary = payload.get("summary", {})
	var functions: Array = summary.get("script_functions", [])
	var top: Array = []
	for item in functions:
		if top.size() >= 8:
			break
		top.append(item)
	return {
		"path": payload.get("path", ""),
		"applied": false,
		"profiler": payload.get("profiler", ""),
		"scripts_profiler": payload.get("scripts_profiler", ""),
		"frame_count": summary.get("frame_count", 0),
		"frame_time_sec": summary.get("frame_time_sec", 0.0),
		"process_time_sec": summary.get("process_time_sec", 0.0),
		"physics_time_sec": summary.get("physics_time_sec", 0.0),
		"script_time_sec": summary.get("script_time_sec", 0.0),
		"top_self_sec": summary.get("top_self_sec", 0.0),
		"top_functions": top,
		"servers": summary.get("servers", []),
		"include_visual": payload.get("include_visual", false),
		"note": payload.get("note", ""),
	}


static func _error(message: String) -> Dictionary:
	return {"isError": true, "content": [{"type": "text", "text": message}]}
