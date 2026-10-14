extends Node

## GPU Recorder Runtime
## Runs in the game process and sends GPU timing data back to the editor

const Context = preload("res://addons/render_lens/context.gd")
const Samples = preload("res://addons/render_lens/frame_samples.gd")
const PassTiming = preload("res://addons/render_lens/runtime/pass_timing.gd")
const Metrics = preload("res://addons/render_lens/metrics_snapshot.gd")
const Pacing = preload("res://addons/render_lens/pacing.gd")
const VramEstimate = preload("res://addons/render_lens/vram_estimate.gd")
const LensProfilerScript = preload("res://addons/render_lens/runtime/lens_profiler.gd")

var _recording_scene := ""
var is_recording := false
var frames_to_record := 0
var frames_recorded := 0
var warmup_frames := Pacing.GPU_WARMUP_FRAMES
var warmup_done := 0
var capture_id := 0  # from the editor, echoed on every GPU message
var visual_was_profiling := false  # the user's own Visual Profiler stays on after a capture
var timestamp_waits := 0  # frames without timestamps; frames_recorded only counts frames that had them
var _drawn_at_wait := 0  # Engine.get_frames_drawn() when the wait for timestamps began
var _caps := {}  # the game's V-Sync and max_fps, restored when a capture ends
var _profiler
var _profile_active := false
var _profile_target := 1
var _profile_seen := 0
var _profile_sent := false
var _debugger_bound := false

func _ready() -> void:
	# A headless --script run loads this autoload with no debugger. Registering
	# the profiler there crashes Godot 4.4 on shutdown (signal 11). The editor
	# play path is remote-debug, so the debugger is already active in _ready.
	if not EngineDebugger.is_active():
		return
	_profiler = LensProfilerScript.new()
	if EngineDebugger.has_profiler("render_lens_scripts"):
		EngineDebugger.unregister_profiler("render_lens_scripts")
	EngineDebugger.register_profiler("render_lens_scripts", _profiler)
	_debugger_bound = true
	
	# Send ready message with diagnostics
	var renderer := Metrics.renderer()
	var has_rd := RenderingServer.get_rendering_device() != null
	
	
	print("[GpuRecorder] Ready - renderer: %s, RenderingDevice: %s" % [renderer, has_rd])

func _on_message(message: String, data: Array) -> bool:
	"""Handle messages from editor debugger"""
	# Handle both with and without prefix (Godot version differences)
	var msg := message.trim_prefix("render_lens:")
	
	match msg:
		"start_gpu_recording":
			# Send acknowledgment
			EngineDebugger.send_message("render_lens:ack", ["start_gpu_recording received"])
			_start_recording(data)
		"stop_gpu_recording":
			_stop_recording()
		"collect_metrics":
			var snap: Dictionary = Metrics.collect()
			EngineDebugger.send_message("render_lens:metrics", [snap])
			print("[GpuRecorder] Sent metrics snapshot")
		"profile_start":
			_start_profile(data)
		"vram_request":
			var vram_root: Node = null
			var vram_tree := get_tree()
			if vram_tree != null:
				vram_root = vram_tree.root
			var report: Dictionary = VramEstimate.collect(vram_root)
			EngineDebugger.send_message("render_lens:vram", [report])
			print("[GpuRecorder] Sent VRAM estimate, resources=%d" % int(report.get("resource_count", 0)))
		_:
			print("[GpuRecorder] Unknown message: %s" % message)
	
	return true

func _start_recording(data: Array) -> void:
	"""Start recording GPU passes"""
	if data.size() > 0:
		frames_to_record = data[0]
	else:
		frames_to_record = 60
	capture_id = int(data[1]) if data.size() > 1 else 0
	if Pacing.separate_render_thread():
		_send_error("GPU passes are unavailable on the Separate render thread model: Godot only reads GPU timestamps on the render thread.")
		return
	
	_recording_scene = Samples.scene_path()
	if _caps.is_empty():
		_caps = Pacing.uncap()
	is_recording = true
	frames_recorded = 0
	warmup_done = 0
	timestamp_waits = 0
	
	# Enable visual profiler to start RenderingDevice timestamp capture
	visual_was_profiling = EngineDebugger.is_profiling("visual")
	EngineDebugger.profiler_enable("visual", true)
	
	print("[GpuRecorder] Started recording %d frames (warmup %d)" % [frames_to_record, warmup_frames])

