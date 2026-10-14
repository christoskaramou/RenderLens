extends RefCounted

const Clock = preload("res://addons/render_lens/runtime/frame_clock.gd")
const Pacing = preload("res://addons/render_lens/pacing.gd")

static func collect(frames: int, warmup: int, seconds: float, params: Dictionary = {}) -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	var viewport := tree.root
	var rid := viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var profiler := Clock.new()
	var profiling := EngineDebugger.is_active()
	if profiling:
		if EngineDebugger.has_profiler("render_lens_frames"):  # left registered by a collect stopped by a script error
			EngineDebugger.unregister_profiler("render_lens_frames")
		EngineDebugger.register_profiler("render_lens_frames", profiler)
		EngineDebugger.profiler_enable("render_lens_frames", true)
	var samples: Array = []
	var started := Time.get_ticks_usec()
	var previous := started
	var duration := seconds if seconds > 0.0 else Pacing.gpu_timeout_sec(frames + warmup, Engine.get_frames_per_second())
	var deadline := started + int(duration * 1000000.0)
	var seen := 0
	var pipelines := _pipeline_count()
	var initial_scene := scene_path()
	var scene_changed := false
	# The editor always renders on its main thread; a game on the Separate model would sync on every read.
	var viewport_times := RenderingServer.is_on_render_thread()
	while Time.get_ticks_usec() < deadline and not bool(params.get("_cancel", {}).get("cancelled", false)):
		await tree.process_frame
		# The frame that crosses the deadline is kept (the loop ends after it): a hitch there belongs to this capture.
		var now := Time.get_ticks_usec()
		scene_changed = scene_changed or initial_scene != scene_path()
		var elapsed_ms := float(now - previous) / 1000.0
		previous = now
		seen += 1
		if seen <= warmup:
			continue
		var current_pipelines := _pipeline_count()
		var row: Dictionary = profiler.sample.duplicate()
		row.merge({
			"frame": samples.size(), "frame_ms": elapsed_ms, "total_ms": elapsed_ms,
			"cpu_ms": maxf(0.0, Pacing.sane_viewport_ms(RenderingServer.viewport_get_measured_render_time_cpu(rid))) if viewport_times else 0.0,
			"gpu_ms": maxf(0.0, Pacing.sane_viewport_ms(RenderingServer.viewport_get_measured_render_time_gpu(rid))) if viewport_times else 0.0,
			"shader_compile": current_pipelines > pipelines,
			"process_ms": row.get("process_ms", 0.0), "physics_ms": row.get("physics_ms", 0.0),
		}, true)
		pipelines = current_pipelines
		samples.append(row)
		if frames > 0 and samples.size() >= frames:
			break
		# Bound storage even when a game runs uncapped at thousands of FPS.
		if samples.size() >= 120000:
			break
	var process_source := "EngineProfiler._tick" if not profiler.sample.is_empty() else "unavailable"
	if profiling:
		EngineDebugger.profiler_enable("render_lens_frames", false)
		EngineDebugger.unregister_profiler("render_lens_frames")
	return {
		"samples": samples, "elapsed_seconds": float(Time.get_ticks_usec() - started) / 1000000.0,
		"partial": samples.size() < frames if frames > 0 else Time.get_ticks_usec() < deadline,
		"source": "editor" if Engine.is_editor_hint() else "game", "scene": initial_scene,
		"scene_changed": scene_changed or initial_scene != scene_path(),
		"process_source": process_source,
	}

static func scene_path() -> String:
	var tree := Engine.get_main_loop() as SceneTree
	return str(tree.current_scene.scene_file_path) if tree.current_scene != null else ""

static func _pipeline_count() -> int:
	var total := 0
	for kind in [RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_CANVAS, RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_MESH, RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_SURFACE, RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_DRAW, RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_SPECIALIZATION]:
		total += RenderingServer.get_rendering_info(kind)
	return total
