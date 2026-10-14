extends Node

## Context Capture Utility
## Captures rendering context for every measurement (schema_version, GPU, settings, etc.)

const SCHEMA_VERSION := 2
const Metrics = preload("res://addons/render_lens/metrics_snapshot.gd")

static func capture() -> Dictionary:
	"""Capture current rendering context"""
	var ctx := {}
	ctx.source = "editor" if Engine.is_editor_hint() else "game"
	var tree := Engine.get_main_loop() as SceneTree
	ctx.scene = str(tree.current_scene.scene_file_path) if tree != null and tree.current_scene != null else ""
	ctx.process_id = OS.get_process_id()
	
	# Schema
	ctx.schema_version = SCHEMA_VERSION
	ctx.session_id = _get_session_id()
	ctx.timestamp_ms = Time.get_unix_time_from_system() * 1000
	
	# Engine
	var version_info := Engine.get_version_info()
	ctx.godot_version = "%s.%s.%s.%s" % [
		version_info.major,
		version_info.minor,
		version_info.patch,
		version_info.status
	]
	
	# Rendering
	ctx.renderer = _get_renderer_name()
	ctx.rendering_driver = RenderingServer.get_video_adapter_api_version()
	ctx.gpu = RenderingServer.get_video_adapter_name()
	ctx.gpu_vendor = RenderingServer.get_video_adapter_vendor()
	
	# Platform
	ctx.os = OS.get_name()
	ctx.processor_count = OS.get_processor_count()
	
	# Window/Viewport
	var main_window := DisplayServer.window_get_size()
	ctx.window_size = [main_window.x, main_window.y]
	ctx.vsync = DisplayServer.window_get_vsync_mode()
	ctx.max_fps = Engine.max_fps
	
	# Get active viewport (editor or game)
	var viewport := _get_active_viewport()
	if viewport:
		var vp_size := viewport.get_visible_rect().size
		ctx.viewport_size = [int(vp_size.x), int(vp_size.y)]
		ctx.scaling_3d_mode = viewport.scaling_3d_mode
		ctx.scaling_3d_scale = viewport.scaling_3d_scale
		ctx.msaa_3d = viewport.msaa_3d
		ctx.use_taa = viewport.use_taa
		ctx.screen_space_aa = viewport.screen_space_aa
		ctx.mesh_lod_threshold = viewport.mesh_lod_threshold
		ctx.use_occlusion_culling = viewport.use_occlusion_culling
	
	# Project rendering settings
	ctx.project_renderer = ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method")
	ctx.shadow_atlas_size = ProjectSettings.get_setting_with_override("rendering/lights_and_shadows/positional_shadow/atlas_size")
	ctx.directional_shadow_size = ProjectSettings.get_setting_with_override("rendering/lights_and_shadows/directional_shadow/size")
	
	# Environment (if available)
	var env := _get_active_environment()
	if env:
		ctx.environment = {
			"ssao_enabled": env.ssao_enabled,
			"ssil_enabled": env.ssil_enabled,
			"ssr_enabled": env.ssr_enabled,
			"sdfgi_enabled": env.sdfgi_enabled,
			"glow_enabled": env.glow_enabled,
			"volumetric_fog_enabled": env.volumetric_fog_enabled,
			"adjustment_enabled": env.adjustment_enabled
		}
	
	return ctx

static func compute_hash(ctx: Dictionary) -> String:
	"""Compute context hash for comparison gating"""
	# Hash only the fields that affect rendering performance
	var relevant := {
		"schema_version": ctx.get("schema_version"),
		"source": ctx.get("source"),
		"scene": ctx.get("scene"),
		"godot_version": ctx.get("godot_version"),
		"gpu": ctx.get("gpu"),
		"rendering_driver": ctx.get("rendering_driver"),
		"vsync": ctx.get("vsync"),
		"max_fps": ctx.get("max_fps"),
		"renderer": ctx.get("renderer"),
		"viewport_size": ctx.get("viewport_size"),
		"scaling_3d_scale": ctx.get("scaling_3d_scale"),
		"msaa_3d": ctx.get("msaa_3d"),
		"use_taa": ctx.get("use_taa"),
		"screen_space_aa": ctx.get("screen_space_aa"),
		"environment": ctx.get("environment", {})
	}
	
	var json := JSON.stringify(relevant)
	return json.md5_text()

static func _get_session_id() -> String:
	"""Generate or retrieve session ID"""
	# TODO: Persist across tool calls within same editor session
	return "%d" % Time.get_unix_time_from_system()

static func _get_renderer_name() -> String:
	"""Get human-readable renderer name"""
	# The method the game runs: a --rendering-method argument or a driver fallback changes it, not the project setting.
	var method: String = Metrics.renderer()
	match method:
		"forward_plus":
			return "Forward+"
		"mobile":
			return "Mobile"
		"gl_compatibility":
			return "Compatibility"
		_:
			return method

static func _get_active_viewport() -> Viewport:
	"""Get the active viewport (editor or running game)"""
	# Try to get game viewport first
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		# If game is running, use its viewport
		if tree.current_scene:
			return tree.current_scene.get_viewport()
		# Otherwise use root viewport
		return tree.root
	return null

static func _get_active_environment() -> Environment:
	"""Get the active environment"""
	var viewport := _get_active_viewport()
	if not viewport:
		return null
	
	# The renderer's order: a camera override, then the World3D environment (set by a WorldEnvironment anywhere in the
	# tree), then the world's fallback.
	var camera := viewport.get_camera_3d()
	if camera != null and camera.environment != null:
		return camera.environment
	var world := viewport.find_world_3d()
	if world == null:
		return null
	return world.environment if world.environment != null else world.fallback_environment
