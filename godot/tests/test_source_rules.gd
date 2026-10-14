extends SceneTree

const Checks = preload("res://addons/render_lens/scene_checks.gd")
const Shaders = preload("res://addons/render_lens/shader_checks.gd")
const Rules = preload("res://addons/render_lens/rule_engine.gd")
const Scan = preload("res://addons/render_lens/scene_scan.gd")
const ProjectScan = preload("res://addons/render_lens/project_scan.gd")
const Invariants = preload("res://tests/golden/advice_invariants.gd")
var covered := {}
## First and last Godot 4 minor version (inclusive) of native warnings that exist in only part of the
## verified range, from diffing get_configuration_warnings() in 4.4, 4.5.2, 4.6.3 and 4.7.2.
const ENGINE_WARNING_RANGES := {
	"physics_body_interpolation": [5, 99], "canvas_group_ancestor": [5, 99], "xr_interpolation": [5, 99],
	"openxr_render_model_parent": [5, 99], "openxr_render_model_extension": [5, 99], "openxr_render_model_pose": [5, 99],
	"label_msdf_pixel_range": [6, 99], "xr_origin_scale": [6, 99], "aim_modifier_axes": [5, 99], "iterate_ik_target": [6, 99],
	"spline_ik_path": [6, 99], "two_bone_ik_targets": [6, 99], "openxr_layer_parent": [4, 6],
	"lightmap_missing_nodes": [5, 99], "openxr_layer_sort_zero": [4, 99], "modifier_node_missing": [7, 99],
}

class PerformanceEffect extends CompositorEffect:
	func _render_callback(_type: int, _data: RenderData) -> void:
		pass


class RuntimeTiles extends TileMapLayer:
	var callback_called := false
	func _use_tile_data_runtime_update(_coords: Vector2i) -> bool:
		callback_called = true
		return true


class InheritedRuntimeTiles extends RuntimeTiles:
	pass


class ScriptedPitchShift extends AudioEffectPitchShift:
	pass


class ScriptedSpectrum extends AudioEffectSpectrumAnalyzer:
	pass


class ScriptedPanelStyle extends StyleBoxFlat:
	pass


class ScriptedFont extends FontFile:
	pass


class ScriptedFontVariation extends FontVariation:
	pass


class ScriptedModifier extends SkeletonModifier3D:
	pass


class ScriptedSkeleton2D extends Skeleton2D:
	pass


class ScriptedModificationStack2D extends SkeletonModificationStack2D:
	pass


class ScriptedTwoBoneIK extends SkeletonModification2DTwoBoneIK:
	pass


class ScriptedJiggle extends SkeletonModification2DJiggle:
	pass


class ScriptedSpring extends SpringBoneSimulator3D:
	pass


class ScriptedSpringCollider extends SpringBoneCollisionSphere3D:
	pass


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_particles()
	_visuals()
	_physics()
	_worlds()
	_more_nodes()
	_materials()
	_navigation_and_animation()
	_connections_and_masks()
	_camera_effects()
	_canvas_and_collision_boundaries()
	_skeleton_modifiers()
	_navigation_and_layout()
	_render_quality()
	_performance_pass_one()
	_performance_pass_two()
	_performance_pass_three()
	_performance_pass_four()
	_performance_pass_five()
	_performance_pass_six()
	_performance_pass_seven()
	_performance_pass_eight()
	_performance_pass_nine()
	_panel_styles()
	_skeleton_ik_selection()
	await _zero_modifier_processing()
	await _zero_skeleton2d_processing()
	await _csg_shapes()
	await _spring_exclude_engine_behaviour()
	await _run_game_waits_for_main_scene_uid()
	_spring_exclude_order()
	_cooperative_alignment()
	_matrix_muladd()
	_script_and_text_warnings()
	_video_playback()
	_gridmaps()
	_tilemaps()
	_shaders()
	_cooperative_vector_operands()
	_cooperative_training_operands()
	_shader_stage_intrinsics()
	_spring_collision_pairs()
	_catalog()
	_advise_order()
	_version_ranges()
	_engine_warnings()
	_documented_costs()
	_import_options()
	_frame_calls()
	_shader_material_copies()
	_runtime_warning_checks()
	var minor: int = Engine.get_version_info().minor
	for key in Checks.KEYS:
		if key in ENGINE_WARNING_RANGES and (minor < ENGINE_WARNING_RANGES[key][0] or minor > ENGINE_WARNING_RANGES[key][1]):
			continue
		if key == "skeleton_ik_bones" and not ClassDB.class_exists("SkeletonIK3D"):
			continue
		if key == "tilemap_physics_chunking" and Engine.get_version_info().minor < 5:
			continue
		if key.begins_with("area_") and not ClassDB.class_exists("AreaLight3D"):
			continue
		assert(covered.has(key + ":true") and covered.has(key + ":false"), "Missing predicate coverage: " + key)
	print("PASS source-derived rules: every supported scene predicate positive/negative, renderer/vendor/version gates, SPIR-V bounds and specialization")
	quit()


func _skeleton_ik_selection() -> void:
	if not ClassDB.class_exists("SkeletonIK3D"):
		return
	var ik: SkeletonModifier3D = ClassDB.instantiate("SkeletonIK3D")
	_expect(ik, "skeleton_ik_bones", false)
	var skeleton := Skeleton3D.new()
	skeleton.add_bone("root")
	skeleton.add_bone("joint")
	skeleton.add_bone("tip")
	skeleton.set_bone_parent(1, 0)
	skeleton.set_bone_parent(2, 1)
	skeleton.add_child(ik)
	_expect(ik, "skeleton_ik_bones", true)
	ik.set("root_bone", "root")
	_expect(ik, "skeleton_ik_bones", true)
	ik.set("tip_bone", "tip")
	_expect(ik, "skeleton_ik_bones", false)
	ik.set("root_bone", "missing")
	_expect(ik, "skeleton_ik_bones", true)
	ik.set("root_bone", "tip")
	_expect(ik, "skeleton_ik_bones", true)
	ik.set("tip_bone", "root")
	_expect(ik, "skeleton_ik_bones", true)
	ik.active = false
	_expect(ik, "skeleton_ik_bones", false)
	ik.set("root_bone", "root")
	ik.set("tip_bone", "tip")
	ik.active = true
	root.add_child(skeleton)
	_expect(ik, "skeleton_ik_bones", false)
	assert(not ik.call("is_running"), "The audit must not start an IK solve")
	skeleton.free()


func _zero_skeleton2d_processing() -> void:
	var skeleton := Skeleton2D.new()
	_expect(skeleton, "skeleton2d_zero_strength", false)
	var first := Bone2D.new()
	first.name = "First"
	first.set_autocalculate_length_and_angle(false)
	first.set_length(10.0)
	first.rest = Transform2D.IDENTITY
	var second := Bone2D.new()
	second.name = "Second"
	second.set_autocalculate_length_and_angle(false)
	second.set_length(10.0)
	second.position = Vector2(10.0, 0.0)
	second.rest = second.transform
	first.add_child(second)
	skeleton.add_child(first)
	var target := Node2D.new()
	target.name = "Target"
	target.position = Vector2(10.0, 10.0)
	skeleton.add_child(target)
	root.add_child(skeleton)
	await process_frame
	_expect(skeleton, "skeleton2d_zero_strength", false)
	var stack := SkeletonModificationStack2D.new()
	stack.enabled = true
	stack.strength = 0.0
	var ik := SkeletonModification2DTwoBoneIK.new()
	ik.set_target_node(NodePath("Target"))
	ik.set_joint_one_bone_idx(0)
	ik.set_joint_two_bone_idx(1)
	stack.add_modification(ik)
	skeleton.set_modification_stack(stack)
	var before := skeleton.get_bone_local_pose_override(1)
	_expect(skeleton, "skeleton2d_zero_strength", true)
	assert(skeleton.get_bone_local_pose_override(1).is_equal_approx(before), "Auditing must not run IK")
	await process_frame
	await process_frame
	var processed := skeleton.get_bone_local_pose_override(1)
	assert(not processed.is_equal_approx(before), "Native IK still calculates and writes an override at strength zero")
	assert(second.transform.is_equal_approx(second.rest), "The zero-strength override must not affect the displayed pose")
	stack.enabled = false
	_expect(skeleton, "skeleton2d_zero_strength", false)
	target.position = Vector2(15.0, 0.0)
	await process_frame
	await process_frame
	assert(skeleton.get_bone_local_pose_override(1).is_equal_approx(processed), "Disabling the stack must stop the IK writes")
	stack.enabled = true
	ik.enabled = false
	_expect(skeleton, "skeleton2d_zero_strength", false)
	ik.enabled = true
	for strength in [0.00000001, 0.5, 1.0]:
		stack.strength = strength
		_expect(skeleton, "skeleton2d_zero_strength", false)
	stack.strength = 0.0
	skeleton.process_mode = Node.PROCESS_MODE_DISABLED
	_expect(skeleton, "skeleton2d_zero_strength", false)
	skeleton.process_mode = Node.PROCESS_MODE_PAUSABLE
	paused = true
	_expect(skeleton, "skeleton2d_zero_strength", false)
	skeleton.process_mode = Node.PROCESS_MODE_ALWAYS
	_expect(skeleton, "skeleton2d_zero_strength", true)
	paused = false
	skeleton.set_process_internal(false)
	skeleton.set_physics_process_internal(false)
	_expect(skeleton, "skeleton2d_zero_strength", false)
	ik.execution_mode = 1
	skeleton.set_process_internal(true)
	_expect(skeleton, "skeleton2d_zero_strength", false)
	skeleton.set_physics_process_internal(true)
	_expect(skeleton, "skeleton2d_zero_strength", true)
	ik.execution_mode = 0
	for resource in [ik, stack, skeleton]:
		var script = ScriptedTwoBoneIK if resource == ik else (ScriptedModificationStack2D if resource == stack else ScriptedSkeleton2D)
		resource.set_script(script)
		_expect(skeleton, "skeleton2d_zero_strength", false)
		resource.set_script(null)
		_expect(skeleton, "skeleton2d_zero_strength", true)
	stack.set_modification_count(0)
	_expect(skeleton, "skeleton2d_zero_strength", false)
	stack.set_modification_count(129)
	stack.set_modification(128, ik)
	_expect(skeleton, "skeleton2d_zero_strength", false)
	stack.set_modification(127, ik)
	_expect(skeleton, "skeleton2d_zero_strength", true)
	stack.set_modification_count(0)
	stack.add_modification(ik)
	var other := Skeleton2D.new()
	other.add_child(first.duplicate())
	other.add_child(target.duplicate())
	root.add_child(other)
	assert(other.get_bone_count() == 2)
	other.set_modification_stack(stack)
	_expect(skeleton, "skeleton2d_zero_strength", false)
	_expect(other, "skeleton2d_zero_strength", true)
	other.set_modification_stack(null)
	other.free()
	skeleton.set_modification_stack(stack)
	_expect(skeleton, "skeleton2d_zero_strength", true)
	for constructor in [SkeletonModification2DTwoBoneIK, SkeletonModification2DLookAt, SkeletonModification2DJiggle, SkeletonModification2DCCDIK, SkeletonModification2DFABRIK]:
		var modification: SkeletonModification2D = constructor.new()
		modification.enabled = false
		modification.call("set_target_node", NodePath("Target"))
		stack.set_modification_count(0)
		stack.add_modification(modification)
		_expect(skeleton, "skeleton2d_zero_strength", false)
		modification.enabled = true
		_expect(skeleton, "skeleton2d_zero_strength", true)
		modification.execution_mode = 1
		_expect(skeleton, "skeleton2d_zero_strength", true)
	stack.set_modification_count(0)
	var jiggle := SkeletonModification2DJiggle.new()
	jiggle.enabled = false
	jiggle.set_target_node(NodePath("Target"))
	jiggle.set_jiggle_data_chain_length(1)
	jiggle.use_colliders = true
	stack.add_modification(jiggle)
	_expect(skeleton, "skeleton2d_jiggle_collision_mode", false)
	jiggle.enabled = true
	_expect(skeleton, "skeleton2d_jiggle_collision_mode", true)
	jiggle.use_colliders = false
	_expect(skeleton, "skeleton2d_jiggle_collision_mode", false)
	jiggle.use_colliders = true
	jiggle.set_jiggle_data_chain_length(0)
	_expect(skeleton, "skeleton2d_jiggle_collision_mode", false)
	jiggle.set_jiggle_data_chain_length(1)
	jiggle.execution_mode = 1
	_expect(skeleton, "skeleton2d_jiggle_collision_mode", false)
	jiggle.set_jiggle_data_chain_length(16)
	_expect(skeleton, "skeleton2d_jiggle_colliders", false)
	jiggle.set_jiggle_data_chain_length(17)
	_expect(skeleton, "skeleton2d_jiggle_colliders", true)
	jiggle.collision_mask = 0
	_expect(skeleton, "skeleton2d_jiggle_colliders", false)
	jiggle.collision_mask = 1
	jiggle.set_script(ScriptedJiggle)
	_expect(skeleton, "skeleton2d_jiggle_colliders", false)
	jiggle.execution_mode = 0
	_expect(skeleton, "skeleton2d_jiggle_collision_mode", false)
	jiggle.set_script(null)
	_expect(skeleton, "skeleton2d_jiggle_collision_mode", true)
	stack.enabled = false
	_expect(skeleton, "skeleton2d_jiggle_collision_mode", false)
	stack.enabled = true
	stack.set_modification_count(0)
	stack.add_modification(SkeletonModification2D.new())
	_expect(skeleton, "skeleton2d_zero_strength", false)
	stack.set_modification_count(0)
	stack.add_modification(ik)
	var rebuilt := [0]
	skeleton.bone_setup_changed.connect(func() -> void: rebuilt[0] += 1)
	second.rest = Transform2D(0.0, Vector2(12.0, 0.0))
	var callbacks_before: int = rebuilt[0]
	_expect(skeleton, "skeleton2d_zero_strength", true)
	assert(rebuilt[0] == callbacks_before, "The audit must not call the cache-rebuilding bone-count getter or emit callbacks")
	skeleton.free()
	print("PASS native two-bone IK runs at zero strength; five native classes; Jiggle collision modes/masks/counts; disabled/paused/script gates; audit does not solve or rebuild bones")


func _zero_modifier_processing() -> void:
	var skeleton := Skeleton3D.new()
	var modifier := SkeletonModifier3D.new()
	modifier.influence = 0.0
	skeleton.add_child(modifier)
	_expect(modifier, "skeleton_zero_influence", false)
	skeleton.add_bone("pose")
	_expect(modifier, "skeleton_zero_influence", false)
	var processed := [0]
	modifier.modification_processed.connect(func() -> void: processed[0] += 1)
	root.add_child(skeleton)
	_expect(modifier, "skeleton_zero_influence", true)
	await process_frame
	await process_frame
	assert(processed[0] > 0, "Zero influence must still run the native modifier processing path")
	var before: int = processed[0]
	_expect(modifier, "skeleton_zero_influence", true)
	assert(processed[0] == before, "Inspecting a modifier must not execute its processing callback")
	for value in [-1.0, 0.25, 1.0]:
		modifier.influence = value
		_expect(modifier, "skeleton_zero_influence", false)
	modifier.influence = 0.0
	modifier.process_mode = Node.PROCESS_MODE_DISABLED
	_expect(modifier, "skeleton_zero_influence", true)
	await process_frame
	await process_frame
	assert(processed[0] > before, "Native skeleton dispatch is controlled by the parent, not the modifier's process mode")
	modifier.active = false
	_expect(modifier, "skeleton_zero_influence", false)
	await process_frame
	before = processed[0]
	await process_frame
	await process_frame
	assert(processed[0] == before, "An inactive modifier must skip its processing body")
	modifier.active = true
	skeleton.process_mode = Node.PROCESS_MODE_DISABLED
	_expect(modifier, "skeleton_zero_influence", false)
	skeleton.process_mode = Node.PROCESS_MODE_INHERIT
	skeleton.set_process_internal(false)
	skeleton.set_physics_process_internal(false)
	_expect(modifier, "skeleton_zero_influence", false)
	skeleton.set_process_internal(true)
	var scripted := ScriptedModifier.new()
	scripted.influence = 0.0
	skeleton.add_child(scripted)
	_expect(scripted, "skeleton_zero_influence", false)
	skeleton.clear_bones()
	_expect(modifier, "skeleton_zero_influence", false)
	root.remove_child(skeleton)
	_expect(modifier, "skeleton_zero_influence", false)
	skeleton.free()
	print("PASS native zero-influence skeleton processing and audit isolation")


func _skeleton_modifiers() -> void:
	var skeleton := Skeleton3D.new()
	skeleton.add_bone("aim")
	var look := LookAtModifier3D.new()
	skeleton.add_child(look)
	_expect(look, "look_at_bone", false)
	root.add_child(skeleton)
	_expect(look, "look_at_bone", true)
	look.active = false
	_expect(look, "look_at_bone", false)
	look.active = true
	look.bone = 0
	_expect(look, "look_at_bone", false)
	for axis in range(6):
		look.forward_axis = axis
		look.primary_rotation_axis = int(axis / 2)
		_expect(look, "look_at_axes", true)
		look.primary_rotation_axis = (int(axis / 2) + 1) % 3
		_expect(look, "look_at_axes", false)
	_expect(look, "look_at_target", false)
	look.target_node = NodePath("../Missing")
	_expect(look, "look_at_target", true)
	var target := Node.new()
	target.name = "WrongType"
	skeleton.add_child(target)
	look.target_node = NodePath("../WrongType")
	_expect(look, "look_at_target", true)
	look.target_node = NodePath("..")
	_expect(look, "look_at_target", false)
	look.active = false
	look.forward_axis = SkeletonModifier3D.BONE_AXIS_PLUS_X
	look.primary_rotation_axis = Vector3.AXIS_X
	look.target_node = NodePath("../Missing")
	for key in ["look_at_axes", "look_at_bone", "look_at_target"]:
		_expect(look, key, false)
	var retarget := RetargetModifier3D.new()
	_expect(retarget, "retarget_children", true)
	_expect(retarget, "retarget_profile", true)
	var intermediate := Node.new()
	retarget.add_child(intermediate)
	intermediate.add_child(Skeleton3D.new())
	_expect(retarget, "retarget_children", true)
	retarget.add_child(Skeleton3D.new())
	_expect(retarget, "retarget_children", false)
	retarget.profile = SkeletonProfile.new()
	_expect(retarget, "retarget_profile", false)
	retarget.active = false
	retarget.profile = null
	_expect(retarget, "retarget_profile", false)
	retarget.free()
	skeleton.free()


func _navigation_and_layout() -> void:
	for link in [NavigationLink2D.new(), NavigationLink3D.new()]:
		link.end_position = link.start_position
		_expect(link, "navigation_link_endpoints", true)
		link.enabled = false
		_expect(link, "navigation_link_endpoints", false)
		link.enabled = true
		link.end_position = Vector2.ONE if link is NavigationLink2D else Vector3.ONE
		_expect(link, "navigation_link_endpoints", false)
		link.free()
	var mesh := MeshInstance2D.new()
	_expect(mesh, "mesh_missing", true)
	mesh.mesh = QuadMesh.new()
	_expect(mesh, "mesh_missing", false)
	mesh.free()
	var scroll := ScrollContainer.new()
	_expect(scroll, "scroll_container_children", true)
	var content := Control.new()
	scroll.add_child(content)
	_expect(scroll, "scroll_container_children", false)
	var extra := Control.new()
	scroll.add_child(extra)
	_expect(scroll, "scroll_container_children", true)
	extra.hide()
	_expect(scroll, "scroll_container_children", false)
	extra.show()
	extra.top_level = true
	_expect(scroll, "scroll_container_children", false)
	content.hide()
	_expect(scroll, "scroll_container_children", true)
	content.show()
	scroll.hide()
	_expect(scroll, "scroll_container_children", false)
	scroll.free()
	var rect := TextureRect.new()
	rect.stretch_mode = TextureRect.STRETCH_TILE
	_expect(rect, "texture_rect_atlas_tile", false)
	var atlas := AtlasTexture.new()
	atlas.atlas = GradientTexture2D.new()
	rect.texture = atlas
	_expect(rect, "texture_rect_atlas_tile", false)
	atlas.margin = Rect2(1, 0, 0, 0)
	_expect(rect, "texture_rect_atlas_tile", true)
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	_expect(rect, "texture_rect_atlas_tile", false)
	rect.stretch_mode = TextureRect.STRETCH_TILE
	var wrapper := AtlasTexture.new()
	wrapper.atlas = atlas
	rect.texture = wrapper
	_expect(rect, "texture_rect_atlas_tile", true)
	atlas.margin = Rect2()
	_expect(rect, "texture_rect_atlas_tile", false)
	rect.free()


func _render_quality() -> void:
	var particles := GPUParticles2D.new()
	particles.trail_sections = 9
	_expect(particles, "particle_trail_segments", false)
	particles.trail_enabled = true
	_expect(particles, "particle_trail_segments", true)
	particles.trail_sections = 8
	_expect(particles, "particle_trail_segments", false)
	particles.trail_sections = 16
	particles.trail_section_subdivisions = 2
	_expect(particles, "particle_trail_segments", false)
	particles.trail_section_subdivisions = 3
	_expect(particles, "particle_trail_segments", true)
	particles.free()
	for node in [Camera3D.new(), WorldEnvironment.new()]:
		_expect(node, "fog_aerial", false)
		var env := Environment.new()
		node.environment = env
		env.fog_enabled = true
		env.fog_aerial_perspective = 0.5
		env.background_mode = Environment.BG_SKY
		env.sky = Sky.new()
		_expect(node, "fog_aerial", false)
		env.sky.sky_material = ProceduralSkyMaterial.new()
		_expect(node, "fog_aerial", true)
		env.background_mode = Environment.BG_COLOR
		_expect(node, "fog_aerial", false)
		env.background_mode = Environment.BG_SKY
		env.fog_enabled = false
		_expect(node, "fog_aerial", false)
		env.fog_enabled = true
		env.fog_aerial_perspective = 0.0
		_expect(node, "fog_aerial", false)
		var attributes := CameraAttributesPractical.new()
		if node is Camera3D:
			node.attributes = attributes
		else:
			node.camera_attributes = attributes
		attributes.dof_blur_amount = 0.2
		_expect(node, "camera_blur_amount", false)
		attributes.dof_blur_far_enabled = true
		_expect(node, "camera_blur_amount", true)
		attributes.dof_blur_amount = 0.1
		_expect(node, "camera_blur_amount", false)
		node.free()
	var probe := ReflectionProbe.new()
	_expect(probe, "probe_lod_disabled", false)
	probe.mesh_lod_threshold = 0.0
	_expect(probe, "probe_lod_disabled", true)
	probe.cull_mask = 0
	_expect(probe, "probe_lod_disabled", false)
	probe.free()
	var viewport := SubViewport.new()
	for key in ["viewport_lod_disabled", "viewport_supersampling", "viewport_msaa_2d"]:
		_expect(viewport, key, false)
	viewport.mesh_lod_threshold = 0.0
	viewport.scaling_3d_scale = 1.5
	viewport.msaa_2d = Viewport.MSAA_4X
	for key in ["viewport_lod_disabled", "viewport_supersampling", "viewport_msaa_2d"]:
		_expect(viewport, key, true)
	viewport.disable_3d = true
	_expect(viewport, "viewport_lod_disabled", false)
	_expect(viewport, "viewport_supersampling", false)
	_expect(viewport, "viewport_msaa_2d", true)
	viewport.disable_3d = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	for key in ["viewport_lod_disabled", "viewport_supersampling", "viewport_msaa_2d"]:
		_expect(viewport, key, false)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
	_expect(viewport, "viewport_supersampling", false)
	viewport.msaa_2d = Viewport.MSAA_2X
	_expect(viewport, "viewport_msaa_2d", false)
	viewport.free()


func _performance_pass_one() -> void:
	var gpu := GPUParticles3D.new()
	_expect(gpu, "gpu_depth_sort", false)
	gpu.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	_expect(gpu, "gpu_depth_sort", true)
	gpu.amount = 1
	_expect(gpu, "gpu_depth_sort", false)
	gpu.amount = 64
	gpu.draw_order = GPUParticles3D.DRAW_ORDER_LIFETIME
	_expect(gpu, "gpu_depth_sort", false)
	gpu.free()
	for cpu in [CPUParticles2D.new(), CPUParticles3D.new()]:
		cpu.amount = 64
		_expect(cpu, "cpu_particle_sort", false)
		cpu.draw_order = 1
		_expect(cpu, "cpu_particle_sort", true)
		cpu.amount = 63
		_expect(cpu, "cpu_particle_sort", false)
		cpu.free()
	var collider := GPUParticlesCollisionHeightField3D.new()
	_expect(collider, "heightfield_camera", false)
	collider.follow_camera_enabled = true
	_expect(collider, "heightfield_camera", true)
	collider.update_mode = GPUParticlesCollisionHeightField3D.UPDATE_MODE_ALWAYS
	_expect(collider, "heightfield_camera", false)
	collider.free()
	var camera := Camera3D.new()
	camera.environment = Environment.new()
	var env := camera.environment
	for key in ["fog_ambient_inject", "sdfgi_small_cells", "ssao_large_radius"]:
		_expect(camera, key, false)
	env.volumetric_fog_ambient_inject = 1.0
	env.sdfgi_min_cell_size = 0.1
	env.ssao_radius = 2.0
	for key in ["fog_ambient_inject", "sdfgi_small_cells", "ssao_large_radius"]:
		_expect(camera, key, false)
	env.volumetric_fog_enabled = true
	env.sdfgi_enabled = true
	env.ssao_enabled = true
	for key in ["fog_ambient_inject", "sdfgi_small_cells", "ssao_large_radius"]:
		_expect(camera, key, true)
	env.volumetric_fog_ambient_inject = 0.0
	env.sdfgi_min_cell_size = 0.2
	env.ssao_radius = 1.0
	for key in ["fog_ambient_inject", "sdfgi_small_cells", "ssao_large_radius"]:
		_expect(camera, key, false)
	camera.free()
	var skeleton := Skeleton3D.new()
	skeleton.add_bone("root")
	var mesh := MeshInstance3D.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	arrays[Mesh.ARRAY_BONES] = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
	arrays[Mesh.ARRAY_WEIGHTS] = PackedFloat32Array([1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0])
	mesh.mesh = ArrayMesh.new()
	mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	skeleton.add_child(mesh)
	_expect(mesh, "skin_dynamic_bounds", false)
	root.add_child(skeleton)
	mesh.skeleton = NodePath("..")
	_expect(mesh, "skin_dynamic_bounds", true)
	_expect(mesh, "skin_eight_weights", false)
	mesh.custom_aabb = AABB(Vector3.ZERO, Vector3.ONE)
	_expect(mesh, "skin_dynamic_bounds", false)
	mesh.custom_aabb = AABB()
	mesh.mesh.custom_aabb = AABB(Vector3.ZERO, Vector3.ONE)
	_expect(mesh, "skin_dynamic_bounds", false)
	mesh.mesh.custom_aabb = AABB()
	mesh.skeleton = NodePath("missing")
	_expect(mesh, "skin_dynamic_bounds", false)
	mesh.skeleton = NodePath("..")
	mesh.mesh = ArrayMesh.new()
	arrays[Mesh.ARRAY_BONES] = null
	arrays[Mesh.ARRAY_WEIGHTS] = null
	mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_expect(mesh, "skin_dynamic_bounds", false)
	skeleton.free()


func _performance_pass_two() -> void:
	var material := StandardMaterial3D.new()
	material.metallic = 1.0
	material.metallic_texture = GradientTexture2D.new()
	_expect(material, "material_orm_pack", false)
	material.roughness_texture = GradientTexture2D.new()
	_expect(material, "material_orm_pack", true)
	material.ao_enabled = true
	material.ao_on_uv2 = true
	_expect(material, "material_orm_pack", false)
	material.ao_enabled = false
	_expect(material, "material_orm_pack", true)
	material.metallic = 0.0
	_expect(material, "material_orm_pack", false)
	material.metallic = 1.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_expect(material, "material_orm_pack", false)
	_expect(ORMMaterial3D.new(), "material_orm_pack", false)
	var copy := BackBufferCopy.new()
	_expect(copy, "backbuffer_full", false)
	copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	_expect(copy, "backbuffer_full", true)
	copy.hide()
	_expect(copy, "backbuffer_full", false)
	copy.show()
	copy.copy_mode = BackBufferCopy.COPY_MODE_RECT
	copy.rect = Rect2()
	_expect(copy, "backbuffer_full", true)
	copy.rect = Rect2(0, 0, 1, 1)
	_expect(copy, "backbuffer_full", false)
	copy.copy_mode = BackBufferCopy.COPY_MODE_DISABLED
	_expect(copy, "backbuffer_full", false)
	copy.free()
	var csg := CSGCombiner3D.new()
	_expect(csg, "csg_composition", false)
	var box := CSGBox3D.new()
	csg.add_child(box)
	_expect(csg, "csg_composition", true)
	_expect(box, "csg_composition", false)
	csg.free()
	for agent in [NavigationAgent2D.new(), NavigationAgent3D.new()]:
		agent.max_neighbors = 11
		_expect(agent, "navigation_neighbors", false)
		agent.avoidance_enabled = true
		_expect(agent, "navigation_neighbors", true)
		agent.max_neighbors = 10
		_expect(agent, "navigation_neighbors", false)
		agent.max_neighbors = 11
		agent.neighbor_distance = 0.0
		_expect(agent, "navigation_neighbors", false)
		agent.free()
	var rich := RichTextLabel.new()
	rich.text = "x".repeat(32768)
	_expect(rich, "richtext_sync", false)
	rich.text += "x"
	_expect(rich, "richtext_sync", true)
	rich.threaded = true
	_expect(rich, "richtext_sync", false)
	rich.threaded = false
	rich.clear()
	assert(rich.text.length() == 32769)
	_expect(rich, "richtext_sync", false)
	rich.add_text("x".repeat(32769))
	_expect(rich, "richtext_sync", true)
	rich.text = ""
	rich.push_color(Color.RED)
	rich.add_text("x".repeat(32768))
	rich.pop()
	_expect(rich, "richtext_sync", false)
	rich.add_text("x")
	assert(rich.text.is_empty())
	_expect(rich, "richtext_sync", true)
	rich.bbcode_enabled = true
	rich.text = "[b][/b]".repeat(5000)
	_expect(rich, "richtext_sync", false)
	rich.free()


func _performance_pass_three() -> void:
	var provider := WorldEnvironment.new()
	provider.environment = Environment.new()
	var env := provider.environment
	env.volumetric_fog_enabled = true
	env.volumetric_fog_gi_inject = 1.0
	_expect(provider, "fog_sdfgi_inject", false)
	env.sdfgi_enabled = true
	_expect(provider, "fog_sdfgi_inject", true)
	env.volumetric_fog_gi_inject = 0.0001
	_expect(provider, "fog_sdfgi_inject", false)
	env.volumetric_fog_gi_inject = 0.00011
	_expect(provider, "fog_sdfgi_inject", true)
	env.volumetric_fog_enabled = false
	_expect(provider, "fog_sdfgi_inject", false)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	viewport.add_child(provider)
	var light := OmniLight3D.new()
	_expect(light, "light_volumetric_fog", false)
	viewport.add_child(light)
	_expect(light, "light_volumetric_fog", false)
	env.volumetric_fog_enabled = true
	_expect(light, "light_volumetric_fog", true)
	light.light_volumetric_fog_energy = 0.0
	_expect(light, "light_volumetric_fog", false)
	light.light_volumetric_fog_energy = 1.0
	light.light_energy = 0.0
	_expect(light, "light_volumetric_fog", false)
	light.light_energy = 1.0
	var camera := Camera3D.new()
	camera.environment = Environment.new()
	viewport.add_child(camera)
	camera.make_current()
	_expect(light, "light_volumetric_fog", false)
	camera.environment = null
	_expect(light, "light_volumetric_fog", true)
	light.shadow_enabled = true
	_expect(light, "light_shadow_blur", false)
	light.shadow_blur = 2.0
	_expect(light, "light_shadow_blur", true)
	light.shadow_enabled = false
	_expect(light, "light_shadow_blur", false)
	light.shadow_enabled = true
	light.hide()
	for key in ["light_shadow_blur", "light_volumetric_fog"]:
		_expect(light, key, false)
	light.show()
	light.editor_only = true
	for key in ["light_shadow_blur", "light_volumetric_fog"]:
		_expect(light, key, false)
	viewport.physics_object_picking = true
	viewport.physics_object_picking_sort = true
	viewport.gui_disable_input = false
	_expect(viewport, "viewport_pick_sort", true)
	viewport.gui_disable_input = true
	_expect(viewport, "viewport_pick_sort", false)
	viewport.gui_disable_input = false
	viewport.physics_object_picking = false
	_expect(viewport, "viewport_pick_sort", false)
	viewport.physics_object_picking = true
	viewport.physics_object_picking_sort = false
	_expect(viewport, "viewport_pick_sort", false)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_expect(viewport, "viewport_hdr2d", false)
	viewport.use_hdr_2d = true
	_expect(viewport, "viewport_hdr2d", true)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_expect(viewport, "viewport_hdr2d", false)
	var gpu := GPUParticles2D.new()
	var process := ParticleProcessMaterial.new()
	process.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
	gpu.process_material = process
	_expect(gpu, "particle_sdf2d_quality", false)
	viewport.add_child(gpu)
	viewport.sdf_scale = Viewport.SDF_SCALE_50_PERCENT
	viewport.sdf_oversize = Viewport.SDF_OVERSIZE_120_PERCENT
	_expect(gpu, "particle_sdf2d_quality", false)
	viewport.sdf_scale = Viewport.SDF_SCALE_100_PERCENT
	_expect(gpu, "particle_sdf2d_quality", true)
	viewport.sdf_scale = Viewport.SDF_SCALE_50_PERCENT
	viewport.sdf_scale = Viewport.SDF_SCALE_25_PERCENT
	_expect(gpu, "particle_sdf2d_quality", false)
	viewport.sdf_scale = Viewport.SDF_SCALE_50_PERCENT
	viewport.sdf_oversize = Viewport.SDF_OVERSIZE_150_PERCENT
	_expect(gpu, "particle_sdf2d_quality", true)
	viewport.sdf_oversize = Viewport.SDF_OVERSIZE_200_PERCENT
	_expect(gpu, "particle_sdf2d_quality", true)
	process.collision_mode = ParticleProcessMaterial.COLLISION_DISABLED
	_expect(gpu, "particle_sdf2d_quality", false)
	gpu.process_material = ShaderMaterial.new()
	_expect(gpu, "particle_sdf2d_quality", false)
	viewport.free()
	var mesh := MeshInstance3D.new()
	mesh.mesh = ArrayMesh.new()
	mesh.extra_cull_margin = 2.0
	_expect(mesh, "mesh_cull_margin", false)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_expect(mesh, "mesh_cull_margin", true)
	mesh.extra_cull_margin = 1.0
	_expect(mesh, "mesh_cull_margin", false)
	mesh.extra_cull_margin = 2.0
	mesh.mesh.custom_aabb = AABB(Vector3.ZERO, Vector3.ONE * 3.0)
	_expect(mesh, "mesh_cull_margin", false)
	mesh.custom_aabb = AABB(Vector3.ZERO, Vector3.ONE)
	_expect(mesh, "mesh_cull_margin", true)
	mesh.custom_aabb = AABB(Vector3.ZERO, Vector3.ONE * 4.0)
	_expect(mesh, "mesh_cull_margin", false)
	mesh.free()
	for sprite in [Sprite3D.new(), Label3D.new()]:
		_expect(sprite, "sprite_opaque_prepass", false)
		sprite.alpha_cut = 2
		_expect(sprite, "sprite_opaque_prepass", true)
		sprite.material_override = StandardMaterial3D.new()
		_expect(sprite, "sprite_opaque_prepass", false)
		sprite.material_override = null
		sprite.alpha_cut = 1
		_expect(sprite, "sprite_opaque_prepass", false)
		sprite.free()
	for node in [Sprite2D.new(), Sprite3D.new(), TextureRect.new()]:
		var texture := AnimatedTexture.new()
		texture.set_frame_texture(0, GradientTexture2D.new())
		node.texture = texture
		_expect(node, "animated_texture", false)
		texture.frames = 2
		texture.set_frame_texture(1, GradientTexture2D.new())
		_expect(node, "animated_texture", true)
		texture.pause = true
		_expect(node, "animated_texture", false)
		texture.pause = false
		texture.speed_scale = 0.0
		_expect(node, "animated_texture", false)
		texture.speed_scale = -1.0
		_expect(node, "animated_texture", true)
		if node is Sprite3D:
			node.material_override = StandardMaterial3D.new()
		else:
			node.use_parent_material = true
		_expect(node, "animated_texture", false)
		node.free()


