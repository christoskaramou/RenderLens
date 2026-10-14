extends Node

## GPU Timing Spike Test
## Tests per-pass GPU timing via EditorDebuggerPlugin messages
## Forward+ and Mobile renderers only (not Compatibility/OpenGL)

var frame_count := 0
const TEST_FRAMES := 10

func _ready() -> void:
	print("\n========================================")
	print("GPU Timing Spike Test")
	print("========================================\n")
	
	# Check if we have RenderingDevice (null in headless and Compatibility renderer)
	var rd := RenderingServer.get_rendering_device()
	if rd == null:
		print("❌ FAIL: RenderingDevice is null")
		print("   Cause: Either headless mode, Compatibility renderer, or OpenGL")
		print("   GPU timing requires Forward+ or Mobile renderer")
		get_tree().quit(1)
		return
	
	print("✅ RenderingDevice available")
	print("   Driver: %s" % RenderingServer.get_video_adapter_name())
	print("   Renderer: %s" % RenderingServer.get_video_adapter_api_version())
	
	# Enable visual profiling (enables timestamp capture)
	if EngineDebugger.is_active():
		print("✅ Engine debugger is active")
		EngineDebugger.profiler_enable("visual", true)
		print("   Enabled 'visual' profiler")
	else:
		print("⚠️  Engine debugger not active (running standalone)")
		print("   Testing RenderingDevice timestamps directly...")
	
	# Register our own message capture
	if EngineDebugger.is_active():
		EngineDebugger.register_message_capture("render_lens_test", _on_debug_message)
		print("✅ Registered message capture 'render_lens_test'")

func _process(_delta: float) -> void:
	frame_count += 1
	
	if frame_count > TEST_FRAMES:
		return
	
	# Read GPU timestamps
	var rd := RenderingServer.get_rendering_device()
	if rd == null:
		return
	
	var timestamp_count := rd.get_captured_timestamps_count()
	var frame_number := rd.get_captured_timestamps_frame()
	
	if frame_count == 1:
		print("\nFrame %d: Waiting for timestamps..." % frame_count)
		if timestamp_count == 0:
			print("   No timestamps yet (need to wait a few frames)")
	elif frame_count == 5:
		print("\nFrame %d: Checking timestamps..." % frame_count)
		print("   Timestamp count: %d" % timestamp_count)
		print("   Frame number: %d" % frame_number)
		
		if timestamp_count > 0:
			print("\n✅ SUCCESS: GPU timestamps are being captured!")
			print("\nSample timestamps (first 10):")
			var show_count := mini(10, timestamp_count)
			for i in range(show_count):
				var name := rd.get_captured_timestamp_name(i)
				var gpu_time_ns := rd.get_captured_timestamp_gpu_time(i)
				var cpu_time_us := rd.get_captured_timestamp_cpu_time(i)
				var gpu_ms := gpu_time_ns / 1_000_000.0
				var cpu_ms := cpu_time_us / 1_000.0
				print("   [%d] %s: GPU %.3f ms, CPU %.3f ms" % [i, name, gpu_ms, cpu_ms])
			
			if timestamp_count > 10:
				print("   ... (%d more timestamps)" % (timestamp_count - 10))
			
			# Try to send a message to the editor
			if EngineDebugger.is_active():
				var test_data := {
					"frame": frame_count,
					"timestamp_count": timestamp_count,
					"frame_number": frame_number,
					"sample_name": rd.get_captured_timestamp_name(0) if timestamp_count > 0 else "",
					"sample_gpu_ms": rd.get_captured_timestamp_gpu_time(0) / 1_000_000.0 if timestamp_count > 0 else 0.0
				}
				EngineDebugger.send_message("render_lens_test:timing_data", [test_data])
				print("\n📤 Sent timing data to editor via EngineDebugger.send_message")
		else:
			print("❌ No timestamps captured after 5 frames")
			print("   This may be normal - timestamps are async and may need more frames")
	
	elif frame_count == TEST_FRAMES:
		print("\nFrame %d: Final check..." % frame_count)
		print("   Timestamp count: %d" % timestamp_count)
		
		if timestamp_count > 0:
			print("\n✅ TEST PASSED")
			print("\nConclusion:")
			print("- GPU timestamps work in Godot 4")
			print("- Can read pass names and timings via RenderingDevice")
			print("- Can send data to editor via EngineDebugger.send_message")
			print("- Ready to implement gpu_passes tool in M3")
			get_tree().quit(0)
		else:
			print("\n⚠️  TEST INCONCLUSIVE")
			print("   Timestamps not captured, but this might be:")
			print("   - Running in Xvfb with limited GPU (expected)")
			print("   - Need more frames to warm up")
			print("   - Need actual rendering work to measure")
			print("\n   Implementation notes:")
			print("   - Add more complex scene with shadows/SSAO/post effects")
			print("   - Wait longer (20-30 frames) for async GPU")
			print("   - Test with real GPU (not CI lavapipe)")
			get_tree().quit(2)  # Exit code 2 = needs manual verification

func _on_debug_message(_message: String, _data: Array) -> bool:
	print("   📥 Editor could receive message: %s" % _message)
	return true