func _stop_recording() -> void:
	"""Stop recording"""
	is_recording = false
	Pacing.restore(_caps)
	_caps = {}

	# Disable visual profiler unless the user had it on
	if not visual_was_profiling:
		EngineDebugger.profiler_enable("visual", false)
	
	print("[GpuRecorder] Stopped recording")

func _start_profile(data: Array) -> void:
	_profile_target = 20
	if data.size() > 0:
		_profile_target = maxi(1, int(data[0]))
	_profile_seen = 0
	_profile_sent = false
	_profile_active = true
	EngineDebugger.profiler_enable("render_lens_scripts", true, [_profile_target])
	# Read before the editor's own toggles arrive (sent after this request), so script_profile leaves on what the user had on.
	EngineDebugger.send_message("render_lens:ack", ["profile_start", EngineDebugger.is_profiling("servers"), EngineDebugger.is_profiling("visual")])
	print("[GpuRecorder] Profile start, frames=%d" % _profile_target)


func _service_profile(delta: float) -> void:
	if not _profile_active or _profile_sent:
		return
	_profile_seen += 1
	var profiler = _profiler
	if profiler != null and bool(profiler.ticked_this_frame):
		profiler.ticked_this_frame = false
	elif profiler != null:
		profiler.add_fallback(delta, 0.0, 0.0, 0.0)
	var tick_n := 0
	var fall_n := 0
	if profiler != null:
		tick_n = profiler.samples.size()
		fall_n = profiler.fallback_samples.size()
	var ready := tick_n >= _profile_target
	if not ready and tick_n == 0 and fall_n >= _profile_target and _profile_seen > _profile_target + 2:
		ready = true
	if not ready:
		return
	_profile_sent = true
	_profile_active = false
	EngineDebugger.profiler_enable("render_lens_scripts", false, [])
	var used: Array = profiler.fallback_samples
	var source := "process_fallback"
	if tick_n > 0:
		used = profiler.samples
		source = "engine_profiler_tick"
	var note := "Frame, process, and physics times come from EngineProfiler._tick (the same header values ServersDebugger::ServersProfiler records). Per-function script self/total time is not in _tick. GDScript cannot call ScriptLanguage::profiling_get_frame_data. The editor also toggles the built-in 'servers' profiler; those servers:profile_frame rows are merged when the debugger session delivers them."
	if source == "process_fallback":
		note = "EngineProfiler._tick did not run, so only _process delta is available. Process, physics and per-function script times were not collected; zero fields are unavailable measurements."
	EngineDebugger.send_message("render_lens:profile", [{
		"ok": true,
		"source": source,
		"frames": used,
		"note": note,
	}])
	print("[GpuRecorder] Sent profile (%s, %d frames)" % [source, used.size()])