func _performance_pass_four() -> void:
	for body in [RigidBody2D.new(), RigidBody3D.new()]:
		_expect(body, "rigid_sleep_disabled", false)
		body.can_sleep = false
		_expect(body, "rigid_sleep_disabled", true)
		body.max_contacts_reported = 33
		_expect(body, "rigid_contact_budget", false)
		body.contact_monitor = true
		_expect(body, "rigid_contact_budget", true)
		body.max_contacts_reported = 32
		_expect(body, "rigid_contact_budget", false)
		body.max_contacts_reported = 33
		body.freeze = true
		_expect(body, "rigid_contact_budget", false)
		_expect(body, "rigid_sleep_disabled", false)
		body.free()
	var line := Line2D.new()
	line.round_precision = 9
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_expect(line, "line_round_precision", false)
	line.points = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT])
	_expect(line, "line_round_precision", true)
	line.round_precision = 8
	_expect(line, "line_round_precision", false)
	line.round_precision = 9
	line.closed = true
	_expect(line, "line_round_precision", true)
	line.points = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.UP])
	_expect(line, "line_round_precision", false)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	_expect(line, "line_round_precision", true)
	line.width = 0.0
	_expect(line, "line_round_precision", false)
	line.width = 1.0
	line.hide()
	_expect(line, "line_round_precision", false)
	line.free()
	var sprite := Sprite2D.new()
	var texture := GradientTexture2D.new()
	sprite.texture = texture
	texture.use_hdr = true
	_expect(sprite, "gradient_hdr_size", false)
	texture.width = 512
	texture.height = 512
	_expect(sprite, "gradient_hdr_size", true)
	texture.use_hdr = false
	_expect(sprite, "gradient_hdr_size", false)
	texture.use_hdr = true
	sprite.use_parent_material = true
	_expect(sprite, "gradient_hdr_size", false)
	sprite.free()
	var skeleton := Skeleton3D.new()
	skeleton.add_bone("root")
	var mesh := MeshInstance3D.new()
	mesh.mesh = ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	bones.resize(24)
	weights.resize(24)
	for i in [0, 8, 16]:
		weights[i] = 1.0
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
	skeleton.add_child(mesh)
	mesh.skeleton = NodePath("..")
	_expect(mesh, "skin_eight_weights", false)
	root.add_child(skeleton)
	_expect(mesh, "skin_eight_weights", true)
	mesh.custom_aabb = AABB(Vector3.ZERO, Vector3.ONE)
	_expect(mesh, "skin_eight_weights", true)
	mesh.skeleton = NodePath("missing")
	_expect(mesh, "skin_eight_weights", false)
	skeleton.free()
	var group := Node.new()
	group.name = "ParticleGroup"
	var gpu := GPUParticles2D.new()
	gpu.name = "GPU"
	gpu.amount = 64
	gpu.fixed_fps = 60
	gpu.trail_enabled = true
	gpu.process_material = ParticleProcessMaterial.new()
	gpu.process_material.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
	group.add_child(gpu)
	var cpu := CPUParticles2D.new()
	cpu.name = "CPU"
	group.add_child(cpu)
	var scan := Scan.scan(group, "res://fixture.tscn")
	assert(scan.counts.particle_node_count == 2 and scan.counts.cpu_particle_count == 1)
	for key in ["gpu_particle_high_amount_count", "gpu_particle_fixed_fps_high_count", "gpu_particle_trail_count", "gpu_particle_collision_count"]:
		assert(scan.counts[key] == 1, "Missing 2D coverage: " + key)
	assert(scan.counts.gpu_particle_multi_pass_count == 0)
	assert(scan.offenders.particle_nodes.size() == 2)
	gpu.amount = 8
	gpu.fixed_fps = 30
	gpu.trail_enabled = false
	gpu.process_material.collision_mode = ParticleProcessMaterial.COLLISION_DISABLED
	scan = Scan.scan(group, "res://fixture.tscn")
	for key in ["gpu_particle_high_amount_count", "gpu_particle_fixed_fps_high_count", "gpu_particle_trail_count", "gpu_particle_collision_count"]:
		assert(scan.counts[key] == 0, "Unexpected 2D finding: " + key)
	group.free()


func _performance_pass_five() -> void:
	var source: Font = ThemeDB.fallback_font
	while source is FontVariation:
		source = source.base_font
	assert(source is FontFile)
	var font := source.duplicate() as FontFile
	var label := Label.new()
	label.text = "Test"
	var variation := FontVariation.new()
	variation.base_font = font
	label.add_theme_font_override("font", variation)
	font.multichannel_signed_distance_field = true
	font.msdf_size = 48
	_expect(label, "font_msdf_size", false)
	font.msdf_size = 49
	_expect(label, "font_msdf_size", true)
	font.multichannel_signed_distance_field = false
	_expect(label, "font_msdf_size", false)
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_ONE_QUARTER
	label.add_theme_font_size_override("font_size", 20)
	_expect(label, "font_subpixel_large", false)
	label.add_theme_font_size_override("font_size", 21)
	_expect(label, "font_subpixel_large", true)
	font.fixed_size = 16
	_expect(label, "font_subpixel_large", false)
	font.fixed_size = 0
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	_expect(label, "font_subpixel_large", false)
	font.generate_mipmaps = true
	_expect(label, "font_local_mipmaps", true)
	for sampling in [0.0, 1.0, 2.0, 2.25]:
		font.oversampling = sampling
		_expect(label, "font_oversampling", sampling > 2.0)
	font.multichannel_signed_distance_field = true
	_expect(label, "font_oversampling", false)
	font.multichannel_signed_distance_field = false
	font.fixed_size = 16
	_expect(label, "font_oversampling", false)
	font.fixed_size = 0
	var scripted_font := ScriptedFont.new()
	scripted_font.data = font.data
	scripted_font.oversampling = 3.0
	variation.base_font = scripted_font
	_expect(label, "font_oversampling", false)
	variation.base_font = font
	var scripted_variation := ScriptedFontVariation.new()
	scripted_variation.base_font = font
	label.add_theme_font_override("font", scripted_variation)
	_expect(label, "font_oversampling", false)
	label.add_theme_font_override("font", variation)
	for text_node in [Button.new(), Label3D.new()]:
		text_node.text = "Font override"
		if text_node is Label3D:
			text_node.font = variation
		else:
			text_node.add_theme_font_override("font", variation)
		_expect(text_node, "font_local_mipmaps", true)
		_expect(text_node, "font_oversampling", text_node is Button)
		text_node.text = ""
		_expect(text_node, "font_local_mipmaps", false)
		_expect(text_node, "font_oversampling", false)
		text_node.free()
	label.label_settings = LabelSettings.new()
	label.label_settings.font = FontFile.new()
	for key in ["font_msdf_size", "font_subpixel_large", "font_local_mipmaps", "font_oversampling"]:
		_expect(label, key, false)
	label.label_settings.font = font
	_expect(label, "font_local_mipmaps", true)
	_expect(label, "font_oversampling", true)
	font.generate_mipmaps = false
	_expect(label, "font_local_mipmaps", false)
	label.text = "x".repeat(128)
	label.label_settings.outline_size = 2
	_expect(label, "label_effect_passes", false)
	label.label_settings.shadow_color = Color.BLACK
	_expect(label, "label_effect_passes", true)
	label.visible_characters = 0
	_expect(label, "label_effect_passes", false)
	label.visible_characters = -1
	label.text = "x".repeat(127)
	_expect(label, "label_effect_passes", false)
	label.text += "x"
	label.label_settings.outline_color.a = 0.0
	_expect(label, "label_effect_passes", false)
	label.label_settings = null
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_expect(label, "label_effect_passes", true)
	label.free()
	for node in [MeshInstance2D.new(), MeshInstance3D.new()]:
		var mesh := TextMesh.new()
		node.mesh = mesh
		mesh.curve_step = 0.25
		_expect(node, "textmesh_detail", false)
		mesh.text = "Text"
		_expect(node, "textmesh_detail", true)
		mesh.curve_step = 0.5
		_expect(node, "textmesh_detail", false)
		mesh.font_size = 64
		_expect(node, "textmesh_detail", true)
		mesh.font_size = 63
		_expect(node, "textmesh_detail", false)
		node.free()
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var world := WorldEnvironment.new()
	var effect := PerformanceEffect.new()
	effect.enabled = true
	effect.effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_OPAQUE
	effect.access_resolved_color = true
	effect.needs_motion_vectors = true
	effect.needs_normal_roughness = true
	world.compositor = Compositor.new()
	world.compositor.compositor_effects = [effect]
	for key in ["compositor_msaa_resolve", "compositor_motion", "compositor_extra_buffers"]:
		_expect(world, key, false)
	viewport.add_child(world)
	_expect(world, "worldenv_conflict", false)
	var second := WorldEnvironment.new()
	second.compositor = Compositor.new()
	viewport.add_child(second)
	_expect(second, "worldenv_conflict", true)
	_expect(second, "compositor_motion", false)
	second.free()
	_expect(world, "compositor_msaa_resolve", false)
	_expect(world, "compositor_motion", true)
	_expect(world, "compositor_extra_buffers", false)
	world.environment = Environment.new()
	_expect(world, "compositor_extra_buffers", true)
	viewport.msaa_3d = Viewport.MSAA_2X
	_expect(world, "compositor_msaa_resolve", true)
	for stage in [CompositorEffect.EFFECT_CALLBACK_TYPE_POST_SKY, CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT]:
		effect.effect_callback_type = stage
		_expect(world, "compositor_msaa_resolve", false)
	effect.effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_PRE_TRANSPARENT
	effect.access_resolved_color = false
	effect.access_resolved_depth = true
	_expect(world, "compositor_msaa_resolve", true)
	viewport.use_taa = true
	_expect(world, "compositor_motion", false)
	viewport.use_taa = false
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
	_expect(world, "compositor_motion", false)
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.make_current()
	camera.compositor = Compositor.new()
	for key in ["compositor_msaa_resolve", "compositor_motion", "compositor_extra_buffers"]:
		_expect(world, key, false)
	camera.compositor.compositor_effects = [effect]
	for key in ["compositor_msaa_resolve", "compositor_motion", "compositor_extra_buffers"]:
		_expect(camera, key, true)
	effect.enabled = false
	for key in ["compositor_msaa_resolve", "compositor_motion", "compositor_extra_buffers"]:
		_expect(camera, key, false)
	effect.enabled = true
	viewport.disable_3d = true
	_expect(camera, "compositor_motion", false)
	viewport.disable_3d = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_expect(camera, "compositor_motion", false)
	viewport.free()


func _performance_pass_six() -> void:
	for mesh in [PlaneMesh.new(), BoxMesh.new(), SphereMesh.new(), CylinderMesh.new(), CapsuleMesh.new(), TorusMesh.new()]:
		var node := MeshInstance3D.new()
		node.mesh = mesh
		_expect(node, "primitive_density", false)
		if mesh is PlaneMesh:
			mesh.subdivide_width = 125
			mesh.subdivide_depth = 62
			_expect(node, "primitive_density", false)
			mesh.subdivide_width = 126
		elif mesh is BoxMesh:
			mesh.subdivide_width = 64
			mesh.subdivide_height = 64
			mesh.subdivide_depth = 64
		elif mesh is TorusMesh:
			mesh.rings = 128
			mesh.ring_segments = 64
		else:
			mesh.radial_segments = 256
			mesh.rings = 64
		_expect(node, "primitive_density", true)
		var actual: int = mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX].size()
		assert(Checks._primitive_vertex_floor(mesh) <= actual and actual >= 8192)
		node.free()
	for path in [Path2D.new(), Path3D.new()]:
		_expect(path, "path_dense_cache", false)
		var curve: Resource = Curve2D.new() if path is Path2D else Curve3D.new()
		path.curve = curve
		curve.bake_interval = 0.01
		_expect(path, "path_dense_cache", false)
		if path is Path2D:
			curve.add_point(Vector2.ZERO)
			curve.add_point(Vector2.ONE)
		else:
			curve.add_point(Vector3.ZERO)
			curve.add_point(Vector3.ONE)
		_expect(path, "path_dense_cache", true)
		curve.bake_interval = 1.0 if path is Path2D else 0.05
		_expect(path, "path_dense_cache", false)
		curve.bake_interval = 0.0
		_expect(path, "path_dense_cache", false)
		path.free()
	var region := NavigationRegion3D.new()
	_expect(region, "navigation_polygons", false)
	var mesh := NavigationMesh.new()
	mesh.vertices = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.FORWARD])
	for i in range(8192):
		mesh.add_polygon(PackedInt32Array([0, 1, 2]))
	region.navigation_mesh = mesh
	_expect(region, "navigation_polygons", false)
	mesh.add_polygon(PackedInt32Array([0, 1, 2]))
	_expect(region, "navigation_polygons", true)
	region.enabled = false
	_expect(region, "navigation_polygons", false)
	region.enabled = true
	region.navigation_layers = 0
	_expect(region, "navigation_polygons", false)
	region.free()


func _performance_pass_seven() -> void:
	var viewport := SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_expect(viewport, "viewport_shadow_atlas", false)
	viewport.positional_shadow_atlas_size = 4096
	_expect(viewport, "viewport_shadow_atlas", true)
	viewport.positional_shadow_atlas_size = 2048
	viewport.positional_shadow_atlas_16_bits = false
	_expect(viewport, "viewport_shadow_atlas", true)
	viewport.positional_shadow_atlas_size = 0
	_expect(viewport, "viewport_shadow_atlas", false)
	viewport.positional_shadow_atlas_size = 4096
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	_expect(viewport, "viewport_msaa_fxaa", false)
	viewport.msaa_3d = Viewport.MSAA_2X
	_expect(viewport, "viewport_msaa_fxaa", true)
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	_expect(viewport, "viewport_msaa_fxaa", false)
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	viewport.disable_3d = true
	for key in ["viewport_shadow_atlas", "viewport_msaa_fxaa"]:
		_expect(viewport, key, false)
	viewport.disable_3d = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	for key in ["viewport_shadow_atlas", "viewport_msaa_fxaa"]:
		_expect(viewport, key, false)
	viewport.free()
	var noise := FastNoiseLite.new()
	var texture := NoiseTexture2D.new()
	texture.width = 1024
	texture.height = 1024
	var sprite := Sprite2D.new()
	sprite.texture = texture
	_expect(sprite, "noise_texture_startup", false)
	texture.noise = noise
	_expect(sprite, "noise_texture_startup", true)
	texture.width = 1023
	_expect(sprite, "noise_texture_startup", false)
	texture.width = 256
	texture.height = 256
	noise.fractal_octaves = 5
	_expect(sprite, "noise_texture_octaves", false)
	noise.fractal_octaves = 6
	_expect(sprite, "noise_texture_octaves", true)
	texture.width = 255
	_expect(sprite, "noise_texture_octaves", false)
	texture.width = 256
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_expect(sprite, "noise_texture_octaves", false)
	noise.domain_warp_fractal_octaves = 6
	noise.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_PROGRESSIVE
	_expect(sprite, "noise_texture_octaves", false)
	noise.domain_warp_enabled = true
	_expect(sprite, "noise_texture_octaves", true)
	noise.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_NONE
	_expect(sprite, "noise_texture_octaves", false)
	noise.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_PROGRESSIVE
	sprite.material = ShaderMaterial.new()
	_expect(sprite, "noise_texture_octaves", false)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	_expect(material, "noise_texture_octaves", true)
	sprite.free()
	var volume := FogVolume.new()
	var fog := FogMaterial.new()
	volume.material = fog
	var texture3 := NoiseTexture3D.new()
	texture3.noise = noise
	texture3.width = 128
	texture3.height = 128
	texture3.depth = 64
	fog.density_texture = texture3
	_expect(volume, "noise_texture_startup", true)
	_expect(volume, "noise_texture_octaves", true)
	texture3.depth = 63
	_expect(volume, "noise_texture_startup", false)
	texture3.noise = null
	_expect(volume, "noise_texture_octaves", false)
	volume.material = ShaderMaterial.new()
	_expect(volume, "noise_texture_startup", false)
	volume.free()


func _performance_pass_eight() -> void:
	for cast in [ShapeCast2D.new(), ShapeCast3D.new()]:
		cast.shape = CircleShape2D.new() if cast is ShapeCast2D else SphereShape3D.new()
		_expect(cast, "shape_cast_results", false)
		cast.max_results = 33
		_expect(cast, "shape_cast_results", true)
		cast.enabled = false
		_expect(cast, "shape_cast_results", false)
		cast.enabled = true
		cast.collision_mask = 0
		_expect(cast, "shape_cast_results", false)
		cast.collision_mask = 1
		cast.collide_with_bodies = false
		_expect(cast, "shape_cast_results", false)
		cast.collide_with_areas = true
		_expect(cast, "shape_cast_results", true)
		if cast is ShapeCast3D:
			cast.shape = ConcavePolygonShape3D.new()
			_expect(cast, "shape_cast_results", false)
		cast.shape = null
		_expect(cast, "shape_cast_results", false)
		cast.free()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	var material := StandardMaterial3D.new()
	mesh.material_override = material
	assert(Scan.scan(mesh).counts.transparent_alpha_blend_count == 0)
	material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	assert(Scan.scan(mesh).counts.transparent_alpha_blend_count == 1)
	material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_DITHER
	assert(Scan.scan(mesh).counts.transparent_alpha_blend_count == 0)
	material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_DISABLED
	material.proximity_fade_enabled = true
	assert(Scan.scan(mesh).counts.transparent_alpha_blend_count == 1)
	material.proximity_fade_enabled = false
	material.shadow_to_opacity = true
	assert(Scan.scan(mesh).counts.transparent_alpha_blend_count == 1)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	assert(Scan.scan(mesh).counts.transparent_alpha_blend_count == 0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	var scan := Scan.scan(mesh)
	assert(scan.counts.transparent_alpha_blend_count == 0 and scan.counts.transparent_depth_prepass_count == 1)
	mesh.mesh.material = material
	mesh.material_override = StandardMaterial3D.new()
	assert(Scan.scan(mesh).counts.transparent_alpha_blend_count == 0)
	mesh.free()
	for node in [MultiMeshInstance2D.new(), MultiMeshInstance3D.new()]:
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_2D if node is MultiMeshInstance2D else MultiMesh.TRANSFORM_3D
		multi.mesh = QuadMesh.new()
		multi.instance_count = 512
		node.multimesh = multi
		assert(Scan.scan(node).counts.multimesh_max_instances == 512)
		multi.visible_instance_count = 256
		scan = Scan.scan(node)
		assert(scan.counts.multimesh_max_instances == 256 and scan.offenders.multimesh_many_instances.size() == 1)
		multi.visible_instance_count = 255
		scan = Scan.scan(node)
		assert(scan.counts.multimesh_max_instances == 255 and not scan.offenders.has("multimesh_many_instances"))
		multi.visible_instance_count = 0
		assert(Scan.scan(node).counts.multimesh_max_instances == 0)
		multi.visible_instance_count = -1
		multi.mesh = null
		assert(Scan.scan(node).counts.multimesh_max_instances == 0)
		node.free()
	for agent in [NavigationAgent2D.new(), NavigationAgent3D.new()]:
		assert(Scan.scan(agent).counts.navigation_avoidance_count == 0)
		agent.avoidance_enabled = true
		scan = Scan.scan(agent)
		var dimension := "navigation_agent_2d_count" if agent is NavigationAgent2D else "navigation_agent_3d_count"
		assert(scan.counts[dimension] == 1 and scan.counts.navigation_avoidance_count == 1)
		assert(scan.offenders.avoidance_agents.size() == 1)
		agent.free()


func _performance_pass_nine() -> void:
	for body in [CharacterBody2D.new(), CharacterBody3D.new()]:
		var cutoff := 4 if body is CharacterBody2D else 6
		body.max_slides = cutoff + 1
		_expect(body, "character_slide_budget", false)
		var shape: Node = CollisionShape2D.new() if body is CharacterBody2D else CollisionShape3D.new()
		shape.shape = CircleShape2D.new() if body is CharacterBody2D else SphereShape3D.new()
		body.add_child(shape)
		_expect(body, "character_slide_budget", true)
		shape.disabled = true
		_expect(body, "character_slide_budget", false)
		shape.disabled = false
		body.max_slides = cutoff
		_expect(body, "character_slide_budget", false)
		body.max_slides += 1
		body.collision_mask = 0
		_expect(body, "character_slide_budget", false)
		body.collision_mask = 1
		body.process_mode = Node.PROCESS_MODE_DISABLED
		_expect(body, "character_slide_budget", false)
		body.free()
	var soft := SoftBody3D.new()
	soft.simulation_precision = 6
	_expect(soft, "softbody_precision", false)
	soft.mesh = ArrayMesh.new()
	_expect(soft, "softbody_precision", false)
	soft.mesh = SphereMesh.new()
	_expect(soft, "softbody_precision", true)
	soft.simulation_precision = 5
	_expect(soft, "softbody_precision", false)
	soft.simulation_precision = 6
	soft.process_mode = Node.PROCESS_MODE_DISABLED
	_expect(soft, "softbody_precision", false)
	soft.disable_mode = SoftBody3D.DISABLE_MODE_KEEP_ACTIVE
	_expect(soft, "softbody_precision", true)
	soft.free()
	var audio := AudioStreamPlayer3D.new()
	audio.autoplay = true
	_expect(audio, "audio_unbounded_distance", false)
	audio.stream = AudioStreamWAV.new()
	audio.stream.data = PackedByteArray([0, 0, 0, 0])
	_expect(audio, "audio_unbounded_distance", true)
	audio.max_distance = 50.0
	_expect(audio, "audio_unbounded_distance", false)
	audio.max_distance = 0.0
	audio.autoplay = false
	_expect(audio, "audio_unbounded_distance", false)
	root.add_child(audio)
	audio.play()
	_expect(audio, "audio_unbounded_distance", true)
	audio.stop()
	_expect(audio, "audio_unbounded_distance", false)
	audio.free()


func _panel_styles() -> void:
	for panel in [Panel.new(), PanelContainer.new()]:
		var style := StyleBoxFlat.new()
		panel.add_theme_stylebox_override("panel", style)
		panel.size = Vector2(128, 128)
		style.set_corner_radius_all(16)
		assert(style.corner_detail == 8)
		_expect(panel, "panel_corner_detail", false)
		style.corner_detail = 9
		_expect(panel, "panel_corner_detail", true)
		style.bg_color.a = 0.0
		_expect(panel, "panel_corner_detail", false)
		style.bg_color.a = 1.0
		style.set_corner_radius_all(0)
		_expect(panel, "panel_corner_detail", false)
		style.set_corner_radius(CORNER_TOP_LEFT, 16)
		_expect(panel, "panel_corner_detail", true)
		style.set_corner_radius(CORNER_TOP_RIGHT, -32)
		_expect(panel, "panel_corner_detail", false)
		style.set_corner_radius(CORNER_TOP_RIGHT, 0)
		panel.visible = false
		_expect(panel, "panel_corner_detail", false)
		panel.visible = true
		style.draw_center = false
		_expect(panel, "panel_corner_detail", false)
		style.shadow_size = 4
		style.shadow_color = Color.BLACK
		_expect(panel, "panel_corner_detail", true)
		style.shadow_color.a = 0.0
		_expect(panel, "panel_corner_detail", false)
		style.set_border_width_all(1)
		style.border_color = Color.WHITE
		_expect(panel, "panel_corner_detail", true)
		style.set_border_width_all(64)
		_expect(panel, "panel_corner_detail", false)
		style.set_border_width_all(0)
		style.shadow_size = 0
		style.draw_center = true
		panel.size = Vector2.ZERO
		_expect(panel, "panel_corner_detail", false)
		panel.size = Vector2(0.000001, 128)
		_expect(panel, "panel_corner_detail", false)
		panel.size = Vector2.ZERO
		style.set_expand_margin_all(4)
		_expect(panel, "panel_corner_detail", true)
		style.set_expand_margin_all(-4)
		_expect(panel, "panel_corner_detail", false)
		style.set_expand_margin_all(0)
		panel.size = Vector2(128, 128)
		var parent := Control.new()
		parent.add_child(panel)
		root.add_child(parent)
		_expect(panel, "panel_corner_detail", true)
		parent.visible = false
		_expect(panel, "panel_corner_detail", false)
		parent.visible = true
		panel.remove_theme_stylebox_override("panel")
		var theme := Theme.new()
		theme.set_stylebox("panel", panel.get_class(), style)
		parent.theme = theme
		_expect(panel, "panel_corner_detail", true)
		panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		_expect(panel, "panel_corner_detail", false)
		var scripted := ScriptedPanelStyle.new()
		scripted.corner_detail = 20
		scripted.set_corner_radius_all(16)
		panel.add_theme_stylebox_override("panel", scripted)
		_expect(panel, "panel_corner_detail", false)
		parent.free()


func _video_playback() -> void:
	load("res://tests/test_video_checks.gd").run(self, _expect)

func _expect(node: Object, key: String, value: bool) -> void:
	var state := {"counts": {}, "offenders": {}}
	if node is Material:
		Checks.inspect_material(node, state, "res://fixture.tscn::TestNode", false)
	else:
		Checks.inspect(node, state, "res://fixture.tscn::TestNode")
	assert((int(state.counts.get("check_" + key, 0)) > 0) == value, key + " expected " + str(value))
	if value:
		if key in ["skeleton2d_zero_strength", "skeleton2d_jiggle_collision_mode", "skeleton2d_jiggle_colliders"]:
			assert(state.offenders["check_" + key].size() == 1)
			assert(str(state.offenders["check_" + key][0]).begins_with("res://fixture.tscn::TestNode [modification="))
		elif key == "missing_node":
			assert(str(state.offenders["check_" + key][0]).begins_with("res://fixture.tscn::TestNode [original_class="))
		else:
			assert(state.offenders["check_" + key] == ["res://fixture.tscn::TestNode"])
	covered[key + ":" + str(value)] = true


func _particles() -> void:
	var p := GPUParticles3D.new()
	_expect(p, "gpu_process_missing", true)
	_expect(p, "gpu_mesh_missing", true)
	p.process_material = ParticleProcessMaterial.new()
	p.draw_pass_1 = QuadMesh.new()
	_expect(p, "gpu_process_missing", false)
	_expect(p, "gpu_mesh_missing", false)
	_expect(p, "particles_animation_3d", false)
	p.process_material.anim_speed_max = 1.0
	_expect(p, "particles_animation_3d", true)
	p.material_override = StandardMaterial3D.new()
	p.material_override.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_expect(p, "particles_animation_3d", false)
	_expect(p, "trails_renderer", false)
	p.trail_enabled = true
	_expect(p, "trails_renderer", true)
	_expect(p, "trails_no_pose", true)
	p.draw_pass_1 = RibbonTrailMesh.new()
	_expect(p, "trails_no_pose", false)
	_expect(p, "trails_material", true)
	p.material_override.use_particle_trails = true
	_expect(p, "trails_material", false)
	# Effective override wins even when the embedded material has trails disabled.
	p.draw_pass_1.material = StandardMaterial3D.new()
	_expect(p, "trails_material", false)
	p.material_override = ShaderMaterial.new()
	_expect(p, "trails_material", false)
	_expect(p, "trails_multiple", false)
	p.draw_passes = 2
	p.draw_pass_2 = TubeTrailMesh.new()
	_expect(p, "trails_multiple", true)
	_expect(p, "trails_skin", false)
	p.draw_skin = Skin.new()
	_expect(p, "trails_skin", true)
	_expect(p, "trails_multiple", false)
	_expect(p, "subemitter_renderer", false)
	p.sub_emitter = NodePath("Secondary")
	_expect(p, "subemitter_renderer", true)
	p.free()
	var cpu := CPUParticles3D.new()
	_expect(cpu, "cpu_mesh_missing", true)
	cpu.mesh = QuadMesh.new()
	_expect(cpu, "cpu_mesh_missing", false)
	_expect(cpu, "particles_animation_3d", false)
	cpu.anim_speed_max = 1.0
	_expect(cpu, "particles_animation_3d", true)
	cpu.material_override = StandardMaterial3D.new()
	cpu.material_override.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_expect(cpu, "particles_animation_3d", false)
	cpu.material_override = ShaderMaterial.new()
	_expect(cpu, "particles_animation_3d", false)
	cpu.free()
	var cpu2 := CPUParticles2D.new()
	_expect(cpu2, "particles_animation_2d", false)
	cpu2.anim_offset_max = 1.0
	_expect(cpu2, "particles_animation_2d", true)
	cpu2.material = CanvasItemMaterial.new()
	cpu2.material.particles_animation = true
	_expect(cpu2, "particles_animation_2d", false)
	cpu2.material = ShaderMaterial.new()
	_expect(cpu2, "particles_animation_2d", false)
	cpu2.free()
	var p2 := GPUParticles2D.new()
	p2.process_material = ParticleProcessMaterial.new()
	_expect(p2, "particles_animation_2d", false)
	p2.process_material.anim_offset_max = 0.5
	_expect(p2, "particles_animation_2d", true)
	p2.material = CanvasItemMaterial.new()
	p2.material.particles_animation = true
	_expect(p2, "particles_animation_2d", false)
	p2.material = ShaderMaterial.new()
	_expect(p2, "particles_animation_2d", false)
	p2.free()


func _visuals() -> void:
	var tex := GradientTexture2D.new()
	var decal := Decal.new()
	_expect(decal, "decal_textures", true)
	_expect(decal, "decal_albedo", false)
	decal.texture_normal = tex
	_expect(decal, "decal_textures", false)
	_expect(decal, "decal_albedo", true)
	decal.texture_albedo = tex
	_expect(decal, "decal_albedo", false)
	_expect(decal, "decal_mask", false)
	decal.cull_mask = 0
	_expect(decal, "decal_mask", true)
	decal.free()
	var light := SpotLight3D.new()
	_expect(light, "light_scale", false)
	light.scale = Vector3(2, 1, 1)
	_expect(light, "light_scale", true)
	_expect(light, "projector_renderer", false)
	light.light_projector = tex
	_expect(light, "projector_renderer", true)
	_expect(light, "projector_shadows", true)
	light.shadow_enabled = true
	_expect(light, "projector_shadows", false)
	light.spot_angle = 89.9
	_expect(light, "spot_shadows", false)
	light.spot_angle = 90.0
	_expect(light, "spot_shadows", true)
	light.free()
	if ClassDB.class_exists("AreaLight3D"):
		var area: Node = ClassDB.instantiate("AreaLight3D")
		_expect(area, "area_projector", false)
		area.set("light_projector", tex)
		_expect(area, "area_projector", true)
		_expect(area, "area_texture", false)
		area.set("area_texture", tex)
		_expect(area, "area_texture", true)
		_expect(area, "area_shadows", false)
		area.set("shadow_enabled", true)
		_expect(area, "area_shadows", true)
		_expect(area, "area_light_cost", true)
		area.set("visible", false)
		_expect(area, "area_light_cost", false)
		area.free()
	var occluder := OccluderInstance3D.new()
	_expect(occluder, "occluder_missing", true)
	occluder.occluder = ArrayOccluder3D.new()
	_expect(occluder, "occluder_missing", false)
	_expect(occluder, "occluder_empty", true)
	occluder.occluder = BoxOccluder3D.new()
	_expect(occluder, "occluder_empty", false)
	_expect(occluder, "occluder_bake_mask", false)
	occluder.bake_mask = 0
	_expect(occluder, "occluder_bake_mask", true)
	occluder.free()
	var mesh := MeshInstance3D.new()
	_expect(mesh, "mesh_missing", true)
	mesh.mesh = BoxMesh.new()
	_expect(mesh, "mesh_missing", false)
	mesh.free()
	var voxel := VoxelGI.new()
	_expect(voxel, "voxel_renderer", true)
	voxel.free()
	var plain := Node.new()
	_expect(plain, "voxel_renderer", false)
	_expect(plain, "fog_renderer", false)
	plain.free()


func _physics() -> void:
	var shape := CollisionShape3D.new()
	_expect(shape, "collision_parent", true)
	_expect(shape, "collision_resource", true)
	shape.shape = BoxShape3D.new()
	_expect(shape, "collision_resource", false)
	var body := RigidBody3D.new()
	body.add_child(shape)
	_expect(shape, "collision_parent", false)
	_expect(shape, "collision_nonuniform", false)
	shape.scale = Vector3(1, 2, 1)
	_expect(shape, "collision_nonuniform", true)
	shape.shape = ConcavePolygonShape3D.new()
	_expect(shape, "concave_dynamic", true)
	body.freeze = true
	body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	_expect(shape, "concave_dynamic", false)
	body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	_expect(shape, "concave_dynamic", true)
	shape.shape = WorldBoundaryShape3D.new()
	_expect(shape, "boundary_dynamic", true)
	body.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	_expect(shape, "boundary_dynamic", false)
	_expect(body, "rigid_scale", false)
	body.scale = Vector3(1.1, 1, 1)
	_expect(body, "rigid_scale", true)
	body.free()
	var polygon := CollisionPolygon2D.new()
	_expect(polygon, "collision_polygon_parent", true)
	_expect(polygon, "collision_polygon_empty", true)
	var area := Area2D.new()
	area.add_child(polygon)
	_expect(polygon, "collision_polygon_parent", false)
	polygon.polygon = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT])
	_expect(polygon, "collision_polygon_empty", false)
	_expect(polygon, "collision_polygon_points", true)
	polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	_expect(polygon, "collision_polygon_points", false)
	_expect(polygon, "one_way_area", false)
	polygon.one_way_collision = true
	_expect(polygon, "one_way_area", true)
	area.free()


func _worlds() -> void:
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var first := WorldEnvironment.new()
	_expect(first, "worldenv_empty", true)
	first.environment = Environment.new()
	_expect(first, "worldenv_empty", false)
	viewport.add_child(first)
	_expect(first, "worldenv_conflict", false)
	var second := WorldEnvironment.new()
	second.environment = Environment.new()
	viewport.add_child(second)
	_expect(second, "worldenv_conflict", true)
	var fog := FogVolume.new()
	_expect(fog, "fog_renderer", true)
	_expect(fog, "fog_environment", false) # Detached scans do not guess the world.
	viewport.add_child(fog)
	_expect(fog, "fog_environment", true)
	first.environment.volumetric_fog_enabled = true
	_expect(fog, "fog_environment", false)
	var camera := Camera3D.new()
	camera.environment = Environment.new()
	viewport.add_child(camera)
	camera.make_current()
	_expect(fog, "fog_environment", true)
	camera.environment.volumetric_fog_enabled = true
	first.environment.volumetric_fog_enabled = false
	_expect(fog, "fog_environment", false)
	viewport.free()


