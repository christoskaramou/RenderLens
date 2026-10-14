extends Node

const Game = preload("res://addons/render_lens/game_bridge.gd")

## session_summary Tool
## Records session timeline with 10s rows (median/p99/max/spikes)
## <=60 rows for model, trend analysis

const Samples = preload("res://addons/render_lens/frame_samples.gd")
const Stutters = preload("res://addons/render_lens/tools/stutter_report.gd")
const Context = preload("res://addons/render_lens/context.gd")
const FileHelper = preload("res://addons/render_lens/file_helper.gd")

const ROW_DURATION_SEC := 10.0
const MAX_ROWS := 60

static func execute(params: Dictionary) -> Dictionary:
	var duration_sec := float(params.get("duration", 300.0))  # 5 minutes default
	# Validated before the game request too: a negative duration made the editor's wait negative.
	if duration_sec < 30.0 or duration_sec > 600.0:
		return _build_error("duration must be between 30 and 600 seconds")
	if Engine.is_editor_hint() and str(params.get("source", "game")) != "editor":
		return await Game.request(params, "session_summary", duration_sec + 15.0)
	
	# The context is the scene being measured; a scene change ends the recording early.
	var context := Context.capture()
	var recording := {"scene_changed": false}
	var rows := await _record_session(duration_sec, params, recording)
	
	if rows.is_empty():
		return _build_error("The running scene changed before the first row was recorded" if recording.scene_changed else "Failed to record session")
	
	# Analyze trend
	var trend := _analyze_trend(rows)
	
	# Build summary
	var recorded := 0.0
	for row in rows:
		recorded += float(row.elapsed_seconds)
	var summary := {
		"duration_sec": duration_sec,
		"recorded_sec": recorded,
		"partial": recording.scene_changed,
		"row_count": rows.size(),
		"rows": rows,
		"trend": trend
	}
	if recording.scene_changed:
		summary["partial_reason"] = "The running scene changed; rows cover only the scene in context."
	
	summary.context = context
	
	# Write to file
	var path := FileHelper.write_json(summary, "session_summary")
	if path.is_empty():
		return _build_error("Failed to write session summary")
	
	# Build response
	var response := _build_summary(summary, path)
	
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify(response, "\t")
		}]
	}

static func _record_session(duration_sec: float, params: Dictionary = {}, recording: Dictionary = {}) -> Array:
	var deadline := Time.get_ticks_msec() + int(duration_sec * 1000.0)
	var rows: Array = []
	while Time.get_ticks_msec() < deadline and rows.size() < MAX_ROWS:
		var remaining := float(deadline - Time.get_ticks_msec()) / 1000.0
		var capture: Dictionary = await Samples.collect(0, 0, minf(ROW_DURATION_SEC, remaining), params)
		if capture.samples.is_empty() or capture.scene_changed:
			recording["scene_changed"] = capture.scene_changed
			break
		var times: Array = capture.samples.map(func(row): return float(row.total_ms))
		times.sort()
		var analysis: Dictionary = Stutters._analyze_stutters(capture.samples)
		rows.append({
			"row": rows.size(), "elapsed_seconds": capture.elapsed_seconds,
			"median_ms": times[times.size() / 2], "p99_ms": times[mini(times.size() - 1, int(times.size() * 0.99))],
			"max_ms": times.back(), "spike_count": analysis.hitch_count,
			"top_spike_side": _get_top_spike_side(analysis.hitches),
		})
		if bool(params.get("_cancel", {}).get("cancelled", false)):
			break
	return rows

static func _get_top_spike_side(spikes: Array) -> String:
	"""Get most common spike side"""
	if spikes.is_empty():
		return "none"
	
	var counts := {}
	for spike in spikes:
		var side: String = spike.side
		counts[side] = counts.get(side, 0) + 1
	
	var max_side := "none"
	var max_count := 0
	
	for side in counts:
		if counts[side] > max_count:
			max_count = counts[side]
			max_side = side
	
	return max_side

static func _analyze_trend(rows: Array) -> String:
	"""Analyze trend across rows"""
	if rows.size() < 3:
		return "insufficient"
	
	# Compare first third vs last third
	var third := rows.size() / 3
	
	var first_third := []
	var last_third := []
	
	for i in range(third):
		first_third.append(rows[i].median_ms)
	
	for i in range(rows.size() - third, rows.size()):
		last_third.append(rows[i].median_ms)
	
	var first_avg := _average(first_third)
	var last_avg := _average(last_third)
	
	var diff_percent := ((last_avg - first_avg) / first_avg) * 100.0
	
	if diff_percent > 10.0:
		return "rising"
	elif diff_percent < -10.0:
		return "falling"
	else:
		return "steady"

static func _build_summary(summary: Dictionary, path: String) -> Dictionary:
	"""Build response summary"""
	var rows: Array = summary.rows
	
	# Overall stats
	var all_medians := []
	var total_spikes := 0
	
	for row in rows:
		all_medians.append(row.median_ms)
		total_spikes += row.spike_count
	
	all_medians.sort()
	
	return {
		"path": path,
		"duration_sec": summary.duration_sec,
		"recorded_sec": "%.1f" % summary.recorded_sec,
		"partial": summary.partial,
		"partial_reason": summary.get("partial_reason", ""),
		"row_count": summary.row_count,
		"overall_median_ms": "%.1f" % all_medians[all_medians.size() / 2],
		"total_spikes": total_spikes,
		"trend": summary.trend
	}

static func _average(arr: Array) -> float:
	if arr.is_empty():
		return 0.0
	var sum := 0.0
	for v in arr:
		sum += v
	return sum / arr.size()

static func _build_error(message: String) -> Dictionary:
	return {
		"isError": true,
		"content": [{
			"type": "text",
			"text": message
		}]
	}
