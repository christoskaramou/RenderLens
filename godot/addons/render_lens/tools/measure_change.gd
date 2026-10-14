extends Node

## measure_change
## Tries a change in the running game only: measures the frame (A), applies the change and measures again (B), restores
## it and measures once more (A again). Saving = mean of the two A captures minus B; the drift between the A captures is
## the noise. Nothing in the project is changed.

const Game = preload("res://addons/render_lens/game_bridge.gd")
const Rules = preload("res://addons/render_lens/rule_engine.gd")
const GpuPasses = preload("res://addons/render_lens/tools/gpu_passes.gd")
const FrameTiming = preload("res://addons/render_lens/tools/frame_timing.gd")
const Advise = preload("res://addons/render_lens/tools/advise.gd")
const FileHelper = preload("res://addons/render_lens/file_helper.gd")
## A difference below this is never called a saving, however quiet the run (timer and scheduling jitter).
const MIN_EFFECT_MS := 0.05
const MIN_PASS_EFFECT_MS := 0.02
const PASS_ROWS := 12

static func execute(params: Dictionary) -> Dictionary:
	var frames := int(params.get("frames", 60))
	if frames < 10 or frames > 300:
		return Game.error("frames must be between 10 and 300")
	var settle := float(params.get("settle_seconds", 1.0))
	if settle < 0.0 or settle > 10.0:
		return Game.error("settle_seconds must be between 0 and 10")
	var changes = params.get("changes", [])
	var finding := str(params.get("finding", ""))
	if finding != "":
		if typeof(changes) == TYPE_ARRAY and not changes.is_empty():
			return Game.error("Pass either finding or changes, not both")
		changes = _finding_changes(finding)
		if typeof(changes) == TYPE_STRING:
			return Game.error(changes)
	if typeof(changes) != TYPE_ARRAY or changes.is_empty():
		return Game.error("Pass changes (a non-empty array) or finding (the id of a finding with a ready-made experiment)")
	var debugger = params.get("_debugger_plugin")
	if debugger == null or not debugger.has_method("request_measurement"):
		return Game.error("Start the game from the editor to measure a change in it.")
	var started := Time.get_ticks_msec()
	var first := await _capture(debugger, frames, true)
	if first.has("error"):
		return Game.error(str(first.error))
	# The game undoes the change by itself after this long, should the restore below never arrive (plugin disabled,
	# editor closed): the "with change" capture takes about as long as the first one.
	var lease := settle + 3.0 * (Time.get_ticks_msec() - started) / 1000.0 + 30.0
	var applied: Dictionary = await Game.request({"_debugger_plugin": debugger, "action": "apply", "changes": changes, "lease_seconds": lease}, "experiment", 20.0)
	if applied.get("isError", false):
		# A refused change undoes itself in the game, but a timeout or a pause does not prove it was never applied.
		var undone := await _restore(debugger)
		return Game.error("%s (%s)" % [Game.error_text(applied), undone.get("note", undone.get("error", "nothing was left applied"))])
	await _wait(settle)
	var changed := await _capture(debugger, frames, first.has("gpu_ms"))
	# Restored on every path: a failed capture must not leave the game running with the change.
	var restored := await _restore(debugger)
	if changed.has("error"):
		return Game.error("%s (%s)" % [changed.error, restored.get("note", restored.get("error", "the change was restored"))])
	if restored.has("error"):
		return Game.error(str(restored.error))
	if restored.get("expired", false):
		return Game.error("The game undid the change on its own (its %.0f s lease ran out) before the capture with the change finished, so that capture is not the change. Retry with fewer frames." % lease)
	await _wait(settle)
	var last := await _capture(debugger, frames, first.has("gpu_ms"))
	if last.has("error"):
		return Game.error(str(last.error))
	if not (first.scene == changed.scene and changed.scene == last.scene):
		return Game.error("The running scene changed during the experiment (%s, %s, %s), so the captures do not compare." % [first.scene, changed.scene, last.scene])
	var truncated: bool = first.has("gpu_ms") and (first.truncated or changed.truncated or last.truncated)
	# The timestamp span of a frame cut off at Godot's per-frame timestamp limit is not the frame's GPU time.
	var gpu_compares: bool = first.has("gpu_ms") and first.gpu_source == changed.gpu_source and changed.gpu_source == last.gpu_source and not (truncated and first.gpu_source == "timestamp span")
	# The frame and GPU captures sample the same machine: when either drifted between the two "before" captures (another
	# program on the GPU, clock changes), every value was that unsteady, though its own two captures may agree by chance
	# (seen 2026-10-14 with a game running beside the TPS demo: frame drift 0.1 ms, GPU drift 2.5 ms in the same phases).
	var drift := _drift(first.frame_ms, last.frame_ms)
	if gpu_compares:
		drift = maxf(drift, _drift(first.gpu_ms, last.gpu_ms))
	var result := {
		"applied_to_project": false,
		"scene": first.scene,
		"changes": applied.get("applied", []),
		"frames_per_capture": frames,
		"frame_ms": _compare(first.frame_ms, changed.frame_ms, last.frame_ms, MIN_EFFECT_MS, drift),
		"run_drift_percent": snappedf(drift * 100.0, 0.1),
		"method": "Three captures in the running game: before (A), with the change (B), after restoring it (A again). saving_ms = mean(A) - B; noise_ms = |A1 - A2|, or the run's drift (run_drift_percent, the larger relative A1/A2 change of frame and GPU time) of the value when that is larger; a saving within the noise (or under %.2f ms) is reported as within_noise. Frame times are frame_timing medians, GPU times gpu_passes medians, all with V-Sync and max_fps off. Another program using the GPU can shift the capture with the change alone, which no noise estimate catches; repeat the call before acting on a surprising verdict." % MIN_EFFECT_MS,
	}
	if restored.has("note"):
		result["restore_note"] = restored.note
	var notes: Array = applied.get("notes", [])
	if not notes.is_empty():
		result["notes"] = notes
	if first.has("gpu_ms"):
		if gpu_compares:
			result["gpu_frame_ms"] = _compare(first.gpu_ms, changed.gpu_ms, last.gpu_ms, MIN_EFFECT_MS, drift)
			result["gpu_frame_source"] = first.gpu_source
		else:
			result["gpu_frame_note"] = "No GPU frame time compares across the three captures: Godot's viewport GPU counter was unusable in some (it fails in frames past the timestamp limit) and the timestamp span of a cut-off frame is not the frame. frame_ms and pass_changes still compare."
		result["pass_changes"] = _pass_changes(first.passes, changed.passes, last.passes, [first.truncated, changed.truncated, last.truncated], [first.calls, changed.calls, last.calls], drift)
		result["captures"] = [first.path, changed.path, last.path]
		if truncated:
			result["truncation_note"] = "Some frames reached debug/settings/profiler/max_timestamp_query_elements, so passes after the limit were not timed; only passes timed in all three captures are compared. Raise the setting for a full breakdown."
	else:
		result["gpu_note"] = first.gpu_note
	var path := FileHelper.write_json(result, "measure_change")
	if path.is_empty():
		return Game.error("Failed to write the measure_change result")
	result["path"] = path
	return {"content": [{"type": "text", "text": JSON.stringify(result, "\t")}]}


