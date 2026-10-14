extends Node

const Game = preload("res://addons/render_lens/game_bridge.gd")

## capture_viewport Tool
## Captures viewport with settle frames and debug_draw modes
## Debug draw modes: normal and overdraw
## Writes PNG, returns path + summary + context

const Context = preload("res://addons/render_lens/context.gd")
const FileHelper = preload("res://addons/render_lens/file_helper.gd")

static func execute(params: Dictionary) -> Dictionary:
	if Engine.is_editor_hint() and str(params.get("source", "game")) != "editor":
		return await Game.request(params, "capture_viewport", 135.0)
	"""Execute capture_viewport tool"""
	var settle_frames: int = params.get("settle_frames", 2)
	var debug_draw: String = params.get("debug_draw", "normal")
	var max_width: int = params.get("max_width", 1920)
	
	# Validate
	if settle_frames < 0 or settle_frames > 30:
		return _build_error("settle_frames must be between 0 and 30")
	if max_width < 1 or max_width > 16384:
		return _build_error("max_width must be between 1 and 16384")
	if debug_draw not in ["normal", "overdraw"]:
		return _build_error("Supported debug draw modes: normal, overdraw")
	
	# Force continuous rendering during capture (disable low-processor mode)
	var original_low_processor := OS.low_processor_usage_mode
	OS.low_processor_usage_mode = false
	
	# Get viewport
	var viewport := _get_target_viewport()
	if not viewport:
		OS.low_processor_usage_mode = original_low_processor
		return _build_error("No active viewport")
	
	# Save original debug draw mode
	var original_debug_draw := viewport.debug_draw
	# A hidden SubViewport (the 3D editor while another main screen is open) is not drawn; ask for one update.
	var original_update := -1
	if viewport is SubViewport:
		original_update = viewport.render_target_update_mode
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	if debug_draw == "overdraw":
		viewport.debug_draw = Viewport.DEBUG_DRAW_OVERDRAW
	else:
		viewport.debug_draw = Viewport.DEBUG_DRAW_DISABLED
	
	# Settle frames (wait for rendering to stabilize)
	for i in range(settle_frames):
		await Engine.get_main_loop().process_frame
	
	# process_frame comes before the draw, so wait for a frame drawn with the new mode (debugger messages arrive after drawing).
	# Godot draws nothing while no window can (minimized, headless; main.cpp skips RenderingServer.draw), so the wait is bounded.
	var drawn := Engine.get_frames_drawn()
	var deadline := Time.get_ticks_msec() + 5000
	while Engine.get_frames_drawn() == drawn and Time.get_ticks_msec() < deadline:
		await Engine.get_main_loop().process_frame
	if Engine.get_frames_drawn() == drawn:
		viewport.debug_draw = original_debug_draw
		OS.low_processor_usage_mode = original_low_processor
		if original_update >= 0:
			viewport.render_target_update_mode = original_update
		return _build_error("Godot drew no frame within 5 s (the window is minimized or the editor runs headless), so there is nothing to capture.")
	
	# Capture
	var texture := viewport.get_texture()
	var image := texture.get_image() if texture != null else null
	
	# Restore debug draw
	viewport.debug_draw = original_debug_draw
	OS.low_processor_usage_mode = original_low_processor
	if original_update >= 0:
		viewport.render_target_update_mode = original_update
	
	if not image:
		return _build_error("Failed to capture viewport texture")
	
	# Resize if needed
	var original_size := image.get_size()
	if original_size.x > max_width:
		var scale := max_width / float(original_size.x)
		var new_height := maxi(1, int(original_size.y * scale))
		image.resize(max_width, new_height, Image.INTERPOLATE_LANCZOS)
	
	# Write PNG
	var path := FileHelper.write_png(image, "capture_%s" % debug_draw)
	if path.is_empty():
		return _build_error("Failed to save PNG")
	
	# Capture context
	var ctx := Context.capture()
	
	# Write metadata JSON
	var metadata := {
		"context": ctx,
		"image": {
			"path": path,
			"size": [image.get_width(), image.get_height()],
			"original_size": [int(original_size.x), int(original_size.y)],
			"debug_draw": debug_draw,
			"settle_frames": settle_frames
		}
	}
	
	var json_path := path.replace(".png", ".json")
	var json_file := FileAccess.open(json_path, FileAccess.WRITE)
	if json_file:
		json_file.store_string(JSON.stringify(metadata, "\t"))
		json_file.close()
	else:
		return _build_error("PNG saved, but failed to write capture metadata: " + json_path)
	
	# Build summary
	var summary := {
		"path": path,
		"metadata_path": json_path,
		"size": "%dx%d" % [image.get_width(), image.get_height()],
		"debug_draw": debug_draw,
		"renderer": ctx.renderer
	}
	
	return {
		"content": [{
			"type": "text",
			"text": JSON.stringify(summary, "\t")
		}]
	}

static func _get_target_viewport() -> Viewport:
	"""Get the target viewport to capture
	
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

static func _build_error(message: String) -> Dictionary:
	"""Build error result"""
	return {
		"isError": true,
		"content": [{
			"type": "text",
			"text": message
		}]
	}
