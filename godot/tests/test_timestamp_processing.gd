extends SceneTree

## Headless proof that exclusive pass times partition the frame.
## godot --headless --path sample_project --script res://../tests/test_timestamp_processing.gd
## (also works as an absolute --script when --path is the sample project)

const PassTiming = preload("res://addons/render_lens/runtime/pass_timing.gd")


func _init() -> void:
	print("=== GPU timestamp exclusive-time test ===")
	var failed := false
	if not _test_nested():
		failed = true
	if not _test_repeated():
		failed = true
	if not _test_zero_dropped():
		failed = true
	if not _test_truncated():
		failed = true
	if not _test_intermittent():
		failed = true
	if not _test_terminal_marker():
		failed = true
	if failed:
		print("FAILED")
		quit(1)
	else:
		print("All tests passed")
		quit(0)


func _test_nested() -> bool:
	print("\nNested regions")
	# Span is 4.0 ms. Containers share that inclusive span; leaves split 3.0 ms.
	var timestamps := [
		{"name": "> Render Viewports", "cpu_ns": 0.0, "gpu_ns": 0.0},
		{"name": "> Render Viewport 0", "cpu_ns": 0.0, "gpu_ns": 0.0},
		{"name": "> Render 3D Scene", "cpu_ns": 0.0, "gpu_ns": 0.0},
		{"name": "Opaque", "cpu_ns": 1000000.0, "gpu_ns": 1000000.0},
		{"name": "Shadows", "cpu_ns": 3000000.0, "gpu_ns": 3000000.0},
		{"name": "< Render 3D Scene", "cpu_ns": 4000000.0, "gpu_ns": 4000000.0},
		{"name": "< Render Viewport 0", "cpu_ns": 4000000.0, "gpu_ns": 4000000.0},
		{"name": "< Render Viewports", "cpu_ns": 4000000.0, "gpu_ns": 4000000.0},
	]
	var processed: Dictionary = PassTiming.process_timestamps(timestamps)
	var frame := {
		"total_gpu_ms": processed.total_gpu_ms,
		"viewport_gpu_ms": 4.2,
		"passes": processed.passes,
	}
	var stats: Dictionary = PassTiming.aggregate_frames([frame, frame])
	var top: Array = stats.top_passes
	print("  frame GPU %.3f ms, exclusive share sum %.2f%%" % [stats.median_frame_gpu_ms, stats.exclusive_share_sum_pct])
	print("  viewport median %.3f ms" % stats.median_viewport_gpu_ms)
	var names := {}
	for item in top:
		var row: Dictionary = item
		names[row.name] = row
		print("  top %s exclusive %.3f share %.1f" % [row.name, row.exclusive_median_ms, row.share_pct])

	var ok := true
	if names.has("Render Viewports") or names.has("Render Viewport 0"):
		print("  containers with no self time leaked into the top list")
		ok = false
	if not names.has("Opaque") or abs(float(names["Opaque"].exclusive_median_ms) - 2.0) > 0.01:
		print("  Opaque exclusive expected 2.0 ms")
		ok = false
	if not names.has("Shadows") or abs(float(names["Shadows"].exclusive_median_ms) - 1.0) > 0.01:
		print("  Shadows exclusive expected 1.0 ms")
		ok = false
	if abs(float(stats.exclusive_share_sum_pct) - 100.0) > 0.2:
		print("  exclusive shares should sum to ~100, got %.2f" % stats.exclusive_share_sum_pct)
		ok = false
	if abs(float(stats.median_viewport_gpu_ms) - 4.2) > 0.01:
		print("  viewport median not preserved")
		ok = false
	# Inclusive times stay on the hierarchy even when exclusive is 0.
	var saw_container := false
	for item in stats.hierarchy:
		var row: Dictionary = item
		if row.name == "Render Viewports" and float(row.inclusive_median_ms) > 3.9:
			saw_container = true
	if not saw_container:
		print("  hierarchy missing inclusive time for Render Viewports")
		ok = false
	print("  %s" % ("PASS" if ok else "FAIL"))
	return ok


