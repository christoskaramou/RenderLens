extends Node

const Game = preload("res://addons/render_lens/game_bridge.gd")

## frame_timing Tool
## Measures GPU/CPU frame timing with warm-up, percentiles, budget analysis
## Warm-up drop, target-FPS budget, GPU/CPU-bound hint
## Read-only

const Context = preload("res://addons/render_lens/context.gd")
const FileHelper = preload("res://addons/render_lens/file_helper.gd")
const Samples = preload("res://addons/render_lens/frame_samples.gd")
const Pacing = preload("res://addons/render_lens/pacing.gd")

static func execute(params: Dictionary) -> Dictionary:
	if Engine.is_editor_hint() and str(params.get("source", "game")) != "editor":
		return await Game.request(params, "frame_timing", 135.0)
	"""Execute frame_timing tool"""
	var frames: int = params.get("frames", 120)
	var warmup: int = params.get("warmup", 10)
	var target_fps: int = params.get("target_fps", 60)
	
	# Validate params
	if frames < 10 or frames > 1000:
		return _build_error("frames must be between 10 and 1000")
	
	# Warm-up frames are dropped before sampling and do not count toward frames (schema: 0-frames).
	if warmup < 0 or warmup > frames:
		return _build_error("warmup must be between 0 and frames")
	
	if target_fps < 1 or target_fps > 240:
		return _build_error("target_fps must be between 1 and 240")
	
	# Context
	var ctx := Context.capture()
	
	# source=editor measures the editor itself; its own V-Sync and frame cap stay as they are.
	var caps := {} if Engine.is_editor_hint() else Pacing.uncap()
	var captured: Dictionary = await Samples.collect(frames, warmup, 0.0, params)
	Pacing.restore(caps)
	var samples: Array = captured.samples
	if samples.is_empty():
		return _build_error("No frame samples arrived before the capture deadline")
	if captured.scene_changed:
		return _build_error("The running scene changed during measurement; capture the new scene again")
	var partial: bool = captured.partial

	# Compute statistics
	var stats := _compute_stats(samples, target_fps)
	stats.context = ctx
	stats.source = captured.source
	stats.scene = captured.scene
	stats.process_source = captured.process_source
	stats.elapsed_seconds = captured.elapsed_seconds
	stats.partial = partial
	stats.params = {
		"frames": frames,
		"warmup": warmup,
		"target_fps": target_fps
	}
	var sampled_ms := float(stats.timing.median_ms)
	stats["uncapped"] = Pacing.uncapped(caps, 1000.0 / sampled_ms if sampled_ms > 0.05 else 0.0)
	var embed_note := str(params.get("_embedded_play_note", Pacing.current_embedded_play_note()))
	stats["embedded_play_note"] = embed_note
	
	# Write to file
	var path := FileHelper.write_json(stats, "frame_timing")
	if path.is_empty():
		return _build_error("Failed to write frame timing data")
	
	var median_ms := float(stats.timing.median_ms)
	var median_fps := 1000.0 / median_ms if median_ms > 0.05 else 0.0
	var summary := {
		"path": path,
		"source": captured.source,
		"scene": captured.scene,
		"timing_note": "Frame percentiles measure wall-clock intervals. Process time includes renderer waits; it is not isolated CPU work.",
		"median_fps": "%.1f" % median_fps,
		"median_frame_ms": median_ms,
		"recent_monitor_fps": Engine.get_frames_per_second(),
		"target_fps": target_fps,
		"over_budget": "%.1f%%" % float(stats.budget.over_budget_percent),
		"bound": stats.bound,
		"partial": partial,
		"verdict": stats.summary.verdict,
		"uncapped": stats.uncapped,
	}
	if embed_note != "":
		summary["embedded_play_note"] = embed_note

	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify(summary, "\t")
		}]
	}