static func _finding_changes(id: String):
	for rule in Rules.load_rules():
		if typeof(rule) == TYPE_DICTIONARY and str(rule.get("id", "")) == id:
			if rule.has("experiment"):
				return rule.experiment
			return "%s has no ready-made experiment; pass changes yourself (it names setting %s and node property %s)" % [id, str(rule.get("setting", "")) if rule.get("setting") else "none", str(rule.get("node_property", "")) if rule.get("node_property") else "none"]
	return "Unknown finding id: " + id


## Restores through a measurement request, which confirms it; when that is refused (a paused game, another measurement
## still running), the restore message the bridge applies without a reply is sent instead.
static func _restore(debugger) -> Dictionary:
	var restored: Dictionary = await Game.request({"_debugger_plugin": debugger, "action": "restore"}, "experiment", 20.0)
	if not restored.get("isError", false):
		return restored
	if debugger.has_method("send_experiment_restore") and debugger.send_experiment_restore():
		return {"note": "The game did not confirm the restore (%s); a restore message was sent that the game applies even while paused." % Game.error_text(restored)}
	return {"error": "The change could not be restored (%s); it lasts until the game restarts." % Game.error_text(restored)}


## The tools answer with their summary as MCP text; the full capture is in the file it names (as advise reads them).
static func _capture(debugger, frames: int, gpu: bool) -> Dictionary:
	var timing_call: Dictionary = await FrameTiming.execute({"frames": frames, "warmup": 10, "_debugger_plugin": debugger})
	if timing_call.get("isError", false):
		return {"error": Game.error_text(timing_call)}
	var timing = JSON.parse_string(Advise._text_of(timing_call))
	if typeof(timing) != TYPE_DICTIONARY or not timing.has("median_frame_ms") or bool(timing.get("partial", false)):
		return {"error": "frame_timing returned no complete capture: " + Advise._text_of(timing_call).left(200)}
	var out := {"frame_ms": float(timing.median_frame_ms), "scene": str(timing.get("scene", ""))}
	if not gpu:
		return out
	var pass_call: Dictionary = await GpuPasses.execute({"frames": frames, "_debugger_plugin": debugger})
	# A capture without timestamps although the game drew frames (the visual profiler toggle did not take) is tried once
	# more; a game that drew no frames (minimized) gets its own error from the recorder and is not retried.
	if pass_call.get("isError", false) and Game.error_text(pass_call).contains("timestamp capture not enabled"):
		pass_call = await GpuPasses.execute({"frames": frames, "_debugger_plugin": debugger})
	if pass_call.get("isError", false):
		var message := Game.error_text(pass_call)
		# Compatibility and the Separate thread model have no pass timing; frame time still compares.
		if message.contains("Compatibility") or message.contains("Separate"):
			out["gpu_note"] = message
			return out
		return {"error": message}
	var data: Dictionary = Advise._read_written(pass_call)
	if data.is_empty() or bool(data.get("partial", false)):
		return {"error": "gpu_passes returned no complete capture: " + Advise._text_of(pass_call).left(200)}
	if str(data.get("scene", out.scene)) != out.scene:
		return {"error": "The running scene changed between the frame and GPU captures (%s, %s)." % [out.scene, data.get("scene")]}
	var by_name := {}
	var calls := {}
	var frame_count := int(data.get("frame_count", 0))
	for row in data.get("passes", []):
		by_name[str(row.get("name", ""))] = float(row.get("exclusive_median_ms", 0.0))
		# Runs per frame, or -1 when they varied between frames or the pass was missing from some frames (some frames
		# were cut off before it, so its median is over a biased subset).
		var uneven: bool = bool(row.get("calls_vary", false)) or bool(row.get("incomplete", false)) or int(row.get("frames", frame_count)) < frame_count
		calls[str(row.get("name", ""))] = -1 if uneven else int(row.get("calls_per_frame", 1))
	# Godot's viewport GPU counter is not cut off by the timestamp limit; the timestamp span is the fallback.
	var viewport := float(data.get("median_viewport_gpu_ms", -1.0))
	out["gpu_ms"] = viewport if viewport > 0.0 else float(data.get("median_frame_gpu_ms", 0.0))
	out["gpu_source"] = "viewport counter" if viewport > 0.0 else "timestamp span"
	out["truncated"] = int(data.get("timestamp_truncated_frames", 0)) > 0
	out["passes"] = by_name
	out["calls"] = calls
	out["path"] = str(JSON.parse_string(Advise._text_of(pass_call)).get("path", ""))
	return out