func _more_nodes() -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	_expect(mesh, "visibility_range_invalid", false)
	mesh.visibility_range_begin = 10.0
	mesh.visibility_range_end = 10.0
	_expect(mesh, "visibility_range_invalid", true)
	mesh.visibility_range_end = 0.0
	_expect(mesh, "visibility_range_invalid", false)
	mesh.visibility_range_end = 20.0
	_expect(mesh, "geometry_fade", false)
	_expect(mesh, "geometry_fade_cost", false)
	mesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	_expect(mesh, "geometry_fade", true)
	_expect(mesh, "visibility_fade_begin", true)
	_expect(mesh, "visibility_fade_end", true)
	mesh.visibility_range_begin_margin = 1.0
	mesh.visibility_range_end_margin = 1.0
	_expect(mesh, "visibility_fade_begin", false)
	_expect(mesh, "visibility_fade_end", false)
	_expect(mesh, "geometry_fade_cost", true)
	mesh.visibility_range_end = 5.0
	_expect(mesh, "geometry_fade_cost", false)
	mesh.visibility_range_end = 20.0
	# Without a mesh the instance is never culled or drawn, so its fade costs nothing.
	var hollow: MeshInstance3D = mesh.duplicate()
	hollow.mesh = null
	_expect(hollow, "geometry_fade_cost", false)
	hollow.free()
	mesh.visibility_range_end = 5.0
	_expect(mesh, "geometry_transparency", false)
	mesh.transparency = 0.5
	_expect(mesh, "geometry_transparency", true)
	mesh.free()
	var light := PointLight2D.new()
	_expect(light, "point_light_texture", true)
	light.texture = GradientTexture2D.new()
	_expect(light, "point_light_texture", false)
	light.free()
	var occluder := LightOccluder2D.new()
	_expect(occluder, "light_occluder_missing", true)
	_expect(occluder, "light_occluder_empty", false)
	occluder.occluder = OccluderPolygon2D.new()
	_expect(occluder, "light_occluder_missing", false)
	_expect(occluder, "light_occluder_empty", true)
	occluder.occluder.polygon = PackedVector2Array([Vector2.ZERO, Vector2.ONE])
	_expect(occluder, "light_occluder_empty", false)
	occluder.free()
	for p in [GPUParticles2D.new(), GPUParticles3D.new()]:
		p.fixed_fps = 0
		p.preprocess = 3.99
		_expect(p, "particle_warmup", false)
		p.preprocess = 4.0
		_expect(p, "particle_warmup", true)
		p.fixed_fps = 60
		p.preprocess = 2.0
		_expect(p, "particle_warmup", true)
		p.free()
	var sdf := GPUParticlesCollisionSDF3D.new()
	_expect(sdf, "particle_sdf_bake_mask", false)
	sdf.bake_mask = 0
	_expect(sdf, "particle_sdf_bake_mask", true)
	_expect(sdf, "particle_sdf_texture", true)
	sdf.resolution = GPUParticlesCollisionSDF3D.RESOLUTION_512
	_expect(sdf, "particle_sdf_large", false) # The setting is not the baked texture.
	var texture := ImageTexture3D.new()
	assert(texture.create(Image.FORMAT_R8, 256, 1, 1, false, [Image.create(256, 1, false, Image.FORMAT_R8)]) == OK)
	sdf.texture = texture
	_expect(sdf, "particle_sdf_texture", false)
	_expect(sdf, "particle_sdf_large", true)
	var parent := Node3D.new()
	parent.scale = Vector3(2, 1, 1)
	parent.add_child(sdf)
	_expect(sdf, "particle_collision_scale", false) # Detached: world scale is unknown.
	root.add_child(parent)
	_expect(sdf, "particle_collision_scale", true)
	sdf.scale = Vector3(0.5, 1, 1)
	_expect(sdf, "particle_collision_scale", false) # Parent compensation must win.
	parent.free()
	var height := GPUParticlesCollisionHeightField3D.new()
	_expect(height, "particle_heightfield_always", false)
	height.update_mode = GPUParticlesCollisionHeightField3D.UPDATE_MODE_ALWAYS
	_expect(height, "particle_heightfield_always", true)
	height.free()
	var container := SubViewportContainer.new()
	_expect(container, "viewport_container_child", true)
	var nested := Node.new()
	nested.add_child(SubViewport.new())
	container.add_child(nested)
	_expect(container, "viewport_container_child", true)
	container.add_child(SubViewport.new())
	_expect(container, "viewport_container_child", false)
	container.free()
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	_expect(viewport, "viewport_ssr_transparent", false)
	root.add_child(viewport)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.ssr_enabled = true
	viewport.add_child(world)
	_expect(viewport, "viewport_ssr_transparent", true)
	var camera := Camera3D.new()
	camera.environment = Environment.new()
	viewport.add_child(camera)
	camera.make_current()
	_expect(viewport, "viewport_ssr_transparent", false)
	camera.environment.ssr_enabled = true
	_expect(viewport, "viewport_ssr_transparent", true)
	viewport.transparent_bg = false
	_expect(viewport, "viewport_ssr_transparent", false)
	viewport.free()
	for sprite in [AnimatedSprite2D.new(), AnimatedSprite3D.new()]:
		sprite.sprite_frames = null
		_expect(sprite, "sprite_frames_missing", true)
		sprite.sprite_frames = SpriteFrames.new()
		_expect(sprite, "sprite_frames_missing", false)
		sprite.free()
	for follow in [PathFollow2D.new(), PathFollow3D.new()]:
		_expect(follow, "path_follow_parent", true)
		var path: Node = Path3D.new() if follow is PathFollow3D else Path2D.new()
		path.add_child(follow)
		_expect(follow, "path_follow_parent", false)
		if follow is PathFollow3D:
			path.curve = Curve3D.new()
			_expect(follow, "path_follow_up_vector", false)
			follow.rotation_mode = PathFollow3D.ROTATION_ORIENTED
			path.curve.up_vector_enabled = false
			_expect(follow, "path_follow_up_vector", true)
			path.curve.up_vector_enabled = true
			_expect(follow, "path_follow_up_vector", false)
		path.free()
	for remote in [RemoteTransform2D.new(), RemoteTransform3D.new()]:
		_expect(remote, "remote_transform_target", false) # Detached paths are not guessed.
		var remote_parent: Node = Node3D.new() if remote is RemoteTransform3D else Node2D.new()
		remote_parent.add_child(remote)
		root.add_child(remote_parent)
		_expect(remote, "remote_transform_target", true)
		var target: Node = Node3D.new() if remote is RemoteTransform3D else Node2D.new()
		root.add_child(target)
		remote.remote_path = remote.get_path_to(target)
		_expect(remote, "remote_transform_target", false)
		remote.remote_path = NodePath("/root")
		_expect(remote, "remote_transform_target", true)
		remote.remote_path = NodePath(".")
		_expect(remote, "remote_transform_target", true)
		remote.remote_path = NodePath("..")
		_expect(remote, "remote_transform_target", true)
		var descendant: Node = Node3D.new() if remote is RemoteTransform3D else Node2D.new()
		remote.add_child(descendant)
		remote.remote_path = remote.get_path_to(descendant)
		_expect(remote, "remote_transform_target", true)
		remote_parent.free()
		target.free()


func _triangle(tangents: bool, normals: bool = false) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP])
	if tangents or normals:
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK])
	if tangents:
		arrays[Mesh.ARRAY_TANGENT] = PackedFloat32Array([1, 0, 0, 1, 1, 0, 0, 1, 1, 0, 0, 1])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _materials() -> void:
	var tex := GradientTexture2D.new()
	for entry in [
		["material_next_pass", {"next_pass": StandardMaterial3D.new()}],
		["material_triplanar_uv1", {"uv1_triplanar": true, "albedo_texture": tex}],
		["material_triplanar_uv2", {"uv2_triplanar": true, "detail_enabled": true, "detail_uv_layer": BaseMaterial3D.DETAIL_UV_2, "detail_albedo": tex}],
		["material_deep_parallax", {"heightmap_enabled": true, "heightmap_deep_parallax": true, "heightmap_texture": tex}],
		["material_clearcoat", {"clearcoat_enabled": true, "clearcoat": 1.0}],
		["material_rim", {"rim_enabled": true, "rim": 1.0}],
		["material_anisotropy", {"anisotropy_enabled": true, "anisotropy": 1.0}],
		["material_detail", {"detail_enabled": true, "detail_albedo": tex}],
		["material_normal", {"normal_enabled": true, "normal_texture": tex}],
		["material_height_triplanar", {"heightmap_enabled": true, "uv1_triplanar": true}],
		["material_msdf_triplanar", {"albedo_texture_msdf": true, "uv1_triplanar": true}],
		["material_unshaded_features", {"shading_mode": BaseMaterial3D.SHADING_MODE_UNSHADED, "clearcoat_enabled": true}],
		["material_particle_trails", {"use_particle_trails": true}],
	]:
		var mat := StandardMaterial3D.new()
		_expect(mat, entry[0], false)
		for prop in entry[1]:
			mat.set(prop, entry[1][prop])
		_expect(mat, entry[0], true)
		if entry[0] == "material_deep_parallax":
			mat.uv1_triplanar = true
			_expect(mat, entry[0], false)
		if entry[0] in ["material_clearcoat", "material_rim", "material_anisotropy", "material_normal"]:
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
			_expect(mat, entry[0], false)
	var mat := StandardMaterial3D.new()
	mat.anisotropy_enabled = true
	mat.anisotropy = 1.0
	for tangents in [false, true]:
		var state := {"counts": {}, "offenders": {}}
		Checks.inspect_surface(_triangle(tangents), 0, mat, state, "res://fixture.tscn::TestNode")
		assert(state.counts.has("check_material_anisotropy_tangents") == not tangents)
		covered["material_anisotropy_tangents:" + str(not tangents)] = true
	var normal_mat := StandardMaterial3D.new()
	for feature in ["normal_enabled", "heightmap_enabled"]:
		normal_mat.set(feature, true)
		for tangents in [false, true]:
			var state := {"counts": {}, "offenders": {}}
			Checks.inspect_surface(_triangle(tangents), 0, normal_mat, state, "res://fixture.tscn::TestNode")
			assert(state.counts.has("check_material_normal_tangents") == not tangents, feature)
			covered["material_normal_tangents:" + str(not tangents)] = true
		normal_mat.uv1_triplanar = true
		var triplanar := {"counts": {}, "offenders": {}}
		Checks.inspect_surface(_triangle(false), 0, normal_mat, triplanar, "triplanar")
		assert(not triplanar.counts.has("check_material_normal_tangents"), "Triplanar " + feature + " builds tangents")
		normal_mat.uv1_triplanar = false
		normal_mat.set(feature, false)
	var generated := {"counts": {}, "offenders": {}}
	Checks.inspect_surface(_triangle(false, true), 0, mat, generated, "generated")
	assert(not generated.counts.has("check_material_anisotropy_tangents"), "Godot's generated tangents are already present in the stored format")
	for property in ["uv1_triplanar", "uv2_triplanar"]:
		mat.set(property, true)
		Checks.inspect_surface(_triangle(false), 0, mat, generated, "triplanar")
		assert(not generated.counts.has("check_material_anisotropy_tangents"), "Triplanar shader generates tangent space")
		mat.set(property, false)
	mat.use_particle_trails = true
	var shared := {"counts": {}, "offenders": {}}
	Checks.inspect_material(mat, shared, "particles", true)
	assert(not shared.counts.has("check_material_particle_trails"))
	Checks.inspect_material(mat, shared, "mesh", false)
	assert(shared.offenders.check_material_particle_trails == ["mesh"])
	var particles := GPUParticles3D.new()
	particles.draw_pass_1 = QuadMesh.new()
	particles.draw_pass_1.material = mat
	particles.material_override = StandardMaterial3D.new()
	var scan := Scan.scan(particles, "res://fixture.tscn")
	assert(scan.counts.check_material_anisotropy == 0, "Inactive particle material must be excluded")
	particles.free()
	var group := Node3D.new()
	var ordinary := MeshInstance3D.new()
	ordinary.mesh = QuadMesh.new()
	ordinary.material_override = mat
	group.add_child(ordinary)
	particles = GPUParticles3D.new()
	particles.draw_passes = 2
	particles.draw_pass_1 = ordinary.mesh
	particles.draw_pass_2 = ordinary.mesh
	particles.material_override = mat
	group.add_child(particles)
	scan = Scan.scan(group, "res://fixture.tscn")
	assert(scan.counts.particle_per_pixel_material_count == 1, "Mesh-first sharing must neither hide nor double-count particle shading")
	group.free()
	var cpu := CPUParticles3D.new()
	cpu.mesh = QuadMesh.new()
	cpu.mesh.material = mat
	scan = Scan.scan(cpu, "res://fixture.tscn")
	assert(scan.counts.particle_per_pixel_material_count == 1, "CPU particle draw materials still perform GPU shading")
	assert(scan.counts.check_material_particle_trails == 1, "CPU particle materials cannot use the GPU trail shader")
	cpu.material_override = StandardMaterial3D.new()
	cpu.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	scan = Scan.scan(cpu, "res://fixture.tscn")
	assert(scan.counts.particle_per_pixel_material_count == 0 and scan.counts.check_material_anisotropy == 0)
	cpu.free()
	var node := MeshInstance3D.new()
	node.mesh = _triangle(false)
	node.mesh.surface_set_material(0, mat)
	node.material_override = StandardMaterial3D.new()
	scan = Scan.scan(node, "res://fixture.tscn")
	assert(scan.counts.check_material_anisotropy_tangents == 0)
	node.material_override = null
	scan = Scan.scan(node, "res://fixture.tscn")
	assert(scan.counts.check_material_anisotropy_tangents == 1)
	var chain := StandardMaterial3D.new()
	node.material_override = chain
	for i in 8:
		chain.next_pass = StandardMaterial3D.new()
		chain = chain.next_pass
	chain.rim_enabled = true
	scan = Scan.scan(node, "res://fixture.tscn")
	assert(scan.material_scan.truncated_chains == 1 and scan.counts.check_material_rim == 0)
	assert(scan.counts.check_material_next_pass == 8)
	chain = node.material_override.next_pass
	chain.rim_enabled = true
	scan = Scan.scan(node, "res://fixture.tscn")
	assert(scan.counts.check_material_rim == 1, "Extra passes must be inspected")
	node.free()


func _module(size: Vector3i) -> PackedByteArray:
	return PackedInt32Array([0x07230203, 0x00010000, 0, 32, 0, (5 << 16) | 15, 5, 1, 0x6e69616d, 0, (6 << 16) | 16, 1, 17, size.x, size.y, size.z]).to_byte_array()


func _navigation_and_animation() -> void:
	for agent in [NavigationAgent2D.new(), NavigationAgent3D.new()]:
		_expect(agent, "navigation_agent_parent", true)
		var parent: Node = Node2D.new() if agent is NavigationAgent2D else Node3D.new()
		parent.add_child(agent)
		_expect(agent, "navigation_agent_parent", false)
		parent.free()
	for region in [NavigationRegion2D.new(), NavigationRegion3D.new()]:
		_expect(region, "navigation_region_missing", true)
		region.enabled = false
		_expect(region, "navigation_region_missing", false)
		region.enabled = true
		if region is NavigationRegion2D:
			region.navigation_polygon = NavigationPolygon.new()
		else:
			region.navigation_mesh = NavigationMesh.new()
		_expect(region, "navigation_region_missing", false)
		region.free()
	var obstacle3 := NavigationObstacle3D.new()
	obstacle3.rotation.x = 0.2
	_expect(obstacle3, "navigation_obstacle_rotation", false) # Detached world transform unknown.
	root.add_child(obstacle3)
	_expect(obstacle3, "navigation_obstacle_rotation", true)
	obstacle3.rotation = Vector3(0, 0.2, 0)
	_expect(obstacle3, "navigation_obstacle_rotation", false)
	_expect(obstacle3, "navigation_obstacle_scale", false)
	obstacle3.scale = Vector3(0.0005, 1, 1)
	_expect(obstacle3, "navigation_obstacle_scale", true)
	obstacle3.scale = Vector3(2, 1, 1)
	obstacle3.radius = 0.0
	_expect(obstacle3, "navigation_obstacle_nonuniform", false)
	obstacle3.radius = 1.0
	_expect(obstacle3, "navigation_obstacle_nonuniform", true)
	obstacle3.scale = Vector3.ONE * 2.0
	_expect(obstacle3, "navigation_obstacle_nonuniform", false)
	obstacle3.free()
	var parent2 := Node2D.new()
	parent2.scale = Vector2(2, 1)
	root.add_child(parent2)
	var obstacle2 := NavigationObstacle2D.new()
	obstacle2.radius = 1.0
	parent2.add_child(obstacle2)
	_expect(obstacle2, "navigation_obstacle_nonuniform", true)
	obstacle2.scale = Vector2(0.5, 1)
	_expect(obstacle2, "navigation_obstacle_nonuniform", false)
	_expect(obstacle2, "navigation_obstacle_scale", false)
	obstacle2.scale = Vector2(-1, 1)
	_expect(obstacle2, "navigation_obstacle_scale", true)
	obstacle2.scale = Vector2(0.5, 1)
	_expect(obstacle2, "navigation_obstacle_skew", false)
	obstacle2.skew = 0.2
	_expect(obstacle2, "navigation_obstacle_skew", true)
	obstacle2.radius = 0.0
	_expect(obstacle2, "navigation_obstacle_skew", false)
	parent2.free()
	var attachment := BoneAttachment3D.new()
	_expect(attachment, "bone_attachment_parent", true)
	_expect(attachment, "bone_attachment_bone", true)
	var skeleton := Skeleton3D.new()
	skeleton.add_bone("root_bone")
	skeleton.add_child(attachment)
	root.add_child(skeleton)
	_expect(attachment, "bone_attachment_parent", false)
	attachment.bone_idx = 0
	_expect(attachment, "bone_attachment_bone", false)
	_expect(attachment, "bone_attachment_external", false)
	attachment.set_use_external_skeleton(true)
	_expect(attachment, "bone_attachment_parent", false)
	_expect(attachment, "bone_attachment_external", true)
	attachment.set_external_skeleton(NodePath(".."))
	_expect(attachment, "bone_attachment_external", false)
	skeleton.free()
	var bone := Bone2D.new()
	_expect(bone, "bone2d_hierarchy", true)
	_expect(bone, "bone2d_rest", true)
	bone.rest = Transform2D.IDENTITY
	_expect(bone, "bone2d_rest", false)
	var parent_bone := Bone2D.new()
	parent_bone.add_child(bone)
	_expect(bone, "bone2d_hierarchy", true)
	var skeleton2 := Skeleton2D.new()
	skeleton2.add_child(parent_bone)
	_expect(bone, "bone2d_hierarchy", false)
	skeleton2.free()
	var tree := AnimationTree.new()
	_expect(tree, "animation_tree_root", true)
	tree.tree_root = AnimationNodeBlendTree.new()
	_expect(tree, "animation_tree_root", false)
	tree.free()
	var mixer := AnimationPlayer.new()
	mixer.root_node = NodePath("NoSuchRoot")
	_expect(mixer, "animation_mixer_root", false)
	root.add_child(mixer)
	_expect(mixer, "animation_mixer_root", true)
	mixer.active = false
	_expect(mixer, "animation_mixer_root", false)
	mixer.root_node = NodePath("..")
	mixer.active = true
	_expect(mixer, "animation_mixer_root", false)
	mixer.free()
	var group := CanvasGroup.new()
	_expect(group, "canvas_group_mipmaps", false)
	group.use_mipmaps = true
	_expect(group, "canvas_group_mipmaps", true)
	_expect(group, "canvas_group_margins", false)
	group.fit_margin = 11.0
	_expect(group, "canvas_group_margins", true)
	group.fit_margin = 10.0
	group.clear_margin = 11.0
	_expect(group, "canvas_group_margins", true)
	var clip := Node2D.new()
	clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_expect(clip, "canvas_group_clip", false)
	group.add_child(clip)
	_expect(clip, "canvas_group_clip", true)
	clip.top_level = true
	_expect(clip, "canvas_group_clip", false)
	clip.top_level = false
	clip.clip_children = CanvasItem.CLIP_CHILDREN_DISABLED
	_expect(clip, "canvas_group_clip", false)
	group.free()
	for particles in [GPUParticles2D.new(), GPUParticles3D.new()]:
		_expect(particles, "particle_turbulence", false)
		particles.process_material = ParticleProcessMaterial.new()
		particles.process_material.turbulence_enabled = true
		_expect(particles, "particle_turbulence", true)
		particles.process_material = ShaderMaterial.new()
		_expect(particles, "particle_turbulence", false)
		particles.free()


func _shaders() -> void:
	_shader_stages()
	_audio_bus_checks()
	_shader_math()
	_shader_zero_divisors()
	_shader_ray_queries()
	_shader_resources()
	_shader_layouts()
	_shader_buffers()
	_shader_image_formats()
	_shader_8bit_interfaces()
	var device_limits := {"x": 128, "y": 128, "z": 64, "invocations": 256}
	for entry in [[Vector3i(16, 16, 1), false, false], [Vector3i(128, 2, 1), false, false], [Vector3i(129, 1, 1), true, false], [Vector3i(1, 129, 1), true, false], [Vector3i(1, 1, 65), true, false], [Vector3i(16, 16, 2), false, true]]:
		var state := {"counts": {}, "offenders": {}}
		Shaders.record(entry[0], state, "res://limits.glsl", device_limits)
		assert(state.counts.has("check_compute_dimension_limit") == entry[1])
		assert(state.counts.has("check_compute_invocation_limit") == entry[2])
	for limits in [{}, {"x": 0, "y": 0, "z": 0, "invocations": 0}]:
		var state := {"counts": {}, "offenders": {}}
		Shaders.record(Vector3i(1024, 1024, 1024), state, "res://unknown.glsl", limits)
		assert(not state.counts.has("check_compute_dimension_limit") and not state.counts.has("check_compute_invocation_limit"))
	if DisplayServer.get_name() == "headless":
		assert(Shaders.device_limits().is_empty(), "Headless must not guess device limits")
		assert(Shaders.device_features().is_empty(), "Headless must not guess device features")
	var bytes := _module(Vector3i(8, 8, 1))
	assert(Shaders.local_size(bytes).size == Vector3i(8, 8, 1))
	var specialized := bytes.duplicate()
	specialized.append_array(PackedInt32Array([(4 << 16) | 71, 12, 11, 25]).to_byte_array())
	assert(Shaders.local_size(specialized).has("skip")) # Unknown builtin overrides literal mode.
	var constants := PackedInt32Array([(4 << 16) | 21, 2, 32, 0, (4 << 16) | 43, 2, 3, 4, (4 << 16) | 43, 2, 4, 1, (6 << 16) | 44, 5, 12, 3, 3, 4]).to_byte_array()
	specialized.append_array(constants)
	assert(Shaders.local_size(specialized).size == Vector3i(4, 4, 1))
	var local_ids := _module(Vector3i(3, 3, 4))
	local_ids.encode_u32(40, (6 << 16) | 331)
	local_ids.encode_u32(48, 38)
	assert(Shaders.local_size(local_ids).has("skip"))
	local_ids.append_array(constants)
	assert(Shaders.local_size(local_ids).size == Vector3i(4, 4, 1))
	assert(Shaders.local_size(PackedByteArray()).has("skip"))
	for length in bytes.size():
		assert(Shaders.local_size(bytes.slice(0, length)).has("skip"))
	var malformed := bytes.duplicate()
	malformed.encode_u32(20, 15)
	assert(Shaders.local_size(malformed).has("skip"))
	malformed = bytes.duplicate()
	malformed.resize(Shaders.MAX_BYTES + 4)
	assert(Shaders.local_size(malformed).has("skip"))
	assert(not Shaders.local_size(malformed).get("invalid_header", false), "An audit budget is not a shader validity limit")
	assert(not Shaders.local_size(bytes).get("invalid_header", false))
	assert(Shaders.local_size(bytes.slice(0, 19)).get("invalid_header", false))
	assert(Shaders.local_size(bytes.slice(0, bytes.size() - 1)).get("invalid_header", false))
	malformed = bytes.duplicate()
	malformed.encode_u32(0, 0)
	assert(Shaders.local_size(malformed).get("invalid_header", false))
	assert(not Shaders.local_size(malformed, 3).get("invalid_header", false), "Unsupported stage reflection must remain a coverage skip")
	malformed.encode_u32(0, 0x03022307)
	assert(not Shaders.local_size(malformed).get("invalid_header", false), "Byte-swapped modules are unsupported, not proven corrupt")
	for entry in [[Vector3i(8, 8, 1), false, false, false], [Vector3i(128, 1, 1), true, false, false], [Vector3i(3, 4, 1), false, true, true], [Vector3i.ONE, false, true, true]]:
		var state := {"counts": {}, "offenders": {}}
		Shaders.record(entry[0], state, "res://compute.glsl")
		for i in 3:
			var key: String = ["compute_arm_large", "compute_arm_alignment", "compute_amd_alignment"][i]
			assert(state.counts.has("check_" + key) == entry[i + 1], key)
	var empty := {"counts": {}, "offenders": {}}
	Shaders.scan(["res://unimported.glsl"], empty)
	assert(empty.shader_scan.unavailable_files == 1 and empty.counts.is_empty())
	var many: Array = []
	for i in 65:
		many.append("res://unimported_%d.glsl" % i)
	Shaders.scan(many, empty)
	assert(empty.shader_scan.unavailable_files == 64 and empty.shader_scan.skipped_files == 1)
	# Exercise ResourceLoader's .import mapping using an actual saved RDShaderFile.
	var file := RDShaderFile.new()
	var spirv := RDShaderSPIRV.new()
	spirv.set_stage_bytecode(RenderingDevice.SHADER_STAGE_COMPUTE, _module(Vector3i(128, 1, 1)))
	spirv.set_stage_bytecode(RenderingDevice.SHADER_STAGE_FRAGMENT, _module(Vector3i.ONE))
	var oversized := PackedByteArray()
	oversized.resize(Shaders.MAX_BYTES + 4)
	spirv.set_stage_bytecode(RenderingDevice.SHADER_STAGE_VERTEX, oversized)
	file.set_bytecode(spirv)
	file.base_error = "fixture compilation error"
	assert(ResourceSaver.save(file, "res://test-shader.res") == OK)
	var config := ConfigFile.new()
	config.set_value("remap", "type", "RDShaderFile")
	config.set_value("remap", "path", "res://test-shader.res")
	assert(config.save("res://test-shader.glsl.import") == OK)
	var source := FileAccess.open("res://test-shader.glsl", FileAccess.WRITE)
	source.store_string("#[compute]\n")
	source.close()
	Shaders.scan(["res://test-shader.glsl"], empty)
	assert(empty.shader_scan.inspected_versions == 1)
	assert(empty.shader_scan.inspected_stages == 1 and empty.shader_scan.skipped_stages == 2)
	assert(empty.shader_scan.resource_versions == 1 and empty.shader_scan.shared_memory_skipped_versions == 0)
	assert(empty.counts.has("check_shader_compile_error") and empty.counts.has("check_compute_arm_large"))
	if RenderingServer.get_current_rendering_driver_name() != "vulkan":
		var invalid_resource := ResourceLoader.load("res://test-shader.glsl") as RDShaderFile
		invalid_resource.base_error = ""
		invalid_resource.get_spirv().bytecode_compute = PackedByteArray([0])
		var unsupported := {"counts": {}, "offenders": {}}
		Shaders.scan(["res://test-shader.glsl"], unsupported)
		assert(unsupported.shader_scan.inspected_versions == 0 and unsupported.shader_scan.skipped_versions == 1)
		assert(not unsupported.counts.has("check_shader_invalid_spirv"), "Shader header findings require Vulkan")
	for path in ["res://test-shader.glsl", "res://test-shader.glsl.import", "res://test-shader.res"]:
		DirAccess.remove_absolute(path)


func _shader_stages() -> void:
	_shader_interfaces()
	for model in Shaders.STAGE_MODELS:
		var words := _math_module(26, [-1.0], [null]).to_int32_array()
		words[6] = model
		var bytes := words.to_byte_array()
		var parsed := Shaders.local_size(bytes, model)
		assert(parsed.execution_model == model and parsed.pow_domain)
		assert(parsed.has("size") == (model == 5))
		assert(not Shaders.local_size(bytes, 3).has("execution_model"))
		if model != 5:
			assert(not Shaders.local_size(bytes).has("execution_model"))
		var state := {"counts": {}, "offenders": {}}
		parsed.merge({"driver": "vulkan", "shared_bytes": 2048, "descriptor_bytes": 300, "push_constant_bytes": 128, "separate_sampler": true}, true)
		Shaders.record(Vector3i(128, 1, 1), state, "synthetic stage", {"invocations": 64, "x": 64, "y": 64, "z": 64, "shared_memory": 1024, "push_constants": 64}, parsed)
		for key in ["compute_arm_large", "compute_invocation_limit", "compute_dimension_limit", "compute_shared_memory_limit"]:
			assert(state.counts.has("check_" + key) == (model == 5), str(model, key, state))
		for key in ["compute_pow_domain", "compute_nvidia_separate_sampler", "compute_nvidia_descriptor_space", "compute_amd_layout", "compute_push_constant_limit"]:
			assert(state.counts.has("check_" + key), str(model, key, state))
	for mode in ["after_ignore_intersection", "after_terminate_ray"]:
		var words := _math_module(26, [-1.0], [null], mode).to_int32_array()
		words[6] = 5315
		assert(not Shaders.local_size(words.to_byte_array(), 5315).pow_domain, "Ray termination makes later blocks unreachable")


func _interface_module(model: int, storage: int, kind: int, width: int, count: int = 1, component: int = 0) -> PackedByteArray:
	var words := PackedInt32Array([0x07230203, 0x00010000, 0, 64, 0, (6 << 16) | 15, model, 1, 0x6e69616d, 0, 10,
		(4 << 16) | 71, 10, 30, 0, (4 << 16) | 71, 10, 31, component])
	words.append_array(PackedInt32Array([((4 if kind == 21 else 3) << 16) | kind, 2, width]))
	if kind == 21:
		words.append(1)
	if count > 1:
		words.append_array(PackedInt32Array([(4 << 16) | 23, 3, 2, count]))
	words.append_array(PackedInt32Array([(4 << 16) | 32, 4, storage, 3 if count > 1 else 2, (4 << 16) | 59, 4, 10, storage]))
	return words.to_byte_array()


func _shader_interfaces() -> void:
	for width in [16, 32, 64]:
		for count in [1, 2, 3, 4]:
			var vertex := Shaders.local_size(_interface_module(0, 3, 22, width, count), 0)
			assert(vertex.interface_outputs.size() == count * (2 if width == 64 else 1))
			for kind in [21, 22]:
				var fragment := Shaders.local_size(_interface_module(4, 1, kind, width, count), 4)
				for driver in ["vulkan", "d3d12", "opengl3"]:
					var state := {"counts": {}, "offenders": {}}
					assert(Shaders.record_interfaces({0: vertex, 1: fragment}, state, "fixture", driver) == (driver == "vulkan"))
					assert(state.counts.has("check_shader_interface") == (kind == 21 and driver == "vulkan"), "Interface numeric-kind mismatch must respect the driver gate")
	var vertex := Shaders.local_size(_interface_module(0, 3, 22, 32), 0)
	var fragment := Shaders.local_size(_interface_module(4, 1, 22, 64), 4)
	var state := {"counts": {}, "offenders": {}}
	assert(Shaders.record_interfaces({0: vertex, 1: fragment}, state, "fixture", "vulkan"))
	assert(state.counts.has("check_shader_interface"))
	assert(str(state.offenders.check_shader_interface[0]).contains("location=0; component=0; vertex=float32; fragment=float64"))
	for stages in [{0: vertex}, {1: fragment}, {0: vertex, 1: fragment, 2: {}}, {0: vertex, 1: fragment, 4: {}}]:
		assert(not Shaders.record_interfaces(stages, {"counts": {}, "offenders": {}}, "fixture", "vulkan"))
	fragment = Shaders.local_size(_interface_module(4, 1, 21, 32, 1, 1), 4)
	state = {"counts": {}, "offenders": {}}
	Shaders.record_interfaces({0: vertex, 1: fragment}, state, "fixture", "vulkan")
	assert(state.counts.has("check_shader_interface") and str(state.offenders.check_shader_interface[0]).contains("missing vertex output"))
	vertex.interface_skipped_declarations = 1
	state = {"counts": {}, "offenders": {}}
	Shaders.record_interfaces({0: vertex, 1: fragment}, state, "fixture", "vulkan")
	assert(state.counts.is_empty(), "Incomplete output reflection cannot prove a missing output")
	var words := _interface_module(0, 3, 22, 32).to_int32_array()
	words[5] = (5 << 16) | 15
	words.remove_at(10)
	assert(Shaders.local_size(words.to_byte_array(), 0).interface_outputs.is_empty(), "Only entry-point interface IDs are inspected")
	assert(Shaders.local_size(_interface_module(0, 3, 22, 8), 0).interface_outputs.is_empty())
	words = _interface_module(0, 3, 22, 32).to_int32_array()
	words.append_array(PackedInt32Array([(2 << 16) | 73, 30]))
	var unknown := Shaders.local_size(words.to_byte_array(), 0)
	assert(unknown.interface_outputs.is_empty() and unknown.interface_skipped_declarations > 0, "Grouped decorations remain unknown")
	words = _interface_module(0, 3, 22, 32).to_int32_array()
	for index in 4:
		words.remove_at(11)
	unknown = Shaders.local_size(words.to_byte_array(), 0)
	assert(unknown.interface_skipped_declarations == 1, "Unlocated non-built-in outputs must not count as complete reflection")
	words = _interface_module(0, 3, 22, 32).to_int32_array()
	words[5] = (4 << 16) | 15
	assert(Shaders.local_size(words.to_byte_array(), 0).has("skip"), "An unterminated entry-point name cannot establish its interface")
	var types := {1: [22, 32], 2: [23, 1, 3], 3: [24, 2, 2], 4: [28, 3, 10], 5: [30, 1, 2], 6: [28, 1, 11]}
	var matrix := Shaders._interface_type(3, types, {})
	assert(matrix.size() == 8 and matrix[3] == Vector2i.ZERO and matrix[7] == Vector2i.ZERO)
	assert(Shaders._interface_type(4, types, {10: 2}).size() == 16)
	assert(Shaders._interface_type(5, types, {}).size() == 8)
	assert(Shaders._interface_type(4, types, {}).is_empty(), "Specialized/unknown array lengths stay unknown")
	assert(Shaders._interface_type(6, types, {11: 256}).size() == Shaders.MAX_INTERFACE_SLOTS)
	assert(Shaders._interface_type(6, types, {11: 257}).is_empty())
	assert(Shaders._interface_type(6, types, {11: 0x7fffffff}).is_empty())
	types[7] = [28, 7, 10]
	assert(Shaders._interface_type(7, types, {10: 1}).is_empty(), "Recursive types are bounded")
	words = _interface_module(4, 1, 22, 32, 2).to_int32_array()
	words[words.size() - 5] = 12
	words.append_array(PackedInt32Array([(4 << 16) | 21, 14, 32, 0, (4 << 16) | 43, 14, 13, 3, (4 << 16) | 28, 12, 3, 13]))
	fragment = Shaders.local_size(words.to_byte_array(), 4)
	assert(fragment.interface_inputs.size() == 6)
	words.append_array(PackedInt32Array([(3 << 16) | 71, 10, 5285]))
	fragment = Shaders.local_size(words.to_byte_array(), 4)
	assert(fragment.interface_inputs.size() == 2, "PerVertexKHR discards exactly the outer fragment array wrapper")
	vertex = Shaders.local_size(_interface_module(0, 3, 22, 32, 2), 0)
	state = {"counts": {}, "offenders": {}}
	Shaders.record_interfaces({0: vertex, 1: fragment}, state, "per-vertex fixture", "vulkan")
	assert(state.counts.is_empty(), "A valid barycentric input must not report missing outputs")
	words = _interface_module(0, 3, 22, 32).to_int32_array()
	words[5] = (7 << 16) | 15
	words.insert(11, 11)
	words.append_array(PackedInt32Array([(4 << 16) | 71, 11, 30, 0, (4 << 16) | 59, 4, 11, 3]))
	vertex = Shaders.local_size(words.to_byte_array(), 0)
	assert(vertex.interface_outputs[Vector2i.ZERO] == Vector2i.ZERO, "Overlapping declarations are unknown")
	words[words.size() - 5] = 256
	var pointer_index := 0
	for i in range(12, words.size() - 3):
		if words[i] == ((4 << 16) | 32):
			pointer_index = i
			break
	assert(pointer_index > 0)
	words[pointer_index + 3] = 12
	words.append_array(PackedInt32Array([(4 << 16) | 21, 14, 32, 0, (4 << 16) | 43, 14, 13, 256, (4 << 16) | 28, 12, 2, 13]))
	vertex = Shaders.local_size(words.to_byte_array(), 0)
	assert(vertex.interface_outputs.size() == 256 and vertex.interface_skipped_declarations == 1, "Interface slot budget is shared across declarations")


