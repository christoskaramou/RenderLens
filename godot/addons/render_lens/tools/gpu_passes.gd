extends Node

## gpu_passes Tool
## Per-pass GPU timing with hierarchy and statistics
## Requires Forward+/Mobile renderer and running game

const Context = preload("res://addons/render_lens/context.gd")
const FileHelper = preload("res://addons/render_lens/file_helper.gd")
const PassTiming = preload("res://addons/render_lens/runtime/pass_timing.gd")
const Pacing = preload("res://addons/render_lens/pacing.gd")

static func execute(params: Dictionary) -> Dictionary:
	"""Execute gpu_passes tool"""
	var frames: int = params.get("frames", 60)
	
	# Validate
	if frames < 10 or frames > 300:
		return _build_error("frames must be between 10 and 300")
	
	# Get debugger plugin (passed by mcp_server)
	var debugger_plugin = params.get("_debugger_plugin")
	if not debugger_plugin:
		return _build_error("Not available: the Render Lens debugger plugin is missing or this is not running in the editor")
	
	# Check renderer support
	var renderer := ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method")
	if renderer == "gl_compatibility":
		return _build_error("GPU passes unsupported on Compatibility renderer (use Forward+ or Mobile)")
	if Pacing.separate_render_thread() or bool(debugger_plugin.game_separate_render_thread):
		return _build_error("GPU passes are unavailable with rendering/driver/threads/thread_model = Separate: Godot only reads GPU timestamps on the render thread. Use Safe to capture passes.")

	# Request GPU data from game; with no session the plugin reports the error before a handler could be connected.
	if not debugger_plugin.send_start_recording(frames):
		return _build_error(str(debugger_plugin.last_error))

	var editor_fps := Engine.get_frames_per_second()
	if editor_fps < 1.0:
		editor_fps = 1.0
	var budget_fps := minf(editor_fps, 10.0)
	var timeout_sec := Pacing.gpu_timeout_sec(frames + Pacing.GPU_WARMUP_FRAMES, budget_fps)
	var start_time := Time.get_ticks_msec()
	
	# Use reference type for lambda capture (GDScript captures by value)
	var state := {"data": null, "error": ""}
	
	# Connect signals
	var on_data := func(data):
		state.data = data
	var on_error := func(err):
		state.error = err
	
	debugger_plugin.gpu_data_received.connect(on_data)
	debugger_plugin.gpu_error.connect(on_error)
	
	# Poll for result. The deadline grows when the game reports a slower fps.
	while state.data == null and state.error.is_empty():
		await Engine.get_main_loop().process_frame
		var observed := float(debugger_plugin.partial_gpu_fps)
		if observed >= 1.0:
			budget_fps = observed
			timeout_sec = Pacing.gpu_timeout_sec(frames + Pacing.GPU_WARMUP_FRAMES, budget_fps)
		var elapsed_sec := (Time.get_ticks_msec() - start_time) / 1000.0
		var session = debugger_plugin._get_active_session()
		var game_gone: bool = session == null
		var paused: bool = not game_gone and session.is_breaked()
		if elapsed_sec > timeout_sec or game_gone or paused:
			debugger_plugin.gpu_data_received.disconnect(on_data)
			debugger_plugin.gpu_error.disconnect(on_error)
			if game_gone:
				return _build_error("The game stopped during the GPU capture")
			debugger_plugin.stop_gpu_recording()
			if paused:
				return _build_error(debugger_plugin.PAUSED_ERROR)
			if debugger_plugin.has_method("take_partial_gpu_frames"):
				var partial: Array = debugger_plugin.take_partial_gpu_frames()
				if not partial.is_empty():
					var partial_data := {"scene": str(partial[0].get("scene", "")), "frames": partial, "warmup_dropped": Pacing.GPU_WARMUP_FRAMES, "partial": true}
					return _finish(partial_data, frames, debugger_plugin, true, elapsed_sec, timeout_sec, budget_fps)
			var empty: Dictionary = Pacing.timeout_payload(0, elapsed_sec, timeout_sec, budget_fps)
			return _build_error(str(empty.get("error", "Timeout waiting for GPU data")))
	
	# Disconnect signals
	debugger_plugin.gpu_data_received.disconnect(on_data)
	debugger_plugin.gpu_error.disconnect(on_error)
	
	# Check for error
	if not state.error.is_empty():
		return _build_error(state.error)
	
	if state.data == null:
		return _build_error("No GPU data received")
	
	var gpu_data = state.data
	
	return _finish(gpu_data, frames, debugger_plugin, bool(gpu_data.get("partial", false)), (Time.get_ticks_msec() - start_time) / 1000.0, timeout_sec, budget_fps)


