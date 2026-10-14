extends RefCounted

## Editor or game snapshot of Performance monitors, RenderingServer counters,
## and project settings. Safe to preload from the game autoload (no editor types).

const Pacing = preload("res://addons/render_lens/pacing.gd")

const SETTING_PREFIXES: PackedStringArray = [
	"rendering/",
	"physics/",
	"display/window/vsync/",
	"display/window/per_pixel_transparency/",
	"display/window/subwindows/",
	"application/run/max_fps",
	"application/run/low_processor_mode",
	"application/run/delta_smoothing",
	"application/run/flush_stdout_on_print",
	"memory/limits/",
	"threading/",
	"audio/",
	"navigation/",
	"gui/",
	"xr/",
	"animation/",
	"debug/settings/profiler/",
	"debug/settings/stdout/print_gpu_profile",
	"debug/settings/gdscript/",
	"display/window/hdr/",
]


static func collect() -> Dictionary:
	var version := Engine.get_version_info()
	var tree := Engine.get_main_loop() as SceneTree
	var snap := {
		"schema": 1,
		"source": "editor" if Engine.is_editor_hint() else "game",
		"scene": str(tree.current_scene.scene_file_path) if tree != null and tree.current_scene != null else "",
		"process_id": OS.get_process_id(),
		"godot_version": str(version.get("string", "")),
		"version_major": int(version.get("major", 0)),
		"version_minor": int(version.get("minor", 0)),
		"renderer": renderer(),
		"adapter": _adapter(),
		"monitors": _monitors(),
		"custom_monitors": _custom_monitors(),
		"rendering_info": _rendering_info(),
		"device": _device(),
		"viewport": _viewport(),
		"settings": _settings(),
	}
	snap["metrics"] = _flat_metrics(snap)
	return snap


## The renderer this process runs with: a game reports its own (a command-line --rendering-method or a driver fallback
## overrides the project); the editor, which may run another one, reports what the project starts with.
static func renderer() -> String:
	var running := RenderingServer.get_current_rendering_method()
	if Engine.is_editor_hint() or running.is_empty():
		return str(ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method"))
	return running


static func _monitors() -> Dictionary:
	var out := {}
	var names: PackedStringArray = ClassDB.class_get_enum_constants("Performance", "Monitor")
	for key in names:
		if key == "MONITOR_MAX":
			continue
		var index := ClassDB.class_get_integer_constant("Performance", key)
		out[key] = {
			"index": index,
			"value": Performance.get_monitor(index),
			"unit": _unit(key),
		}
	return out


static func _custom_monitors() -> Dictionary:
	var out := {}
	if not Performance.has_method("get_custom_monitor_names") or not Performance.has_method("get_custom_monitor"):
		return out
	var names = Performance.get_custom_monitor_names()
	for raw in names:
		var key := str(raw)
		out[key] = Performance.get_custom_monitor(key)
	return out


static func _device() -> Dictionary:
	var rd := RenderingServer.get_rendering_device()
	if rd == null:
		return {"available": false}
	var limits := {}
	# Godot 4.4's Vulkan getter fails (ERR_FAIL_V) for these; from 4.5 unknown limits return silently in release builds.
	var unimplemented: Array = []
	if Engine.get_version_info().major == 4 and Engine.get_version_info().minor < 5:
		unimplemented = ["LIMIT_MAX_COMPUTE_SHARED_MEMORY_SIZE", "LIMIT_METALFX_TEMPORAL_SCALER_MIN_SCALE", "LIMIT_METALFX_TEMPORAL_SCALER_MAX_SCALE"]
	for key in ClassDB.class_get_enum_constants("RenderingDevice", "Limit"):
		if key in unimplemented:
			continue
		var index := ClassDB.class_get_integer_constant("RenderingDevice", key)
		limits[key] = rd.limit_get(index)
	var features := {}
	for key in ClassDB.class_get_enum_constants("RenderingDevice", "Features"):
		var index := ClassDB.class_get_integer_constant("RenderingDevice", key)
		features[key] = rd.has_feature(index)
	return {
		"available": true,
		"memory_textures": rd.get_memory_usage(RenderingDevice.MEMORY_TEXTURES),
		"memory_buffers": rd.get_memory_usage(RenderingDevice.MEMORY_BUFFERS),
		"memory_total": rd.get_memory_usage(RenderingDevice.MEMORY_TOTAL),
		"limits": limits,
		"features": features,
	}


static func _unit(name: String) -> String:
	if name == "TIME_FPS":
		return "frames_per_second"
	if name == "TIME_PROCESS" or name == "TIME_PHYSICS_PROCESS" or name == "TIME_NAVIGATION_PROCESS" or name == "AUDIO_OUTPUT_LATENCY":
		return "seconds"
	if name.begins_with("MEMORY_") or name.begins_with("RENDER_VIDEO") or name.begins_with("RENDER_TEXTURE") or name.begins_with("RENDER_BUFFER"):
		return "bytes"
	return "count"


static func _rendering_info() -> Dictionary:
	return {
		"TOTAL_OBJECTS_IN_FRAME": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		"TOTAL_PRIMITIVES_IN_FRAME": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"TOTAL_DRAW_CALLS_IN_FRAME": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"TEXTURE_MEM_USED": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED),
		"BUFFER_MEM_USED": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED),
		"VIDEO_MEM_USED": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED),
		"PIPELINE_COMPILATIONS_CANVAS": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_CANVAS),
		"PIPELINE_COMPILATIONS_MESH": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_MESH),
		"PIPELINE_COMPILATIONS_SURFACE": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_SURFACE),
		"PIPELINE_COMPILATIONS_DRAW": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_DRAW),
		"PIPELINE_COMPILATIONS_SPECIALIZATION": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_SPECIALIZATION),
	}


