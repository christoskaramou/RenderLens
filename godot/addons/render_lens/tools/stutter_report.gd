extends Node

const Game = preload("res://addons/render_lens/game_bridge.gd")

## stutter_report Tool
## Detects stutters/hitches with attribution (GPU/CPU/physics/script/shader_compile)
## Spike = 2x local median AND +2ms, attribution by deepest >=50% source

const Samples = preload("res://addons/render_lens/frame_samples.gd")
const Context = preload("res://addons/render_lens/context.gd")
const FileHelper = preload("res://addons/render_lens/file_helper.gd")

const BASELINE_WINDOW := 64  # Frames for local median
const SPIKE_THRESHOLD_MULTIPLIER := 2.0
const SPIKE_THRESHOLD_MS := 2.0
const SLOWDOWN_MULTIPLIER := 1.25

static func execute(params: Dictionary) -> Dictionary:
	if Engine.is_editor_hint() and str(params.get("source", "game")) != "editor":
		return await Game.request(params, "stutter_report", 135.0)
	"""Execute stutter_report tool"""
	var seconds: float = params.get("seconds", 30.0)
	
	# Validate
	if seconds < 5.0 or seconds > 120.0:
		return _build_error("seconds must be between 5 and 120")
	
	var captured: Dictionary = await Samples.collect(0, 0, seconds, params)
	var frames: Array = captured.samples
	if captured.scene_changed:
		return _build_error("The running scene changed during the stutter capture")
	if frames.is_empty():
		return _build_error("Failed to collect frame data")
	
	# Guard against empty analysis
	if frames.size() < 10:
		return _build_error("Insufficient frames collected (%d frames, need at least 10)" % frames.size())
	
	# Analyze stutters
	var analysis := _analyze_stutters(frames)
	
	# Validate analysis has required fields
	if not analysis.has("verdict"):
		return _build_error("Analysis missing verdict field")
	if not analysis.has("frame_count"):
		return _build_error("Analysis missing frame_count field")
	
	# Add context and params
	analysis["context"] = Context.capture()
	analysis["params"] = {"seconds": seconds, "frames_collected": frames.size()}
	analysis["elapsed_seconds"] = captured.elapsed_seconds
	analysis["partial"] = captured.partial
	
	# Write to file
	var path := FileHelper.write_json(analysis, "stutter_report")
	if path.is_empty():
		return _build_error("Failed to write stutter report")
	
	# Build summary
	var summary := {
		"path": path,
		"verdict": analysis.verdict,
		"hitch_count": analysis.get("hitch_count", 0),
		"slowdown_count": analysis.get("slowdown_count", 0),
		"duration_seconds": captured.elapsed_seconds,
		"source": captured.source,
		"scene": captured.scene,
		"partial": captured.partial,
		"frame_count": analysis.frame_count
	}
	
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify(summary, "\t")
		}]
	}

static func _analyze_stutters(frames: Array) -> Dictionary:
	"""Analyze frames for stutters/hitches"""
	var hitches := []
	var slowdowns := []
	var baseline_window := []
	var component_windows := {"gpu_ms": [], "cpu_ms": [], "physics_ms": []}
	
	for i in range(frames.size()):
		var frame: Dictionary = frames[i]
		var total_ms: float = frame.total_ms
		
		# Build baseline window (last N frames)
		baseline_window.append(total_ms)
		if baseline_window.size() > BASELINE_WINDOW:
			baseline_window.pop_front()
		for key in component_windows:
			component_windows[key].append(float(frame.get(key, 0.0)))
			if component_windows[key].size() > BASELINE_WINDOW:
				component_windows[key].pop_front()
		
		# Need enough frames for baseline
		if baseline_window.size() < 30:
			continue
		
		# Compute local median
		var sorted_baseline := baseline_window.duplicate()
		sorted_baseline.sort()
		var median: float = sorted_baseline[sorted_baseline.size() / 2]
		
		# Check for spike (2x median AND +2ms)
		var is_spike: bool = total_ms >= (median * SPIKE_THRESHOLD_MULTIPLIER) and \
						total_ms >= (median + SPIKE_THRESHOLD_MS)
		
		# Check for slowdown (1.25-2x median, but ignore frames under 25% of 16.67ms budget)
		var absolute_floor_ms := 4.17  # 25% of 60fps budget - ignore micro-variations
		var is_slowdown: bool = not is_spike and \
						   total_ms >= (median * SLOWDOWN_MULTIPLIER) and \
						   total_ms < (median * SPIKE_THRESHOLD_MULTIPLIER) and \
						   total_ms >= absolute_floor_ms
		
		if is_spike:
			# Attribute spike
			var attribution := _attribute_spike(frame, median, _medians(component_windows))
			
			hitches.append({
				"frame": i,
				"total_ms": total_ms,
				"baseline_ms": median,
				"excess_ms": total_ms - median,
				"multiplier": total_ms / median,
				"side": attribution.side,
				"source": attribution.source
			})
		elif is_slowdown:
			# Attribute slowdown
			var attribution := _attribute_spike(frame, median, _medians(component_windows))
			
			slowdowns.append({
				"frame": i,
				"total_ms": total_ms,
				"baseline_ms": median,
				"excess_ms": total_ms - median,
				"multiplier": total_ms / median,
				"side": attribution.side,
				"source": attribution.source
			})
	
	# Merge consecutive hitches
	var merged_hitches := _merge_hitches(hitches)
	
	# Compute verdict
	var seconds := 0.0
	for frame in frames:
		seconds += float(frame.get("total_ms", 0.0)) / 1000.0
	var verdict := _compute_verdict(frames.size(), seconds, merged_hitches, slowdowns)
	
	return {
		"frame_count": frames.size(),
		"hitches": merged_hitches,
		"hitch_count": merged_hitches.size(),
		"slowdown_count": slowdowns.size(),
		"verdict": verdict,
		"sources": _summarize_sources(merged_hitches, slowdowns),
		"total_ms_lost_hitches": _sum_excess_ms(merged_hitches),
		"total_ms_lost_slowdowns": _sum_excess_ms(slowdowns)
	}

