extends Node

## advise
## Ranks the shared rule set by measured pass share, then severity.
## Reads collect_metrics, scan_scene, frame_timing, and gpu_passes when a game is running.
## Does not apply changes.

const FileHelper = preload("res://addons/render_lens/file_helper.gd")
const Rules = preload("res://addons/render_lens/rule_engine.gd")
const Advisor = preload("res://addons/render_lens/advisor_context.gd")
const CollectMetrics = preload("res://addons/render_lens/tools/collect_metrics.gd")
const ScanScene = preload("res://addons/render_lens/tools/scan_scene.gd")
const FrameTiming = preload("res://addons/render_lens/tools/frame_timing.gd")
const GpuPasses = preload("res://addons/render_lens/tools/gpu_passes.gd")
const ScriptProfile = preload("res://addons/render_lens/tools/script_profile.gd")
const VramReport = preload("res://addons/render_lens/tools/vram_report.gd")
const Audit = preload("res://addons/render_lens/tools/audit_project_rendering.gd")
const Game = preload("res://addons/render_lens/game_bridge.gd")
const Pacing = preload("res://addons/render_lens/pacing.gd")

static func execute(params: Dictionary) -> Dictionary:
	var target_fps := int(params.get("target_fps", 60))
	if target_fps < 15 or target_fps > 240:
		return _error("target_fps must be between 15 and 240")
	var top_n := int(params.get("top", 8))
	if top_n < 1:
		top_n = 1
	if top_n > 40:
		top_n = 40
	var focus := str(params.get("focus", "all"))
	if focus != "all" and not Rules.AREAS.has(focus):
		return _error("focus must be all, performance, visual, missing or to_check")
	var timing_frames := int(params.get("timing_frames", 40))
	var pass_frames := int(params.get("pass_frames", 30))

	if str(params.get("scene", "")) != "" or str(params.get("source", "game")) == "editor":
		return _error("advise measures the running scene. Use audit_project_rendering for an explicit scene or editor-only audit.")
	var scanned: Dictionary = await ScanScene.gather(params)
	if str(scanned.get("error", "")) != "":
		return _error(str(scanned.error))
	var gathered: Dictionary = await CollectMetrics.gather(params)
	if gathered.get("active_source") != "game":
		return _error("Game metrics were unavailable: " + str(gathered.get("game_error", "")))
	var active: Dictionary = gathered.get("active", {})

	var timing_note := ""
	var timing := {}
	var timing_call: Dictionary = await FrameTiming.execute({
		"frames": timing_frames,
		"_debugger_plugin": params.get("_debugger_plugin"),
		"warmup": mini(8, maxi(0, timing_frames - 1)),
		"target_fps": target_fps,
	})
	if timing_call.get("isError", false):
		timing_note = _text_of(timing_call)
	else:
		timing = _read_written(timing_call)
		# Sampled while Render Lens does nothing else in the game; the TIME_PROCESS peak also catches its scene scan.
		_put_metric(active, "PROCESS_MEDIAN_SEC", float(timing.get("process", {}).get("median_ms", 0.0)) / 1000.0)

	var pass_note := ""
	var pass_summary := {}
	var passes: Array = []
	var debugger_plugin = params.get("_debugger_plugin")
	var renderer := str(active.get("renderer", ""))
	if _game_running(debugger_plugin) and renderer != "gl_compatibility":
		var pass_call: Dictionary = await GpuPasses.execute({
			"frames": pass_frames,
			"_debugger_plugin": debugger_plugin,
		})
		if pass_call.get("isError", false):
			pass_note = _text_of(pass_call)
		else:
			pass_summary = _read_written(pass_call)
			var listed = pass_summary.get("passes", [])
			if bool(pass_summary.get("partial", false)):
				# A timed-out capture can be a few frames; ranking findings by its shares would mislead.
				pass_note = "gpu_passes timed out with a partial capture, so measured pass shares were not used."
				pass_summary = {}
			elif typeof(listed) == TYPE_ARRAY:
				passes = listed
	elif renderer == "gl_compatibility":
		pass_note = "gpu_passes is not available on the Compatibility renderer."
	else:
		pass_note = "No running game, so gpu_passes was not recorded."

	var profile_note := ""
	var vram_note := ""
	if _game_running(debugger_plugin):
		var profile_call: Dictionary = await ScriptProfile.gather({
			"frames": int(params.get("profile_frames", 12)),
			"max_functions": 32,
			"include_visual": false,
			"_debugger_plugin": debugger_plugin,
		})
		if str(profile_call.get("error", "")) != "":
			profile_note = str(profile_call.error)
		else:
			var summary: Dictionary = profile_call.get("summary", {})
			_put_metric(active, "PROFILE_FRAME_TIME_SEC", summary.get("frame_time_sec", 0.0))
			_put_metric(active, "PROFILE_PROCESS_TIME_SEC", summary.get("process_time_sec", 0.0))
			_put_metric(active, "PROFILE_PHYSICS_TIME_SEC", summary.get("physics_time_sec", 0.0))
			_put_metric(active, "PROFILE_SCRIPT_TIME_SEC", summary.get("script_time_sec", 0.0))
			_put_metric(active, "PROFILE_TOP_SELF_SEC", summary.get("top_self_sec", 0.0))
		var vram_call: Dictionary = await VramReport.gather({"_debugger_plugin": debugger_plugin})
		vram_note = str(vram_call.get("list_error", ""))
		_put_metric(active, "VRAM_LARGEST_BYTES", vram_call.get("largest_bytes", 0))
		var listed_total := float(vram_call.get("listed_total_bytes", 0))
		_put_metric(active, "VRAM_LISTED_TOTAL_BYTES", listed_total)
		if listed_total > 0.0:
			_put_metric(active, "VRAM_LISTED_HALF", listed_total / 2.0)
	else:
		profile_note = "No running game, so script_profile was not recorded."
		vram_note = "No running game, so the per-resource VRAM list was not collected."

	var game_metrics := {}
	if gathered.get("active_source") == "game":
		game_metrics = active.get("metrics", {})
	var embed_note := Pacing.current_embedded_play_note()
	if timing.is_empty():
		return _error("Game frame timing unavailable: " + timing_note)
	if str(timing.get("scene", "")) != str(active.get("scene", "")) or not scanned.get("scenes", []).has("scene:" + str(active.get("scene", ""))):
		return _error("The running scene changed between captures; repeat advise on the new scene")
	var final_metrics: Dictionary = await Game.request(params, "metrics_snapshot", 10.0)
	if final_metrics.get("isError", false) or str(final_metrics.get("scene", "")) != str(active.get("scene", "")):
		return _error("The game stopped or changed scenes during advice; capture again")
	if not pass_summary.is_empty() and str(pass_summary.get("scene", "")) != str(active.get("scene", "")):
		return _error("GPU passes came from a different scene; capture again")
	var frame: Dictionary = Advisor.choose_frame(target_fps, timing, game_metrics, pass_summary)
	if not frame.is_empty():
		frame["script_time_sec"] = float(game_metrics.get("PROFILE_SCRIPT_TIME_SEC", 0.0))
		frame["embed_note"] = embed_note
	var ctx: Dictionary = Advisor.make(active, scanned, frame, passes)
	var findings: Array = Rules.evaluate(ctx, "measured")
	var packed: Dictionary = Rules.package(findings, frame, top_n, "measured", focus)
	var payload := {
		"applied": false,
		"target_fps": target_fps,
		"rule_count": Rules.load_rules().size(),
		"inputs": {
			"metrics_source": gathered.get("active_source", "editor"),
			"metrics_game_error": gathered.get("game_error", ""),
			"scenes": scanned.get("scenes", []),
			"shader_scan": scanned.get("shader_scan", {}),
			"material_scan": scanned.get("material_scan", {}),
			"file_walk": scanned.get("file_walk", {}),
			"script_scan": scanned.get("script_scan", {}),
			"frame_timing_error": timing_note,
			"gpu_passes_error": pass_note,
			"pass_count": passes.size(),
			"gpu_passes_truncation": Pacing.timestamp_truncation_note(int(pass_summary.get("timestamp_truncated_frames", 0)), int(pass_summary.get("frame_count", 0)), int(pass_summary.get("timestamp_limit", 0))),
			"script_profile_error": profile_note,
			"vram_error": vram_note,
			"embedded_play_note": embed_note,
			"frame_timing_uncapped": timing.get("uncapped", {}),
			"gpu_passes_uncapped": pass_summary.get("uncapped", {}),
		},
		"headroom": packed.get("headroom", {}),
		"within_budget": packed.get("within_budget", null),
		"finding_count": packed.get("finding_count", 0),
		"focus": focus,
		"area_counts": packed.get("area_counts", {}),
		"godot_warned_count": packed.get("godot_warned_count", 0),
		"category_counts": Audit._categories(findings),
		"groups": Audit.group_findings(findings),
		"top": Audit._brief_list(packed.get("top", [])),
		"optional_quality": Audit._brief_list(packed.get("optional_quality", [])),
		"performance_findings": Audit._brief_list(packed.get("performance_findings", [])),
		"configuration_findings": Audit._brief_list(packed.get("configuration_findings", [])),
		"to_check": Audit._brief_list(packed.get("to_check", [])),
		"info": Audit._brief_list(packed.get("info", [])),
		"findings": packed.get("findings", []),
	}
	var path := FileHelper.write_json(payload, "advise")
	if path.is_empty():
		return _error("Failed to write advise JSON")
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify({
				"path": path,
				"applied": false,
				"target_fps": target_fps,
				"rule_count": payload.rule_count,
				"within_budget": payload.within_budget,
				"headroom": payload.headroom,
				"inputs": payload.inputs,
				"finding_count": payload.finding_count,
				"category_counts": payload.category_counts,
				"groups": Audit.group_ids(findings),
				"focus": focus,
				"area_counts": payload.area_counts,
				"godot_warned_count": payload.godot_warned_count,
				"top": payload.top,
			}, "\t")
		}]
	}


static func _put_metric(snap: Dictionary, key: String, value) -> void:
	if typeof(snap) != TYPE_DICTIONARY:
		return
	var metrics = snap.get("metrics", {})
	if typeof(metrics) != TYPE_DICTIONARY:
		metrics = {}
	metrics[key] = value
	snap["metrics"] = metrics


static func _game_running(debugger_plugin) -> bool:
	if debugger_plugin == null or not debugger_plugin.has_method("get_debug_status"):
		return false
	var status: Dictionary = debugger_plugin.get_debug_status()
	return int(status.get("active_sessions", 0)) > 0


static func _text_of(result: Dictionary) -> String:
	var content = result.get("content", [])
	if typeof(content) == TYPE_ARRAY and content.size() > 0 and typeof(content[0]) == TYPE_DICTIONARY:
		return str(content[0].get("text", ""))
	return ""


static func _read_written(result: Dictionary) -> Dictionary:
	var summary = JSON.parse_string(_text_of(result))
	if typeof(summary) != TYPE_DICTIONARY:
		return {}
	var path := str(summary.get("path", ""))
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func _error(message: String) -> Dictionary:
	return {
		"isError": true,
		"content": [{"type": "text", "text": message}]
	}