static func _viewport() -> Dictionary:
	var rid := _viewport_rid()
	var out := {
		"measured_render_time_cpu_ms": 0.0,
		"measured_render_time_gpu_ms": 0.0,
		"frame_setup_time_cpu_ms": RenderingServer.get_frame_setup_time_cpu(),
	}
	if rid.is_valid():
		var cpu_raw := RenderingServer.viewport_get_measured_render_time_cpu(rid)
		var gpu_raw := RenderingServer.viewport_get_measured_render_time_gpu(rid)
		out["measured_render_time_cpu_ms_raw"] = cpu_raw
		out["measured_render_time_gpu_ms_raw"] = gpu_raw
		var cpu_sane := Pacing.sane_viewport_ms(cpu_raw)
		var gpu_sane := Pacing.sane_viewport_ms(gpu_raw)
		out["measured_render_time_cpu_ms"] = cpu_sane if cpu_sane >= 0.0 else 0.0
		out["measured_render_time_gpu_ms"] = gpu_sane if gpu_sane >= 0.0 else 0.0
		out["visible"] = _viewport_type(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE)
		out["shadow"] = _viewport_type(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW)
		out["canvas"] = _viewport_type(rid, RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS)
	return out


static func _viewport_type(rid: RID, kind: int) -> Dictionary:
	return {
		"objects": RenderingServer.viewport_get_render_info(rid, kind, RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME),
		"primitives": RenderingServer.viewport_get_render_info(rid, kind, RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME),
		"draw_calls": RenderingServer.viewport_get_render_info(rid, kind, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME),
	}


static func _viewport_rid() -> RID:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_viewport_rid()
	return RID()


static func _adapter() -> Dictionary:
	# RenderingServer.get_video_adapter_type() returns RenderingDevice.DeviceType:
	# 0 other, 1 integrated, 2 discrete, 3 virtual, 4 cpu.
	var kind := int(RenderingServer.get_video_adapter_type())
	var names := ["other", "integrated", "discrete", "virtual", "cpu"]
	var kind_name := "other"
	if kind >= 0 and kind < names.size():
		kind_name = names[kind]
	return {
		"name": RenderingServer.get_video_adapter_name(),
		"vendor": RenderingServer.get_video_adapter_vendor(),
		"api": RenderingServer.get_video_adapter_api_version(),
		"type": kind,
		"type_name": kind_name,
	}


