extends SceneTree

# One run = one variant of heavy_test.tscn. Args after "--": variant=<name> out=<json> warmup=<n> frames=<n>

var variant := "baseline"
var out_path := ""
var warmup := 300
var count := 600
var frame := 0
var last_us := 0
var intervals: Array[float] = []
var gpu: Array[float] = []
var cpu: Array[float] = []
var vp: RID
const Variants = preload("res://variants.gd")


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=", true, 1)
		if kv.size() != 2:
			continue
		match kv[0]:
			"variant": variant = kv[1]
			"out": out_path = kv[1]
			"warmup": warmup = int(kv[1])
			"frames": count = int(kv[1])
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var scene: Node = load("res://heavy_test.tscn").instantiate()
	for name in variant.split("+"):
		if not Variants.apply(scene, name):
			push_error("unknown variant " + name)
			quit(2)
			return
	root.add_child(scene)
	vp = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)


func _process(_delta: float) -> bool:
	var now := Time.get_ticks_usec()
	frame += 1
	if frame > warmup and last_us > 0:
		intervals.append((now - last_us) / 1000.0)
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vp))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(vp) + RenderingServer.get_frame_setup_time_cpu())
	last_us = now
	if intervals.size() < count:
		return false
	var screen := DisplayServer.window_get_current_screen()
	var result := {
		"variant": variant,
		"godot": Engine.get_version_info().string,
		"adapter": RenderingServer.get_video_adapter_name(),
		"adapter_version": RenderingServer.get_video_adapter_api_version(),
		"screen": screen,
		"window": [root.size.x, root.size.y],
		"vsync": DisplayServer.window_get_vsync_mode(),
		"gi_half_resolution": ProjectSettings.get_setting("rendering/global_illumination/gi/use_half_resolution"),
		"warmup": warmup,
		"frames": intervals.size(),
		"interval_ms": _stats(intervals),
		"gpu_ms": _stats(gpu),
		"cpu_ms": _stats(cpu),
	}
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	return true


func _stats(values: Array[float]) -> Dictionary:
	var sorted := values.duplicate()
	sorted.sort()
	return {
		"median": sorted[sorted.size() / 2],
		"p95": sorted[int(sorted.size() * 0.95)],
		"mean": sorted.reduce(func(a, b): return a + b, 0.0) / sorted.size(),
	}