func _shader_resources() -> void:
	var shared := _module(Vector3i(8, 1, 1))
	shared.append_array(PackedInt32Array([
		(4 << 16) | 21, 2, 32, 0, (4 << 16) | 43, 2, 3, 16,
		(3 << 16) | 22, 4, 32, (4 << 16) | 23, 5, 4, 4,
		(4 << 16) | 28, 6, 5, 3, (4 << 16) | 32, 7, 4, 6,
		(4 << 16) | 59, 7, 8, 4,
		(2 << 16) | 26, 9, (4 << 16) | 32, 10, 0, 9,
		(4 << 16) | 59, 10, 11, 0,
		(4 << 16) | 71, 11, 34, 0, (4 << 16) | 71, 11, 33, 1,
	]).to_byte_array())
	var parsed := Shaders.local_size(shared)
	assert(parsed.shared_bytes == 256 and parsed.separate_sampler)
	for maximum in [0, 255, 256, 257]:
		var state := {"counts": {}, "offenders": {}}
		Shaders.record(parsed.size, state, "res://resource.glsl", {"shared_memory": maximum}, parsed)
		assert(state.counts.has("check_compute_shared_memory_limit") == (maximum == 255))
	for driver in ["vulkan", "d3d12", "metal", "opengl3", ""]:
		parsed["driver"] = driver
		var state := {"counts": {}, "offenders": {}}
		Shaders.record(parsed.size, state, "res://resource.glsl", {}, parsed)
		assert(state.counts.has("check_compute_nvidia_separate_sampler") == (driver == "vulkan"))
	var specialized := shared.duplicate()
	specialized.encode_u32(52, 0) # Unknown local size does not erase fixed resource declarations.
	parsed = Shaders.local_size(specialized)
	assert(parsed.has("skip") and parsed.shared_bytes == 256 and parsed.separate_sampler)
	parsed["driver"] = "vulkan"
	var state := {"counts": {}, "offenders": {}}
	Shaders.record(Vector3i.ZERO, state, "res://specialized.glsl", {"shared_memory": 128}, parsed)
	assert(state.counts.has("check_compute_shared_memory_limit") and state.counts.has("check_compute_nvidia_separate_sampler"))
	for key in ["compute_arm_large", "compute_arm_alignment", "compute_amd_alignment", "compute_invocation_limit", "compute_dimension_limit"]:
		assert(not state.counts.has("check_" + key))
	for decoration in [PackedInt32Array([(3 << 16) | 71, 8, 20]), PackedInt32Array([(2 << 16) | 17, 4428])]:
		var aliased := shared.duplicate()
		aliased.append_array(decoration.to_byte_array())
		parsed = Shaders.local_size(aliased)
		assert(parsed.shared_bytes == -1 and parsed.separate_sampler)
	var unknown_length := shared.duplicate()
	unknown_length.encode_u32(80, (4 << 16) | 50) # OpSpecConstant is not a fixed array length.
	assert(Shaders.local_size(unknown_length).shared_bytes == -1)
	var no_variables := shared.slice(0, 156)
	parsed = Shaders.local_size(no_variables)
	assert(parsed.shared_bytes == 0 and not parsed.separate_sampler)
	var cycle := shared.duplicate()
	cycle.encode_u32(132, 6) # Array element refers to itself: bounded recursion, no guessed size.
	assert(Shaders.local_size(cycle).shared_bytes == -1)
	var nested := shared.duplicate()
	nested.append_array(PackedInt32Array([(4 << 16) | 28, 12, 6, 3, (4 << 16) | 32, 13, 4, 12, (4 << 16) | 59, 13, 14, 4]).to_byte_array())
	assert(Shaders.local_size(nested).shared_bytes == 4352)
	nested.encode_u32(92, 1 << 24)
	assert(Shaders.local_size(nested).shared_bytes == (1 << 30))
	var unsupported := shared.duplicate()
	unsupported.encode_u32(108, (4 << 16) | 30) # OpTypeStruct is outside shared-memory size coverage.
	assert(Shaders.local_size(unsupported).shared_bytes == -1)
	var sampler_array := shared.duplicate()
	sampler_array.append_array(PackedInt32Array([(4 << 16) | 28, 12, 9, 3]).to_byte_array())
	sampler_array.encode_u32(192, 12)
	assert(Shaders.local_size(sampler_array).separate_sampler)
	assert(Shaders.local_size(sampler_array).descriptor_bytes == 64)
	for count in [64, 65]:
		sampler_array.encode_u32(92, count)
		parsed = Shaders.local_size(sampler_array)
		assert(parsed.descriptor_bytes == count * 4)
		for driver in ["vulkan", "d3d12", "metal", ""]:
			parsed["driver"] = driver
			state = {"counts": {}, "offenders": {}}
			Shaders.record(parsed.size, state, "res://many-descriptors.glsl", {}, parsed)
			assert(state.counts.has("check_compute_nvidia_descriptor_space") == (count == 65 and driver == "vulkan"))
	var duplicate_binding := sampler_array.duplicate()
	duplicate_binding.append_array(PackedInt32Array([(4 << 16) | 59, 10, 15, 0, (4 << 16) | 71, 15, 34, 0, (4 << 16) | 71, 15, 33, 1]).to_byte_array())
	assert(Shaders.local_size(duplicate_binding).descriptor_bytes == 260)
	var unused_type := _module(Vector3i.ONE)
	unused_type.append_array(PackedInt32Array([(2 << 16) | 26, 9]).to_byte_array())
	assert(not Shaders.local_size(unused_type).separate_sampler)
	for feature in [["buffer_device_address", 5347], ["ray_query", 4472], ["raytracing_pipeline", 4479]]:
		var required := _module(Vector3i.ONE)
		required.append_array(PackedInt32Array([(2 << 16) | 17, feature[1]]).to_byte_array())
		parsed = Shaders.local_size(required)
		assert(parsed["requires_" + feature[0]])
		for supported in [true, false, null]:
			for driver in ["vulkan", "d3d12", ""]:
				parsed["driver"] = driver
				parsed["features"] = {feature[0]: supported}
				state = {"counts": {}, "offenders": {}}
				Shaders.record(parsed.size, state, "res://capability.glsl", {}, parsed)
				assert(state.counts.has("check_compute_" + feature[0]) == (supported == false and driver == "vulkan"))
	for capability in [4, 5, 6, 7, 8, 21, 38, 1, 9, 5347, 60000]:
		var required := _module(Vector3i.ONE)
		required.append_array(PackedInt32Array([(2 << 16) | 17, capability, (2 << 16) | 17, capability]).to_byte_array())
		var forbidden: Array = Shaders.local_size(required).forbidden_vulkan_capabilities
		assert(forbidden.size() == int(Shaders.FORBIDDEN_CAPABILITIES.has(capability)), "Only the seven confirmed capabilities are forbidden; duplicates are collapsed")
		if not forbidden.is_empty():
			assert(forbidden[0] == Shaders.FORBIDDEN_CAPABILITIES[capability])
	for name in ["GL_X", "", "spv_", "SPV_unknown_future", "x".repeat(255), "x".repeat(256), String.chr(255), String.chr(1)]:
		var payload: PackedByteArray = name.to_utf8_buffer()
		payload.append(0)
		while payload.size() % 4 != 0:
			payload.append(0)
		var instruction := PackedInt32Array([((payload.size() / 4 + 1) << 16) | 10]).to_byte_array()
		instruction.append_array(payload)
		var module := _module(Vector3i.ONE)
		module.append_array(instruction)
		module.append_array(instruction)
		var invalid: Array = Shaders.local_size(module).non_spirv_extensions
		var expected: bool = not name.begins_with("SPV_") and name.length() <= 255 and name not in [String.chr(255), String.chr(1)]
		assert(invalid == ([name] if expected else []), "Namespace names are bounded, terminated ASCII; duplicate names collapse")
	var malformed := _module(Vector3i.ONE)
	malformed.append_array(PackedInt32Array([(2 << 16) | 10, 0x41414141, (1 << 16) | 10]).to_byte_array())
	assert(Shaders.local_size(malformed).non_spirv_extensions.is_empty(), "Unterminated and operandless strings are skipped")
	var many := _module(Vector3i.ONE)
	for index in 20:
		var payload := ("GL_%02d" % index).to_ascii_buffer()
		payload.append_array(PackedByteArray([0, 0, 0]))
		many.append_array(PackedInt32Array([(3 << 16) | 10]).to_byte_array())
		many.append_array(payload)
	assert(Shaders.local_size(many).non_spirv_extensions.size() == 16, "Diagnostic name collection is bounded")


func _cooperative_training_operands() -> void:
	for storage: int in range(13) + [5349, 99999]:
		for opcode in [5290, 5291]:
			for capability in [true, false]:
				var module := _module(Vector3i.ONE)
				module.append_array(PackedInt32Array([
					(2 << 16) | 17, 5435 if capability else 1,
					(3 << 16) | 22, 2, 16, (4 << 16) | 5288, 3, 2, 11,
					(4 << 16) | 32, 4, storage, 2, (4 << 16) | 59, 4, 9, storage,
					(4 << 16) | 21, 10, 32, 0, (4 << 16) | 43, 10, 11, 0,
					(4 << 16) | 43, 10, 12, 3, (4 << 16) | 43, 10, 13, 0,
					(4 << 16) | 32, 7, 7, 3,
					(5 << 16) | 54, 17, 1, 0, 18, (2 << 16) | 248, 19,
					(4 << 16) | 59, 7, 6, 7, (4 << 16) | 61, 3, 8, 6,
				]).to_byte_array())
				var operation := PackedInt32Array([(8 << 16) | 5290, 9, 11, 8, 8, 12, 13, 11]) if opcode == 5290 else PackedInt32Array([(4 << 16) | 5291, 9, 11, 8])
				module.append_array(operation.to_byte_array())
				var parsed := Shaders.local_size(module)
				assert(parsed.cooperative_training_storage == (storage < 12 and capability), "Only known forbidden core storage classes are flagged")
				assert(not parsed.cooperative_reduce_type and not parsed.cooperative_outer_interpretation)
				var helper := module.to_int32_array()
				for cursor in helper.size():
					if helper[cursor] == ((5 << 16) | 54):
						helper[cursor + 2] = 20
				assert(not Shaders.local_size(helper.to_byte_array()).cooperative_training_storage)
	for component in [[22, 16], [22, 32], [22, 64], [21, 32], [22, 128]]:
		var words := PackedInt32Array([
			(2 << 16) | 17, 5435, ((4 if component[0] == 21 else 3) << 16) | component[0], 2, component[1],
		])
		if component[0] == 21:
			words.append(1)
		words.append_array(PackedInt32Array([
			(4 << 16) | 5288, 3, 2, 11, (4 << 16) | 32, 7, 7, 3,
			(5 << 16) | 54, 17, 1, 0, 18, (2 << 16) | 248, 19,
			(4 << 16) | 59, 7, 6, 7, (4 << 16) | 61, 3, 8, 6,
			(4 << 16) | 5291, 999, 11, 8,
		]))
		var module := _module(Vector3i.ONE)
		module.append_array(words.to_byte_array())
		assert(Shaders.local_size(module).cooperative_reduce_type == (component in [[22, 64], [21, 32]]))
		assert(not Shaders.local_size(module).cooperative_training_storage, "An unresolved destination is omitted independently")
	for interpretation in [-1, 0, 1, 2, 5]:
		var module := _module(Vector3i.ONE)
		module.append_array(PackedInt32Array([
			(2 << 16) | 17, 5435, (4 << 16) | 21, 10, 32, 1,
			(4 << 16) | 43, 10, 11, interpretation,
			(5 << 16) | 54, 17, 1, 0, 18, (2 << 16) | 248, 19,
			(7 << 16) | 5290, 999, 999, 999, 999, 999, 11,
		]).to_byte_array())
		assert(Shaders.local_size(module).cooperative_outer_interpretation == (interpretation not in [0, 1]))
		var words := module.to_int32_array()
		for cursor in words.size():
			if words[cursor] == ((4 << 16) | 43):
				words[cursor] = (4 << 16) | 50
		assert(not Shaders.local_size(words.to_byte_array()).cooperative_outer_interpretation, "Specialized interpretations remain unknown")
	for opcode in [5289, 5292]:
		for interpretation in [0, 1000491002, 1000491003]:
			for layout in [-1, 0, 1, 2, 3, 4]:
				var module := _module(Vector3i.ONE)
				module.append_array(PackedInt32Array([
					(2 << 16) | 17, 5394, (4 << 16) | 21, 10, 32, 1,
					(4 << 16) | 43, 10, 11, interpretation, (4 << 16) | 43, 10, 12, layout,
					(5 << 16) | 54, 17, 1, 0, 18, (2 << 16) | 248, 19,
				]).to_byte_array())
				var operation := PackedInt32Array([(12 << 16) | 5289, 3, 8, 9, 9, 9, 9, 11, 9, 9, 12, 9]) if opcode == 5289 else PackedInt32Array([(15 << 16) | 5292, 3, 8, 9, 9, 9, 9, 11, 9, 9, 9, 9, 9, 12, 9])
				module.append_array(operation.to_byte_array())
				assert(Shaders.local_size(module).cooperative_fp8_layout == (interpretation != 0 and layout not in [2, 3]))
				var unknown := module.to_int32_array()
				unknown[unknown.size() - 2] = 999
				assert(not Shaders.local_size(unknown.to_byte_array()).cooperative_fp8_layout, "Unknown layouts do not imply incompatibility")


func _shader_stage_intrinsics() -> void:
	for model: int in Shaders.STAGE_MODELS + [99999]:
		var module := _module(Vector3i.ONE)
		var words := module.to_int32_array()
		words[6] = model
		words.append_array(PackedInt32Array([(2 << 16) | 17, 4191]))
		assert(Shaders.local_size(words.to_byte_array(), model).get("graph_capability", false) == (model in Shaders.STAGE_MODELS))
	for count in [2, 3, 4, 5, 6]:
		for capability in [true, false]:
			var module := _module(Vector3i.ONE)
			module.append_array(PackedInt32Array([(2 << 16) | 17, 4174 if capability else 1]).to_byte_array())
			module.append_array(PackedInt32Array([(count << 16) | 4163, 3, 2, 11, 20, 21]).slice(0, count).to_byte_array())
			assert(Shaders.local_size(module).tensor_declaration == (count in [3, 5] and capability))
	for opcode in Shaders.REPACK_OPCODES:
		for matching_entry in [true, false]:
			for complete in [true, false]:
				var module := _module(Vector3i.ONE)
				module.append_array(PackedInt32Array([(3 << 16) | 16, 1 if matching_entry else 2, 4421]).to_byte_array())
				var count: int = Shaders.REPACK_OPCODES[opcode][0] - int(not complete)
				var words := PackedInt32Array()
				words.resize(count)
				words.fill(10)
				words[0] = (count << 16) | opcode
				module.append_array(words.to_byte_array())
				assert(Shaders.local_size(module).subgroup_repack == (matching_entry and complete), "Matching mode plus complete repack opcode is forbidden module-wide")


## Script calls and saved text that Godot warns about at runtime (docs/GODOT_RUNTIME_WARNINGS.json).
func _script_and_text_warnings() -> void:
	var script_cases := [
		["script_deprecated_call", "func _ready():\n\tvar rd := RenderingServer.get_rendering_device()\n\trd.barrier()\n", true],
		["script_deprecated_call", "func _ready():\n\tNavigationMeshGenerator.bake(mesh, self)\n", true],
		["script_deprecated_call", "func _ready():\n\t# rd.barrier()\n\tvar text := \"full_barrier(\"\n", false],
		["script_draw_ignored", "func _draw():\n\tdraw_rect(Rect2(0, 0, 4, 4), Color.RED, true, 2.0)\n", true],
		["script_draw_ignored", "func _draw():\n\tdraw_polyline(points, Color.RED, -1, true)\n", true],
		["script_draw_ignored", "func _draw():\n\tdraw_circle(Vector2.ZERO, 4.0, Color(1, 0, 0), true, 3.0)\n", true],
		["script_draw_ignored", "func _draw():\n\tdraw_rect(Rect2(0, 0, 4, 4), Color.RED, true, -1.0)\n\tdraw_rect(Rect2(0, 0, 4, 4), Color.RED, false, 2.0)\n\tdraw_polyline(points, Color.RED, 2.0, true)\n\tdraw_circle(Vector2.ZERO, 4.0, Color.RED)\n\tdraw_rect(rect, color, true, width)\n", false],
		["script_theme_in_init", "extends Control\n\nfunc _init():\n\tvar color := get_theme_color(\"font_color\")\n", true],
		["script_theme_in_init", "extends Control\n\nfunc _init():\n\tpass\n\nfunc _ready():\n\tvar color := get_theme_color(\"font_color\")\n", false],
		["script_theme_in_init", "extends Control\n\nfunc _init():\n\tvar color := other_theme.get_theme_color(\"font_color\")\n", false],
		["script_jolt_server_call", "func _ready():\n\tPhysicsServer3D.space_set_param(space, PhysicsServer3D.SPACE_PARAM_SOLVER_ITERATIONS, 32)\n", true],
		["script_jolt_server_call", "func _ready():\n\tPhysicsServer3D.body_set_param(body, PhysicsServer3D.BODY_PARAM_MASS, 2.0)\n", false],
		["script_emit_particle", "func _ready():\n\t$Particles.emit_particle(Transform3D(), Vector3.ZERO, Color.WHITE, Color.WHITE, 0)\n", true],
		["script_emit_particle", "func _ready():\n\t$Particles.restart()\n", false],
	]
	for case in script_cases:
		var state := {"counts": {}, "offenders": {}}
		ProjectScan.script_warnings(case[1], "res://fixture.gd", state)
		assert(state.counts.has("check_" + case[0]) == case[2], "%s: %s" % [case[0], case[1]])
		covered[case[0] + ":" + str(case[2])] = true
	var known_uid := ResourceUID.id_to_text(ResourceLoader.get_resource_uid("res://heavy_scripts.gd"))
	var sidecar_uid := ResourceUID.id_to_text(ResourceUID.create_id())
	FileAccess.open("res://uid_sidecar_fixture.cs.uid", FileAccess.WRITE).store_string(sidecar_uid + "\n")
	var text_cases := [
		["ext_resource_uid_invalid", "[gd_scene format=3]\n\n[ext_resource type=\"Texture2D\" uid=\"%s\" path=\"res://missing_texture.png\" id=\"1\"]\n" % ResourceUID.id_to_text(ResourceUID.create_id()), true],
		["ext_resource_uid_invalid", "[gd_scene format=3]\n\n[ext_resource type=\"Script\" uid=\"%s\" path=\"res://heavy_scripts.gd\" id=\"1\"]\n[ext_resource type=\"Texture2D\" path=\"res://missing.png\" id=\"2\"]\n" % known_uid, false],
		# A C# script's UID lives in its .uid sidecar; a build without .NET registers no loader for .cs.
		["ext_resource_uid_invalid", "[gd_scene format=3]\n\n[ext_resource type=\"Script\" uid=\"%s\" path=\"res://uid_sidecar_fixture.cs\" id=\"1\"]\n" % sidecar_uid, false],
		["ext_resource_uid_invalid", "[gd_scene format=3]\n\n[ext_resource type=\"Script\" uid=\"%s\" path=\"res://uid_sidecar_fixture.cs\" id=\"1\"]\n" % ResourceUID.id_to_text(ResourceUID.create_id()), true],
		["shader_param_old_names", "[gd_scene format=3]\n\n[sub_resource type=\"ShaderMaterial\" id=\"1\"]\nshader_param/tint = Color(1, 0, 0, 1)\n", true],
		["shader_param_old_names", "[gd_resource type=\"ShaderMaterial\" format=3]\n\n[resource]\nshader_uniform/tint = 1.0\n", true],
		["shader_param_old_names", "[gd_scene format=3]\n\n[sub_resource type=\"ShaderMaterial\" id=\"1\"]\nshader_parameter/tint = Color(1, 0, 0, 1)\n\n[sub_resource type=\"Animation\" id=\"2\"]\nparam/x = 1\n", false],
		["mesh_old_surface_format", "[gd_scene format=3]\n\n[sub_resource type=\"ArrayMesh\" id=\"1\"]\n_surfaces = [{\n\"aabb\": AABB(0, 0, 0, 1, 1, 1),\n\"format\": 4097,\n}]\n", true],
		["mesh_old_surface_format", "[gd_scene format=3]\n\n[sub_resource type=\"ArrayMesh\" id=\"1\"]\n_surfaces = [{\n\"format\": 34359742487,\n}]\n\n[sub_resource type=\"Image\" id=\"2\"]\ndata = {\n\"format\": 4097,\n}\n", false],
	]
	for case in text_cases:
		var state := {"counts": {}, "offenders": {}}
		ProjectScan.resource_text_checks(case[1], "res://fixture.tscn", state)
		assert(state.counts.has("check_" + case[0]) == case[2], "%s: %s" % [case[0], case[1]])
		covered[case[0] + ":" + str(case[2])] = true
	DirAccess.remove_absolute("res://uid_sidecar_fixture.cs.uid")
	# Transition expressions need advance_expression_base_node to resolve.
	var tree := AnimationTree.new()
	var machine := AnimationNodeStateMachine.new()
	machine.add_node("a", AnimationNodeAnimation.new())
	machine.add_node("b", AnimationNodeAnimation.new())
	var transition := AnimationNodeStateMachineTransition.new()
	transition.advance_expression = "is_ready"
	machine.add_transition("a", "b", transition)
	tree.tree_root = machine
	root.add_child(tree)
	_expect(tree, "animation_expression_base", false) # The default "." is the AnimationTree itself.
	tree.advance_expression_base_node = NodePath("Missing")
	_expect(tree, "animation_expression_base", true)
	transition.advance_expression = ""
	_expect(tree, "animation_expression_base", false)
	tree.free()


## Cooperative-vector offset/stride alignment and offset width (Vulkan RuntimeSpirv 10096-10101, 11809), on synthesized bytecode.
func _cooperative_alignment() -> void:
	# Ids: 2 uint32, 3 uint64, 4 float16, 5 coop vector, 6 StorageBuffer pointer, 11 four, 12 offset, 13 64-bit offset,
	# 14 variable, 15 layout, 16 stride, 20 loaded vector.
	for case in [[32, 0, 32, false, false], [24, 0, 32, true, false], [32, 0, 24, true, false], [32, 2, 24, false, false], [32, 0, 32, false, true]]:
		for capability in [true, false]:
			var module := _module(Vector3i.ONE)
			module.append_array(PackedInt32Array([
				(2 << 16) | 17, 5394 if capability else 1,
				(4 << 16) | 21, 2, 32, 0, (4 << 16) | 21, 3, 64, 0, (3 << 16) | 22, 4, 16,
				(4 << 16) | 43, 2, 11, 4, (4 << 16) | 43, 2, 12, case[0], (5 << 16) | 43, 3, 13, 16, 0,
				(4 << 16) | 43, 2, 15, case[1], (4 << 16) | 43, 2, 16, case[2], (4 << 16) | 43, 2, 21, 64,
				(4 << 16) | 5288, 5, 4, 11, (4 << 16) | 32, 6, 12, 4, (4 << 16) | 59, 6, 14, 12,
				(5 << 16) | 54, 17, 1, 0, 18, (2 << 16) | 248, 19,
				(5 << 16) | 5302, 5, 20, 14, 13 if case[4] else 12,
				(4 << 16) | 5303, 14, 12, 20,
				(13 << 16) | 5289, 5, 22, 20, 11, 14, 21, 11, 11, 11, 15, 11, 16,
				(1 << 16) | 253, (1 << 16) | 56,
			]).to_byte_array())
			var parsed := Shaders.local_size(module)
			assert(parsed.cooperative_alignment == (case[3] and capability), "cooperative alignment %s" % [case])
			assert(parsed.cooperative_offset_width == (case[4] and capability), "cooperative offset width %s" % [case])
			covered["shader_cooperative_alignment:" + str(case[3] and capability)] = true
			covered["shader_cooperative_offset_width:" + str(case[4] and capability)] = true
			if case[4] and capability:
				# Shader64BitIndexingEXT on the entry permits 64-bit offsets.
				module.append_array(PackedInt32Array([(3 << 16) | 16, 1, 5427]).to_byte_array())
				assert(not Shaders.local_size(module).cooperative_offset_width, "Shader64BitIndexingEXT exempts 64-bit offsets")


## OpCooperativeMatrixMulAddKHR contracts from SPIRV-Tools, on synthesized bytecode.
func _matrix_muladd() -> void:
	# Ids: 2 uint32, 4 float16, 7 int32; 31 Subgroup scope, 37 Workgroup scope, 32 sixteen, 33 eight, 34/35/36 uses A/B/Acc.
	# Matrix types: [A, B, C/D] as (component, scope, rows, cols, use); operands A, B, C and the literal mask.
	var valid := [[4, 31, 32, 32, 34], [4, 31, 32, 32, 35], [4, 31, 32, 32, 36]]
	var cases := [
		["valid", valid, [60, 61, 62], 0, false],
		["swapped A/B uses", valid, [61, 60, 62], 0, true],
		["scope mismatch", [[4, 31, 32, 32, 34], [4, 37, 32, 32, 35], [4, 31, 32, 32, 36]], [60, 61, 62], 0, true],
		["K mismatch", [[4, 31, 32, 33, 34], [4, 31, 32, 32, 35], [4, 31, 32, 32, 36]], [60, 61, 62], 0, true],
		["signed flag on float A", valid, [60, 61, 62], 1, true],
		["signed flag on int A", [[7, 31, 32, 32, 34], [7, 31, 32, 32, 35], [7, 31, 32, 32, 36]], [60, 61, 62], 1, false],
	]
	for case in cases:
		for capability in [true, false]:
			var words := PackedInt32Array([
				(2 << 16) | 17, 6022 if capability else 1,
				(4 << 16) | 21, 2, 32, 0, (3 << 16) | 22, 4, 16, (4 << 16) | 21, 7, 32, 1,
				(4 << 16) | 43, 2, 31, 3, (4 << 16) | 43, 2, 37, 2, (4 << 16) | 43, 2, 32, 16, (4 << 16) | 43, 2, 33, 8,
				(4 << 16) | 43, 2, 34, 0, (4 << 16) | 43, 2, 35, 1, (4 << 16) | 43, 2, 36, 2, (4 << 16) | 43, 2, 38, 0,
			])
			for index in 3:
				var type: Array = case[1][index]
				words.append_array(PackedInt32Array([(7 << 16) | 4456, 50 + index] + type))
			for index in 3:
				words.append_array(PackedInt32Array([(4 << 16) | 44, 50 + index, 60 + index, 38]))
			var operands: Array = case[2]
			if case[3] == 0:
				words.append_array(PackedInt32Array([(6 << 16) | 4459, 52, 63, operands[0], operands[1], operands[2]]))
			else:
				words.append_array(PackedInt32Array([(7 << 16) | 4459, 52, 63, operands[0], operands[1], operands[2], case[3]]))
			var module := _module(Vector3i.ONE)
			module.append_array(words.to_byte_array())
			assert(Shaders.local_size(module).matrix_muladd == (case[4] and capability), "matrix muladd: %s" % case[0])
			covered["shader_matrix_muladd:" + str(case[4] and capability)] = true


## Exclude lists out of child order (unsorted or duplicate) keep excluded collisions active in Godot's native merge.
func _spring_exclude_order() -> void:
	var skeleton := Skeleton3D.new()
	skeleton.add_bone("root")
	root.add_child(skeleton)
	var spring := SpringBoneSimulator3D.new()
	skeleton.add_child(spring)
	spring.setting_count = 1
	var colliders: Array = []
	for index in 2:
		var sphere := SpringBoneCollisionSphere3D.new()
		sphere.name = "Collider%d" % index
		spring.add_child(sphere)
		colliders.append(sphere)
	spring.set_enable_all_child_collisions(0, true)
	for order_case in [[[0, 1], false], [[1, 0], true], [[0, 0], true], [[1], false], [[], false]]:
		var order: Array = order_case[0]
		spring.set_exclude_collision_count(0, order.size())
		for index in order.size():
			spring.set_exclude_collision_path(0, index, spring.get_path_to(colliders[order[index]]))
		_expect(spring, "spring_bone_exclude_order", order_case[1])
	spring.set_enable_all_child_collisions(0, false)
	spring.set_exclude_collision_count(0, 2)
	spring.set_exclude_collision_path(0, 0, spring.get_path_to(colliders[1]))
	spring.set_exclude_collision_path(0, 1, spring.get_path_to(colliders[0]))
	_expect(spring, "spring_bone_exclude_order", false) # The deny list is unused with an allow list.
	# A scene scanned by path is outside the tree, where an absolute path makes get_node_or_null print an engine error.
	spring.set_enable_all_child_collisions(0, true)
	spring.set_exclude_collision_count(0, 1)
	spring.set_exclude_collision_path(0, 0, NodePath("/root/Skeleton3D/SpringBoneSimulator3D/Collider0"))
	root.remove_child(skeleton)
	_expect(spring, "spring_bone_exclude_order", false)
	skeleton.free()


## Godot behaviour behind scene_validation.spring_bone_exclude_order: an unsorted exclude list leaves the excluded
## collider active. If a future Godot fixes the merge, this fails and the rule needs a version cap.
func _spring_exclude_engine_behaviour() -> void:
	var tips := {}
	for order in [[0, 1], [1, 0]]:
		var skeleton := Skeleton3D.new()
		for bone in ["root", "mid", "tip"]:
			skeleton.add_bone(bone)
		skeleton.set_bone_parent(1, 0)
		skeleton.set_bone_parent(2, 1)
		skeleton.set_bone_rest(1, Transform3D(Basis(), Vector3(0, -1, 0)))
		skeleton.set_bone_rest(2, Transform3D(Basis(), Vector3(0, -1, 0)))
		skeleton.reset_bone_poses()
		root.add_child(skeleton)
		var spring := SpringBoneSimulator3D.new()
		skeleton.add_child(spring)
		spring.setting_count = 1
		spring.set_root_bone_name(0, "root")
		spring.set_end_bone_name(0, "tip")
		var colliders: Array = []
		for index in 2:
			var sphere := SpringBoneCollisionSphere3D.new()
			sphere.radius = 0.6
			sphere.position = Vector3(0.3, -2, 0) if index == 0 else Vector3(100, 0, 0)
			spring.add_child(sphere)
			colliders.append(sphere)
		spring.set_enable_all_child_collisions(0, true)
		spring.set_exclude_collision_count(0, 2)
		for index in 2:
			spring.set_exclude_collision_path(0, index, spring.get_path_to(colliders[order[index]]))
		var seen := {"tip": Vector3.INF}
		# Skeleton3D restores the unmodified pose after modifiers run; the modified pose is readable in skeleton_updated.
		skeleton.skeleton_updated.connect(func(): seen.tip = skeleton.get_bone_global_pose(2).origin)
		for frame in 60:
			await process_frame
		tips[str(order)] = seen.tip
		skeleton.free()
	assert(tips["[0, 1]"].is_equal_approx(Vector3(0, -2, 0)), "Sorted exclusion leaves the chain at rest: %s" % tips)
	assert(not tips["[1, 0]"].is_equal_approx(Vector3(0, -2, 0)), "Unsorted exclusion still applies the excluded collider (Godot behaviour): %s" % tips)


func _spring_collision_pairs() -> void:
	var skeleton := Skeleton3D.new()
	for index in 18:
		skeleton.add_bone("spring_%d" % index)
		if index > 0:
			skeleton.set_bone_parent(index, index - 1)
			skeleton.set_bone_rest(index, Transform3D(Basis.IDENTITY, Vector3(0, 0.2, 0)))
	var spring := SpringBoneSimulator3D.new()
	skeleton.add_child(spring)
	root.add_child(skeleton)
	skeleton.set_process_internal(true)
	spring.set_setting_count(1)
	spring.set_enable_all_child_collisions(0, true)
	spring.set_root_bone(0, 0)
	spring.set_end_bone(0, 15)
	assert(spring.get_joint_count(0) == 16)
	for index in 8:
		var collider := SpringBoneCollisionSphere3D.new()
		collider.name = "collider_%d" % index
		spring.add_child(collider)
	_expect(spring, "spring_bone_collision_pairs", false)
	spring.set_end_bone(0, 16)
	assert(spring.get_joint_count(0) == 17)
	_expect(spring, "spring_bone_collision_pairs", true)
	spring.set_exclude_collision_count(0, 1)
	spring.set_exclude_collision_path(0, 0, NodePath("collider_0"))
	_expect(spring, "spring_bone_collision_pairs", false)
	spring.set_exclude_collision_count(0, 129)
	_expect(spring, "spring_bone_collision_pairs", false)
	spring.set_enable_all_child_collisions(0, false)
	spring.set_collision_count(0, 9)
	for index in 9:
		spring.set_collision_path(0, index, NodePath("collider_%d" % mini(index, 7)))
	_expect(spring, "spring_bone_collision_pairs", true)
	for index in 9:
		spring.set_collision_path(0, index, NodePath("collider_0"))
	_expect(spring, "spring_bone_collision_pairs", false)
	spring.set_enable_all_child_collisions(0, true)
	spring.set_exclude_collision_count(0, 0)
	spring.active = false
	_expect(spring, "spring_bone_collision_pairs", false)
	spring.active = true
	skeleton.process_mode = Node.PROCESS_MODE_DISABLED
	_expect(spring, "spring_bone_collision_pairs", false)
	skeleton.process_mode = Node.PROCESS_MODE_INHERIT
	skeleton.set_process_internal(false)
	skeleton.set_physics_process_internal(false)
	_expect(spring, "spring_bone_collision_pairs", false)
	skeleton.set_physics_process_internal(true)
	_expect(spring, "spring_bone_collision_pairs", true)
	var scripted := ScriptedSpring.new()
	skeleton.add_child(scripted)
	scripted.set_setting_count(1)
	scripted.set_enable_all_child_collisions(0, true)
	scripted.set_root_bone(0, 0)
	scripted.set_end_bone(0, 17)
	for index in 8:
		scripted.add_child(SpringBoneCollisionSphere3D.new())
	_expect(scripted, "spring_bone_collision_pairs", false)
	var custom := ScriptedSpringCollider.new()
	spring.add_child(custom)
	spring.set_end_bone(0, 15)
	_expect(spring, "spring_bone_collision_pairs", false)
	spring.set_enable_all_child_collisions(0, false)
	spring.set_collision_count(0, 1)
	spring.set_collision_path(0, 0, NodePath("collider_7"))
	spring.get_node("collider_7").free()
	var unrelated := Node3D.new()
	unrelated.name = "collider_7"
	spring.add_child(unrelated)
	_expect(spring, "spring_bone_collision_pairs", false)
	assert(spring.get_collision_path(0, 0) == NodePath("collider_7"), "The audit must not rebuild caches and clear an obsolete path")
	var bounded := SpringBoneSimulator3D.new()
	skeleton.add_child(bounded)
	bounded.set_setting_count(1)
	bounded.set_root_bone(0, 0)
	bounded.set_end_bone(0, 17)
	bounded.set_enable_all_child_collisions(0, true)
	for index in 128:
		bounded.add_child(Node3D.new())
	for index in 8:
		bounded.add_child(SpringBoneCollisionSphere3D.new())
	_expect(bounded, "spring_bone_collision_pairs", false)
	for child in bounded.get_children().slice(0, 128):
		child.free()
	_expect(bounded, "spring_bone_collision_pairs", true)
	bounded.set_setting_count(129)
	bounded.set_root_bone(128, 0)
	bounded.set_end_bone(128, 17)
	bounded.set_enable_all_child_collisions(128, true)
	bounded.set_end_bone(0, 0)
	_expect(bounded, "spring_bone_collision_pairs", false)
	skeleton.free()


func _cooperative_vector_operands() -> void:
	for component in [[22, 16, false], [22, 32, true], [22, 64, true], [21, 32, true], [22, 128, false]]:
		for layout in [-1, 0, 1, 2, 3, 4]:
			for capability in [true, false]:
				var module := _module(Vector3i.ONE)
				module.append_array(PackedInt32Array([
					(2 << 16) | 17, 5435 if capability else 1,
					((3 if component[0] == 22 else 4) << 16) | component[0], 2, component[1],
				]).to_byte_array())
				if component[0] == 21:
					module.append_array(PackedInt32Array([1]).to_byte_array())
				module.append_array(PackedInt32Array([
					(4 << 16) | 5288, 3, 2, 11, (4 << 16) | 32, 4, 7, 3,
					(4 << 16) | 21, 10, 32, 1, (4 << 16) | 43, 10, 11, layout,
					(5 << 16) | 54, 17, 1, 0, 18, (2 << 16) | 248, 19,
					(4 << 16) | 59, 4, 9, 7, (4 << 16) | 61, 3, 8, 9,
					(8 << 16) | 5290, 12, 13, 8, 8, 11, 11, 13, (1 << 16) | 253, (1 << 16) | 56,
				]).to_byte_array())
				var parsed := Shaders.local_size(module)
				assert(parsed.cooperative_outer_type == (component[2] and capability))
				assert(parsed.cooperative_outer_layout == (layout != 3 and capability))
				var without_stride := module.to_int32_array()
				var call := without_stride.find((8 << 16) | 5290)
				without_stride[call] = (7 << 16) | 5290
				without_stride.remove_at(call + 7)
				var omitted_stride := Shaders.local_size(without_stride.to_byte_array())
				assert(omitted_stride.cooperative_outer_type == parsed.cooperative_outer_type and omitted_stride.cooperative_outer_layout == parsed.cooperative_outer_layout, "The optional stride does not affect these restrictions")
				var later := module.duplicate()
				var words := later.to_int32_array()
				for index in range(5, words.size() - 1):
					if words[index] == ((5 << 16) | 54):
						words[index + 2] = 20
				var helper := Shaders.local_size(words.to_byte_array())
				assert(not helper.cooperative_outer_type and not helper.cooperative_outer_layout, "Helper bodies are omitted")
				words = module.to_int32_array()
				var offset := words.find((8 << 16) | 5290) * 4
				var later_block := module.slice(0, offset)
				later_block.append_array(PackedInt32Array([(2 << 16) | 249, 20, (2 << 16) | 248, 20]).to_byte_array())
				later_block.append_array(module.slice(offset))
				var later_parsed := Shaders.local_size(later_block)
				assert(not later_parsed.cooperative_outer_type and not later_parsed.cooperative_outer_layout, "Later blocks are omitted")
				var literal := words.find((4 << 16) | 43)
				words[literal] = (4 << 16) | 50
				var specialized := Shaders.local_size(words.to_byte_array())
				assert(not specialized.cooperative_outer_layout and specialized.cooperative_outer_type == (component[2] and capability), "A specialized layout is unknown independently of vector component types")
	var unknown := _module(Vector3i.ONE)
	unknown.append_array(PackedInt32Array([
		(2 << 16) | 17, 5394, (5 << 16) | 54, 17, 1, 0, 18,
		(8 << 16) | 5290, 12, 13, 8, 8, 11, 11, 13, (1 << 16) | 253,
		(8 << 16) | 5290, 12, 13, 8, 8, 11, 11, 13, (1 << 16) | 56,
	]).to_byte_array())
	var parsed := Shaders.local_size(unknown)
	assert(not parsed.cooperative_outer_type and not parsed.cooperative_outer_layout, "Unresolved inputs and layouts are skipped")