static func _finish(gpu_data: Dictionary, frames: int, debugger_plugin, partial: bool, elapsed: float, timeout_sec: float, budget_fps: float) -> Dictionary:
	if partial and debugger_plugin != null and debugger_plugin.has_method("stop_gpu_recording"):
		debugger_plugin.stop_gpu_recording()
	var result := _process_gpu_data(gpu_data, frames)
	if result.has("error"):
		return _build_error(str(result.error))
	result.context = gpu_data.get("context", {"source": "game", "scene": gpu_data.get("scene", "")})
	result.scene = gpu_data.get("scene", "")
	result.params = {"frames": frames}
	result["uncapped"] = gpu_data.get("uncapped", {})
	result["partial"] = partial
	result["timeout_sec"] = timeout_sec
	result["elapsed_sec"] = elapsed
	result["budget_fps"] = budget_fps
	
	var path := FileHelper.write_json(result, "gpu_passes")
	if path.is_empty():
		return _build_error("Failed to write GPU passes data")
	
	var summary := _build_summary(result, path)
	
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify(summary, "\t")
		}]
	}

static func _get_debugger_plugin():
	"""Get debugger plugin from EditorInterface"""
	# This will be passed in via a global or retrieved from the plugin
	# For now, we'll access it through the MCP server
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return null
	
	# Find MCP server node
	for child in tree.root.get_children():
		if child.has_method("get") and child.get("debugger_plugin"):
			return child.debugger_plugin
	
	return null

static func _process_gpu_data(gpu_data: Dictionary, _target_frames: int) -> Dictionary:
	"""Process raw GPU frame data into exclusive-time statistics"""
	var frames: Array = gpu_data.get("frames", [])
	if frames.is_empty():
		return {"error": "No frames in GPU data"}
	var stats: Dictionary = PassTiming.aggregate_frames(frames)
	stats["warmup_dropped"] = gpu_data.get("warmup_dropped", 0)
	return stats

static func _build_summary(result: Dictionary, path: String) -> Dictionary:
	"""Build summary for agent. top_passes are exclusive (self) time, not containers."""
	var top_src: Array = result.get("top_passes", [])
	if top_src.is_empty():
		return {
			"path": path,
			"error": "No passes recorded",
			"frame_count": result.get("frame_count", 0)
		}

	var median_frame := float(result.get("median_frame_gpu_ms", 0.0))
	var median_viewport := float(result.get("median_viewport_gpu_ms", 0.0))
	var p95_viewport := float(result.get("p95_viewport_gpu_ms", 0.0))
	var rejected_max := float(result.get("viewport_rejected_max_ms", -1.0))
	var viewport_note := ""
	var median_viewport_text := "omitted"
	var p95_viewport_text := "omitted"
	var truncated := int(result.get("timestamp_truncated_frames", 0))
	var truncation_note := Pacing.timestamp_truncation_note(truncated, int(result.get("frame_count", 0)), int(result.get("timestamp_limit", 0)))
	var share_denominator := "exclusive GPU ms / median timestamp-span frame GPU time (%.3f ms)." % median_frame
	if median_viewport < 0.0:
		viewport_note = Pacing.viewport_rejected_note(median_frame, rejected_max)
		share_denominator += " viewport_get_measured_render_time_gpu was omitted because the counter was outside 0..%.0f ms." % Pacing.MAX_VIEWPORT_FRAME_MS
	else:
		median_viewport_text = "%.3f" % median_viewport
		p95_viewport_text = "%.3f" % p95_viewport
		viewport_note = Pacing.viewport_counter_note(median_frame, median_viewport)
		share_denominator += " viewport_get_measured_render_time_gpu median is %.3f ms." % median_viewport
	var top_passes: Array = []
	for item in top_src:
		var p: Dictionary = item
		var row := {
			"name": p.name,
			"median_ms": "%.3f" % float(p.exclusive_median_ms),
			"p95_ms": "%.3f" % float(p.exclusive_p95_ms),
			"share": "%.1f%%" % float(p.share_pct),
		}
		var calls := int(p.get("calls_per_frame", 1))
		if calls > 1:
			row["calls_per_frame"] = calls
		top_passes.append(row)

	return {
		"path": path,
		"frame_count": result.get("frame_count", 0),
		"pass_count": result.get("passes", []).size(),
		"median_frame_gpu_ms": "%.3f" % median_frame,
		"p95_frame_gpu_ms": "%.3f" % float(result.get("p95_frame_gpu_ms", 0.0)),
		"median_viewport_gpu_ms": median_viewport_text,
		"p95_viewport_gpu_ms": p95_viewport_text,
		"share_denominator": share_denominator,
		"viewport_note": viewport_note,
		"timestamp_truncated": truncated > 0,
		"timestamp_truncation_note": truncation_note,
		"partial": bool(result.get("partial", false)),
		"requested_frames": int(result.get("params", {}).get("frames", 0)),
		"exclusive_share_sum_pct": "%.1f" % float(result.get("exclusive_share_sum_pct", 0.0)),
		"uncapped": result.get("uncapped", {}),
		"top_passes": top_passes,
	}

static func _build_error(message: String) -> Dictionary:
	return {
		"isError": true,
		"content": [{
			"type": "text",
			"text": message
		}]
	}
