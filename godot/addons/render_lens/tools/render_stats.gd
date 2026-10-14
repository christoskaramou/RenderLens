extends Node

const Game = preload("res://addons/render_lens/game_bridge.gd")

## render_stats Tool
## Returns global render stats plus VISIBLE/SHADOW/CANVAS split
## Read-only, fast (<100ms)

const Context = preload("res://addons/render_lens/context.gd")

static func execute(params: Dictionary) -> Dictionary:
	if Engine.is_editor_hint() and str(params.get("source", "game")) != "editor":
		return await Game.request(params, "render_stats", 135.0)
	"""Execute render_stats tool"""
	var stats := {}
	
	# Capture context
	stats.context = Context.capture()
	
	# Global stats
	stats.global = _get_global_stats()
	
	# Per-viewport stats (visible/shadow/canvas split)
	stats.viewports = _get_viewport_stats()
	
	# Memory
	stats.memory = _get_memory_stats()
	
	# Pipeline compilations (Godot-specific stutter source)
	stats.pipeline_compilations = _get_pipeline_compilations()
	
	# Summary
	stats.summary = _build_summary(stats)
	
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify(stats, "\t")
		}]
	}

static func _get_global_stats() -> Dictionary:
	"""Get global rendering info"""
	var rs := RenderingServer
	
	return {
		"total_objects_in_frame": rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		"total_primitives_in_frame": rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"total_draw_calls_in_frame": rs.get_rendering_info(rs.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
	}

static func _get_viewport_stats() -> Array:
	"""Get per-viewport stats with VISIBLE/SHADOW/CANVAS split"""
	var viewport_stats := []
	
	var main_viewport := _get_target_viewport()
	if not main_viewport:
		return []
	
	var vp_rid := main_viewport.get_viewport_rid()
	
	# Enable measurement for this viewport
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	
	# Visible pass (3D opaque/transparent)
	var visible := {
		"type": "VISIBLE",
		"objects": RenderingServer.viewport_get_render_info(
			vp_rid,
			RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
			RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME
		),
		"primitives": RenderingServer.viewport_get_render_info(
			vp_rid,
			RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
			RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME
		),
		"draw_calls": RenderingServer.viewport_get_render_info(
			vp_rid,
			RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME
		),
	}
	
	# Shadow pass
	var shadow := {
		"type": "SHADOW",
		"objects": RenderingServer.viewport_get_render_info(
			vp_rid,
			RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW,
			RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME
		),
		"primitives": RenderingServer.viewport_get_render_info(
			vp_rid,
			RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW,
			RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME
		),
		"draw_calls": RenderingServer.viewport_get_render_info(
			vp_rid,
			RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME
		),
	}
	
	# Canvas (2D)
	var canvas := {
		"type": "CANVAS",
		"objects": RenderingServer.viewport_get_render_info(
			vp_rid,
			RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
			RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME
		),
		"primitives": RenderingServer.viewport_get_render_info(
			vp_rid,
			RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
			RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME
		),
		"draw_calls": RenderingServer.viewport_get_render_info(
			vp_rid,
			RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
			RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME
		),
	}
	
	viewport_stats.append(visible)
	viewport_stats.append(shadow)
	viewport_stats.append(canvas)
	
	return viewport_stats

static func _get_memory_stats() -> Dictionary:
	"""Get memory usage"""
	var rs := RenderingServer
	
	return {
		"texture_mem_used_mb": rs.get_rendering_info(rs.RENDERING_INFO_TEXTURE_MEM_USED) / (1024.0 * 1024.0),
		"buffer_mem_used_mb": rs.get_rendering_info(rs.RENDERING_INFO_BUFFER_MEM_USED) / (1024.0 * 1024.0),
		"video_mem_used_mb": rs.get_rendering_info(rs.RENDERING_INFO_VIDEO_MEM_USED) / (1024.0 * 1024.0),
	}

static func _get_pipeline_compilations() -> Dictionary:
	"""Get pipeline compilation counts (Godot-specific stutter source)"""
	var rs := RenderingServer
	
	return {
		"canvas": rs.get_rendering_info(rs.RENDERING_INFO_PIPELINE_COMPILATIONS_CANVAS),
		"mesh": rs.get_rendering_info(rs.RENDERING_INFO_PIPELINE_COMPILATIONS_MESH),
		"surface": rs.get_rendering_info(rs.RENDERING_INFO_PIPELINE_COMPILATIONS_SURFACE),
		"draw": rs.get_rendering_info(rs.RENDERING_INFO_PIPELINE_COMPILATIONS_DRAW),
		"specialization": rs.get_rendering_info(rs.RENDERING_INFO_PIPELINE_COMPILATIONS_SPECIALIZATION),
	}

static func _build_summary(stats: Dictionary) -> Dictionary:
	"""Build human-readable summary"""
	var global: Dictionary = stats.global
	var memory: Dictionary = stats.memory
	var viewports: Array = stats.viewports
	
	var shadow_draws := 0
	var visible_draws := 0
	
	for vp in viewports:
		if vp.type == "SHADOW":
			shadow_draws = vp.draw_calls
		elif vp.type == "VISIBLE":
			visible_draws = vp.draw_calls
	
	var shadow_cost_pct := 0.0
	if global.total_draw_calls_in_frame > 0:
		shadow_cost_pct = (shadow_draws / float(global.total_draw_calls_in_frame)) * 100.0
	
	return {
		"total_draw_calls": global.total_draw_calls_in_frame,
		"visible_draw_calls": visible_draws,
		"shadow_draw_calls": shadow_draws,
		"shadow_cost_percent": "%.1f%%" % shadow_cost_pct,
		"vram_used_mb": "%.1f" % memory.video_mem_used_mb,
		"renderer": stats.context.renderer
	}

static func _get_target_viewport() -> Viewport:
	"""Get the target viewport to measure
	
	Priority:
	1. Running game viewport (tree.current_scene)
	2. Editor 3D viewport (when in editor)
	3. Root viewport (fallback)
	"""
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return null
	
	# If game is running, use game viewport
	if tree.current_scene:
		return tree.current_scene.get_viewport()
	
	# In editor (no game running), try to get 3D editor viewport
	if Engine.is_editor_hint():
		# Try EditorInterface (requires plugin context)
		if Engine.has_singleton("EditorInterface"):
			var editor := Engine.get_singleton("EditorInterface")
			if editor.has_method("get_editor_viewport_3d"):
				var vp3d = editor.get_editor_viewport_3d(0)
				if vp3d:
					return vp3d
	
	# Fallback to root
	return tree.root