static func _settings() -> Dictionary:
	var out := {}
	var paths: Array = []
	var overrides := {}  # base path -> its feature-tag variants, in Godot's registration order
	for prop in ProjectSettings.get_property_list():
		if typeof(prop) != TYPE_DICTIONARY:
			continue
		var path := str(prop.get("name", ""))
		if not _wanted_setting(path):
			continue
		if not ProjectSettings.has_setting(path):
			continue
		var leaf := path.get_slice("/", path.get_slice_count("/") - 1)
		if leaf.contains("."):
			overrides.get_or_add(path.substr(0, path.length() - leaf.length() + leaf.find(".")), []).append(path)
		paths.append(path)
	for path in paths:
		out[path] = _json_safe(_shipped_value(path, overrides.get(path, [])))
	return out


## The value the exported game reads (GLOBAL_GET applies feature-tag overrides): platform and release tags apply,
## debug and editor tags do not (Godot's own flush_stdout_on_print.debug is true only while debugging).
static func _shipped_value(path: String, overrides: Array) -> Variant:
	var build_tags := ["debug", "editor", "editor_hint", "editor_runtime", "release", "template", "template_debug", "template_release"]
	if not overrides.any(func(key): return Array(str(key).substr(path.length() + 1).split(".")).any(func(tag): return tag in build_tags)):
		return ProjectSettings.get_setting_with_override(path)  # Godot's own resolution order (registration, not name)
	for key in overrides:
		for tag in str(key).substr(path.length() + 1).split("."):
			if tag in ["release", "template", "template_release"] or (tag not in ["debug", "editor", "editor_hint", "editor_runtime", "template_debug"] and OS.has_feature(tag)):
				return ProjectSettings.get_setting(key)
	return ProjectSettings.get_setting(path)


static func _wanted_setting(path: String) -> bool:
	for prefix in SETTING_PREFIXES:
		if path == prefix or path.begins_with(prefix):
			return true
	return false


static func _json_safe(value):
	var kind := typeof(value)
	if kind == TYPE_BOOL or kind == TYPE_INT or kind == TYPE_FLOAT or kind == TYPE_STRING or kind == TYPE_NIL:
		return value
	return str(value)


static func _flat_metrics(snap: Dictionary) -> Dictionary:
	var flat := {}
	var monitors: Dictionary = snap.get("monitors", {})
	for key in monitors.keys():
		var row: Dictionary = monitors[key]
		flat[str(key)] = row.get("value", 0)
	var custom: Dictionary = snap.get("custom_monitors", {})
	for key in custom.keys():
		flat["CUSTOM:%s" % str(key)] = custom[key]
	var device: Dictionary = snap.get("device", {})
	if bool(device.get("available", false)):
		flat["RD_MEMORY_TEXTURES"] = device.get("memory_textures", 0)
		flat["RD_MEMORY_BUFFERS"] = device.get("memory_buffers", 0)
		flat["RD_MEMORY_TOTAL"] = device.get("memory_total", 0)
	var view: Dictionary = snap.get("viewport", {})
	flat["VIEWPORT_MEASURED_GPU_MS"] = view.get("measured_render_time_gpu_ms", 0.0)
	flat["VIEWPORT_MEASURED_CPU_MS"] = view.get("measured_render_time_cpu_ms", 0.0)
	flat["VIEWPORT_MEASURED_GPU_MS_RAW"] = view.get("measured_render_time_gpu_ms_raw", 0.0)
	flat["VIEWPORT_MEASURED_CPU_MS_RAW"] = view.get("measured_render_time_cpu_ms_raw", 0.0)
	flat["FRAME_SETUP_CPU_MS"] = view.get("frame_setup_time_cpu_ms", 0.0)
	for kind in ["visible", "shadow", "canvas"]:
		if not view.has(kind):
			continue
		var block: Dictionary = view[kind]
		var prefix := "VIEWPORT_%s_" % kind.to_upper()
		flat[prefix + "OBJECTS"] = block.get("objects", 0)
		flat[prefix + "PRIMITIVES"] = block.get("primitives", 0)
		flat[prefix + "DRAW_CALLS"] = block.get("draw_calls", 0)
	return flat