func _shader_layouts() -> void:
	for dim in [0, 1, 2, 3, 5, 6]:
		for entry_body in [true, false]:
			var module := _module(Vector3i(8, 1, 1))
			module.append_array(PackedInt32Array([
				(3 << 16) | 22, 2, 32, (9 << 16) | 25, 3, 2, dim, 0, 0, 0, 2, 0,
				(4 << 16) | 32, 4, 0, 3, (4 << 16) | 59, 4, 5, 0,
			]).to_byte_array())
			assert(not Shaders.local_size(module).multidimensional_image_access, "A declaration does not prove image access")
			module.append_array(PackedInt32Array([
				(5 << 16) | 54, 6, 1 if entry_body else 20, 0, 7,
				(4 << 16) | 61, 3, 8, 5, (4 << 16) | 99, 8, 9, 10, (1 << 16) | 56,
			]).to_byte_array())
			var parsed := Shaders.local_size(module)
			assert(parsed.multidimensional_image_access == (entry_body and dim in [1, 2, 3]))
			for size in [Vector3i(8, 1, 1), Vector3i(1, 8, 1), Vector3i(8, 8, 1), Vector3i.ONE, Vector3i.ZERO]:
				for driver in ["vulkan", "d3d12", ""]:
					parsed["driver"] = driver
					var state := {"counts": {}, "offenders": {}}
					Shaders.record(size, state, "res://image.glsl", {}, parsed)
					assert(state.counts.has("check_compute_arm_spatial") == (entry_body and dim in [1, 2, 3] and size in [Vector3i(8, 1, 1), Vector3i(1, 8, 1)] and driver == "vulkan"))
	for words_count in [13, 14, 32, 33]:
		var module := _module(Vector3i.ONE)
		module.append_array(PackedInt32Array([
			(4 << 16) | 21, 2, 32, 0, (4 << 16) | 43, 2, 3, words_count,
			(4 << 16) | 28, 4, 2, 3, (3 << 16) | 30, 5, 4,
			(5 << 16) | 72, 5, 0, 35, 0, (4 << 16) | 32, 6, 9, 5,
			(4 << 16) | 59, 6, 7, 9,
		]).to_byte_array())
		var parsed := Shaders.local_size(module)
		assert(parsed.push_constant_bytes == words_count * 4)
		for driver in ["vulkan", "d3d12", "metal", ""]:
			for limit in [0, 128]:
				parsed["driver"] = driver
				var state := {"counts": {}, "offenders": {}}
				Shaders.record(parsed.size, state, "res://push.glsl", {"push_constants": limit}, parsed)
				assert(state.counts.has("check_compute_amd_layout") == (words_count > 13 and driver == "vulkan"))
				assert(state.counts.has("check_compute_push_constant_limit") == (words_count == 33 and limit == 128 and driver == "vulkan"))
		module.encode_u32(80, (4 << 16) | 50) # Unknown specialization-controlled array length.
		assert(Shaders.local_size(module).push_constant_bytes == 0)
	var member := _module(Vector3i.ONE)
	member.append_array(PackedInt32Array([
		(3 << 16) | 22, 2, 32, (3 << 16) | 30, 3, 2,
		(4 << 16) | 32, 4, 9, 3, (4 << 16) | 59, 4, 5, 9,
	]).to_byte_array())
	assert(Shaders.local_size(member).push_constant_bytes == 0, "Missing offsets are unknown")
	member.append_array(PackedInt32Array([(5 << 16) | 72, 3, 0, 35, 128]).to_byte_array())
	assert(Shaders.local_size(member).push_constant_bytes == 132, "Explicit member offsets contribute to the range")
	for dim in [1, 5, 6]:
		for sampled in [1, 2]:
			var module := _module(Vector3i.ONE)
			module.append_array(PackedInt32Array([
				(3 << 16) | 22, 2, 32, (9 << 16) | 25, 3, 2, dim, 0, 0, 0, sampled, 0,
				(4 << 16) | 21, 4, 32, 0, (4 << 16) | 43, 4, 5, 17,
				(4 << 16) | 28, 6, 3, 5, (4 << 16) | 32, 7, 0, 6,
				(4 << 16) | 59, 7, 8, 0, (4 << 16) | 71, 8, 34, 0, (4 << 16) | 71, 8, 33, 1,
			]).to_byte_array())
			var parsed := Shaders.local_size(module)
			assert(parsed.descriptor_counts.sampled_images == (17 if dim == 1 and sampled == 1 else 0))
			assert(parsed.descriptor_counts.storage_images == (17 if dim == 1 and sampled == 2 else 0))
			assert(parsed.descriptor_counts.samplers == 0)
	for resource in ["samplers", "sampled_images", "storage_images"]:
		for amount in [16, 17]:
			for maximum in [0, 16, 17]:
				for driver in ["vulkan", "d3d12", "metal", ""]:
					var state := {"counts": {}, "offenders": {}}
					Shaders.record(Vector3i.ZERO, state, "res://descriptors.glsl", {resource: maximum}, {"driver": driver, "descriptor_counts": {resource: amount}})
					assert(state.counts.has("check_compute_" + resource + "_limit") == (maximum == 16 and amount == 17 and driver == "vulkan"))


func _shader_8bit_interfaces() -> void:
	for stage in RenderingDevice.SHADER_STAGE_MAX:
		var model: int = Shaders.STAGE_MODELS[stage]
		for storage in [0, 1, 3, 4, 6, 9, 12]:
			for width in [8, 16, 32, 64]:
				for count in [1, 4]:
					var parsed := Shaders.local_size(_interface_module(model, storage, 21, width, count), model)
					assert(parsed.interface_8bit == (width == 8 and storage in [1, 3]), str(stage, storage, width, count))
	assert(Shaders.local_size(_interface_module(0, 3, 22, 8), 0).interface_8bit)
	for encoding in [[8, 4214, true], [8, 4215, true], [8, 4226, true], [16, 0, false]]:
		var words := _interface_module(0, 3, 22, encoding[0]).to_int32_array()
		var cursor := 5
		while cursor < words.size():
			var count := words[cursor] >> 16
			if (words[cursor] & 0xffff) == 22:
				words[cursor] = (4 << 16) | 22
				assert(words.insert(cursor + 3, encoding[1]) == OK)
				break
			cursor += count
		assert(Shaders.local_size(words.to_byte_array(), 0).interface_8bit == encoding[2], "Optional floating encodings must preserve eight-bit IO detection")
	for shape in [PackedInt32Array([(3 << 16) | 30, 12, 2]), PackedInt32Array([(4 << 16) | 28, 12, 2, 99]), PackedInt32Array([(3 << 16) | 29, 12, 2])]:
		var module := _interface_module(0, 3, 21, 8)
		module.encode_u32(module.size() - 20, 12)
		module.append_array(shape.to_byte_array())
		assert(Shaders.local_size(module, 0).interface_8bit, "Aggregate element width does not need a known array length")
	var types := {1: [21, 8], 2: [32, 5349, 1], 3: [30, 2], 4: [30, 4], 5: [30, 1, 4]}
	assert(not Shaders._has_8bit(3, types, {}), "Pointers to 8-bit data are not 8-bit members")
	assert(not Shaders._has_8bit(4, types, {}), "Malformed cycles remain bounded")
	assert(Shaders._has_8bit(5, types, {}), "Known 8-bit members provide positive evidence")
	assert(not Shaders._has_8bit(99, types, {}))
	for id in range(10, 30):
		types[id] = [28, id + 1, 99]
	types[30] = [21, 8]
	var cache := {}
	assert(not Shaders._has_8bit(10, types, cache), "Deep chains are outside the audit budget")
	assert(Shaders._has_8bit(25, types, cache), "A deep skip must not suppress a later shallow declaration")
	var spirv := RDShaderSPIRV.new()
	spirv.bytecode_vertex = _interface_module(0, 3, 21, 8)
	var file := RDShaderFile.new()
	file.set_bytecode(spirv)
	assert(ResourceSaver.save(file, "res://interface8-driver.res") == OK)
	var config := ConfigFile.new()
	config.set_value("remap", "type", "RDShaderFile")
	config.set_value("remap", "path", "res://interface8-driver.res")
	assert(config.save("res://interface8-driver.glsl.import") == OK)
	var source := FileAccess.open("res://interface8-driver.glsl", FileAccess.WRITE)
	source.store_string("#[vertex]\n")
	source.close()
	var state := {"counts": {}, "offenders": {}}
	Shaders.scan(["res://interface8-driver.glsl"], state)
	assert(state.counts.has("check_shader_interface_8bit") == (RenderingServer.get_current_rendering_driver_name() == "vulkan"), "Eight-bit IO findings require Vulkan")
	for suffix in [".glsl", ".glsl.import", ".res"]:
		DirAccess.remove_absolute("res://interface8-driver" + suffix)


func _shader_image_formats() -> void:
	for entry in [[1, 1, 2, true], [4, 1, 2, true], [40, 1, 2, true], [41, 1, 2, true], [0, 1, 2, false], [42, 1, 2, false], [1, 1, 1, false], [1, 4, 2, false], [1, 5, 2, false], [1, 6, 2, false]]:
		var module := _module(Vector3i.ONE)
		module.append_array(PackedInt32Array([
			(3 << 16) | 22, 2, 32, (9 << 16) | 25, 3, 2, entry[1], 0, 0, 0, entry[2], entry[0],
			(4 << 16) | 21, 4, 32, 0, (4 << 16) | 43, 4, 5, 2,
			(4 << 16) | 28, 6, 3, 5, (4 << 16) | 32, 7, 0, 6,
			(4 << 16) | 59, 7, 8, 0, (4 << 16) | 71, 8, 34, 0, (4 << 16) | 71, 8, 33, 1,
		]).to_byte_array())
		var expected: Array = [entry[0]] if entry[3] else []
		assert(Shaders.local_size(module).storage_image_formats == expected, str(entry))
		module.append_array(PackedInt32Array([(4 << 16) | 59, 7, 9, 0, (4 << 16) | 71, 9, 34, 0, (4 << 16) | 71, 9, 33, 2]).to_byte_array())
		assert(Shaders.local_size(module).storage_image_formats == expected, "Repeated formats are queried once")
		module.resize(224)
		module.encode_u32(172, 3) # Direct image pointer instead of the fixed array.
		assert(Shaders.local_size(module).storage_image_formats == expected)
		module.encode_u32(172, 6)
		module.encode_u32(128, (4 << 16) | 50) # Specialized lengths remain unknown.
		assert(Shaders.local_size(module).storage_image_formats.is_empty())
		module.encode_u32(128, (4 << 16) | 43)
		module.resize(192) # Missing descriptor decorations.
		assert(Shaders.local_size(module).storage_image_formats.is_empty())
	for driver in ["vulkan", "d3d12", "metal", "opengl3", ""]:
		for supported in [false, true, null]:
			var state := {"counts": {}, "offenders": {}}
			var cache := {1: supported}
			Shaders.record_image_formats([0, -1, 42, 1], state, "synthetic cached device metadata, never submitted", cache, driver)
			assert(state.counts.has("check_shader_storage_format") == (driver == "vulkan" and supported == false))
			assert(cache == {1: supported}, "Unknown formats and other drivers do not query native support")


func _buffer_module(storage: int, decoration: int, buffer_array: bool = false) -> PackedByteArray:
	var bytes := _module(Vector3i.ONE)
	bytes.append_array(PackedInt32Array([
		(3 << 16) | 22, 2, 32, (4 << 16) | 23, 3, 2, 4, (3 << 16) | 30, 4, 3,
		(4 << 16) | 21, 9, 32, 0, (4 << 16) | 43, 9, 10, 2, (4 << 16) | 28, 11, 4, 10,
		(4 << 16) | 32, 5, storage, 11 if buffer_array else 4, (4 << 16) | 59, 5, 6, storage,
		(5 << 16) | 72, 4, 0, 35, 80,
		(4 << 16) | 71, 6, 34, 3, (4 << 16) | 71, 6, 33, 0,
	]).to_byte_array())
	if decoration != 0:
		bytes.append_array(PackedInt32Array([(3 << 16) | 71, 4, decoration]).to_byte_array())
	return bytes


func _shader_buffers() -> void:
	for entry in [[2, 2, "uniform_buffers"], [2, 3, "storage_buffers"], [12, 2, "storage_buffers"], [12, 3, ""], [2, 0, ""]]:
		var module := _buffer_module(entry[0], entry[1])
		var parsed := Shaders.local_size(module)
		assert(parsed.bound_sets == (4 if entry[2] != "" else 0))
		assert(parsed.uniform_buffer_size == (96 if entry[2] == "uniform_buffers" else 0))
		assert(parsed.descriptor_counts.uniform_buffers == int(entry[2] == "uniform_buffers"))
		assert(parsed.descriptor_counts.storage_buffers == int(entry[2] == "storage_buffers"))
		assert(parsed.descriptor_bytes == (8 if entry[2] == "uniform_buffers" else (16 if entry[2] == "storage_buffers" else 0)))
		module.append_array(PackedInt32Array([(4 << 16) | 59, 5, 8, entry[0], (4 << 16) | 71, 8, 34, 3, (4 << 16) | 71, 8, 33, 0]).to_byte_array())
		assert(Shaders.local_size(module).descriptor_counts == parsed.descriptor_counts, "Aliases at the same binding are counted once")
		assert(Shaders.local_size(_buffer_module(entry[0], entry[1], true)).descriptor_bytes == 0, "Buffer arrays are outside the verified reflection path")
	for resource in ["samplers", "sampled_images", "storage_images", "uniform_buffers", "storage_buffers"]:
		for limits in [{resource: 32, resource + "_stage": 16}, {resource: 16, resource + "_stage": 32}, {resource: 0, resource + "_stage": 16}, {resource: 0, resource + "_stage": 0}]:
			for amount in [16, 17]:
				var state := {"counts": {}, "offenders": {}}
				Shaders.record(Vector3i.ZERO, state, "res://stages.glsl", limits, {"driver": "vulkan", "descriptor_counts": {resource: amount}})
				assert(state.counts.has("check_compute_" + resource + "_limit") == (amount == 17 and limits[resource + "_stage"] > 0))
	for resource in ["bound_sets", "uniform_buffer_size"]:
		for amount in [16, 17]:
			for maximum in [0, 16, 17]:
				for driver in ["vulkan", "d3d12", "metal", ""]:
					var state := {"counts": {}, "offenders": {}}
					Shaders.record(Vector3i.ZERO, state, "res://layout.glsl", {resource: maximum}, {"driver": driver, resource: amount})
					assert(state.counts.has("check_compute_" + resource + "_limit") == (amount == 17 and maximum == 16 and driver == "vulkan"))
	for sets in [0, 1, 2]:
		var state := {"counts": {}, "offenders": {}}
		Shaders.record(Vector3i.ONE, state, "res://layout.glsl", {}, {"driver": "vulkan", "push_constant_bytes": 48, "bound_sets": sets})
		assert(state.counts.has("check_compute_amd_layout") == (sets == 2))


func _tilemaps() -> void:
	var layer := TileMapLayer.new()
	for key in ["tilemap_small_quadrants", "tilemap_y_sort_groups", "tilemap_navigation_regions", "tilemap_physics_chunking", "tilemap_occluders", "tilemap_animation_slices"]:
		_expect(layer, key, false)
	var scene_layer := TileMapLayer.new()
	scene_layer.tile_set = TileSet.new()
	var scenes := TileSetScenesCollectionSource.new()
	var packed := PackedScene.new()
	var marker := Node2D.new()
	packed.pack(marker)
	marker.free()
	var scene_id := scenes.create_scene_tile(packed)
	scene_layer.tile_set.add_source(scenes, 0)
	for cell in 257:
		scene_layer.set_cell(Vector2i(cell, 0), 0, Vector2i.ZERO, scene_id)
	_expect(scene_layer, "tilemap_scene_tiles", true)
	scene_layer.erase_cell(Vector2i.ZERO)
	_expect(scene_layer, "tilemap_scene_tiles", false)
	scene_layer.free()
	var tiles := TileSet.new()
	tiles.add_physics_layer()
	tiles.add_navigation_layer()
	tiles.add_occlusion_layer()
	var atlas := TileSetAtlasSource.new()
	var image := Image.create(512, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.create_tile(Vector2i.ZERO)
	tiles.add_source(atlas, 0)
	var tile := atlas.get_tile_data(Vector2i.ZERO, 0)
	var occluder := OccluderPolygon2D.new()
	occluder.polygon = PackedVector2Array([Vector2.ZERO, Vector2(16, 0), Vector2(0, 16)])
	tile.set_occluder_polygons_count(0, 1)
	tile.set_occluder_polygon(0, 0, occluder)
	var navigation := NavigationPolygon.new()
	navigation.vertices = PackedVector2Array([Vector2.ZERO, Vector2(16, 0), Vector2(0, 16)])
	navigation.add_polygon(PackedInt32Array([0, 1, 2]))
	tile.set_navigation_polygon(0, navigation)
	tile.set_collision_polygons_count(0, 1)
	tile.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2.ZERO, Vector2(16, 0), Vector2(0, 16)]))
	layer.tile_set = tiles
	layer.rendering_quadrant_size = 4
	for cell in 256:
		layer.set_cell(Vector2i(cell, 0), 0, Vector2i.ZERO)
	_expect(layer, "tilemap_small_quadrants", false)
	_expect(layer, "tilemap_navigation_regions", false)
	_expect(layer, "tilemap_occluders", false)
	atlas.set_tile_animation_frames_count(Vector2i.ZERO, 16)
	_expect(layer, "tilemap_animation_slices", false)
	layer.set_cell(Vector2i(256, 0), 0, Vector2i.ZERO)
	_expect(layer, "tilemap_animation_slices", true)
	_expect(layer, "tilemap_occluders", true)
	layer.occlusion_enabled = false
	_expect(layer, "tilemap_occluders", false)
	layer.occlusion_enabled = true
	tiles.set_occlusion_layer_light_mask(0, 0)
	tiles.set_occlusion_layer_sdf_collision(0, false)
	_expect(layer, "tilemap_occluders", false)
	tiles.set_occlusion_layer_sdf_collision(0, true)
	_expect(layer, "tilemap_occluders", true)
	occluder.polygon = PackedVector2Array([Vector2.ZERO, Vector2(16, 0)])
	_expect(layer, "tilemap_occluders", false)
	occluder.closed = false
	_expect(layer, "tilemap_occluders", true)
	occluder.polygon = PackedVector2Array()
	_expect(layer, "tilemap_occluders", false)
	tile.set_occluder_polygon(0, 0, null)
	_expect(layer, "tilemap_occluders", false)
	occluder.polygon = PackedVector2Array([Vector2.ZERO, Vector2(16, 0)])
	tile.set_occluder_polygon(0, 0, occluder)
	_expect(layer, "tilemap_small_quadrants", true)
	_expect(layer, "tilemap_navigation_regions", true)
	layer.rendering_quadrant_size = 16
	_expect(layer, "tilemap_small_quadrants", false)
	layer.rendering_quadrant_size = 4
	layer.visible = false
	_expect(layer, "tilemap_small_quadrants", false)
	_expect(layer, "tilemap_occluders", false)
	_expect(layer, "tilemap_animation_slices", false)
	_expect(layer, "tilemap_navigation_regions", true)
	layer.visible = true
	layer.enabled = false
	_expect(layer, "tilemap_small_quadrants", false)
	_expect(layer, "tilemap_occluders", false)
	_expect(layer, "tilemap_animation_slices", false)
	_expect(layer, "tilemap_navigation_regions", false)
	layer.enabled = true
	layer.y_sort_enabled = true
	_expect(layer, "tilemap_small_quadrants", false)
	_expect(layer, "tilemap_y_sort_groups", false)
	for rows in [64, 65]:
		layer.clear()
		for cell in 257:
			layer.set_cell(Vector2i(cell / rows, cell % rows), 0, Vector2i.ZERO, TileSetAtlasSource.TRANSFORM_FLIP_H)
		_expect(layer, "tilemap_y_sort_groups", rows == 65)
	layer.visible = false
	_expect(layer, "tilemap_y_sort_groups", false)
	layer.visible = true
	if Engine.get_version_info().minor >= 5:
		layer.set("physics_quadrant_size", 1)
		_expect(layer, "tilemap_physics_chunking", true)
		layer.collision_enabled = false
		_expect(layer, "tilemap_physics_chunking", false)
		layer.collision_enabled = true
		tiles.set_physics_layer_collision_layer(0, 0)
		tiles.set_physics_layer_collision_mask(0, 0)
		_expect(layer, "tilemap_physics_chunking", false)
		tiles.set_physics_layer_collision_layer(0, 1)
		layer.set("physics_quadrant_size", 16)
		_expect(layer, "tilemap_physics_chunking", false)
	else:
		_expect(layer, "tilemap_physics_chunking", false)
	layer.navigation_enabled = false
	_expect(layer, "tilemap_navigation_regions", false)
	layer.navigation_enabled = true
	tiles.set_navigation_layer_layers(0, 0)
	_expect(layer, "tilemap_navigation_regions", false)
	tiles.set_navigation_layer_layers(0, 1)
	tile.set_navigation_polygon(0, NavigationPolygon.new())
	_expect(layer, "tilemap_navigation_regions", false)
	var texture := atlas.texture
	atlas.texture = null
	_expect(layer, "tilemap_y_sort_groups", false)
	_expect(layer, "tilemap_animation_slices", false)
	atlas.texture = texture
	atlas.set_tile_animation_frames_count(Vector2i.ZERO, 1)
	_expect(layer, "tilemap_animation_slices", false)
	tile.set_occluder_polygons_count(0, 33)
	var occlusion_limited := {"counts": {}, "offenders": {}}
	Checks.inspect(layer, occlusion_limited, "res://occlusion-limit.tscn")
	assert(occlusion_limited.tilemap_scan.resource_limits_reached > 0)
	var limited := {"counts": {}, "offenders": {}, "tilemap_scan": {"inspected_cells": 4096, "skipped_cells": 0, "runtime_layers_skipped": 0, "resource_limits_reached": 0, "max_cells": 4096}}
	Checks.inspect(layer, limited, "res://tiles.tscn")
	assert(limited.tilemap_scan.inspected_cells == 4096 and limited.tilemap_scan.skipped_cells == 257)
	for extra_layer in 32:
		tiles.add_navigation_layer()
	var capped := {"counts": {}, "offenders": {}}
	Checks.inspect(layer, capped, "res://tiles.tscn")
	assert(capped.tilemap_scan.resource_limits_reached > 0)
	for scripted in [RuntimeTiles.new(), InheritedRuntimeTiles.new()]:
		scripted.tile_set = tiles
		scripted.set_cell(Vector2i.ZERO, 0, Vector2i.ZERO)
		var state := {"counts": {}, "offenders": {}}
		Checks.inspect(scripted, state, "res://runtime-tiles.tscn")
		assert(state.tilemap_scan.runtime_layers_skipped == 1 and not scripted.callback_called)
		scripted.free()
	tiles.remove_source(0)
	_expect(layer, "tilemap_y_sort_groups", false)
	tiles.add_source(TileSetScenesCollectionSource.new(), 0)
	_expect(layer, "tilemap_y_sort_groups", false)
	layer.free()


func _query_module(flags: int, minimum: float, maximum: float, mode: String = "literal") -> PackedByteArray:
	var bytes := _module(Vector3i.ONE)
	var constant := 50 if mode == "specialized" else 43
	var words := PackedInt32Array([
		(4 << 16) | 21, 2, 32, 0, (3 << 16) | 22, 4, 32,
		(4 << 16) | constant, 2, 3, flags,
		(4 << 16) | constant, 4, 5, PackedFloat32Array([minimum]).to_byte_array().decode_s32(0),
		(4 << 16) | constant, 4, 6, PackedFloat32Array([maximum]).to_byte_array().decode_s32(0),
		(5 << 16) | 54, 7, 8 if mode == "helper" else 1, 0, 9, (2 << 16) | 248, 10])
	if mode == "after_branch":
		words.append_array(PackedInt32Array([(2 << 16) | 249, 11, (2 << 16) | 248, 11]))
	if mode == "null_minimum":
		words.append_array(PackedInt32Array([(3 << 16) | 46, 4, 12]))
	var dynamic := mode == "dynamic"
	words.append_array(PackedInt32Array([(9 << 16) | 4473, 20, 21, 22 if dynamic else 3, 23, 24, 25 if dynamic else (12 if mode == "null_minimum" else 5), 26, 27 if dynamic else 6, (1 << 16) | 253, (1 << 16) | 56]))
	bytes.append_array(words.to_byte_array())
	return bytes


func _math_module(operation: int, left: Array, right: Array, mode: String = "literal") -> PackedByteArray:
	var bytes := _module(Vector3i.ONE)
	bytes.encode_u32(12, 128)
	var words := PackedInt32Array([(6 << 16) | 11, 10, 0x4c534c47, 0x6474732e, 0x3035342e, 1 if mode == "wrong_import" else 0, (3 << 16) | 22, 2, 32, (4 << 16) | 23, 4, 2, left.size()])
	for side in 2:
		var values: Array = left if side == 0 else right
		for index in values.size():
			if values[index] != null:
				words.append_array(PackedInt32Array([(4 << 16) | (50 if mode == "specialized" else 43), 2, 20 + side * 10 + index, PackedFloat32Array([values[index]]).to_byte_array().decode_s32(0)]))
	words.append_array(PackedInt32Array([(5 << 16) | 54, 7, 8 if mode == "helper" else 1, 0, 9, (2 << 16) | 248, 11]))
	var operands: Array[int] = [20, 30]
	if left.size() > 1:
		operands = [50, 51]
		for side in 2:
			words.append_array(PackedInt32Array([((3 + left.size()) << 16) | 80, 4, 50 + side]))
			for index in left.size():
				words.append(20 + side * 10 + index)
	if mode == "after_branch":
		words.append_array(PackedInt32Array([(2 << 16) | 249, 12, (2 << 16) | 248, 12]))
	elif mode in ["after_ignore_intersection", "after_terminate_ray"]:
		words.append_array(PackedInt32Array([(1 << 16) | (4448 if mode == "after_ignore_intersection" else 4449), (2 << 16) | 248, 12]))
	words.append_array(PackedInt32Array([(7 << 16) | 12, 2 if left.size() == 1 else 4, 60, 10, operation, operands[0], operands[1], (1 << 16) | 253, (1 << 16) | 56]))
	bytes.append_array(words.to_byte_array())
	return bytes


func _shader_math() -> void:
	for entry in [[26, [-1.0], [null], "pow_domain", true], [26, [1.0], [null], "pow_domain", false], [26, [0.0], [0.0], "pow_domain", true], [26, [-0.0], [-1.0], "pow_domain", true], [26, [0.0], [1.0], "pow_domain", false], [26, [null, -1.0], [null, null], "pow_domain", true], [26, [null, 0.0], [null, 1.0], "pow_domain", false], [25, [0.0], [-0.0], "atan2_zero", true], [25, [0.0], [1.0], "atan2_zero", false], [25, [null, 0.0], [null, 0.0], "atan2_zero", true], [25, [null, 0.0], [null, null], "atan2_zero", false], [37, [NAN], [1.0], "minmax_nan", true], [40, [null, 1.0], [null, NAN], "minmax_nan", true], [37, [INF], [1.0], "minmax_nan", false], [40, [null], [0.0], "minmax_nan", false]]:
		var parsed := Shaders.local_size(_math_module(entry[0], entry[1], entry[2]))
		assert(parsed[entry[3]] == entry[4], str(entry, parsed))
		for driver in ["vulkan", "d3d12", "opengl3"]:
			parsed.driver = driver
			var state := {"counts": {}, "offenders": {}}
			Shaders.record(parsed.size, state, "res://math.glsl", {}, parsed)
			assert(state.counts.has("check_compute_" + entry[3]) == (entry[4] and driver == "vulkan"))
		for mode in ["wrong_import", "helper", "after_branch", "specialized"]:
			assert(not Shaders.local_size(_math_module(entry[0], entry[1], entry[2], mode))[entry[3]], str(entry, mode))
	assert(not Shaders.local_size(_math_module(38, [NAN], [1.0])).minmax_nan, "Non-floating min must not use the float rule")


func _audio_expect(key: String, expected: bool) -> void:
	var state := {"counts": {}, "offenders": {}}
	ProjectScan._audio_buses(state)
	assert(state.counts.has("check_" + key) == expected, str(key, state))
	if expected:
		assert(str(state.offenders["check_" + key][0]).begins_with("Audio bus 'RenderLens Fixture' / effect 0"))


func _audio_bus_checks() -> void:
	var bus := AudioServer.get_bus_count()
	AudioServer.add_bus()
	AudioServer.set_bus_name(bus, "RenderLens Fixture")
	var pitch := AudioEffectPitchShift.new()
	pitch.oversampling = 8
	AudioServer.add_bus_effect(bus, pitch)
	_audio_expect("pitch_shift_oversampling", false)
	pitch.pitch_scale = 1.25
	_audio_expect("pitch_shift_oversampling", true)
	AudioServer.set_bus_bypass_effects(bus, true)
	_audio_expect("pitch_shift_oversampling", false)
	AudioServer.set_bus_bypass_effects(bus, false)
	AudioServer.set_bus_effect_enabled(bus, 0, false)
	_audio_expect("pitch_shift_oversampling", false)
	AudioServer.set_bus_effect_enabled(bus, 0, true)
	pitch.pitch_scale = 1.000001
	_audio_expect("pitch_shift_oversampling", false)
	pitch.pitch_scale = 1.25
	pitch.oversampling = 4
	_audio_expect("pitch_shift_oversampling", false)
	pitch.fft_size = AudioEffectPitchShift.FFT_SIZE_256
	pitch.oversampling = 256
	_audio_expect("pitch_shift_oversampling", true)
	_audio_expect("audio_pitch_zero_hop", false)
	pitch.oversampling = 257
	assert(pitch.oversampling == 257)
	_audio_expect("audio_pitch_zero_hop", true)
	_audio_expect("pitch_shift_oversampling", false)
	pitch.pitch_scale = 1.0
	_audio_expect("audio_pitch_zero_hop", false)
	AudioServer.remove_bus_effect(bus, 0)
	var chorus := AudioEffectChorus.new()
	AudioServer.add_bus_effect(bus, chorus)
	_audio_expect("chorus_voices", false)
	chorus.voice_count = 3
	chorus.set_voice_cutoff_hz(2, 8000.0)
	_audio_expect("chorus_voices", true)
	chorus.set_voice_cutoff_hz(2, 0.0)
	_audio_expect("chorus_voices", false)
	chorus.set_voice_cutoff_hz(2, 8000.0)
	chorus.wet = -0.5
	_audio_expect("chorus_voices", true)
	chorus.wet = 0.0
	chorus.dry = 1.0
	_audio_expect("chorus_voices", false)
	_audio_expect("chorus_dry_only", true)
	chorus.dry = 0.5
	_audio_expect("chorus_dry_only", false)
	chorus.dry = 1.0
	AudioServer.set_bus_effect_enabled(bus, 0, false)
	_audio_expect("chorus_dry_only", false)
	AudioServer.set_bus_effect_enabled(bus, 0, true)
	AudioServer.set_bus_bypass_effects(bus, true)
	_audio_expect("chorus_dry_only", false)
	AudioServer.set_bus_bypass_effects(bus, false)
	for voice in chorus.voice_count:
		chorus.set_voice_cutoff_hz(voice, 0.0)
	_audio_expect("chorus_dry_only", false)
	AudioServer.remove_bus_effect(bus, 0)
	var scripted := ScriptedPitchShift.new()
	var reverb := AudioEffectReverb.new()
	AudioServer.add_bus_effect(bus, reverb)
	_audio_expect("reverb_dry_only", false)
	reverb.wet = 0.0
	reverb.dry = 1.0
	_audio_expect("reverb_dry_only", true)
	reverb.wet = 0.000001
	_audio_expect("reverb_dry_only", false)
	reverb.wet = 0.0
	reverb.dry = 0.5
	_audio_expect("reverb_dry_only", false)
	reverb.dry = 1.0
	AudioServer.remove_bus_effect(bus, 0)
	var stereo := AudioEffectStereoEnhance.new()
	AudioServer.add_bus_effect(bus, stereo)
	_audio_expect("stereo_neutral", true)
	stereo.pan_pullout = 0.0
	_audio_expect("stereo_neutral", false)
	stereo.pan_pullout = 1.0
	stereo.time_pullout_ms = 0.1
	_audio_expect("stereo_neutral", false)
	stereo.time_pullout_ms = 0.0
	stereo.surround = 0.1
	_audio_expect("stereo_neutral", false)
	stereo.surround = 0.0
	AudioServer.remove_bus_effect(bus, 0)
	for eq in [AudioEffectEQ6.new(), AudioEffectEQ10.new(), AudioEffectEQ21.new()]:
		AudioServer.add_bus_effect(bus, eq)
		_audio_expect("eq_many_bands", eq is AudioEffectEQ21)
		eq.set_band_gain_db(0, -20.0)
		_audio_expect("eq_many_bands", eq is AudioEffectEQ21)
		AudioServer.remove_bus_effect(bus, 0)
	var spectrum := AudioEffectSpectrumAnalyzer.new()
	AudioServer.add_bus_effect(bus, spectrum)
	_audio_expect("spectrum_history", false)
	spectrum.buffer_length = 4.0
	_audio_expect("spectrum_history", false)
	spectrum.buffer_length = 4.01
	assert(spectrum.buffer_length > 4.0)
	_audio_expect("spectrum_history", true)
	spectrum.buffer_length = INF
	_audio_expect("spectrum_history", false)
	spectrum.buffer_length = NAN
	_audio_expect("spectrum_history", false)
	spectrum.buffer_length = 4.01
	AudioServer.remove_bus_effect(bus, 0)
	for pair in [[reverb, "reverb_dry_only"], [stereo, "stereo_neutral"], [AudioEffectEQ21.new(), "eq_many_bands"], [spectrum, "spectrum_history"]]:
		AudioServer.add_bus_effect(bus, pair[0])
		_audio_expect(pair[1], true)
		AudioServer.set_bus_bypass_effects(bus, true)
		_audio_expect(pair[1], pair[1] == "spectrum_history")
		AudioServer.set_bus_bypass_effects(bus, false)
		AudioServer.set_bus_effect_enabled(bus, 0, false)
		_audio_expect(pair[1], pair[1] == "spectrum_history")
		AudioServer.set_bus_effect_enabled(bus, 0, true)
		AudioServer.remove_bus_effect(bus, 0)
	var scripted_spectrum := ScriptedSpectrum.new()
	scripted_spectrum.buffer_length = 4.01
	AudioServer.add_bus_effect(bus, scripted_spectrum)
	_audio_expect("spectrum_history", false)
	AudioServer.remove_bus_effect(bus, 0)
	scripted.pitch_scale = 1.25
	scripted.oversampling = 8
	AudioServer.add_bus_effect(bus, scripted)
	_audio_expect("pitch_shift_oversampling", false)
	var state := {"counts": {}, "offenders": {}}
	ProjectScan._audio_buses(state)
	assert(state.audio_scan.uninspected_effects >= 1)
	AudioServer.remove_bus(bus)
	assert(AudioServer.get_bus_count() == bus)


func _shader_zero_divisors() -> void:
	for opcode in [134, 135, 136, 137, 138, 139, 140, 141]:
		for mode in ["zero", "one", "negative_zero", "null", "specialized", "helper", "after_branch", "dynamic"]:
			var floating: bool = opcode in [136, 140, 141]
			var bytes := _module(Vector3i.ONE)
			var words := PackedInt32Array([(3 << 16) | 22, 2, 32]) if floating else PackedInt32Array([(4 << 16) | 21, 2, 32, int(opcode in [135, 138, 139])])
			var bits := (0x3f800000 if floating else 1) if mode == "one" else (-2147483648 if mode == "negative_zero" and floating else 0)
			if mode == "null":
				words.append_array(PackedInt32Array([(3 << 16) | 46, 2, 3]))
			else:
				words.append_array(PackedInt32Array([(4 << 16) | (50 if mode == "specialized" else 43), 2, 3, bits]))
			words.append_array(PackedInt32Array([(5 << 16) | 54, 7, 8 if mode == "helper" else 1, 0, 9, (2 << 16) | 248, 10]))
			if mode == "after_branch":
				words.append_array(PackedInt32Array([(2 << 16) | 249, 11, (2 << 16) | 248, 11]))
			words.append_array(PackedInt32Array([(5 << 16) | opcode, 2, 12, 20, 21 if mode == "dynamic" else 3, (1 << 16) | 253, (1 << 16) | 56]))
			bytes.append_array(words.to_byte_array())
			var parsed := Shaders.local_size(bytes)
			var expected: bool = opcode != 136 and mode in ["zero", "negative_zero", "null"]
			assert(parsed.zero_divisor == expected, str(opcode, mode, parsed))
			for driver in ["vulkan", "d3d12", "opengl3"]:
				parsed.driver = driver
				var state := {"counts": {}, "offenders": {}}
				Shaders.record(parsed.size, state, "res://divisor.glsl", {}, parsed)
				assert(state.counts.has("check_compute_zero_divisor") == (expected and driver == "vulkan"))