## Relative change between the two "before" captures.
static func _drift(a1: float, a2: float) -> float:
	return absf(a1 - a2) / ((a1 + a2) / 2.0) if a1 + a2 > 0.0 else 0.0


## drift: the run's relative A1/A2 drift, a noise floor in proportion to the value.
static func _compare(a1: float, b: float, a2: float, floor_ms: float, drift := 0.0) -> Dictionary:
	var before := (a1 + a2) / 2.0
	var saving := before - b
	var noise := maxf(absf(a1 - a2), drift * before)
	var verdict := "within_noise"
	if absf(saving) > maxf(noise, floor_ms):
		verdict = "faster" if saving > 0.0 else "slower"
	return {
		"before": snappedf(before, 0.001),
		"with_change": snappedf(b, 0.001),
		"saving_ms": snappedf(saving, 0.001),
		"saving_percent": snappedf(saving / before * 100.0, 0.1) if before > 0.0 else 0.0,
		"noise_ms": snappedf(noise, 0.001),
		"verdict": verdict,
	}


## Passes whose time moved by more than their own A1/A2 drift. A pass that appears or disappears counts as 0 ms where it
## is missing, except in a capture that was cut off at the timestamp limit (cut[i]): a pass missing there may only be past
## the limit. With any capture cut off, a pass is compared only when it ran as many times per frame in each capture that
## has it (calls[i]), because a pass repeated per viewport can be cut off after its first run.
static func _pass_changes(a1: Dictionary, b: Dictionary, a2: Dictionary, cut := [false, false, false], calls := [{}, {}, {}], drift := 0.0) -> Array:
	var maps := [a1, b, a2]
	var names := {}
	for map in maps:
		for name in map:
			if not range(3).all(func(i): return maps[i].has(name) or not cut[i]):
				continue
			var runs := {}
			for i in 3:
				if maps[i].has(name):
					runs[int(calls[i].get(name, 1))] = true
			if not cut.has(true) or (runs.size() == 1 and not runs.has(-1)):
				names[name] = true
	var rows: Array = []
	for name in names:
		var row := _compare(float(a1.get(name, 0.0)), float(b.get(name, 0.0)), float(a2.get(name, 0.0)), MIN_PASS_EFFECT_MS, drift)
		if row.verdict != "within_noise":
			row["name"] = name
			rows.append(row)
	rows.sort_custom(func(x, y): return absf(x.saving_ms) > absf(y.saving_ms) if absf(x.saving_ms) != absf(y.saving_ms) else str(x.name) < str(y.name))
	return rows.slice(0, PASS_ROWS)


static func _wait(seconds: float) -> void:
	if seconds > 0.0:
		await (Engine.get_main_loop() as SceneTree).create_timer(seconds).timeout