static func _compute_stats(samples: Array, target_fps: int) -> Dictionary:
	"""Compute timing statistics with percentiles and budget analysis"""
	if samples.size() == 0:
		return {"error": "No samples collected"}
	
	var budget_ms := 1000.0 / target_fps
	
	# Frame intervals and renderer components are distinct observations.
	var frame_times := []
	var cpu_times := []
	var gpu_times := []
	var process_times := []
	
	for sample in samples:
		frame_times.append(sample.frame_ms)
		cpu_times.append(sample.cpu_ms)
		gpu_times.append(sample.gpu_ms)
		process_times.append(float(sample.get("process_ms", 0.0)))
	
	# Sort for percentiles
	frame_times.sort()
	cpu_times.sort()
	gpu_times.sort()
	process_times.sort()
	
	var n := frame_times.size()
	
	# Compute percentiles
	var stats := {}
	stats.timing = {
		"avg_ms": _average(frame_times),
		"median_ms": _percentile(frame_times, 50),
		"p95_ms": _percentile(frame_times, 95),
		"p99_ms": _percentile(frame_times, 99),
		"max_ms": frame_times[n - 1],
		"min_ms": frame_times[0],
		"one_percent_low_ms": _percentile(frame_times, 99),
	}
	
	stats.cpu = {
		"avg_ms": _average(cpu_times),
		"median_ms": _percentile(cpu_times, 50),
		"p95_ms": _percentile(cpu_times, 95),
	}
	
	stats.gpu = {
		"avg_ms": _average(gpu_times),
		"median_ms": _percentile(gpu_times, 50),
		"p95_ms": _percentile(gpu_times, 95),
	}
	
	stats.process = {
		"avg_ms": _average(process_times),
		"median_ms": _percentile(process_times, 50),
		"p95_ms": _percentile(process_times, 95),
	}
	
	# Budget analysis
	var over_budget := 0
	for t in frame_times:
		if t > budget_ms:
			over_budget += 1
	
	stats.budget = {
		"target_fps": target_fps,
		"budget_ms": budget_ms,
		"over_budget_frames": over_budget,
		"over_budget_percent": (over_budget / float(n)) * 100.0,
		"headroom_ms": budget_ms - stats.timing.median_ms,
	}
	
	# A renderer wait is not isolated CPU work.
	# An underflowed viewport counter is already stored as 0 and must not win this vote.
	stats.bound = Pacing.bound_label(float(stats.timing.median_ms), float(stats.gpu.median_ms))
	
	# Quality assessment
	var quality := "ok"
	if n < 60:
		quality = "insufficient"
	elif stats.timing.median_ms > budget_ms * 1.5:
		quality = "poor"
	elif stats.timing.p99_ms > budget_ms * 2.0:
		quality = "inconsistent"
	
	# Check for spikiness (high variance)
	var variance_ratio: float = stats.timing.p95_ms / stats.timing.median_ms if stats.timing.median_ms > 0.01 else 1.0
	if variance_ratio > 3.0:
		quality = "spiky"
	
	stats.quality = quality
	
	# Summary
	stats.summary = _build_summary(stats)
	
	return stats

static func _build_summary(stats: Dictionary) -> Dictionary:
	"""Build human-readable summary"""
	var timing: Dictionary = stats.timing
	var budget: Dictionary = stats.budget
	
	return {
		"frame_time_median_ms": "%.2f" % timing.median_ms,
		"median_fps": "%.1f" % (1000.0 / maxf(float(timing.median_ms), 0.001)),
		"target_fps": budget.target_fps,
		"over_budget_percent": "%.1f%%" % budget.over_budget_percent,
		"bound": stats.bound,
		"quality": stats.quality,
		"verdict": _get_verdict(stats)
	}

static func _get_verdict(stats: Dictionary) -> String:
	"""Get human-readable verdict"""
	var quality: String = stats.quality
	var budget: Dictionary = stats.budget
	var bound: String = stats.bound
	
	if quality == "insufficient":
		return "Need more samples (at least 60 frames)"
	
	if quality == "gpu_idle_inflated?":
		return "Very low GPU/CPU time - may be inflated due to power states"
	
	var over_pct: float = budget.over_budget_percent
	
	if over_pct > 50:
		return "Over budget %.0f%% of the time; bottleneck hint: %s" % [over_pct, bound]
	elif over_pct > 10:
		return "Occasionally over budget (%.0f%%); bottleneck hint: %s" % [over_pct, bound]
	else:
		return "Hitting target (%.0f%% over); bottleneck hint: %s" % [over_pct, bound]

static func _average(arr: Array) -> float:
	"""Compute average"""
	if arr.size() == 0:
		return 0.0
	var sum := 0.0
	for v in arr:
		sum += v
	return sum / arr.size()

static func _percentile(sorted_arr: Array, p: float) -> float:
	"""Compute percentile from sorted array"""
	if sorted_arr.size() == 0:
		return 0.0
	
	var index := (p / 100.0) * (sorted_arr.size() - 1)
	var lower := int(floor(index))
	var upper := int(ceil(index))
	
	if lower == upper:
		return sorted_arr[lower]
	
	var weight := index - lower
	return sorted_arr[lower] * (1.0 - weight) + sorted_arr[upper] * weight

static func _build_error(message: String) -> Dictionary:
	"""Build error result"""
	return {
		"isError": true,
		"content": [{
			"type": "text",
			"text": message
		}]
	}