func _test_repeated() -> bool:
	print("\nRepeated pass summed per frame")
	var timestamps := [
		{"name": "Cull CanvasItem Tree", "cpu_ns": 0.0, "gpu_ns": 0.0},
		{"name": "Cull CanvasItem Tree", "cpu_ns": 2000000.0, "gpu_ns": 2000000.0},
		{"name": "End", "cpu_ns": 5000000.0, "gpu_ns": 5000000.0},
	]
	var processed: Dictionary = PassTiming.process_timestamps(timestamps)
	var stats: Dictionary = PassTiming.aggregate_frames([{
		"total_gpu_ms": processed.total_gpu_ms,
		"viewport_gpu_ms": 5.0,
		"passes": processed.passes,
	}])
	var cull: Dictionary = {}
	for item in stats.passes:
		var row: Dictionary = item
		if row.name == "Cull CanvasItem Tree":
			cull = row
	var summed: float = float(cull.get("exclusive_median_ms", -1.0))
	var calls: int = int(cull.get("calls_per_frame", 0))
	var ok: bool = abs(summed - 5.0) < 0.01 and calls == 2
	print("  summed %.3f ms, calls %s" % [float(cull.get("exclusive_median_ms", -1.0)), str(cull.get("calls_per_frame", 0))])
	print("  %s" % ("PASS" if ok else "FAIL"))
	return ok


func _test_zero_dropped() -> bool:
	print("\nZero pass dropped")
	var timestamps := [
		{"name": "Real", "cpu_ns": 0.0, "gpu_ns": 0.0},
		{"name": "Empty", "cpu_ns": 2000000.0, "gpu_ns": 2000000.0},
		{"name": "End", "cpu_ns": 2000000.0, "gpu_ns": 2000000.0},
	]
	var processed: Dictionary = PassTiming.process_timestamps(timestamps)
	var stats: Dictionary = PassTiming.aggregate_frames([{
		"total_gpu_ms": processed.total_gpu_ms,
		"viewport_gpu_ms": 2.0,
		"passes": processed.passes,
	}])
	var ok := true
	for item in stats.top_passes:
		var row: Dictionary = item
		if row.name == "Empty" or float(row.exclusive_median_ms) <= 0.0:
			ok = false
	print("  %s" % ("PASS" if ok else "FAIL"))
	return ok


## Frames that reach Godot's per-frame timestamp limit lose every later pass; the breakdown must say so.
func _test_truncated() -> bool:
	print("\nTimestamp limit reached")
	var frame := {"total_gpu_ms": 1.0, "viewport_gpu_ms": 1.0, "passes": [], "timestamp_limit": 256}
	var full := frame.duplicate()
	full["timestamp_count"] = 256
	var under := frame.duplicate()
	under["timestamp_count"] = 215
	var stats: Dictionary = PassTiming.aggregate_frames([full, under, full])
	var none: Dictionary = PassTiming.aggregate_frames([under])
	var ok: bool = int(stats.timestamp_truncated_frames) == 2 and int(stats.timestamp_limit) == 256 and int(none.timestamp_truncated_frames) == 0
	ok = ok and PassTiming.Pacing.timestamp_truncation_note(2, 3, 256).contains("max_timestamp_query_elements") and PassTiming.Pacing.timestamp_truncation_note(0, 3, 256).is_empty()
	print("  %s" % ("PASS" if ok else "FAIL"))
	return ok