func _shader_ray_queries() -> void:
	for entry in [[0, false], [1, false], [2, false], [4, false], [8, false], [16, false], [32, false], [64, false], [128, false], [256, false], [512, false], [529, false], [3, true], [0x300, true], [0x30, true], [0x110, true], [0x120, true], [0x41, true], [0x82, true], [0xc0, true]]:
		var parsed := Shaders.local_size(_query_module(entry[0], 0.0, 1.0))
		assert(parsed.ray_query_flags == entry[1] and not parsed.ray_query_distance, str(entry, parsed))
		for driver in ["vulkan", "opengl3", "d3d12"]:
			parsed.driver = driver
			var state := {"counts": {}, "offenders": {}}
			Shaders.record(parsed.size, state, "res://query.glsl", {}, parsed)
			assert(state.counts.has("check_compute_ray_query_flags") == (entry[1] and driver == "vulkan"))
	for entry in [[-1.0, 1.0, true], [0.0, -1.0, true], [2.0, 1.0, true], [1.0, 1.0, false], [0.0, 0.0, false], [-0.0, 0.0, false], [0.0, INF, false], [INF, INF, false], [INF, 1.0, true], [NAN, 1.0, true], [0.0, NAN, true]]:
		var parsed := Shaders.local_size(_query_module(0, entry[0], entry[1]))
		assert(parsed.ray_query_distance == entry[2] and not parsed.ray_query_flags, str(entry, parsed))
		for driver in ["vulkan", "opengl3", "d3d12"]:
			parsed.driver = driver
			var state := {"counts": {}, "offenders": {}}
			Shaders.record(parsed.size, state, "res://query.glsl", {}, parsed)
			assert(state.counts.has("check_compute_ray_query_distance") == (entry[2] and driver == "vulkan"))
	for mode in ["specialized", "helper", "after_branch", "dynamic"]:
		var parsed := Shaders.local_size(_query_module(0x300, -1.0, -2.0, mode))
		assert(not parsed.ray_query_flags and not parsed.ray_query_distance, str(mode, parsed))
	assert(not Shaders.local_size(_query_module(0, -1.0, 0.0, "null_minimum")).ray_query_distance)
	var truncated := _query_module(0x300, -1.0, -2.0)
	truncated.resize(truncated.size() - 12)
	assert(Shaders.local_size(truncated).has("skip"))


func _gridmaps() -> void:
	var grid := GridMap.new()
	grid.cell_octant_size = 2
	grid.bake_navigation = true
	_expect(grid, "gridmap_small_octants", false)
	_expect(grid, "gridmap_navigation_regions", false)
	var library := MeshLibrary.new()
	library.create_item(0)
	library.set_item_mesh(0, BoxMesh.new())
	var navigation := NavigationMesh.new()
	navigation.vertices = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.BACK])
	navigation.add_polygon(PackedInt32Array([0, 1, 2]))
	library.set_item_navigation_mesh(0, navigation)
	grid.mesh_library = library
	for cell in 256:
		grid.set_cell_item(Vector3i(cell, 0, 0), 0)
	_expect(grid, "gridmap_small_octants", false)
	_expect(grid, "gridmap_navigation_regions", false)
	grid.set_cell_item(Vector3i(256, 0, 0), 0)
	_expect(grid, "gridmap_small_octants", true)
	_expect(grid, "gridmap_navigation_regions", true)
	grid.cell_octant_size = 8
	_expect(grid, "gridmap_small_octants", false)
	grid.cell_octant_size = 2
	grid.visible = false
	_expect(grid, "gridmap_small_octants", false)
	_expect(grid, "gridmap_navigation_regions", true)
	grid.visible = true
	grid.set("baked_meshes", [BoxMesh.new()])
	_expect(grid, "gridmap_small_octants", false)
	grid.clear_baked_meshes()
	grid.bake_navigation = false
	_expect(grid, "gridmap_navigation_regions", false)
	grid.bake_navigation = true
	library.set_item_navigation_layers(0, 0)
	_expect(grid, "gridmap_navigation_regions", false)
	library.set_item_navigation_layers(0, 1)
	library.set_item_navigation_mesh(0, NavigationMesh.new())
	_expect(grid, "gridmap_navigation_regions", false)
	library.set_item_mesh(0, null)
	_expect(grid, "gridmap_small_octants", false)
	library.set_item_mesh(0, ArrayMesh.new())
	_expect(grid, "gridmap_small_octants", false)
	var limited := {"counts": {}, "offenders": {}, "gridmap_scan": {"inspected_cells": 4096, "skipped_cells": 0, "max_cells": 4096}}
	Checks.inspect(grid, limited, "res://grid.tscn")
	assert(limited.gridmap_scan.inspected_cells == 4096 and limited.gridmap_scan.skipped_cells == 257)
	grid.free()


func _connections_and_masks() -> void:
	for particles in [GPUParticles2D.new(), GPUParticles3D.new()]:
		var process := ParticleProcessMaterial.new()
		particles.process_material = process
		_expect(particles, "particle_points_data", false)
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
		_expect(particles, "particle_points_data", true)
		process.emission_point_texture = GradientTexture2D.new()
		process.emission_point_count = 1
		_expect(particles, "particle_points_data", false)
		process.emission_point_count = 0
		_expect(particles, "particle_points_data", true)
		process.emission_point_count = 1
		process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_DIRECTED_POINTS
		_expect(particles, "particle_points_data", true)
		process.emission_normal_texture = GradientTexture2D.new()
		_expect(particles, "particle_points_data", false)
		particles.process_material = ShaderMaterial.new()
		_expect(particles, "particle_points_data", false)
		particles.sub_emitter = NodePath("Missing")
		_expect(particles, "particle_subemitter_target", false)
		root.add_child(particles)
		_expect(particles, "particle_subemitter_target", true)
		particles.sub_emitter = NodePath(".")
		_expect(particles, "particle_subemitter_target", true)
		particles.sub_emitter = NodePath("/root")
		_expect(particles, "particle_subemitter_target", true)
		var target: Node = GPUParticles3D.new() if particles is GPUParticles3D else GPUParticles2D.new()
		root.add_child(target)
		particles.sub_emitter = particles.get_path_to(target)
		_expect(particles, "particle_subemitter_target", false)
		particles.free()
		target.free()
	for follow in [PathFollow2D.new(), PathFollow3D.new()]:
		_expect(follow, "path_curve_data", false)
		var path: Node = Path3D.new() if follow is PathFollow3D else Path2D.new()
		path.add_child(follow)
		path.curve = null
		_expect(follow, "path_curve_data", true)
		if path is Path3D:
			path.curve = Curve3D.new()
			path.curve.add_point(Vector3.ZERO)
			_expect(follow, "path_curve_data", true)
			path.curve.add_point(Vector3.ONE)
		else:
			path.curve = Curve2D.new()
			path.curve.add_point(Vector2.ZERO)
			_expect(follow, "path_curve_data", true)
			path.curve.add_point(Vector2.ONE)
		_expect(follow, "path_curve_data", false)
		path.free()
	for cast in [ShapeCast2D.new(), ShapeCast3D.new()]:
		_expect(cast, "shape_cast_resource", true)
		if cast is ShapeCast3D:
			_expect(cast, "shape_cast_concave", false)
			cast.shape = ConcavePolygonShape3D.new()
			_expect(cast, "shape_cast_concave", true)
			cast.shape = SphereShape3D.new()
			_expect(cast, "shape_cast_concave", false)
		else:
			cast.shape = CircleShape2D.new()
		_expect(cast, "shape_cast_resource", false)
		cast.free()
	var wheel := VehicleWheel3D.new()
	_expect(wheel, "vehicle_wheel_parent", true)
	var vehicle := VehicleBody3D.new()
	vehicle.add_child(wheel)
	_expect(wheel, "vehicle_wheel_parent", false)
	vehicle.free()
	for joint in [PinJoint2D.new(), PinJoint3D.new()]:
		_expect(joint, "joint_targets", false)
		root.add_child(joint)
		_expect(joint, "joint_targets", true)
		var a: Node = StaticBody2D.new() if joint is Joint2D else StaticBody3D.new()
		var b: Node = RigidBody2D.new() if joint is Joint2D else RigidBody3D.new()
		root.add_child(a)
		root.add_child(b)
		joint.node_b = joint.get_path_to(b)
		_expect(joint, "joint_targets", joint is Joint2D) # Only 3D supports a world endpoint.
		joint.node_a = joint.get_path_to(a)
		_expect(joint, "joint_targets", false)
		joint.node_a = joint.node_b
		_expect(joint, "joint_targets", true)
		joint.node_a = NodePath("/root")
		_expect(joint, "joint_targets", true) # A non-body cannot be a world endpoint.
		joint.free()
		a.free()
		b.free()
	var lightmap := LightmapGI.new()
	lightmap.shadowmask_mode = LightmapGIData.SHADOWMASK_MODE_REPLACE
	_expect(lightmap, "lightmap_shadowmask", false)
	lightmap.light_data = LightmapGIData.new()
	_expect(lightmap, "lightmap_shadowmask", true)
	var shadowmask := Texture2DArray.new()
	assert(shadowmask.create_from_images([Image.create(1, 1, false, Image.FORMAT_RGBA8)]) == OK)
	lightmap.light_data.shadowmask_textures = [shadowmask]
	_expect(lightmap, "lightmap_shadowmask", false)
	lightmap.light_data.shadowmask_textures = []
	lightmap.shadowmask_mode = LightmapGIData.SHADOWMASK_MODE_NONE
	_expect(lightmap, "lightmap_shadowmask", false)
	lightmap.free()
	for entry in [
		[Camera3D.new(), "camera_cull_mask", "cull_mask"],
		[MeshInstance3D.new(), "geometry_layers", "layers"],
		[OmniLight3D.new(), "light_cull_mask", "light_cull_mask"],
		[GPUParticlesCollisionSphere3D.new(), "particle_collider_mask", "cull_mask"],
		[GPUParticlesAttractorSphere3D.new(), "particle_attractor_mask", "cull_mask"],
		[NavigationAgent2D.new(), "navigation_layers", "navigation_layers"],
		[NavigationAgent3D.new(), "navigation_layers", "navigation_layers"],
		[NavigationRegion2D.new(), "navigation_layers", "navigation_layers"],
		[NavigationRegion3D.new(), "navigation_layers", "navigation_layers"],
		[NavigationLink2D.new(), "navigation_layers", "navigation_layers"],
		[NavigationLink3D.new(), "navigation_layers", "navigation_layers"],
	]:
		var node: Node = entry[0]
		_expect(node, entry[1], false)
		node.set(entry[2], 0)
		_expect(node, entry[1], true)
		node.set(entry[2], 1 << 25)
		_expect(node, entry[1], false) # Reserved/internal layers must not be treated as zero.
		if node is NavigationRegion2D or node is NavigationRegion3D or node is NavigationLink2D or node is NavigationLink3D:
			node.navigation_layers = 0
			node.enabled = false
			_expect(node, entry[1], false)
		node.free()
	var field := GPUParticlesAttractorVectorField3D.new()
	_expect(field, "particle_vector_texture", true)
	_expect(field, "particle_vector_resolution", false)
	var texture := ImageTexture3D.new()
	var slices: Array[Image] = []
	for i in 64:
		slices.append(Image.create(64, 64, false, Image.FORMAT_R8))
	assert(texture.create(Image.FORMAT_R8, 64, 64, 64, false, slices) == OK)
	field.texture = texture
	_expect(field, "particle_vector_texture", false)
	_expect(field, "particle_vector_resolution", false)
	slices.append(Image.create(64, 64, false, Image.FORMAT_R8))
	assert(texture.create(Image.FORMAT_R8, 64, 64, 65, false, slices) == OK)
	_expect(field, "particle_vector_resolution", true)
	field.strength = 0.0
	_expect(field, "particle_vector_resolution", false)
	field.strength = 1.0
	field.cull_mask = 0
	_expect(field, "particle_vector_resolution", false)
	field.free()
	var heightfield := GPUParticlesCollisionHeightField3D.new()
	assert(Scan.scan(heightfield).counts.heightfield_high_res_count == 0)
	heightfield.resolution = GPUParticlesCollisionHeightField3D.RESOLUTION_2048
	assert(Scan.scan(heightfield).counts.heightfield_high_res_count == 1)
	heightfield.free()
	var slider := HSlider.new()
	slider.min_value = -1.0
	_expect(slider, "range_exp_min", false)
	slider.exp_edit = true
	_expect(slider, "range_exp_min", true)
	slider.min_value = 0.0
	_expect(slider, "range_exp_min", Engine.get_version_info().minor == 4)
	slider.min_value = 1.0
	_expect(slider, "range_exp_min", false)
	slider.free()
	var control := Control.new()
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_expect(control, "tooltip_mouse_filter", false)
	control.tooltip_text = "Details"
	_expect(control, "tooltip_mouse_filter", true)
	control.mouse_filter = Control.MOUSE_FILTER_PASS
	_expect(control, "tooltip_mouse_filter", false)
	control.free()
	for sprite in [Sprite3D.new(), AnimatedSprite3D.new(), Label3D.new()]:
		_expect(sprite, "sprite_shaded", false)
		sprite.shaded = true
		_expect(sprite, "sprite_shaded", true)
		sprite.material_override = ShaderMaterial.new()
		_expect(sprite, "sprite_shaded", false)
		sprite.free()


func _camera_effects() -> void:
	for provider in [Camera3D.new(), WorldEnvironment.new()]:
		_expect(provider, "camera_dof_renderer", false)
		_expect(provider, "camera_autoexposure_renderer", false)
		var attributes := CameraAttributesPractical.new()
		provider.set("attributes" if provider is Camera3D else "camera_attributes", attributes)
		attributes.dof_blur_near_enabled = true
		_expect(provider, "camera_dof_renderer", true)
		attributes.dof_blur_near_enabled = false
		attributes.dof_blur_far_enabled = true
		_expect(provider, "camera_dof_renderer", true)
		attributes.auto_exposure_enabled = true
		_expect(provider, "camera_autoexposure_renderer", true)
		var physical := CameraAttributesPhysical.new()
		provider.set("attributes" if provider is Camera3D else "camera_attributes", physical)
		_expect(provider, "camera_dof_renderer", false) # Do not guess physical lens blur.
		physical.auto_exposure_enabled = true
		_expect(provider, "camera_autoexposure_renderer", true)
		provider.free()
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	_expect(viewport, "viewport_dof_transparent", false)
	root.add_child(viewport)
	var world := WorldEnvironment.new()
	world.camera_attributes = CameraAttributesPractical.new()
	world.camera_attributes.dof_blur_far_enabled = true
	viewport.add_child(world)
	_expect(viewport, "viewport_dof_transparent", true)
	var camera := Camera3D.new()
	camera.attributes = CameraAttributesPractical.new()
	viewport.add_child(camera)
	camera.make_current()
	_expect(viewport, "viewport_dof_transparent", false)
	camera.attributes.dof_blur_near_enabled = true
	_expect(viewport, "viewport_dof_transparent", true)
	viewport.transparent_bg = false
	_expect(viewport, "viewport_dof_transparent", false)
	viewport.free()
	var modifier := SkeletonModifier3D.new()
	_expect(modifier, "skeleton_modifier_parent", true)
	modifier.active = false
	_expect(modifier, "skeleton_modifier_parent", false)
	modifier.active = true
	var skeleton := Skeleton3D.new()
	skeleton.add_child(modifier)
	_expect(modifier, "skeleton_modifier_parent", false)
	skeleton.free()
	var container := SubViewportContainer.new()
	_expect(container, "viewport_shrink_ignored", false)
	container.stretch_shrink = 2
	_expect(container, "viewport_shrink_ignored", true)
	container.stretch = true
	_expect(container, "viewport_shrink_ignored", false)
	container.free()


func _canvas_and_collision_boundaries() -> void:
	var ancestor := CanvasGroup.new()
	var middle := Node2D.new()
	var clip := Node2D.new()
	clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	ancestor.add_child(middle)
	middle.add_child(clip)
	_expect(clip, "canvas_group_clip", true)
	_expect(clip, "canvas_nested_clip", false)
	ancestor.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	_expect(clip, "canvas_nested_clip", true)
	middle.top_level = true
	_expect(clip, "canvas_group_clip", false)
	_expect(clip, "canvas_nested_clip", false)
	middle.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_expect(clip, "canvas_nested_clip", true) # Children still inherit from a top-level parent.
	middle.remove_child(clip)
	for boundary in [Node.new(), CanvasLayer.new(), SubViewport.new()]:
		ancestor.add_child(boundary)
		boundary.add_child(clip)
		_expect(clip, "canvas_group_clip", false)
		_expect(clip, "canvas_nested_clip", false)
		boundary.remove_child(clip)
		boundary.free()
	var control := Control.new()
	control.clip_contents = true
	control.add_child(clip)
	_expect(clip, "canvas_nested_clip", false) # Scissor clipping is a separate mechanism.
	control.free()
	ancestor.free()
	for body in [Area2D.new(), StaticBody2D.new(), Area3D.new(), StaticBody3D.new(), CharacterBody3D.new(), RigidBody3D.new()]:
		_expect(body, "collision_object_empty", false) # Shape owners may not be registered while detached.
		root.add_child(body)
		_expect(body, "collision_object_empty", true)
		var owner_id: int = body.create_shape_owner(body)
		_expect(body, "collision_object_empty", false) # An empty owner still exists in the native shapes map.
		body.remove_shape_owner(owner_id)
		_expect(body, "collision_object_empty", true)
		if body is CollisionObject3D:
			_expect(body, "collision_nonuniform", false)
			body.scale = Vector3(1, 1.02, 1)
			_expect(body, "collision_nonuniform", true)
		body.free()


func _catalog() -> void:
	var audio_ctx := {"renderer": "forward_plus", "version_major": 4, "version_minor": 4, "scene": {"audio_unbounded_count": 1, "check_audio_unbounded_distance": 1}}
	var audio_findings := Rules.evaluate(audio_ctx, "static")
	assert(_has(audio_findings, "audio.unbounded_3d") and not _has(audio_findings, "audio.audio_unbounded_distance"), "One audio distance finding retains the original rule ID")
	audio_ctx.scene.check_audio_unbounded_distance = 0
	assert(not _has(Rules.evaluate(audio_ctx, "static"), "audio.unbounded_3d"), "Inactive or streamless audio does not activate the distance rule")
	var particle_ctx := {"renderer": "forward_plus", "version_major": 4, "version_minor": 4, "scene": {"gpu_particle_high_amount_count": 1, "heightfield_high_res_count": 1}}
	var particle_findings := Rules.evaluate(particle_ctx, "static")
	assert(_has(particle_findings, "particles.gpu_amount") and _has(particle_findings, "particles.heightfield_resolution"))
	assert(not _has(particle_findings, "particles.amount_documented") and not _has(particle_findings, "particles.particle_heightfield_resolution"), "Particle amount and height-field resolution each have one finding")
	var ssao := {"renderer": "gl_compatibility", "version_major": 4, "version_minor": 4, "scene": {"env_ssao": 1}}
	assert(_has(Rules.evaluate(ssao, "static"), "scene_validation.env_ssao_renderer"))
	ssao.version_minor = 7
	assert(not _has(Rules.evaluate(ssao, "static"), "scene_validation.env_ssao_renderer"), "Godot 4.7 Compatibility supports SSAO")
	ssao.version_minor = 5
	assert(_has(Rules.evaluate(ssao, "static"), "scene_validation.env_ssao_renderer"), "The 4.5 GLES3 driver only stores SSAO settings")
	ssao.version_minor = 6
	assert(not _has(Rules.evaluate(ssao, "static"), "scene_validation.env_ssao_renderer"), "Godot 4.6 Compatibility implements SSAO")
	var parallax := {"renderer": "forward_plus", "version_major": 4, "version_minor": 4, "scene": {"heightmap_material_count": 1, "check_material_deep_parallax": 1}}
	assert(_has(Rules.evaluate(parallax, "static"), "materials.material_deep_parallax"))
	assert(not _has(Rules.evaluate(parallax, "static"), "materials.heightmap"), "Specific parallax advice replaces the generic duplicate")
	parallax.scene.check_material_deep_parallax = 0
	assert(_has(Rules.evaluate(parallax, "static"), "materials.heightmap"))
	for rule in Rules.load_rules():
		if rule.category != "scene_validation" and rule.get("evidence_kind", "") != "godot_feature" and not rule.id.begins_with("gpu_best_practices.compute_"):
			continue
		var key: String = rule.offender_key
		# Satisfy every scene threshold in the condition (count cutoffs and companion scene requirements).
		var scene := {key: 1}
		for part in (rule.condition.all if rule.condition.has("all") else [rule.condition]):
			if part.has("scene_gte"):
				scene[part.scene_gte.name] = part.scene_gte.value
		# The positive case uses a renderer allowed at the first verified version (renderers_by_version, as the engine reads it).
		var first_minor := int(rule.applies_to.versions[0].split(".")[1])
		var first_renderers: Array = rule.applies_to.renderers
		var first_at := -1
		for entry in rule.applies_to.get("renderers_by_version", {}):
			var at := int(str(entry).split(".")[1])
			if at <= first_minor and at > first_at:
				first_at = at
				first_renderers = rule.applies_to.renderers_by_version[entry]
		var ctx := {"renderer": first_renderers[0], "version_major": 4, "version_minor": first_minor, "scene": scene, "adapter": {"vendor": ""}, "settings": {"rendering/shading/overrides/force_vertex_shading": false}}
		# Settings a rule's condition requires alongside the scene threshold (for example xr/openxr/enabled).
		for part in (rule.condition.all if rule.condition.has("all") else [rule.condition]):
			if part.has("setting_eq") and part.setting_eq.path != "rendering/shading/overrides/force_vertex_shading":
				ctx.settings[part.setting_eq.path] = part.setting_eq.value
		if rule.condition.has("all") and str(rule.condition).contains("force_vertex_shading"):
			ctx.settings["rendering/shading/overrides/force_vertex_shading"] = true
			assert(not _has(Rules.evaluate(ctx, "static"), rule.id), rule.id + " vertex override")
			ctx.settings["rendering/shading/overrides/force_vertex_shading"] = false
		var vendors: Array = rule.applies_to.get("vendors", [])
		if not vendors.is_empty():
			ctx.adapter.vendor = vendors[0]
		assert(_has(Rules.evaluate(ctx, "static"), rule.id), rule.id + " positive")
		var positive: int = ctx.scene[key]
		ctx.scene[key] = 0
		assert(not _has(Rules.evaluate(ctx, "static"), rule.id), rule.id + " zero")
		ctx.scene[key] = positive
		if not vendors.is_empty():
			ctx.adapter.vendor = "Unknown"
			assert(not _has(Rules.evaluate(ctx, "static"), rule.id), rule.id + " vendor")
		else:
			for renderer in ["forward_plus", "mobile", "gl_compatibility"]:
				ctx.renderer = renderer
				for version in rule.applies_to.versions:
					ctx.version_minor = int(version.split(".")[1])
					# Like the engine: the nearest renderer list at or below this version, else the rule's default list.
					var allowed: Array = rule.applies_to.renderers
					var chosen := 0
					var by_version: Dictionary = rule.applies_to.get("renderers_by_version", {})
					for entry in by_version:
						var at := int(str(entry).split(".")[1])
						if at <= ctx.version_minor and at >= chosen:
							chosen = at
							allowed = by_version[entry]
					assert(_has(Rules.evaluate(ctx, "static"), rule.id) == allowed.has(renderer), rule.id + " renderer/version")
		if rule.applies_to.versions == ["4.7"]:
			ctx.version_minor = 4
			assert(not _has(Rules.evaluate(ctx, "static"), rule.id), rule.id + " version")
	var packed := Rules.package([{"id": "configuration", "kind": "correctness", "severity": "medium"}], {"budget_ms": 16.67, "median_ms": 8.0}, 5)
	assert(packed.configuration_findings.size() == 1 and packed.performance_findings.is_empty())
	assert(not packed.top[0].optional)
	var root_node := Node.new()
	var child := Decal.new()
	root_node.add_child(child)
	var scan := Scan.scan(root_node, "res://fixture.tscn")
	assert(scan.counts.check_decal_textures == 1 and scan.has("shader_scan"))
	root_node.free()


func _csg_shapes() -> void:
	var flat := CSGMesh3D.new()
	flat.mesh = PlaneMesh.new()
	var child := CSGBox3D.new()
	flat.add_child(child)
	var box := CSGBox3D.new()
	_expect(flat, "csg_empty_shape", false)
	root.add_child(flat)
	root.add_child(box)
	# CSG results are rebuilt deferred after entering the tree.
	for frame in 3:
		await process_frame
	_expect(flat, "csg_empty_shape", true)
	_expect(child, "csg_empty_shape", true)
	_expect(box, "csg_empty_shape", false)
	# Fade and dynamic GI cost nothing on an empty CSG result or on a child shape; the root draws.
	for shape in [flat, child, box]:
		shape.visibility_range_end = 30.0
		shape.visibility_range_end_margin = 5.0
		shape.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		shape.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	_expect(flat, "geometry_fade_cost", false)
	_expect(child, "geometry_fade_cost", false)
	_expect(box, "geometry_fade_cost", true)
	_expect(flat, "gi_dynamic", false)
	_expect(child, "gi_dynamic", false)
	_expect(box, "gi_dynamic", true)
	flat.free()
	box.free()


func _documented_costs() -> void:
	var omni := OmniLight3D.new()
	omni.shadow_enabled = true
	_expect(omni, "light_shadow_fade", false)
	omni.distance_fade_enabled = true
	_expect(omni, "light_shadow_fade", true)
	omni.distance_fade_shadow = omni.distance_fade_begin + omni.distance_fade_length - 1.0
	_expect(omni, "light_shadow_fade", false)
	omni.free()
	var compound := StaticBody3D.new()
	for index in 16:
		var shape_node := CollisionShape3D.new()
		shape_node.shape = BoxShape3D.new()
		compound.add_child(shape_node)
	_expect(compound, "body_many_shapes", false)
	var extra := CollisionShape3D.new()
	extra.shape = BoxShape3D.new()
	compound.add_child(extra)
	_expect(compound, "body_many_shapes", true)
	extra.disabled = true
	_expect(compound, "body_many_shapes", false)
	compound.free()
	for obstacle in [NavigationObstacle2D.new(), NavigationObstacle3D.new()]:
		obstacle.radius = 1.0
		_expect(obstacle, "obstacle_static_and_dynamic", false)
		obstacle.vertices = [Vector2.ZERO, Vector2(1, 0), Vector2(0, 1)] if obstacle is NavigationObstacle2D else [Vector3.ZERO, Vector3(1, 0, 0), Vector3(0, 0, 1)]
		_expect(obstacle, "obstacle_static_and_dynamic", true)
		obstacle.avoidance_enabled = false
		_expect(obstacle, "obstacle_static_and_dynamic", false)
		obstacle.free()
	var flat_viewport := SubViewport.new()
	var sprite := Sprite2D.new()
	flat_viewport.add_child(sprite)
	_expect(flat_viewport, "subviewport_3d_unused", true)
	flat_viewport.disable_3d = true
	_expect(flat_viewport, "subviewport_3d_unused", false)
	flat_viewport.disable_3d = false
	sprite.add_child(Camera3D.new())
	_expect(flat_viewport, "subviewport_3d_unused", false)
	flat_viewport.free()
	var exposure := WorldEnvironment.new()
	exposure.camera_attributes = CameraAttributesPractical.new()
	_expect(exposure, "auto_exposure", false)
	exposure.camera_attributes.auto_exposure_enabled = true
	_expect(exposure, "auto_exposure", true)
	exposure.environment = Environment.new()
	exposure.environment.adjustment_enabled = true
	for size in [66, 65, 64]:
		var slices: Array[Image] = []
		for index in size:
			slices.append(Image.create(size, size, false, Image.FORMAT_RGB8))
		var lut := ImageTexture3D.new()
		lut.create(Image.FORMAT_RGB8, size, size, size, false, slices)
		exposure.environment.adjustment_color_correction = lut
		_expect(exposure, "color_correction_lut_large", size > 65)
		var fog := FogVolume.new()
		fog.material = FogMaterial.new()
		fog.material.density_texture = lut
		_expect(fog, "fog_density_texture_large", size > 64)
		fog.free()
	exposure.camera_attributes = CameraAttributesPhysical.new()
	assert(Scan.scan(exposure, "res://fixture.tscn").counts.dof_blur_enabled == 1, "Default physical camera attributes blur the near field")
	exposure.camera_attributes.frustum_near = 100.0
	assert(Scan.scan(exposure, "res://fixture.tscn").counts.dof_blur_enabled == 0, "No visible circle of confusion means no physical depth of field")
	exposure.free()
	var coverage := StandardMaterial3D.new()
	coverage.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
	coverage.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_expect(coverage, "material_alpha_to_coverage", true)
	coverage.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_expect(coverage, "material_alpha_to_coverage", false)
	for light in [OmniLight3D.new(), SpotLight3D.new()]:
		_expect(light, "positional_light_dynamic_bake", true)
		light.light_bake_mode = Light3D.BAKE_STATIC
		_expect(light, "positional_light_dynamic_bake", false)
		light.light_bake_mode = Light3D.BAKE_DYNAMIC
		light.visible = false
		_expect(light, "positional_light_dynamic_bake", false)
		light.free()

	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	_expect(sun, "shadow_blend_splits", false)
	sun.directional_shadow_blend_splits = true
	_expect(sun, "shadow_blend_splits", true)
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	_expect(sun, "shadow_blend_splits", false)
	sun.free()

	var decal := Decal.new()
	_expect(decal, "decal_normal_fade", false)
	decal.normal_fade = 0.3
	_expect(decal, "decal_normal_fade", true)
	# A decal that projects onto no layer never runs its normal fade.
	decal.cull_mask = 0
	_expect(decal, "decal_normal_fade", false)
	decal.free()

	var lightmap := LightmapGI.new()
	lightmap.directional = true
	_expect(lightmap, "lightmap_directional", false)
	lightmap.light_data = LightmapGIData.new()
	_expect(lightmap, "lightmap_directional", true)
	_expect(lightmap, "lightmap_data_embedded", true)
	lightmap.light_data.resource_path = "res://fixture.lmbake"
	_expect(lightmap, "lightmap_data_embedded", false)
	var baked := Scan.scan(lightmap, "res://fixture.tscn")
	assert(baked.counts.lightmap_baked_count == 1 and baked.counts.lightmap_unbaked_count == 0, "Baked LightmapGI count")
	lightmap.directional = false
	_expect(lightmap, "lightmap_directional", false)
	lightmap.free()

	var parallax := StandardMaterial3D.new()
	parallax.heightmap_enabled = true
	parallax.heightmap_deep_parallax = true
	parallax.heightmap_texture = PlaceholderTexture2D.new()
	assert(parallax.heightmap_min_layers == 8 and parallax.heightmap_max_layers == 32, "Deep parallax layer defaults changed")
	_expect(parallax, "parallax_layers", false)
	parallax.heightmap_max_layers = 64
	_expect(parallax, "parallax_layers", true)

	var crowd := MultiMeshInstance3D.new()
	crowd.multimesh = MultiMesh.new()
	crowd.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	crowd.multimesh.instance_count = 4096
	_expect(crowd, "multimesh_custom_aabb", true)
	crowd.multimesh.custom_aabb = AABB(Vector3(-10, -10, -10), Vector3(20, 20, 20))
	_expect(crowd, "multimesh_custom_aabb", false)
	crowd.multimesh.custom_aabb = AABB()
	crowd.multimesh.instance_count = 100
	_expect(crowd, "multimesh_custom_aabb", false)
	crowd.free()

	var trails := GPUParticles3D.new()
	trails.trail_enabled = true
	var tube := TubeTrailMesh.new()
	trails.draw_pass_1 = tube
	_expect(trails, "trail_mesh_detail", false)
	tube.radial_steps = 16
	_expect(trails, "trail_mesh_detail", true)
	var ribbon := RibbonTrailMesh.new()
	trails.draw_pass_1 = ribbon
	_expect(trails, "trail_mesh_detail", false)
	ribbon.section_segments = 6
	_expect(trails, "trail_mesh_detail", true)
	trails.trail_enabled = false
	_expect(trails, "trail_mesh_detail", false)
	trails.free()

	var occluder_node := OccluderInstance3D.new()
	var polygon := PolygonOccluder3D.new()
	occluder_node.occluder = polygon
	polygon.polygon = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT, Vector2.UP])
	_expect(occluder_node, "occluder_dense", false)
	var points := PackedVector2Array()
	for index in 65:
		points.append(Vector2.from_angle(TAU * index / 65.0))
	polygon.polygon = points
	_expect(occluder_node, "occluder_dense", true)
	occluder_node.free()

	var sign_3d := Label3D.new()
	sign_3d.text = "Sign"
	_expect(sign_3d, "label3d_font_size", false)
	sign_3d.font_size = 96
	_expect(sign_3d, "label3d_font_size", true)
	var msdf_font := (ThemeDB.fallback_font as FontFile).duplicate() as FontFile
	msdf_font.multichannel_signed_distance_field = true
	sign_3d.font = msdf_font
	_expect(sign_3d, "label3d_font_size", false)
	sign_3d.free()

	var platform := TileMap.new()
	_expect(platform, "tilemap_kinematic", false)
	platform.collision_animatable = true
	_expect(platform, "tilemap_kinematic", true)
	platform.free()

	var holder := Node3D.new()
	var target := Node3D.new()
	target.name = "Target"
	var flat := Node2D.new()
	flat.name = "Flat"
	var player := AnimationPlayer.new()
	holder.add_child(target)
	holder.add_child(flat)
	holder.add_child(player)
	var library := AnimationLibrary.new()
	var clip := Animation.new()
	var track := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, NodePath("Flat:position"))
	library.add_animation(&"walk", clip)
	player.add_animation_library(&"", library)
	_expect(player, "animation_value_transforms", false)
	clip.track_set_path(track, NodePath("Target:position"))
	_expect(player, "animation_value_transforms", true)
	clip.track_set_path(track, NodePath("Target:visible"))
	_expect(player, "animation_value_transforms", false)
	for index in 15:
		var bone_track := clip.add_track(Animation.TYPE_POSITION_3D)
		clip.track_set_path(bone_track, NodePath("Target"))
		clip.track_set_interpolation_type(bone_track, Animation.INTERPOLATION_CUBIC)
	_expect(player, "animation_cubic_3d", false)
	var last := clip.add_track(Animation.TYPE_ROTATION_3D)
	clip.track_set_path(last, NodePath("Target"))
	clip.track_set_interpolation_type(last, Animation.INTERPOLATION_CUBIC_ANGLE)
	_expect(player, "animation_cubic_3d", true)
	clip.track_set_interpolation_type(last, Animation.INTERPOLATION_LINEAR)
	_expect(player, "animation_cubic_3d", false)
	holder.free()

	var debris := MeshInstance3D.new()
	var pebble := BoxMesh.new()
	pebble.size = Vector3(0.1, 0.1, 0.1)
	debris.mesh = pebble
	_expect(debris, "small_shadow_casters", true)
	_expect(debris, "gi_dynamic", false)
	debris.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	_expect(debris, "gi_dynamic", true)
	debris.mesh = null
	_expect(debris, "gi_dynamic", false)
	debris.mesh = pebble
	debris.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_expect(debris, "small_shadow_casters", false)
	debris.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	debris.scale = Vector3(10, 10, 10)
	_expect(debris, "small_shadow_casters", false)
	debris.free()

	var system_font := SystemFont.new()
	system_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_ONE_HALF
	var system_label := Label.new()
	system_label.text = "System font"
	system_label.label_settings = LabelSettings.new()
	system_label.label_settings.font = system_font
	system_label.label_settings.font_size = 32
	var state := {"counts": {}, "offenders": {}}
	Checks.inspect(system_label, state, "res://fixture.tscn::TestNode")
	assert(int(state.counts.get("check_font_subpixel_large", 0)) == 1, "SystemFont subpixel positioning was not inspected")
	assert(int(state.counts.get("check_font_oversampling", 0)) == 0, "SystemFont oversampling must stay outside the FontFile-verified check")
	system_label.free()


