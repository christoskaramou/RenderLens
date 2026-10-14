extends Node

## Custom Monitors Registration
## Adds Render Lens monitors to Godot's Debugger → Monitors tab (Performance.add_custom_monitor)

var registered := false

func _ready() -> void:
	register_monitors()

func register_monitors() -> void:
	"""Register custom monitors"""
	if registered:
		return
	
	# Frame timing
	Performance.add_custom_monitor("RenderLens/Frame/CPU_ms", _get_cpu_frame_time)
	Performance.add_custom_monitor("RenderLens/Frame/GPU_ms", _get_gpu_frame_time)
	Performance.add_custom_monitor("RenderLens/Frame/Setup_ms", _get_frame_setup_time)
	
	# Draw calls
	Performance.add_custom_monitor("RenderLens/Draw/Total", _get_total_draw_calls)
	Performance.add_custom_monitor("RenderLens/Draw/Visible", _get_visible_draw_calls)
	Performance.add_custom_monitor("RenderLens/Draw/Shadow", _get_shadow_draw_calls)
	Performance.add_custom_monitor("RenderLens/Draw/Canvas", _get_canvas_draw_calls)
	
	# Memory
	Performance.add_custom_monitor("RenderLens/Memory/VRAM_MB", _get_vram_used)
	Performance.add_custom_monitor("RenderLens/Memory/Texture_MB", _get_texture_mem)
	Performance.add_custom_monitor("RenderLens/Memory/Buffer_MB", _get_buffer_mem)
	
	# Objects
	Performance.add_custom_monitor("RenderLens/Objects/Total", _get_total_objects)
	Performance.add_custom_monitor("RenderLens/Objects/Primitives", _get_total_primitives)
	
	# Pipeline compilations (stutter source)
	Performance.add_custom_monitor("RenderLens/Stutter/PipelineCompilations", _get_pipeline_compilations_total)
	
	registered = true
	print("[Render Lens] Registered %d custom monitors" % 13)

# Frame timing callbacks
func _get_cpu_frame_time() -> float:
	var viewport := _get_main_viewport()
	if not viewport:
		return 0.0
	return RenderingServer.viewport_get_measured_render_time_cpu(viewport.get_viewport_rid())

func _get_gpu_frame_time() -> float:
	var viewport := _get_main_viewport()
	if not viewport:
		return 0.0
	return RenderingServer.viewport_get_measured_render_time_gpu(viewport.get_viewport_rid())

func _get_frame_setup_time() -> float:
	return RenderingServer.get_frame_setup_time_cpu()

# Draw calls callbacks
func _get_total_draw_calls() -> int:
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)

func _get_visible_draw_calls() -> int:
	var viewport := _get_main_viewport()
	if not viewport:
		return 0
	return RenderingServer.viewport_get_render_info(
		viewport.get_viewport_rid(),
		RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE,
		RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME
	)

func _get_shadow_draw_calls() -> int:
	var viewport := _get_main_viewport()
	if not viewport:
		return 0
	return RenderingServer.viewport_get_render_info(
		viewport.get_viewport_rid(),
		RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW,
		RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME
	)

func _get_canvas_draw_calls() -> int:
	var viewport := _get_main_viewport()
	if not viewport:
		return 0
	return RenderingServer.viewport_get_render_info(
		viewport.get_viewport_rid(),
		RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS,
		RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME
	)

# Memory callbacks
func _get_vram_used() -> float:
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / (1024.0 * 1024.0)

func _get_texture_mem() -> float:
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / (1024.0 * 1024.0)

func _get_buffer_mem() -> float:
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED) / (1024.0 * 1024.0)

# Objects callbacks
func _get_total_objects() -> int:
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)

func _get_total_primitives() -> int:
	return RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)

# Pipeline compilations callback
func _get_pipeline_compilations_total() -> int:
	var rs := RenderingServer
	return rs.get_rendering_info(rs.RENDERING_INFO_PIPELINE_COMPILATIONS_CANVAS) + \
		   rs.get_rendering_info(rs.RENDERING_INFO_PIPELINE_COMPILATIONS_MESH) + \
		   rs.get_rendering_info(rs.RENDERING_INFO_PIPELINE_COMPILATIONS_SURFACE) + \
		   rs.get_rendering_info(rs.RENDERING_INFO_PIPELINE_COMPILATIONS_DRAW) + \
		   rs.get_rendering_info(rs.RENDERING_INFO_PIPELINE_COMPILATIONS_SPECIALIZATION)

func _get_main_viewport() -> Viewport:
	"""Get main viewport"""
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		if tree.current_scene:
			return tree.current_scene.get_viewport()
		return tree.root
	return null