## The last marker of a frame has no timestamp after it, so its duration is unknown. Counted as a 0 ms call,
## a pass repeated per viewport and cut off at the timestamp limit would show the same call count as a complete frame.
func _test_terminal_marker() -> bool:
	print("\nFinal marker")
	var timestamps := [
		{"name": "Opaque", "cpu_ns": 0.0, "gpu_ns": 0.0},
		{"name": "Shadows", "cpu_ns": 1000000.0, "gpu_ns": 1000000.0},
		{"name": "Opaque", "cpu_ns": 3000000.0, "gpu_ns": 3000000.0},
	]
	var opaque: Array = PassTiming.process_timestamps(timestamps).passes.filter(func(item): return item.name == "Opaque")
	var ok: bool = opaque.size() == 1 and is_equal_approx(float(opaque[0].exclusive_gpu_ms), 1.0)
	# Frames that ran a pass a different number of times are flagged (calls_vary), whatever the median count says.
	var once := {"total_gpu_ms": 2.0, "viewport_gpu_ms": 2.0, "passes": [{"name": "Opaque", "exclusive_gpu_ms": 1.0, "inclusive_gpu_ms": 1.0}]}
	var twice := {"total_gpu_ms": 2.0, "viewport_gpu_ms": 2.0, "passes": [{"name": "Opaque", "exclusive_gpu_ms": 1.0, "inclusive_gpu_ms": 1.0}, {"name": "Opaque", "exclusive_gpu_ms": 1.0, "inclusive_gpu_ms": 1.0}]}
	var mixed: Array = PassTiming.aggregate_frames([once, twice, twice]).passes.filter(func(item): return item.name == "Opaque")
	var steady: Array = PassTiming.aggregate_frames([twice, twice]).passes.filter(func(item): return item.name == "Opaque")
	ok = ok and mixed.size() == 1 and mixed[0].calls_vary and steady.size() == 1 and not steady[0].calls_vary
	# A region closed by the end of the frame, not its own "<" marker, is flagged incomplete.
	var open_region := [
		{"name": "> Outer", "cpu_ns": 0.0, "gpu_ns": 0.0},
		{"name": "> Child", "cpu_ns": 1000000.0, "gpu_ns": 1000000.0},
		{"name": "< Child", "cpu_ns": 2000000.0, "gpu_ns": 2000000.0},
	]
	var regions: Array = PassTiming.process_timestamps(open_region).passes
	var outer: Array = regions.filter(func(item): return item.name == "Outer")
	var child: Array = regions.filter(func(item): return item.name == "Child")
	ok = ok and outer.size() == 1 and outer[0].incomplete and child.size() == 1 and not child[0].incomplete
	print("  %s" % ("PASS" if ok else "FAIL %s" % [opaque]))
	return ok


## A pass that runs in 1 of 4 frames keeps its cost-when-run median but its share is amortized over every frame.
func _test_intermittent() -> bool:
	print("\nIntermittent pass share")
	var frames := []
	for index in 4:
		var timestamps := [{"name": "Steady", "cpu_ns": 0.0, "gpu_ns": 0.0}]
		var end := 2000000.0
		if index == 0:
			timestamps.append({"name": "Probe Update", "cpu_ns": 2000000.0, "gpu_ns": 2000000.0})
			end = 6000000.0
		timestamps.append({"name": "End", "cpu_ns": end, "gpu_ns": end})
		var processed: Dictionary = PassTiming.process_timestamps(timestamps)
		frames.append({"total_gpu_ms": processed.total_gpu_ms, "viewport_gpu_ms": 0.0, "passes": processed.passes})
	var stats: Dictionary = PassTiming.aggregate_frames(frames)
	var probe: Dictionary = {}
	for item in stats.passes:
		if item.name == "Probe Update":
			probe = item
	# Median frame 2 ms; the probe costs 4 ms when it runs, in 1 of 4 frames: 1 ms per frame, 50% of the median frame.
	var ok: bool = abs(float(probe.get("exclusive_median_ms", -1.0)) - 4.0) < 0.01 and abs(float(probe.get("share_pct", -1.0)) - 50.0) < 0.5
	print("  median %.3f ms, share %.1f%%  %s" % [float(probe.get("exclusive_median_ms", -1.0)), float(probe.get("share_pct", -1.0)), "PASS" if ok else "FAIL"])
	return ok