func _import_options() -> void:
	DirAccess.make_dir_recursive_absolute("res://import_fixture")
	var files := {
		"hq.png.import": "[remap]\nimporter=\"texture\"\n[params]\ncompress/mode=2\ncompress/high_quality=true\n",
		"lq.png.import": "[remap]\nimporter=\"texture\"\n[params]\ncompress/mode=2\ncompress/high_quality=false\n",
		"sky.exr.import": "[remap]\nimporter=\"texture\"\n[params]\ncompress/mode=2\ncompress/high_quality=false\ncompress/hdr_compression=0\n",
		"sky_ok.exr.import": "[remap]\nimporter=\"texture\"\n[params]\ncompress/mode=2\ncompress/hdr_compression=1\n",
		"flat.png.import": "[remap]\nimporter=\"texture\"\n[params]\ncompress/mode=2\ncompress/hdr_compression=0\n",
		"rock.obj.import": "[remap]\nimporter=\"wavefront_obj\"\n[params]\ngenerate_lods=false\ngenerate_shadow_mesh=false\n",
		"sky.png.import": "[remap]\nimporter=\"cubemap_texture\"\n[params]\ncompress/mode=2\ncompress/high_quality=true\nmipmaps/generate=false\n",
		"embedded.glb.import": "[remap]\nimporter=\"scene\"\n[params]\ngltf/embedded_image_handling=3\n",
		"extracted.glb.import": "[remap]\nimporter=\"scene\"\n[params]\ngltf/embedded_image_handling=1\n",
		"tree.obj.import": "[remap]\nimporter=\"wavefront_obj\"\n[params]\ngenerate_lods=true\ngenerate_shadow_mesh=true\n",
		"sprite.png.import": "[remap]\nimporter=\"texture\"\n[params]\ncompress/mode=0\nmipmaps/generate=false\n",
		"array.png.import": "[remap]\nimporter=\"2d_array_texture\"\n[params]\ncompress/mode=0\nmipmaps/generate=true\n",
	}
	for name in files:
		var file := FileAccess.open("res://import_fixture/" + name, FileAccess.WRITE)
		file.store_string(files[name])
		file.close()
	var state := {"counts": {}, "offenders": {}}
	for key in ["import_texture_high_quality_count", "import_texture_hdr_uncompressed_count", "import_obj_lods_off_count", "import_obj_shadow_off_count", "import_gltf_embedded_uncompressed_count", "import_texture_lossless_count", "import_texture_uncompressed_count", "import_texture_no_mipmaps_count", "import_mesh_lods_off_count", "import_mesh_shadow_off_count", "import_mesh_uncompressed_count", "import_audio_pcm_count"]:
		state.counts[key] = 0
	ProjectScan._imports(state, ProjectScan.project_files(state)[".import"])
	assert(state.file_walk.entries > 0 and not state.file_walk.truncated, str(state.file_walk))
	for name in files:
		DirAccess.remove_absolute("res://import_fixture/" + name)
	DirAccess.remove_absolute("res://import_fixture")
	assert(state.offenders.get("import_texture_no_mipmaps", []).has("res://import_fixture/sky.png"), "Layered texture import options were not scanned")
	assert(state.offenders.get("import_texture_lossless", []).has("res://import_fixture/array.png"), "Lossless layered texture import")
	for key in ["import_texture_lossless", "import_texture_no_mipmaps"]:
		assert(not state.offenders.get(key, []).has("res://import_fixture/sprite.png"), "2D texture defaults are not findings: " + key)
	assert(state.offenders.get("import_texture_high_quality", []) == ["res://import_fixture/hq.png", "res://import_fixture/sky.png"], "High-quality import: %s" % [state.offenders.get("import_texture_high_quality", [])])
	assert(state.offenders.get("import_texture_hdr_uncompressed", []) == ["res://import_fixture/sky.exr"], "HDR import: %s" % [state.offenders.get("import_texture_hdr_uncompressed", [])])
	assert(state.offenders.get("import_obj_lods_off", []) == ["res://import_fixture/rock.obj"], "OBJ LOD import")
	assert(state.offenders.get("import_gltf_embedded_uncompressed", []) == ["res://import_fixture/embedded.glb"], "glTF embedded image import")
	assert(state.offenders.get("import_obj_shadow_off", []) == ["res://import_fixture/rock.obj"], "OBJ shadow import")


func _frame_calls() -> void:
	var calls := {
		"frame_texture_readback": "var image := viewport.get_texture().get_image()",
		"frame_mesh_bake": "var baked := body.bake_mesh_from_current_skeleton_pose()",
		"frame_multimesh_buffer": "var data := RenderingServer.multimesh_get_buffer(rid)",
		"frame_global_shader_get": "var wind = RenderingServer.global_shader_parameter_get(&\"wind\")",
		"frame_force_sync": "RenderingServer.force_sync()",
		"frame_find_nodes": "var hud := find_child(\"HUD\")",
		"frame_group_calls": "get_tree().call_group(\"enemies\", \"think\")",
		"frame_output_latency": "var latency := AudioServer.get_output_latency()",
		"frame_window_title": "DisplayServer.window_set_title(str(Engine.get_frames_per_second()))",
		"frame_capture_rect": "var bounds := sparks.capture_rect()",
		"frame_tile_update": "layer.notify_runtime_tile_data_update()",
		"frame_bone_global_pose": "skeleton.set_bone_global_pose(0, pose)",
		"frame_navigation_parse": "NavigationServer3D.parse_source_geometry_data(mesh, source, root)",
		"frame_navigation_reachable": "var reachable := agent.is_target_reachable()",
		"frame_image_texture_set": "texture.set_image(image)",
		"frame_file_flush": "log_file.flush()",
		"frame_impulse": "apply_central_impulse(Vector3.UP)",
		"frame_navigation_force_update": "NavigationServer3D.map_force_update(get_world_3d().navigation_map)",
		"frame_navigation_bake": "$Region.bake_navigation_mesh()",
		"frame_rendering_sync": "var surfaces := RenderingServer.mesh_get_surface_count(mesh_rid)",
		"frame_physics_3d_sync": "var xform = PhysicsServer3D.body_get_state(rid, PhysicsServer3D.BODY_STATE_TRANSFORM)",
		"frame_physics_2d_sync": "var gravity = PhysicsServer2D.area_get_param(area, PhysicsServer2D.AREA_PARAM_GRAVITY)",
	}
	for key in calls:
		var state := {"counts": {}, "offenders": {}}
		ProjectScan.frame_calls("extends Node\n\nfunc _physics_process(delta: float) -> void:\n\tvar speed := 1.0\n\t%s\n" % calls[key], "res://fixture.gd", state)
		assert(state.offenders.get("check_" + key, []).size() == 1, "%s: %s" % [key, state.offenders])
		assert(str(state.offenders["check_" + key][0]).begins_with("res://fixture.gd:5 "), str(state.offenders["check_" + key]))
		for other in calls:
			# Waiting server getters (frame_*_sync) may also be documented costs, such as RenderingServer.multimesh_get_buffer.
			assert(other == key or not state.counts.has("check_" + other) or other.ends_with("_sync") or key.ends_with("_sync"), "%s also matched %s" % [key, other])
		covered[key + ":true"] = true
	var negatives := [
		"func _process(delta):\n\tif Input.is_action_just_pressed(\"jump\"):\n\t\tapply_central_impulse(Vector3.UP)\n",
		"func _process(delta):\n\tif not visible:\n\t\treturn\n\tvar hud := find_child(\"HUD\")\n",
		"func _process(delta):\n\t# var image := texture.get_image()\n\tvar text := \"call_group( in a string # not a comment\"\n",
		"func _ready():\n\tvar hud := find_child(\"HUD\")\n\tlog_file.flush()\n",
		"func _process(delta):\n\tflush()\n\tget_image()\n\tset_image(image)\n",
		"func _process(delta):\n\tfor index in 3:\n\t\tRenderingServer.force_sync()\n",
		"func _process(delta):\n\tRenderingServer.mesh_surface_set_material(mesh_rid, 0, material)\n\tvar count := my_server.mesh_get_surface_count(mesh_rid)\n\tPhysicsServer3D.body_set_state(rid, 0, value)\n",
		"func _physics_process(delta):\n\tapply_central_impulse(Vector3.UP * 5.0 * delta)\n",
		"func _integrate_forces(state):\n\tstate.apply_central_impulse(Vector3.UP * state.step)\n",
		"func _process(delta):\n\tvar text := \"\"\"\nfind_child(\"x\")\n\t\"\"\"\n",
		"func _process(delta):\n\tvar text := \"a\\\"b find_child(\"\n\tvar raw := r\"\\\" # call_group(\"\n",
		"func _process(delta):\n\tif hit: var image := texture.get_image()\n\telif other: RenderingServer.force_sync()\n\telse: find_child(\"HUD\")\n\tfor node in nodes: node.find_child(\"HUD\")\n",
	]
	for source in negatives:
		var state := {"counts": {}, "offenders": {}}
		ProjectScan.frame_calls("extends Node\n\n" + source, "res://fixture.gd", state)
		assert(state.counts.is_empty(), "Unexpected per-frame finding for:\n%s\n%s" % [source, state.offenders])
	for key in calls:
		covered[key + ":false"] = true
	var second := {"counts": {}, "offenders": {}}
	ProjectScan.frame_calls("func _ready():\n\tpass\n\nfunc _integrate_forces(state):\n\tstate.apply_impulse(Vector3.UP)\n\nfunc helper():\n\tapply_impulse(Vector3.UP)\n", "res://fixture.gd", second)
	assert(second.offenders.get("check_frame_impulse", []) == ["res://fixture.gd:5 apply_impulse() in _integrate_forces"], str(second.offenders))
	assert(ProjectScan.code_only("a # c\nb \"x#y\" 'z'\n\"\"\"\nq\n\"\"\"") == "a \nb \"   \" ' '\n\"\"\"\n \n\"\"\"", ProjectScan.code_only("a # c\nb \"x#y\" 'z'\n\"\"\"\nq\n\"\"\"").c_escape())
	# In a raw string a backslash still consumes the next quote, so the string does not end there.
	assert(not ProjectScan.code_only("var t = r\"\\\"RenderingServer.force_sync()\"\nx\n").contains("force_sync"))
	var after_string := {"counts": {}, "offenders": {}}
	ProjectScan.frame_calls("func _process(delta):\n\tvar text := \"\"\"\n\tfirst\n\t\"\"\"\n\tRenderingServer.force_sync()\n", "res://fixture.gd", after_string)
	assert(after_string.offenders.get("check_frame_force_sync", []) == ["res://fixture.gd:5 force_sync() in _process"], str(after_string.offenders))
	var aliases := {
		"frame_global_shader_get": "RenderingServer.global_shader_parameter_get_list()",
		"frame_tile_update": "layer.update_internals()",
		"frame_impulse": "PhysicsServer3D.body_apply_central_impulse(rid, Vector3.UP)",
	}
	for key in aliases:
		var state := {"counts": {}, "offenders": {}}
		ProjectScan.frame_calls("func _process(delta):\n\t%s\n" % aliases[key], "res://fixture.gd", state)
		assert(state.counts.keys().filter(func(name): return not str(name).ends_with("_sync")) == ["check_" + key], "%s: %s" % [key, state.counts])
	var scripts := {
		"tile_runtime_update_all": [
			"func _use_tile_data_runtime_update(coords: Vector2i) -> bool:\n\treturn true\n",
			"func _use_tile_data_runtime_update(coords: Vector2i) -> bool: return true # all\n",
		],
		"draw_line_loop": [
			"func _draw():\n\tfor index in points.size() - 1:\n\t\tif index > 0:\n\t\t\tdraw_line(points[index], points[index + 1], Color.WHITE)\n",
			"func _draw():\n\tfor point in points: draw_line(Vector2.ZERO, point, Color.WHITE)\n",
		],
	}
	var script_negatives := [
		"func _use_tile_data_runtime_update(coords: Vector2i) -> bool:\n\treturn coords in changed\n",
		"func _use_tile_data_runtime_update(coords: Vector2i) -> bool:\n\tif coords in changed:\n\t\treturn true\n\treturn false\n",
		"func _draw():\n\tdraw_line(Vector2.ZERO, Vector2.ONE, Color.WHITE)\n\tfor point in points:\n\t\tpass\n\tdraw_line(Vector2.ONE, Vector2.ZERO, Color.WHITE)\n",
		"func _draw():\n\tdraw_multiline(points, Color.WHITE)\n\nfunc helper():\n\tfor point in points:\n\t\tdraw_line(Vector2.ZERO, point, Color.WHITE)\n",
	]
	for key in scripts:
		for source in scripts[key]:
			var state := {"counts": {}, "offenders": {}}
			ProjectScan.frame_calls("extends Node2D\n\n" + source, "res://fixture.gd", state)
			assert(state.counts.keys() == ["check_" + key], "%s: %s\n%s" % [key, state.counts, source])
		covered[key + ":true"] = true
	for source in script_negatives:
		var state := {"counts": {}, "offenders": {}}
		ProjectScan.frame_calls("extends Node2D\n\n" + source, "res://fixture.gd", state)
		assert(state.counts.is_empty(), "Unexpected finding for:\n%s\n%s" % [source, state.offenders])
	for key in scripts:
		covered[key + ":false"] = true


## Scene predicates for configurations that make Godot print a runtime warning (docs/GODOT_RUNTIME_WARNINGS.json).
## run_game waits for the editor to register a uid:// main scene (its first scan may not have yet) instead of playing
## nothing; an unknown UID times out, a registered one and a res:// path pass at once.
func _run_game_waits_for_main_scene_uid() -> void:
	var RunGame = load("res://addons/render_lens/tools/run_game.gd")
	var known := ResourceUID.id_to_text(ResourceLoader.get_resource_uid("res://heavy_scripts.gd"))
	var started := Time.get_ticks_msec()
	assert(not await RunGame.main_scene_known(ResourceUID.id_to_text(ResourceUID.create_id()), 0.5), "unknown main-scene UID passed")
	assert(Time.get_ticks_msec() - started >= 400, "unknown main-scene UID did not wait")
	assert(await RunGame.main_scene_known(known, 0.5), "registered main-scene UID was not found")
	assert(await RunGame.main_scene_known("res://main.tscn", 0.5), "res:// main scene was not accepted")


func _runtime_warning_checks() -> void:
	# Jolt-ignored joint parameters, compared with a default instance of the same joint class.
	for joint in [HingeJoint3D.new(), PinJoint3D.new(), ConeTwistJoint3D.new(), SliderJoint3D.new(), Generic6DOFJoint3D.new()]:
		root.add_child(joint)
		_expect(joint, "jolt_joint_ignored", false)
		if joint is HingeJoint3D:
			joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, 1.0) # Implemented by Jolt.
			_expect(joint, "jolt_joint_ignored", false)
			joint.set_param(HingeJoint3D.PARAM_LIMIT_SOFTNESS, 0.5)
		elif joint is PinJoint3D:
			joint.set_param(PinJoint3D.PARAM_DAMPING, 0.5)
		elif joint is ConeTwistJoint3D:
			joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, 0.5) # Implemented by Jolt.
			_expect(joint, "jolt_joint_ignored", false)
			joint.set_param(ConeTwistJoint3D.PARAM_RELAXATION, 0.5)
		elif joint is SliderJoint3D:
			joint.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, 2.0) # Implemented by Jolt.
			_expect(joint, "jolt_joint_ignored", false)
			joint.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_UPPER, 0.5)
		else:
			joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 1.0) # Implemented by Jolt.
			_expect(joint, "jolt_joint_ignored", false)
			joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_ERP, 0.9)
		_expect(joint, "jolt_joint_ignored", true)
		joint.free()
	var priority := HingeJoint3D.new()
	root.add_child(priority)
	priority.solver_priority = 3
	_expect(priority, "jolt_joint_ignored", true)
	priority.free()
	# Area3D wind and shape solver bias.
	for wind in [["wind_force_magnitude", 2.0], ["wind_attenuation_factor", 0.5], ["wind_source_path", NodePath("..")], ["", null]]:
		var area_root := Node3D.new()
		var area := Area3D.new()
		if wind[0] != "":
			area.set(wind[0], wind[1])
		area_root.add_child(area)
		var area_scan := Scan.scan(area_root, "res://fixture.tscn")
		area_root.free()
		assert((int(area_scan.counts.get("check_jolt_area_wind_ignored", 0)) > 0) == (wind[0] != ""), "jolt_area_wind_ignored: " + str(wind))
		covered["jolt_area_wind_ignored:" + str(wind[0] != "")] = true
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	_expect(shape, "jolt_shape_bias_ignored", false)
	shape.shape.custom_solver_bias = 0.4
	_expect(shape, "jolt_shape_bias_ignored", true)
	shape.free()
	# Real-time sky radiance size and subsurface transmittance, both inspected by the scene scan.
	for sky_case in [[Sky.PROCESS_MODE_REALTIME, Sky.RADIANCE_SIZE_512, true], [Sky.PROCESS_MODE_REALTIME, Sky.RADIANCE_SIZE_256, false], [Sky.PROCESS_MODE_AUTOMATIC, Sky.RADIANCE_SIZE_512, false]]:
		var sky_root := Node3D.new()
		var world := WorldEnvironment.new()
		world.environment = Environment.new()
		world.environment.background_mode = Environment.BG_SKY
		world.environment.sky = Sky.new()
		world.environment.sky.process_mode = sky_case[0]
		world.environment.sky.radiance_size = sky_case[1]
		sky_root.add_child(world)
		var sky_scan := Scan.scan(sky_root, "res://fixture.tscn")
		sky_root.free()
		assert((int(sky_scan.counts.get("check_sky_realtime_radiance", 0)) > 0) == sky_case[2], "sky_realtime_radiance: " + str(sky_case))
		covered["sky_realtime_radiance:" + str(sky_case[2])] = true
	for transmittance in [true, false]:
		var mesh_root := Node3D.new()
		var mesh := MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		var mat := StandardMaterial3D.new()
		mat.subsurf_scatter_transmittance_enabled = transmittance
		mesh.material_override = mat
		mesh_root.add_child(mesh)
		var mesh_scan := Scan.scan(mesh_root, "res://fixture.tscn")
		mesh_root.free()
		assert((int(mesh_scan.counts.get("check_transmittance_material", 0)) > 0) == transmittance, "transmittance_material")
		covered["transmittance_material:" + str(transmittance)] = true
	# Particle nodes that Compatibility skips.
	var sdf := GPUParticlesCollisionSDF3D.new()
	_expect(sdf, "particle_sdf_collider", true)
	sdf.free()
	var vector := GPUParticlesAttractorVectorField3D.new()
	_expect(vector, "particle_vector_attractor", true)
	vector.free()
	var box_collider := GPUParticlesCollisionBox3D.new()
	_expect(box_collider, "particle_sdf_collider", false)
	box_collider.free()
	var box_attractor := GPUParticlesAttractorBox3D.new()
	_expect(box_attractor, "particle_vector_attractor", false)
	box_attractor.free()
	# Lightmap users that no longer resolve (4.5+ warns; 4.4 prints an engine error for the same data).
	if Engine.get_version_info().minor >= 5:
		_lightmap_missing_users()
	_navigation_cells_and_compositor()
	_runtime_warning_checks_two()
	_runtime_warning_checks_three()
	_runtime_warning_checks_four()
	_path_case()


func _lightmap_missing_users() -> void:
	var lightmap_root := Node3D.new()
	var baked := MeshInstance3D.new()
	baked.name = "Baked"
	lightmap_root.add_child(baked)
	var lightmap := LightmapGI.new()
	lightmap_root.add_child(lightmap)
	root.add_child(lightmap_root)
	lightmap.light_data = LightmapGIData.new()
	lightmap.light_data.add_user(NodePath("../Baked"), Rect2(0, 0, 1, 1), 0, -1)
	_expect(lightmap, "lightmap_missing_nodes", false)
	lightmap.light_data.add_user(NodePath("../Gone"), Rect2(0, 0, 1, 1), 0, -1)
	_expect(lightmap, "lightmap_missing_nodes", true)
	lightmap_root.free()


func _runtime_warning_checks_two() -> void:
	# ConvexPolygonShape2D convexity, as ConvexPolygonShape2D::set_points tests it (either winding).
	for convex_case in [[PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(4, 4), Vector2(0, 4)]), false],
			[PackedVector2Array([Vector2(0, 4), Vector2(4, 4), Vector2(4, 0), Vector2(0, 0)]), false],
			[PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(1, 1), Vector2(0, 4)]), true],
			[PackedVector2Array([Vector2(0, 0), Vector2(4, 0), Vector2(0, 4)]), false]]:
		var collision := CollisionShape2D.new()
		collision.shape = ConvexPolygonShape2D.new()
		collision.shape.points = convex_case[0]
		_expect(collision, "convex_polygon_concave", convex_case[1])
		collision.free()
	# Texture classes that decals, projectors and 2D lights cannot sample.
	# In the tree: Godot's own warning formats the node path.
	var decal := Decal.new()
	root.add_child(decal)
	decal.texture_albedo = GradientTexture2D.new()
	_expect(decal, "texture_type_unsampled", false)
	decal.texture_orm = AtlasTexture.new()
	_expect(decal, "texture_type_unsampled", true)
	decal.free()
	var spot := SpotLight3D.new()
	root.add_child(spot)
	spot.light_projector = PlaceholderTexture2D.new()
	_expect(spot, "texture_type_unsampled", false)
	spot.light_projector = ViewportTexture.new()
	_expect(spot, "texture_type_unsampled", true)
	spot.free()
	var light2d := PointLight2D.new()
	root.add_child(light2d)
	light2d.texture = CanvasTexture.new()
	_expect(light2d, "texture_type_unsampled", true)
	light2d.free()
	# Proportional TextureRect directly inside AspectRatioContainer.
	var ratio := AspectRatioContainer.new()
	var rect := TextureRect.new()
	ratio.add_child(rect)
	_expect(rect, "aspect_ratio_texture_rect", false)
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_expect(rect, "aspect_ratio_texture_rect", true)
	ratio.free()
	# Microphone streams and OpenXR layer sort order.
	var mic := AudioStreamPlayer.new()
	mic.stream = AudioStreamMicrophone.new()
	_expect(mic, "microphone_stream", true)
	mic.stream = AudioStreamWAV.new()
	_expect(mic, "microphone_stream", false)
	mic.free()
	if ClassDB.class_exists("OpenXRCompositionLayerQuad"):
		var layer: Node3D = ClassDB.instantiate("OpenXRCompositionLayerQuad")
		_expect(layer, "openxr_layer_sort_zero", false)
		layer.set("sort_order", 0)
		_expect(layer, "openxr_layer_sort_zero", true)
		layer.free()
	# Any real-time sky (roughness-layer rule) is inspected by the scene scan.
	for realtime in [true, false]:
		var sky_root := Node3D.new()
		var world := WorldEnvironment.new()
		world.environment = Environment.new()
		world.environment.sky = Sky.new()
		world.environment.sky.process_mode = Sky.PROCESS_MODE_REALTIME if realtime else Sky.PROCESS_MODE_AUTOMATIC
		sky_root.add_child(world)
		var sky_scan := Scan.scan(sky_root, "res://fixture.tscn")
		sky_root.free()
		assert((int(sky_scan.counts.get("check_sky_realtime", 0)) > 0) == realtime, "sky_realtime")
		covered["sky_realtime:" + str(realtime)] = true
	# A spring-bone collision attached to a bone the skeleton lacks.
	var skeleton := Skeleton3D.new()
	skeleton.add_bone("spine")
	root.add_child(skeleton)
	var simulator := SpringBoneSimulator3D.new()
	skeleton.add_child(simulator)
	var collision3d := SpringBoneCollisionSphere3D.new()
	simulator.add_child(collision3d)
	collision3d.bone_name = "spine"
	_expect(collision3d, "modifier_bone_missing", false)
	collision3d.bone_name = "tail"
	_expect(collision3d, "modifier_bone_missing", true)
	skeleton.free()


func _path_case() -> void:
	var paths := {"res://art": "res://Art", "res://art/hero.png": "res://Art/hero.png", "res://main.tscn": "res://main.tscn"}
	assert(ProjectScan.path_case_mismatches('var t = preload("res://art/hero.png")', paths, false) == ["res://art/hero.png"], "folder case")
	assert(ProjectScan.path_case_mismatches('var t = preload("res://Art/hero.png")\nload("res://main.tscn")', paths, false).is_empty(), "exact case")
	assert(ProjectScan.path_case_mismatches('load("res://missing.png")', paths, false).is_empty(), "missing files are not case problems")
	assert(ProjectScan.path_case_mismatches('[ext_resource type="Texture2D" uid="uid://abc" path="res://art/hero.png" id="1"]', paths, true).is_empty(), "UID references load by UID")
	assert(ProjectScan.path_case_mismatches('[ext_resource type="Texture2D" path="res://ART/hero.png" id="1"]', paths, true) == ["res://ART/hero.png"], "path-only ext_resource")
	assert(ProjectScan.path_case_mismatches('[sub_resource path="res://Art/hero.png::Image_1"]', paths, true).is_empty(), "subresource suffix")
	# A case-sensitive file system (Linux) can hold Foo.txt and foo.txt: the walk keeps both spellings, and only a
	# spelling that no file has is a mismatch.
	var both := {"res://foo.txt": ["res://Foo.txt", "res://foo.txt"]}
	assert(ProjectScan.path_case_mismatches('load("res://Foo.txt")\nload("res://foo.txt")\nload("res://FOO.txt")', both, false) == ["res://FOO.txt"], "case-variant files")
	# A scene or resource too large to read is counted, not skipped silently.
	var big_path := "res://oversize_fixture.tres"
	var big := FileAccess.open(big_path, FileAccess.WRITE)
	var bytes := PackedByteArray()
	bytes.resize(ProjectScan.MAX_SCRIPT_BYTES + 1)
	big.store_buffer(bytes)
	big.close()
	var big_state := {"counts": {}, "offenders": {}}
	ProjectScan._resource_path_case(big_state, [big_path], {})
	DirAccess.remove_absolute(big_path)
	assert(big_state.script_scan.skipped_resources == 1 and big_state.script_scan.resources == 0, "An oversize resource was skipped silently")
	# Commented-out paths are not loaded; a # inside a string is not a comment.
	var commented := '# preload("res://art/hero.png")\nvar t = preload("res://Art/hero.png") # res://art/hero.png\nvar s = "# res://ART/hero.png"'
	assert(ProjectScan.path_case_mismatches(ProjectScan.without_comments(commented, ProjectScan.code_only(commented)), paths, false) == ["res://ART/hero.png"], "comments")
	# Translation remap targets carry a ":<locale>" suffix; the settings scan strips it before comparing.
	var remap_key := "internationalization/locale/translation_remaps"
	var saved_remaps = ProjectSettings.get_setting(remap_key, {})
	ProjectSettings.set_setting(remap_key, {"res://Art/hero.png": PackedStringArray(["res://art/hero_es.png:es"])})
	var setting_paths := {"res://art": "res://Art", "res://art/hero.png": "res://Art/hero.png", "res://art/hero_es.png": "res://Art/hero_es.png"}
	assert(ProjectScan.path_case_mismatches(ProjectScan._setting_paths(), setting_paths, false) == ["res://art/hero_es.png"], "remap target case")
	ProjectSettings.set_setting(remap_key, saved_remaps)
	covered["path_case_mismatch:true"] = true
	covered["path_case_mismatch:false"] = true


func _runtime_warning_checks_four() -> void:
	# Navigation: a mesh-parsing NavigationMesh, and scripts that bake or parse at runtime.
	var region := NavigationRegion3D.new()
	region.navigation_mesh = NavigationMesh.new()
	_expect(region, "navmesh_parses_meshes", true)
	region.navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	_expect(region, "navmesh_parses_meshes", false)
	region.free()
	for bake_case in [["func _ready():\n\t$Region.bake_navigation_mesh()\n", true], ["func _ready():\n\tpass\n", false]]:
		var bake_path := "user://render_lens_bake_fixture.gd"
		var bake_file := FileAccess.open(bake_path, FileAccess.WRITE)
		bake_file.store_string("extends Node\n\n" + bake_case[0])
		bake_file.close()
		var bake_state := {"counts": {}, "offenders": {}}
		ProjectScan._scripts(bake_state, [bake_path])
		DirAccess.remove_absolute(ProjectSettings.globalize_path(bake_path))
		assert(bake_state.counts.has("check_navigation_runtime_bake") == bake_case[1], "navigation_runtime_bake: " + bake_case[0])
		covered["navigation_runtime_bake:" + str(bake_case[1])] = true
	# Spring-bone joint rotation axis parallel to the child bone (rest origin on +Y).
	var skeleton := Skeleton3D.new()
	skeleton.add_bone("root")
	skeleton.add_bone("tip")
	skeleton.set_bone_parent(1, 0)
	skeleton.set_bone_rest(1, Transform3D(Basis(), Vector3(0, 1, 0)))
	root.add_child(skeleton)
	var spring := SpringBoneSimulator3D.new()
	skeleton.add_child(spring)
	spring.setting_count = 1
	spring.set_root_bone_name(0, "root")
	spring.set_end_bone_name(0, "tip")
	spring.set_rotation_axis(0, SpringBoneSimulator3D.ROTATION_AXIS_X)
	_expect(spring, "modifier_axis_colinear", false)
	spring.set_rotation_axis(0, SpringBoneSimulator3D.ROTATION_AXIS_Y)
	_expect(spring, "modifier_axis_colinear", true)
	spring.set_rotation_axis(0, SpringBoneSimulator3D.ROTATION_AXIS_ALL)
	_expect(spring, "modifier_axis_colinear", false)
	skeleton.free()
	# Instance uniforms declared with different types on one instance.
	var tinted := Shader.new()
	tinted.code = "shader_type spatial;\ninstance uniform vec4 tint : source_color;\nvoid fragment() { ALBEDO = tint.rgb; }\n"
	var scalar := Shader.new()
	scalar.code = "shader_type spatial;\n// instance uniform vec4 tint;\ninstance uniform float tint;\nvoid fragment() { ALBEDO = vec3(tint); }\n"
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	mesh.material_override = ShaderMaterial.new()
	mesh.material_override.shader = tinted
	mesh.material_overlay = ShaderMaterial.new()
	mesh.material_overlay.shader = tinted
	_expect(mesh, "instance_uniform_conflict", false)
	mesh.material_overlay.shader = scalar
	_expect(mesh, "instance_uniform_conflict", true)
	mesh.free()
	assert(Checks.instance_uniforms("instance uniform float a;\ninstance uniform vec3 b : instance_index(5);\ninstance uniform int c;") == {"a": ["float", 0], "b": ["vec3", 5], "c": ["int", 1]}, "instance indices")
	# A fit-mode TextureRect in a FlowContainer that wraps to two lines.
	var flow := HFlowContainer.new()
	flow.size = Vector2(100, 400)
	root.add_child(flow)
	var wide := Control.new()
	wide.custom_minimum_size = Vector2(80, 20)
	flow.add_child(wide)
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(80, 20)
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	flow.add_child(rect)
	flow.notification(Container.NOTIFICATION_SORT_CHILDREN)
	_expect(rect, "flow_fit_texture_rect", flow.get_line_count() > 1)
	rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	_expect(rect, "flow_fit_texture_rect", false)
	flow.free()
	# XR picking: a stereo SubViewport that picks, and a pickable body with an input listener.
	var xr_view := SubViewport.new()
	xr_view.use_xr = true
	xr_view.physics_object_picking = true
	_expect(xr_view, "xr_viewport_picking", true)
	xr_view.physics_object_picking = false
	_expect(xr_view, "xr_viewport_picking", false)
	xr_view.free()
	var body := StaticBody3D.new()
	_expect(body, "xr_pickable_listener", false)
	body.input_event.connect(func(_camera, _event, _position, _normal, _shape): pass)
	_expect(body, "xr_pickable_listener", true)
	body.input_ray_pickable = false
	_expect(body, "xr_pickable_listener", false)
	body.free()
	# Canvas backgrounds and screen or depth reads, both inspected by the scene scan.
	for canvas in [true, false]:
		var env_root := Node3D.new()
		var world := WorldEnvironment.new()
		world.environment = Environment.new()
		world.environment.background_mode = Environment.BG_CANVAS if canvas else Environment.BG_COLOR
		env_root.add_child(world)
		var env_scan := Scan.scan(env_root, "res://fixture.tscn")
		env_root.free()
		assert((int(env_scan.counts.get("check_env_bg_canvas", 0)) > 0) == canvas, "env_bg_canvas")
		covered["env_bg_canvas:" + str(canvas)] = true
	for read_case in [["shader", "shader_type spatial;\nuniform sampler2D screen : hint_screen_texture;\nvoid fragment() { ALBEDO = texture(screen, SCREEN_UV).rgb; }\n", true],
			["shader", "shader_type spatial;\nvoid fragment() { ALBEDO = vec3(1.0); }\n", false], ["refraction", "", true], ["proximity", "", true], ["plain", "", false]]:
		var read_root := Node3D.new()
		var read_mesh := MeshInstance3D.new()
		read_mesh.mesh = QuadMesh.new()
		if read_case[0] == "shader":
			read_mesh.material_override = ShaderMaterial.new()
			read_mesh.material_override.shader = Shader.new()
			read_mesh.material_override.shader.code = read_case[1]
		else:
			var standard := StandardMaterial3D.new()
			standard.refraction_enabled = read_case[0] == "refraction"
			standard.proximity_fade_enabled = read_case[0] == "proximity"
			read_mesh.material_override = standard
		read_root.add_child(read_mesh)
		var read_scan := Scan.scan(read_root, "res://fixture.tscn")
		read_root.free()
		assert((int(read_scan.counts.get("check_shader_screen_read", 0)) > 0) == read_case[2], "shader_screen_read: " + read_case[0])
		covered["shader_screen_read:" + str(read_case[2])] = true
		# Only the screen texture (shader hint or refraction) counts for the XR full-screen-effects rule.
		var screen: bool = read_case[2] and (read_case[0] == "refraction" or read_case[1].contains("hint_screen_texture"))
		assert((int(read_scan.counts.get("check_screen_texture", 0)) > 0) == screen, "screen_texture: " + read_case[0])
		covered["screen_texture:" + str(screen)] = true


func _runtime_warning_checks_three() -> void:
	# Subsurface scattering drawn inside a transparent SubViewport.
	var viewport := SubViewport.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	var material := StandardMaterial3D.new()
	mesh.material_override = material
	viewport.add_child(mesh)
	viewport.transparent_bg = true
	_expect(viewport, "viewport_sss_transparent", false)
	material.subsurf_scatter_enabled = true
	_expect(viewport, "viewport_sss_transparent", true)
	viewport.transparent_bg = false
	_expect(viewport, "viewport_sss_transparent", false)
	viewport.free()
	# Zero-scale physics transforms (Jolt treats the basis as identity).
	var body := StaticBody3D.new()
	root.add_child(body)
	_expect(body, "jolt_singular_basis", false)
	body.scale = Vector3(0.01, 0.01, 0.01)
	_expect(body, "jolt_singular_basis", false)
	body.scale = Vector3(1, 0, 1)
	_expect(body, "jolt_singular_basis", true)
	body.free()
	# Center and reference node paths that do not resolve (Godot warns from 4.7; earlier versions lack the reference-node setting).
	if ClassDB.class_exists("CopyTransformModifier3D"):
		var skeleton := Skeleton3D.new()
		skeleton.add_bone("root")
		root.add_child(skeleton)
		var copy: Node = ClassDB.instantiate("CopyTransformModifier3D")
		skeleton.add_child(copy)
		copy.set("setting_count", 1)
		_expect(copy, "modifier_node_missing", false)
		copy.set("settings/0/reference_node", NodePath("../Missing"))
		_expect(copy, "modifier_node_missing", copy.get("settings/0/reference_node") == NodePath("../Missing"))
		copy.set("settings/0/reference_node", NodePath(".."))
		_expect(copy, "modifier_node_missing", false)
		skeleton.free()