static func _medians(windows: Dictionary) -> Dictionary:
	var out := {}
	for key in windows:
		var sorted: Array = windows[key].duplicate()
		sorted.sort()
		out[key] = sorted[sorted.size() / 2] if not sorted.is_empty() else 0.0
	return out

static func _attribute_spike(frame: Dictionary, baseline_ms: float, component_baselines: Dictionary = {}) -> Dictionary:
	"""Attribute spike to side and source (deepest >=50% of excess)"""
	var excess_ms: float = frame.total_ms - baseline_ms
	var threshold: float = excess_ms * 0.5

	# Shader compile (Godot-specific)
	if frame.shader_compile:
		return {"side": "shader_compile", "source": "Pipeline compilation"}

	# GPU first, then CPU, then physics. Each is judged by its increase over its own recent median: an unchanged
	# 10 ms GPU frame does not explain a physics spike.
	for part in [["gpu", "gpu_ms", "GPU rendering"], ["cpu", "cpu_ms", "CPU rendering"], ["physics", "physics_ms", "Physics simulation"]]:
		if float(frame.get(part[1], 0.0)) - float(component_baselines.get(part[1], 0.0)) >= threshold:
			return {"side": part[0], "source": part[2]}

	# Process time includes rendering synchronization and cannot identify a script.
	return {"side": "unknown", "source": "Unattributed frame stall; inspect script_profile and GPU passes"}


static func _merge_hitches(hitches: Array) -> Array:
	"""Merge consecutive hitches into single events"""
	if hitches.is_empty():
		return []
	
	var merged := []
	var current_hitch = null
	
	for hitch in hitches:
		if current_hitch == null:
			current_hitch = hitch.duplicate()
			current_hitch.frame_count = 1
			current_hitch.frames = [hitch.frame]
		elif hitch.frame == current_hitch.frames[-1] + 1:
			# Consecutive frame
			current_hitch.frame_count += 1
			current_hitch.frames.append(hitch.frame)
			current_hitch.total_ms = maxf(current_hitch.total_ms, hitch.total_ms)
			current_hitch.excess_ms += hitch.excess_ms
		else:
			# Gap - save current and start new
			merged.append(current_hitch)
			current_hitch = hitch.duplicate()
			current_hitch.frame_count = 1
			current_hitch.frames = [hitch.frame]
	
	if current_hitch:
		merged.append(current_hitch)
	
	return merged

static func _compute_verdict(frame_count: int, captured_seconds: float, hitches: Array, slowdowns: Array) -> String:
	"""Compute verdict (insufficient/smooth/occasional/recurring)"""
	if frame_count < 60:
		return "insufficient"
	
	# Rates per minute use the captured frame times, not an assumed 60 fps.
	var seconds := captured_seconds if captured_seconds > 0.0 else frame_count / 60.0
	var hitches_per_min := (hitches.size() / seconds) * 60.0
	var total_issues := hitches.size() + slowdowns.size()
	var issues_per_min := (total_issues / seconds) * 60.0
	
	if hitches.is_empty() and slowdowns.is_empty():
		return "smooth"
	elif hitches.is_empty() and slowdowns.size() > 0:
		# Only slowdowns - grade separately
		if issues_per_min < 2.0:
			return "occasional_slowdown"
		else:
			return "uneven"
	elif hitches_per_min < 1.0:
		return "occasional"
	else:
		return "recurring"

static func _summarize_sources(hitches: Array, slowdowns: Array) -> Dictionary:
	"""Summarize hitch and slowdown sources"""
	var sources := {}
	
	for hitch in hitches:
		var side: String = hitch.side
		if not sources.has(side):
			sources[side] = 0
		sources[side] += 1
	
	for slowdown in slowdowns:
		var side: String = slowdown.side + "_slowdown"
		if not sources.has(side):
			sources[side] = 0
		sources[side] += 1
	
	return sources

static func _sum_excess_ms(events: Array) -> float:
	"""Sum excess ms from events"""
	var total := 0.0
	for event in events:
		total += event.get("excess_ms", 0.0)
	return total

static func _build_summary(analysis: Dictionary, path: String) -> Dictionary:
	"""Build summary for agent"""
	return {
		"path": path,
		"verdict": analysis.verdict,
		"hitch_count": analysis.hitch_count,
		"slowdown_count": analysis.slowdown_count,
		"sources": analysis.hitch_sources,
		"ms_lost": "%.1f" % analysis.total_ms_lost_hitches
	}

static func _build_error(message: String) -> Dictionary:
	return {
		"isError": true,
		"content": [{
			"type": "text",
			"text": message
		}]
	}