func _process(delta: float) -> void:
	"""Collect GPU timing each frame"""
	_service_profile(delta)
	if not is_recording:
		return
	
	if Samples.scene_path() != _recording_scene:
		_send_error("The running scene changed during GPU capture")
		_stop_recording()
		return

	# Warmup frames
	if warmup_done < warmup_frames:
		warmup_done += 1
		return
	
	# Get RenderingDevice
	var rd := RenderingServer.get_rendering_device()
	if not rd:
		_send_error("RenderingDevice not available (Compatibility renderer?)")
		_stop_recording()
		return
	
	# Collect timestamp data (note: 2-frame delay after enabling capture)
	var timestamp_count := rd.get_captured_timestamps_count()
	if timestamp_count == 0:
		# Check if we've been waiting too long for timestamps
		timestamp_waits += 1
		if timestamp_waits == 1:
			_drawn_at_wait = Engine.get_frames_drawn()
		if timestamp_waits > 60:
			# Godot draws nothing while every game window is minimized or the render loop is off (main.cpp), and a frame
			# not drawn records no timestamps. Seen 2026-10-13 on 4.7.2: frames_drawn stood still while the game ran.
			if Engine.get_frames_drawn() == _drawn_at_wait:
				_send_error("The game drew no frames during the capture (a minimized window or a stopped render loop), so there were no GPU timestamps to read")
			else:
				_send_error("RenderingDevice timestamp capture not enabled after 60 frames (visual profiler toggle may have failed)")
			_stop_recording()
			return
		# Still warming up timestamp capture
		return
	
	# Collect raw timestamps
	var timestamps := []
	for i in range(timestamp_count):
		var name: String = rd.get_captured_timestamp_name(i)
		var cpu_time_ns: float = rd.get_captured_timestamp_cpu_time(i) * 1000.0  # the engine stores CPU timestamps in microseconds (get_ticks_usec)
		var gpu_time_ns: float = rd.get_captured_timestamp_gpu_time(i)
		
		timestamps.append({
			"name": name,
			"cpu_ns": cpu_time_ns,
			"gpu_ns": gpu_time_ns
		})
	
	var processed: Dictionary = PassTiming.process_timestamps(timestamps)
	var measured := _measured_viewport_times()
	
	var frame_data := {
		"frame": frames_recorded,
		"scene": _recording_scene,
		"timestamp_count": timestamp_count,
		# RenderingDevice drops every timestamp past this per-frame limit (and logs an error), truncating the frame.
		"timestamp_limit": int(ProjectSettings.get_setting("debug/settings/profiler/max_timestamp_query_elements", 256)),
		"total_gpu_ms": processed.total_gpu_ms,
		"total_cpu_ms": processed.total_cpu_ms,
		"viewport_gpu_ms": measured.gpu_ms,
		"viewport_cpu_ms": measured.cpu_ms,
		"passes": processed.passes,
		"tree": processed.tree
	}
	
	frames_recorded += 1
	var game_fps := Engine.get_frames_per_second()
	EngineDebugger.send_message("render_lens:gpu_frame", [frame_data, game_fps, capture_id])
	
	# Send progress every 30 frames
	if frames_recorded % 30 == 0:
		EngineDebugger.send_message("render_lens:progress", [frames_recorded, timestamp_count, game_fps])
		print("[GpuRecorder] Progress: %d/%d frames, %d timestamps" % [frames_recorded, frames_to_record, timestamp_count])
	
	# Check if done
	if frames_recorded >= frames_to_record:
		_send_data()
		_stop_recording()

func _send_data() -> void:
	"""Send the capture summary; every frame already went out as its own render_lens:gpu_frame message."""
	# All frames in one message can exceed the debugger's 8 MiB packet buffer (remote_debugger_peer.cpp), and Godot drops it.
	var result := {
		"frame_count": frames_recorded,
		"scene": _recording_scene,
		"context": Context.capture(),
		"warmup_dropped": warmup_frames,
		"uncapped": Pacing.uncapped(_caps, Engine.get_frames_per_second()),
	}
	
	EngineDebugger.send_message("render_lens:gpu_data", [result, capture_id])
	print("[GpuRecorder] Sent %d frames of GPU data" % frames_recorded)

func _measured_viewport_times() -> Dictionary:
	## viewport_get_measured_render_time_* stays 0 until measurement is enabled
	## and a frame has been presented. The root viewport and the current viewport
	## are both sampled. The larger reading is kept.
	var best_gpu := 0.0
	var best_cpu := 0.0
	var rids: Array = []
	var vp := get_viewport()
	if vp != null:
		rids.append(vp.get_viewport_rid())
	var tree := get_tree()
	if tree != null and tree.root != null:
		var root_rid := tree.root.get_viewport_rid()
		if not rids.has(root_rid):
			rids.append(root_rid)
	for rid in rids:
		if typeof(rid) != TYPE_RID or not (rid as RID).is_valid():
			continue
		RenderingServer.viewport_set_measure_render_time(rid, true)
		var gpu := RenderingServer.viewport_get_measured_render_time_gpu(rid)
		var cpu := RenderingServer.viewport_get_measured_render_time_cpu(rid)
		if gpu > best_gpu:
			best_gpu = gpu
		if cpu > best_cpu:
			best_cpu = cpu
	return {"gpu_ms": best_gpu, "cpu_ms": best_cpu}

func _exit_tree() -> void:
	if not _debugger_bound:
		return
	_debugger_bound = false
	if EngineDebugger.has_profiler("render_lens_scripts"):
		EngineDebugger.unregister_profiler("render_lens_scripts")
	_profiler = null


func _send_error(msg: String) -> void:
	"""Send error back to editor"""
	EngineDebugger.send_message("render_lens:gpu_error", [msg, capture_id])
	print("[GpuRecorder] Error: %s" % msg)