func _navigation_cells_and_compositor() -> void:
	# Navigation mesh cells smaller than the default map's, and static obstacle vertex heights.
	var region := NavigationRegion3D.new()
	region.navigation_mesh = NavigationMesh.new()
	_expect(region, "navmesh_cell_size_mismatch", false)
	region.navigation_mesh.cell_size = 0.1
	_expect(region, "navmesh_cell_size_mismatch", true)
	region.navigation_mesh.cell_size = 0.25
	region.navigation_mesh.cell_height = 0.1
	_expect(region, "navmesh_cell_size_mismatch", true)
	region.enabled = false
	_expect(region, "navmesh_cell_size_mismatch", false)
	region.free()
	var region2d := NavigationRegion2D.new()
	region2d.navigation_polygon = NavigationPolygon.new()
	_expect(region2d, "navmesh_cell_size_mismatch", false)
	region2d.navigation_polygon.cell_size = 0.5
	_expect(region2d, "navmesh_cell_size_mismatch", true)
	region2d.free()
	var obstacle := NavigationObstacle3D.new()
	root.add_child(obstacle)
	obstacle.vertices = PackedVector3Array([Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)])
	_expect(obstacle, "obstacle_vertex_height", false)
	obstacle.vertices = PackedVector3Array([Vector3(0, 0, 0), Vector3(1, 0.5, 0), Vector3(0, 0, 1)])
	_expect(obstacle, "obstacle_vertex_height", true)
	obstacle.free()
	# Compositor callbacks the renderer cannot serve.
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	root.add_child(viewport)
	var compositor_world := WorldEnvironment.new()
	var effect := PerformanceEffect.new()
	effect.enabled = true
	effect.effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_PRE_OPAQUE
	effect.access_resolved_color = true
	compositor_world.compositor = Compositor.new()
	compositor_world.compositor.compositor_effects = [effect]
	viewport.add_child(compositor_world)
	_expect(compositor_world, "compositor_pre_opaque_resolved", false) # No MSAA, nothing to resolve.
	_expect(compositor_world, "compositor_mobile_unsupported", false)
	viewport.msaa_3d = Viewport.MSAA_2X
	_expect(compositor_world, "compositor_pre_opaque_resolved", true)
	effect.effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_PRE_TRANSPARENT
	_expect(compositor_world, "compositor_pre_opaque_resolved", false)
	effect.access_resolved_color = false
	effect.access_resolved_depth = true
	_expect(compositor_world, "compositor_mobile_unsupported", true)
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	_expect(compositor_world, "compositor_mobile_unsupported", false)
	effect.effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_OPAQUE
	_expect(compositor_world, "compositor_mobile_unsupported", true)
	_expect(compositor_world, "compositor_transparent_callback", false)
	effect.effect_callback_type = CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	_expect(compositor_world, "compositor_transparent_callback", true)
	viewport.free()
	# Skeleton modifier bones that the skeleton does not have.
	var skeleton := Skeleton3D.new()
	skeleton.add_bone("hip")
	skeleton.add_bone("knee")
	skeleton.set_bone_parent(1, 0)
	root.add_child(skeleton)
	var spring := SpringBoneSimulator3D.new()
	skeleton.add_child(spring)
	spring.setting_count = 1
	_expect(spring, "modifier_bone_missing", false)
	spring.set_root_bone_name(0, "hip")
	spring.set_end_bone_name(0, "knee")
	_expect(spring, "modifier_bone_missing", false)
	spring.set_end_bone_name(0, "ankle")
	_expect(spring, "modifier_bone_missing", true)
	skeleton.free()
	# Animation tracks whose node path does not resolve from root_node.
	var anim_root := Node3D.new()
	var target := Node3D.new()
	target.name = "Target"
	anim_root.add_child(target)
	var player := AnimationPlayer.new()
	anim_root.add_child(player)
	root.add_child(anim_root)
	var animation := Animation.new()
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath("Target:visible"))
	var library := AnimationLibrary.new()
	library.add_animation("blink", animation)
	player.add_animation_library("", library)
	_expect(player, "animation_track_unresolved", false)
	animation.track_set_path(track, NodePath("Renamed:visible"))
	_expect(player, "animation_track_unresolved", true)
	animation.track_set_enabled(track, false)
	_expect(player, "animation_track_unresolved", false)
	animation.track_set_enabled(track, true)
	# Godot resolves the last subname as a property (or a bone/blend shape name), and earlier ones as resources.
	var rig := Skeleton3D.new()
	rig.name = "Rig"
	rig.add_bone("Hips")
	anim_root.add_child(rig)
	var tinted := MeshInstance3D.new()
	tinted.name = "Tinted"
	tinted.material_override = StandardMaterial3D.new()
	anim_root.add_child(tinted)
	for resolved in ["Rig:Hips", "Tinted:material_override:albedo_color", "Target:position:x"]:
		animation.track_set_path(track, NodePath(resolved))
		_expect(player, "animation_track_unresolved", false)
	animation.track_set_path(track, NodePath("Tinted:missing_resource:albedo_color"))
	_expect(player, "animation_track_unresolved", true)
	anim_root.free()


func _shader_material_copies() -> void:
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nuniform vec4 tint : source_color;\nuniform sampler2D albedo;\nvoid fragment() { ALBEDO = tint.rgb * texture(albedo, UV).rgb; }\n"
	var canvas_shader := Shader.new()
	canvas_shader.code = "shader_type canvas_item;\nuniform vec4 tint : source_color;\nvoid fragment() { COLOR *= tint; }\n"
	var texture := GradientTexture2D.new()
	var cases := [
		[true, [[shader, texture, Color.RED], [shader, texture, Color.BLUE]]],
		[true, [[canvas_shader, null, Color.RED], [canvas_shader, null, Color.BLUE]]],
		[false, [[shader, texture, Color.RED], [shader, GradientTexture2D.new(), Color.BLUE]]],
		[false, [[shader, texture, Color.RED], [shader.duplicate(), texture, Color.BLUE]]],
		[false, [[shader, texture, Color.RED], "shared"]],
	]
	for case in cases:
		var root := Node.new()
		var first: ShaderMaterial = null
		for entry in case[1]:
			var mat: ShaderMaterial = first
			if entry is Array:
				mat = ShaderMaterial.new()
				mat.shader = entry[0]
				mat.set_shader_parameter("tint", entry[2])
				if entry[1] != null:
					mat.set_shader_parameter("albedo", entry[1])
				first = mat if first == null else first
			var node: Node
			if mat.shader.get_mode() == Shader.MODE_CANVAS_ITEM:
				node = Sprite2D.new()
				node.texture = texture
				node.material = mat
			else:
				node = MeshInstance3D.new()
				node.mesh = QuadMesh.new()
				node.material_override = mat
			root.add_child(node)
		var scan := Scan.scan(root, "res://fixture.tscn")
		root.free()
		assert((int(scan.counts.get("check_shader_material_copies", 0)) == 1) == case[0], "shader_material_copies %s: %s" % [case, scan.offenders.get("check_shader_material_copies")])
		covered["shader_material_copies:" + str(case[0])] = true
	# Matrices and uniform arrays cannot be instance uniforms either (shader_language.cpp), so differing there is no copy.
	var matrix_shader := Shader.new()
	matrix_shader.code = "shader_type spatial;\nuniform vec4 tint : source_color;\nuniform mat4 warp;\nuniform float weights[2];\nvoid fragment() { ALBEDO = (warp * tint).rgb * weights[0]; }\n"
	for matrix_case in [[Projection.IDENTITY, PackedFloat32Array([1, 2]), true], [Projection.ZERO, PackedFloat32Array([1, 2]), false], [Projection.IDENTITY, PackedFloat32Array([3, 4]), false]]:
		var holder := Node.new()
		for variant in [[Projection.IDENTITY, PackedFloat32Array([1, 2]), Color.RED], [matrix_case[0], matrix_case[1], Color.BLUE]]:
			var matrix_mat := ShaderMaterial.new()
			matrix_mat.shader = matrix_shader
			matrix_mat.set_shader_parameter("warp", variant[0])
			matrix_mat.set_shader_parameter("weights", variant[1])
			matrix_mat.set_shader_parameter("tint", variant[2])
			var quad := MeshInstance3D.new()
			quad.mesh = QuadMesh.new()
			quad.material_override = matrix_mat
			holder.add_child(quad)
		var matrix_scan := Scan.scan(holder, "res://fixture.tscn", false)
		holder.free()
		assert((int(matrix_scan.counts.get("check_shader_material_copies", 0)) == 1) == matrix_case[2], "shader_material_copies matrix/array %s" % [matrix_case])
	# Render priority and the next pass belong to the material, so one shared material cannot keep them apart.
	for priority_case in [[0, null, true], [1, null, false], [0, StandardMaterial3D.new(), false]]:
		var sorted_holder := Node.new()
		for index in 2:
			var sorted_mat := ShaderMaterial.new()
			sorted_mat.shader = shader
			sorted_mat.set_shader_parameter("albedo", texture)
			if index == 1:
				sorted_mat.render_priority = priority_case[0]
				sorted_mat.next_pass = priority_case[1]
			var sorted_quad := MeshInstance3D.new()
			sorted_quad.mesh = QuadMesh.new()
			sorted_quad.material_override = sorted_mat
			sorted_holder.add_child(sorted_quad)
		var sorted_scan := Scan.scan(sorted_holder, "res://fixture.tscn", false)
		sorted_holder.free()
		assert((int(sorted_scan.counts.get("check_shader_material_copies", 0)) == 1) == priority_case[2], "shader_material_copies priority/next_pass %s" % [priority_case])
	for normal_case in [["shader_type spatial;\nuniform sampler2D nr : hint_normal_roughness_texture;\nvoid fragment() { ALBEDO = texture(nr, SCREEN_UV).rgb; }\n", true], ["shader_type spatial;\n// hint_normal_roughness_texture\nvoid fragment() { ALBEDO = vec3(1.0); }\n", false]]:
		var normal_shader := Shader.new()
		normal_shader.code = normal_case[0]
		var normal_material := ShaderMaterial.new()
		normal_material.shader = normal_shader
		var normal_root := Node3D.new()
		var normal_mesh := MeshInstance3D.new()
		normal_mesh.mesh = QuadMesh.new()
		normal_mesh.material_override = normal_material
		normal_root.add_child(normal_mesh)
		var normal_scan := Scan.scan(normal_root, "res://fixture.tscn")
		normal_root.free()
		assert((int(normal_scan.counts.get("check_shader_normal_roughness", 0)) > 0) == normal_case[1], "shader_normal_roughness: " + normal_case[0])
		covered["shader_normal_roughness:" + str(normal_case[1])] = true
	for discard_case in [["shader_type spatial;\nvoid fragment() { if (UV.x > 0.5) { discard; } }\n", true], ["shader_type spatial;\n// discard\n/* discard; */\nvoid fragment() { ALBEDO = vec3(1.0); }\n", false], ["shader_type canvas_item;\nvoid fragment() { discard; }\n", false]]:
		var discard_shader := Shader.new()
		discard_shader.code = discard_case[0]
		var discard_material := ShaderMaterial.new()
		discard_material.shader = discard_shader
		var holder := MeshInstance3D.new()
		holder.mesh = QuadMesh.new()
		holder.material_override = discard_material
		var discard_scan := Scan.scan(holder, "res://fixture.tscn")
		holder.free()
		assert((int(discard_scan.counts.get("check_shader_discard", 0)) > 0) == discard_case[1], "shader_discard: " + discard_case[0])
		covered["shader_discard:" + str(discard_case[1])] = true
	var text := Shader.new()
	text.code = "shader_type spatial;\nuniform sampler2D albedo : filter_linear_mipmap_anisotropic;\nvoid fragment() { ALBEDO = texture(albedo, UV).rgb; }\n"
	for filter in [VisualShaderNodeTextureParameter.FILTER_LINEAR_MIPMAP_ANISOTROPIC, VisualShaderNodeTextureParameter.FILTER_DEFAULT]:
		var graph := VisualShader.new()
		var parameter := VisualShaderNodeTexture2DParameter.new()
		parameter.parameter_name = "albedo_map"
		parameter.texture_filter = filter
		var sample := VisualShaderNodeTexture.new()
		sample.source = VisualShaderNodeTexture.SOURCE_PORT
		graph.add_node(VisualShader.TYPE_FRAGMENT, parameter, Vector2.ZERO, 2)
		graph.add_node(VisualShader.TYPE_FRAGMENT, sample, Vector2.ZERO, 3)
		graph.connect_nodes(VisualShader.TYPE_FRAGMENT, 2, 0, 3, 2)
		graph.connect_nodes(VisualShader.TYPE_FRAGMENT, 3, 0, 0, 0)
		for shader_case in [graph, text] if filter != VisualShaderNodeTextureParameter.FILTER_DEFAULT else [graph]:
			var node := MeshInstance3D.new()
			node.mesh = QuadMesh.new()
			node.material_override = ShaderMaterial.new()
			node.material_override.shader = shader_case
			var scan := Scan.scan(node, "res://fixture.tscn")
			node.free()
			var anisotropic: bool = filter != VisualShaderNodeTextureParameter.FILTER_DEFAULT
			assert(scan.counts.anisotropic_material_count == (1 if anisotropic else 0), "Shader anisotropic filter hint (%s)" % shader_case)


func _setting(path: String, value: Variant) -> Variant:
	var previous: Variant = ProjectSettings.get_setting(path)
	ProjectSettings.set_setting(path, value)
	return previous


func _engine_warnings() -> void:
	var minor: int = Engine.get_version_info().minor
	var missing: Node = ClassDB.instantiate("MissingNode")
	missing.set("original_class", "RemovedPluginNode")
	_expect(missing, "missing_node", true)
	missing.free()
	var plain := Node.new()
	_expect(plain, "missing_node", false)
	plain.free()

	var tint_a := CanvasModulate.new()
	var tint_b := CanvasModulate.new()
	root.add_child(tint_a)
	_expect(tint_a, "canvas_modulate_multiple", false)
	root.add_child(tint_b)
	_expect(tint_a, "canvas_modulate_multiple", true)
	tint_b.visible = false
	_expect(tint_a, "canvas_modulate_multiple", false)
	tint_a.free()
	tint_b.free()

	var timer := Timer.new()
	_expect(timer, "timer_short_wait", false)
	timer.wait_time = 0.04
	_expect(timer, "timer_short_wait", true)
	timer.wait_time = 0.05
	_expect(timer, "timer_short_wait", false)
	timer.free()

	var globals_a := ShaderGlobalsOverride.new()
	var globals_b := ShaderGlobalsOverride.new()
	root.add_child(globals_a)
	root.add_child(globals_b)
	_expect(globals_a, "shader_globals_inactive", false)
	_expect(globals_b, "shader_globals_inactive", true)
	globals_a.free()
	globals_b.free()

	var container := Container.new()
	_expect(container, "container_plain", true)
	container.free()
	var box := VBoxContainer.new()
	_expect(box, "container_plain", false)

	var button := Button.new()
	button.button_group = ButtonGroup.new()
	_expect(button, "button_group_toggle", true)
	button.toggle_mode = true
	_expect(button, "button_group_toggle", false)
	button.free()

	var label := Label.new()
	label.text = "Wrapped words"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(label)
	root.add_child(box)
	_expect(label, "label_autowrap_width", true)
	label.custom_minimum_size = Vector2(120, 0)
	_expect(label, "label_autowrap_width", false)
	var font := (ThemeDB.fallback_font as FontFile).duplicate() as FontFile
	font.allow_system_fallback = false
	font.fallbacks = []
	label.label_settings = LabelSettings.new()
	label.label_settings.font = font
	_expect(label, "label_missing_glyphs", false)
	label.text = "Private glyph "
	_expect(label, "label_missing_glyphs", true)
	label.text = "Plain text"
	if minor >= 6:
		font.multichannel_signed_distance_field = true
		font.msdf_size = 48
		font.msdf_pixel_range = 8
		label.label_settings.font_size = 16
		_expect(label, "label_msdf_pixel_range", false)
		label.label_settings.outline_size = 40
		_expect(label, "label_msdf_pixel_range", true)
	box.free()

	var rounded := StyleBoxFlat.new()
	rounded.set_corner_radius_all(6)
	var popup := PopupPanel.new()
	popup.add_theme_stylebox_override("panel", rounded)
	var menu := MenuButton.new()
	menu.get_popup().add_theme_stylebox_override("panel", rounded)
	var embed: Variant = _setting("display/window/subwindows/embed_subwindows", true)
	_expect(popup, "popup_transparency", false)
	ProjectSettings.set_setting("display/window/subwindows/embed_subwindows", false)
	_expect(popup, "popup_transparency", not DisplayServer.is_window_transparency_available())
	_expect(menu, "popup_transparency", not DisplayServer.is_window_transparency_available())
	popup.remove_theme_stylebox_override("panel")
	popup.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	_expect(popup, "popup_transparency", false)
	ProjectSettings.set_setting("display/window/subwindows/embed_subwindows", embed)
	popup.free()
	menu.free()

	var frame := SubViewportContainer.new()
	_expect(frame, "subviewport_cursor", false)
	frame.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_expect(frame, "subviewport_cursor", true)
	frame.free()

	var layer := ParallaxLayer.new()
	_expect(layer, "parallax_layer_parent", true)
	var background := ParallaxBackground.new()
	background.add_child(layer)
	_expect(layer, "parallax_layer_parent", false)
	background.free()

	var voxel := VoxelGI.new()
	_expect(voxel, "voxel_gi_data", true)
	voxel.data = VoxelGIData.new()
	_expect(voxel, "voxel_gi_data", false)
	voxel.free()

	var occluder := OccluderInstance3D.new()
	var culling: Variant = _setting("rendering/occlusion_culling/use_occlusion_culling", false)
	_expect(occluder, "occluder_culling_disabled", true)
	ProjectSettings.set_setting("rendering/occlusion_culling/use_occlusion_culling", true)
	_expect(occluder, "occluder_culling_disabled", false)
	ProjectSettings.set_setting("rendering/occlusion_culling/use_occlusion_culling", culling)
	occluder.free()

	var tile_map := TileMap.new()
	_expect(tile_map, "tilemap_deprecated", true)
	_expect(tile_map, "tilemap_layer_ysort", false)
	_expect(tile_map, "tilemap_node_ysort", false)
	_expect(tile_map, "tilemap_isometric_ysort", false)
	tile_map.add_layer(-1)
	tile_map.set_layer_y_sort_enabled(0, true)
	_expect(tile_map, "tilemap_ysort_z", true)
	_expect(tile_map, "tilemap_layer_ysort", true)
	tile_map.set_layer_z_index(1, 1)
	_expect(tile_map, "tilemap_ysort_z", false)
	tile_map.y_sort_enabled = true
	_expect(tile_map, "tilemap_layer_ysort", false)
	tile_map.tile_set = TileSet.new()
	tile_map.tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	_expect(tile_map, "tilemap_isometric_ysort", true)
	tile_map.set_layer_y_sort_enabled(1, true)
	_expect(tile_map, "tilemap_isometric_ysort", false)
	tile_map.set_layer_y_sort_enabled(0, false)
	tile_map.set_layer_y_sort_enabled(1, false)
	_expect(tile_map, "tilemap_node_ysort", true)
	tile_map.free()
	var tile_layer := TileMapLayer.new()
	_expect(tile_layer, "tilemap_deprecated", false)
	tile_layer.free()

	var bone_body := PhysicalBone2D.new()
	_expect(bone_body, "physical_bone2d_parent", true)
	_expect(bone_body, "physical_bone2d_bone", false)
	var skeleton_2d := Skeleton2D.new()
	skeleton_2d.add_child(bone_body)
	_expect(bone_body, "physical_bone2d_parent", false)
	_expect(bone_body, "physical_bone2d_bone", true)
	bone_body.bone2d_index = 0
	_expect(bone_body, "physical_bone2d_bone", false)
	var child_bone := PhysicalBone2D.new()
	bone_body.add_child(child_bone)
	_expect(child_bone, "physical_bone2d_parent", false)
	_expect(child_bone, "physical_bone2d_joint", true)
	_expect(bone_body, "physical_bone2d_joint", false)
	child_bone.add_child(PinJoint2D.new())
	_expect(child_bone, "physical_bone2d_joint", false)
	skeleton_2d.free()

	var interpolation: Variant = _setting("physics/common/physics_interpolation", true)
	var body := StaticBody3D.new()
	_expect(body, "physics_body_interpolation", false)
	body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_expect(body, "physics_body_interpolation", minor >= 5)
	var holder := Node3D.new()
	holder.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var inherited := CharacterBody2D.new()
	holder.add_child(inherited)
	_expect(inherited, "physics_body_interpolation", minor >= 5)
	holder.free()
	body.free()

	var group := CanvasGroup.new()
	root.add_child(group)
	_expect(group, "canvas_group_ancestor", false)
	var nested := CanvasGroup.new()
	group.add_child(nested)
	_expect(nested, "canvas_group_ancestor", minor >= 5)
	var clipper := Node2D.new()
	clipper.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	root.add_child(clipper)
	var clipped_group := CanvasGroup.new()
	clipper.add_child(clipped_group)
	_expect(clipped_group, "canvas_group_ancestor", minor >= 5)
	group.free()
	clipper.free()

	var xr_shaders: Variant = _setting("xr/shaders/enabled", false)
	var stage := Node3D.new()
	root.add_child(stage)
	var origin := XROrigin3D.new()
	stage.add_child(origin)
	_expect(origin, "xr_origin_camera", true)
	_expect(origin, "xr_shaders_disabled", true)
	var camera := XRCamera3D.new()
	origin.add_child(camera)
	_expect(origin, "xr_origin_camera", false)
	_expect(camera, "xr_camera_parent", false)
	# Godot 4.7 XR nodes default to OFF; the warning targets nodes switched back on.
	_expect(camera, "xr_interpolation", false)
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	_expect(camera, "xr_interpolation", minor >= 5)
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_expect(camera, "xr_interpolation", false)
	origin.scale = Vector3(2, 2, 2)
	_expect(origin, "xr_origin_scale", minor >= 6)
	origin.scale = Vector3.ONE
	_expect(origin, "xr_origin_scale", false)
	ProjectSettings.set_setting("xr/shaders/enabled", true)
	_expect(origin, "xr_shaders_disabled", false)
	ProjectSettings.set_setting("xr/shaders/enabled", xr_shaders)
	var loose_camera := XRCamera3D.new()
	stage.add_child(loose_camera)
	_expect(loose_camera, "xr_camera_parent", true)
	var controller := XRController3D.new()
	stage.add_child(controller)
	controller.tracker = &"left_hand"
	_expect(controller, "xr_node_parent", true)
	_expect(controller, "xr_node_tracker", false)
	_expect(controller, "xr_node_pose", false)
	controller.tracker = &""
	controller.pose = &""
	_expect(controller, "xr_node_tracker", true)
	_expect(controller, "xr_node_pose", true)
	controller.reparent(origin)
	_expect(controller, "xr_node_parent", false)
	var hand := XRHandModifier3D.new()
	var openxr: Variant = _setting("xr/openxr/enabled", false)
	var hand_tracking: Variant = _setting("xr/openxr/extensions/hand_tracking", false)
	_expect(hand, "xr_hand_tracking", false)
	ProjectSettings.set_setting("xr/openxr/enabled", true)
	_expect(hand, "xr_hand_tracking", true)
	ProjectSettings.set_setting("xr/openxr/extensions/hand_tracking", true)
	_expect(hand, "xr_hand_tracking", false)
	ProjectSettings.set_setting("xr/openxr/enabled", openxr)
	ProjectSettings.set_setting("xr/openxr/extensions/hand_tracking", hand_tracking)
	hand.free()

	if ClassDB.can_instantiate("OpenXRCompositionLayerQuad"):
		var quad: Node3D = ClassDB.instantiate("OpenXRCompositionLayerQuad")
		_expect(quad, "openxr_layer_transform", false)
		_expect(quad, "openxr_layer_hole_punch", false)
		quad.scale = Vector3(2, 2, 2)
		_expect(quad, "openxr_layer_transform", true)
		quad.set("enable_hole_punch", true)
		quad.set("sort_order", 1)
		_expect(quad, "openxr_layer_hole_punch", true)
		quad.set("sort_order", -1)
		_expect(quad, "openxr_layer_hole_punch", false)
		stage.add_child(quad)
		_expect(quad, "openxr_layer_parent", minor <= 6)
		quad.reparent(origin)
		_expect(quad, "openxr_layer_parent", false)
	if ClassDB.can_instantiate("OpenXRVisibilityMask"):
		var mask: Node3D = ClassDB.instantiate("OpenXRVisibilityMask")
		stage.add_child(mask)
		_expect(mask, "openxr_visibility_mask_parent", true)
		mask.reparent(camera)
		_expect(mask, "openxr_visibility_mask_parent", false)
	if minor >= 5:
		var render_model_extension: Variant = _setting("xr/openxr/extensions/render_model", false)
		# Render models process OpenXR state every frame, so these fixtures stay outside the tree.
		var offline := Node3D.new()
		var offline_origin := XROrigin3D.new()
		offline.add_child(offline_origin)
		var manager: Node3D = ClassDB.instantiate("OpenXRRenderModelManager")
		offline.add_child(manager)
		_expect(manager, "openxr_render_model_parent", true)
		_expect(manager, "openxr_render_model_extension", true)
		_expect(manager, "openxr_render_model_pose", false)
		manager.set("make_local_to_pose", "aim")
		_expect(manager, "openxr_render_model_pose", true)
		manager.set("make_local_to_pose", "")
		offline.remove_child(manager)
		offline_origin.add_child(manager)
		_expect(manager, "openxr_render_model_parent", false)
		var model: Node3D = ClassDB.instantiate("OpenXRRenderModel")
		offline.add_child(model)
		_expect(model, "openxr_render_model_parent", true)
		offline.remove_child(model)
		manager.add_child(model)
		_expect(model, "openxr_render_model_parent", false)
		ProjectSettings.set_setting("xr/openxr/extensions/render_model", true)
		_expect(model, "openxr_render_model_extension", false)
		ProjectSettings.set_setting("xr/openxr/extensions/render_model", render_model_extension)
		offline.free()
	stage.free()
	ProjectSettings.set_setting("physics/common/physics_interpolation", interpolation)

	var spawner: Node = ClassDB.instantiate("MultiplayerSpawner")
	_expect(spawner, "multiplayer_spawner_path", true)
	spawner.set("spawn_path", NodePath("."))
	_expect(spawner, "multiplayer_spawner_path", false)
	spawner.free()
	var synchronizer: Node = ClassDB.instantiate("MultiplayerSynchronizer")
	_expect(synchronizer, "multiplayer_synchronizer_root", true)
	var replicated := Node.new()
	replicated.add_child(synchronizer)
	_expect(synchronizer, "multiplayer_synchronizer_root", false)
	replicated.free()

	var soft := SoftBody3D.new()
	_expect(soft, "mesh_missing", true)
	soft.mesh = BoxMesh.new()
	_expect(soft, "mesh_missing", false)
	soft.free()

	var collider := SpringBoneCollisionSphere3D.new()
	_expect(collider, "spring_bone_collision_parent", true)
	var simulator := SpringBoneSimulator3D.new()
	simulator.add_child(collider)
	_expect(collider, "spring_bone_collision_parent", false)
	simulator.free()

	if minor >= 5:
		# Godot 4.5.2 already warns (aim_modifier_3d.cpp); the axes need no tree, so a scene scanned by path is checked.
		var detached_aim: Node = ClassDB.instantiate("AimModifier3D")
		detached_aim.set("setting_count", 1)
		detached_aim.call("set_use_euler", 0, true)
		detached_aim.call("set_forward_axis", 0, 0) # BONE_AXIS_PLUS_X
		detached_aim.call("set_primary_rotation_axis", 0, Vector3.AXIS_X)
		_expect(detached_aim, "aim_modifier_axes", true)
		detached_aim.call("set_primary_rotation_axis", 0, Vector3.AXIS_Y)
		_expect(detached_aim, "aim_modifier_axes", false)
		detached_aim.free()
	if minor >= 6:
		var skeleton := Skeleton3D.new()
		skeleton.add_bone("root")
		root.add_child(skeleton)
		var target := Node3D.new()
		skeleton.add_child(target)
		var fabrik: Node = ClassDB.instantiate("FABRIK3D")
		skeleton.add_child(fabrik)
		fabrik.set("setting_count", 1)
		_expect(fabrik, "iterate_ik_target", true)
		fabrik.call("set_target_node", 0, fabrik.get_path_to(target))
		_expect(fabrik, "iterate_ik_target", false)
		var spline: Node = ClassDB.instantiate("SplineIK3D")
		skeleton.add_child(spline)
		spline.set("setting_count", 1)
		_expect(spline, "spline_ik_path", true)
		var path_3d := Path3D.new()
		path_3d.curve = Curve3D.new()
		skeleton.add_child(path_3d)
		spline.call("set_path_3d", 0, spline.get_path_to(path_3d))
		_expect(spline, "spline_ik_path", true)
		path_3d.curve.add_point(Vector3.ZERO)
		_expect(spline, "spline_ik_path", false)
		var two_bone: Node = ClassDB.instantiate("TwoBoneIK3D")
		skeleton.add_child(two_bone)
		two_bone.set("setting_count", 1)
		two_bone.call("set_target_node", 0, two_bone.get_path_to(target))
		_expect(two_bone, "two_bone_ik_targets", true)
		two_bone.call("set_pole_node", 0, two_bone.get_path_to(target))
		_expect(two_bone, "two_bone_ik_targets", false)
		skeleton.free()


func _advise_order() -> void:
	var findings: Array = []
	for index in 8:
		findings.append({"id": "config_%d" % index, "kind": "correctness", "severity": "low"})
	findings.append({"id": "visual", "kind": "quality_up", "severity": "low"})
	findings.append({"id": "uncosted", "kind": "performance", "severity": "high", "measured_share": 0.0})
	findings.append({"id": "tiny", "kind": "performance", "severity": "high", "measured_share": 0.4})
	findings.append({"id": "costed", "kind": "performance", "severity": "low", "measured_share": 42.0})
	findings.append({"id": "monitor", "kind": "performance", "severity": "medium", "measured_share": 0.0, "measured_evidence": {"metrics": {"TIME_FPS": 20.0}, "pass": null}})
	# One order whatever the budget. Measured runs: performance (measured costs, measured observations without a share,
	# then costs under 1% of the frame), visual, missing parts, then To check for candidates nothing measured.
	for frame in [{"budget_ms": 16.67, "median_ms": 40.0}, {"budget_ms": 16.67, "median_ms": 8.0}]:
		var pack: Dictionary = Rules.package(findings.duplicate(true), frame, 10, "measured")
		var order: Array = pack.top.map(func(row): return row.id)
		assert(order.slice(0, 4) == ["costed", "monitor", "tiny", "visual"] and order.slice(4, 12).all(func(id): return str(id).begins_with("config_")) and order.slice(12) == ["uncosted"], "Advice order changed with the frame budget %s: %s" % [frame, order])
		assert(pack.area_counts == {"performance": 3, "visual": 1, "missing": 8, "to_check": 1, "info": 0}, "Area counts: %s" % pack.area_counts)
		var tiny: Dictionary = pack.top[2]
		assert(tiny.severity == "low" and tiny.optional and tiny.area == "performance", "A 0.4%% pass kept its catalog severity: %s" % tiny)
	# A static audit measures nothing, so its candidates stay in performance, by severity.
	var static_pack: Dictionary = Rules.package(findings.duplicate(true), {}, 10, "static")
	var static_order: Array = static_pack.top.map(func(row): return row.id)
	assert(static_order.slice(0, 5) == ["costed", "uncosted", "monitor", "tiny", "visual"] and static_pack.area_counts.to_check == 0, "Static order: %s" % [static_order])
	# A long performance list must not hide the other areas.
	var one_each: Array = Rules.package(findings.duplicate(true), {"budget_ms": 16.67, "median_ms": 8.0}, 1, "measured").top.map(func(row): return row.area)
	assert(one_each == ["performance", "visual", "missing", "to_check"], "top=1 must list one finding from each area: %s" % [one_each])
	var missing: Array = Rules.package(findings.duplicate(true), {}, 10, "static", "missing").top
	assert(missing.size() == 8 and missing.all(func(row): return row.area == "missing"), "focus=missing returned other areas")
	# To check is collapsed to a preview unless asked for.
	var candidates: Array = []
	for index in 6:
		candidates.append({"id": "candidate_%d" % index, "kind": "performance", "severity": "medium", "measured_share": 0.0})
	var budget := {"budget_ms": 16.67, "median_ms": 8.0}
	assert(Rules.package(candidates.duplicate(true), budget, 10, "measured").top.size() == Rules.TO_CHECK_PREVIEW, "To check was not collapsed")
	assert(Rules.package(candidates.duplicate(true), budget, 10, "measured", "to_check").top.size() == 6, "focus=to_check must list every candidate up to top")
	# One entry per measured pass: two rules on one combined pass must not both claim its cost.
	var shared := [
		{"id": "spot", "kind": "performance", "severity": "medium", "measured_share": 42.0, "measured_evidence": {"pass": {"name": "Render GI + Render Directional/SpotLight Shadows (Parallel)"}}},
		{"id": "sun", "kind": "performance", "severity": "high", "measured_share": 42.0, "measured_evidence": {"pass": {"name": "Render GI + Render Directional/SpotLight Shadows (Parallel)"}}},
		{"id": "omni", "kind": "performance", "severity": "medium", "measured_share": 24.0, "measured_evidence": {"pass": {"name": "Render OmniLight Shadows"}}},
	]
	# A tolerance compare plus an id tie-break was not transitive (a < b, b < c, c < a).
	var close := [
		{"id": "a", "kind": "performance", "severity": "medium", "measured_share": 10.0},
		{"id": "b", "kind": "performance", "severity": "medium", "measured_share": 10.0008},
		{"id": "c", "kind": "performance", "severity": "medium", "measured_share": 10.0016},
	]
	for order in [[0, 1, 2], [2, 1, 0], [1, 2, 0]]:
		var ranked: Array = Rules.package(order.map(func(index): return close[index].duplicate()), budget, 10, "measured").performance_findings.map(func(row): return row.id)
		assert(ranked == ["c", "b", "a"], "Near-equal shares sorted inconsistently: %s" % [ranked])
	var grouped: Dictionary = Rules.package(shared, budget, 10, "measured")
	assert(grouped.performance_findings.map(func(row): return row.id) == ["sun", "omni"] and grouped.performance_findings[0].same_pass.map(func(row): return row.id) == ["spot"], "Findings on one pass were not grouped under the most severe: %s" % [grouped.performance_findings.map(func(row): return row.id)])
	# Findings Godot already shows (editor or run-time warnings) follow the rest of their area, each group by severity.
	var shown := [
		{"id": "editor_high", "kind": "correctness", "severity": "high", "godot_warns": "editor"},
		{"id": "ours_low", "kind": "correctness", "severity": "low"},
		{"id": "runtime_medium", "kind": "correctness", "severity": "medium", "godot_warns": "runtime"},
		{"id": "ours_medium", "kind": "correctness", "severity": "medium"},
		{"id": "runtime_candidate", "kind": "performance", "severity": "high", "measured_share": 0.0, "godot_warns": "runtime"},
		{"id": "candidate", "kind": "performance", "severity": "low", "measured_share": 0.0},
	]
	var by_godot: Dictionary = Rules.package(shown, {}, 10, "static")
	assert(by_godot.configuration_findings.map(func(row): return row.id) == ["ours_medium", "ours_low", "editor_high", "runtime_medium"], "Godot-warned findings did not follow the rest: %s" % [by_godot.configuration_findings.map(func(row): return row.id)])
	assert(by_godot.performance_findings.map(func(row): return row.id) == ["candidate", "runtime_candidate"] and by_godot.godot_warned_count == 3, "Godot-warned candidates: %s" % [by_godot.performance_findings.map(func(row): return row.id)])
	assert(Invariants.violations(by_godot).is_empty(), str(Invariants.violations(by_godot)))


func _version_ranges() -> void:
	var both := {"versions": ["4.4", "4.7"]}
	var newer := {"versions": ["4.7"], "min_version": "4.7"}
	var older := {"versions": ["4.4"]}
	assert(Rules.version_applies(both, 4005) and Rules.version_applies(both, 4006) and Rules.version_applies(both, 4010), "Rules verified on 4.4 and 4.7 skipped 4.5, 4.6 or 4.10")
	assert(not Rules.version_applies(both, 4003) and not Rules.version_applies(both, 5000), "Verified range extended before 4.4 or into another major")
	assert(not Rules.version_applies(newer, 4006) and Rules.version_applies(newer, 4008) and Rules.version_applies(newer, 4010), "4.7-only rules must start at 4.7 and continue after it")
	assert(not Rules.version_applies(older, 4005) and not Rules.version_applies(older, 4008), "A rule not verified on the newest catalog version extended past 4.4")
	assert(not Rules.version_applies({"versions": ["4.4", "4.7"], "max_version": "4.6"}, 4010), "max_version must compare numerically")
	var hdr := {"renderer": "mobile", "version_major": 4, "version_minor": 5, "adapter": {}, "scene": {"check_viewport_hdr2d": 1}}
	assert(not _has(Rules.evaluate(hdr, "static"), "memory.viewport_hdr2d"), "4.5 used a renderer list first verified on 4.7")
	hdr.version_minor = 8
	var later: Array = Rules.evaluate(hdr, "static").filter(func(row): return row.id == "memory.viewport_hdr2d")
	assert(later.size() == 1 and str(later[0].engine_version_note).contains("4.8"), "An unverified engine version must be flagged on its findings")
	hdr.version_minor = 7
	var verified: Array = Rules.evaluate(hdr, "static").filter(func(row): return row.id == "memory.viewport_hdr2d")
	assert(verified.size() == 1 and verified[0].engine_version_note == "", "A verified version must not carry the unverified note")


func _has(findings: Array, id: String) -> bool:
	for finding in findings:
		if finding.id == id:
			return true
	return false
