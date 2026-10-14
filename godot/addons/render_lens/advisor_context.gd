extends RefCounted

const Pacing = preload("res://addons/render_lens/pacing.gd")

## Builds the dictionary rule_engine.gd evaluates.
## metrics_snap is a metrics_snapshot.gd result.
## scene_result is a scene_scan.gd result.


static func make(metrics_snap: Dictionary, scene_result: Dictionary, frame: Dictionary, passes: Array) -> Dictionary:
	var version := Engine.get_version_info()
	return {
		"renderer": str(metrics_snap.get("renderer", ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method"))),
		"version_major": int(metrics_snap.get("version_major", version.get("major", 0))),
		"version_minor": int(metrics_snap.get("version_minor", version.get("minor", 0))),
		"settings": metrics_snap.get("settings", {}),
		"scene": scene_result.get("counts", {}),
		"offenders": scene_result.get("offenders", {}),
		"metrics": metrics_snap.get("metrics", {}),
		"adapter": metrics_snap.get("adapter", {}),
		"frame": frame,
		"passes": normalize_passes(passes),
	}


static func normalize_passes(passes: Array) -> Array:
	var out: Array = []
	for raw in passes:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var share = raw.get("share", raw.get("share_pct", 0.0))
		out.append({
			"name": str(raw.get("name", "")),
			"exclusive_median_ms": float(raw.get("exclusive_median_ms", 0.0)),
			"share": float(share),
		})
	return out


static func frame_from_timing(timing: Dictionary) -> Dictionary:
	var samples: Dictionary = timing.get("timing", {})
	var budget: Dictionary = timing.get("budget", {})
	var median := float(samples.get("median_ms", 0.0))
	var budget_ms := float(budget.get("budget_ms", 0.0))
	var head := float(budget.get("headroom_ms", budget_ms - median))
	var process_ms := float(timing.get("process", {}).get("median_ms", 0.0))
	var cpu_ms := process_ms if process_ms > 0.05 else float(timing.get("cpu", {}).get("median_ms", 0.0))
	var gpu_ms := Pacing.sane_viewport_ms(float(timing.get("gpu", {}).get("median_ms", 0.0)))
	if gpu_ms < 0.0:
		gpu_ms = 0.0
	var frame := {
		"budget_ms": budget_ms,
		"median_ms": median,
		"median_gpu_ms": gpu_ms,
		"headroom_ms": head,
		"over_budget": Pacing.over_budget(median, budget_ms),
		"bound": str(timing.get("bound", "")),
		"over_budget_percent": _percent(median, budget_ms, budget.get("over_budget_percent", 0.0)),
		"source": "frame_timing",
		"process_frame_ms": cpu_ms,
		"gpu_span_ms": gpu_ms,
		"gpu_span_over_budget_percent": Pacing.median_overrun_percent(gpu_ms, budget_ms),
	}
	return frame


static func frame_from_measured(median_ms: float, target_fps: int, bound: String, source: String, cpu_ms: float, gpu_ms: float) -> Dictionary:
	var budget_ms := 1000.0 / float(target_fps)
	var head := budget_ms - median_ms
	return {
		"budget_ms": budget_ms,
		"median_ms": median_ms,
		"median_cpu_ms": cpu_ms,
		"median_gpu_ms": gpu_ms,
		"headroom_ms": head,
		"over_budget": Pacing.over_budget(median_ms, budget_ms),
		"bound": bound,
		"over_budget_percent": Pacing.median_overrun_percent(median_ms, budget_ms),
		"source": source,
	}


static func _percent(median_ms: float, budget_ms: float, frame_fraction) -> float:
	var fraction := float(frame_fraction)
	var overrun := Pacing.median_overrun_percent(median_ms, budget_ms)
	if overrun > 0.0 and fraction <= 0.0:
		return overrun
	return fraction


static func choose_frame(target_fps: int, timing: Dictionary, game_metrics: Dictionary, _pass_summary: Dictionary) -> Dictionary:
	if timing.get("source", "") != "game" or not timing.has("timing"):
		return {}
	var frame := frame_from_timing(timing)
	var median := float(frame.get("median_ms", 0.0))
	var gpu := float(timing.get("gpu", {}).get("median_ms", 0.0))
	var script_ms := float(game_metrics.get("PROFILE_SCRIPT_TIME_SEC", 0.0)) * 1000.0
	var physics_ms := float(game_metrics.get("PROFILE_PHYSICS_TIME_SEC", 0.0)) * 1000.0
	frame["bound"] = Pacing.bound_label(median, gpu)
	if median > 0.05 and maxf(script_ms, physics_ms) >= median * 0.8:
		frame["bound"] = "cpu"
	frame["source"] = "game wall-clock frame samples; component measurements are diagnostic hints"
	frame["budget_ms"] = 1000.0 / float(target_fps)
	frame["headroom_ms"] = float(frame.budget_ms) - median
	frame["over_budget"] = Pacing.over_budget(median, float(frame.budget_ms))
	frame["over_budget_percent"] = Pacing.median_overrun_percent(median, float(frame.budget_ms))
	return frame
