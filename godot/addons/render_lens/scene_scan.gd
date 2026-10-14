extends RefCounted

## Editor-side scene walk. Counts and offender paths for the rule engine.
## Does not modify the scene. An explicit root is not added to the tree.

const ProjectScan = preload("res://addons/render_lens/project_scan.gd")
const SceneChecks = preload("res://addons/render_lens/scene_checks.gd")
const Metrics = preload("res://addons/render_lens/metrics_snapshot.gd")

const SCENE_KEYS: PackedStringArray = [
	"alpha_blend_depth_always_count",
	"area_light_count",
	"camera_far_at_default_count",
	"canvas_item_count",
	"canvas_light_count",
	"canvas_pcf13_count",
	"canvas_shadow_light_count",
	"collision_shape_count",
	"cpu_particle_count",
	"decal_count",
	"decal_large_count",
	"decal_without_distance_fade_count",
	"directional_max_distance_above_default_count",
	"directional_pssm4_count",
	"directional_shadow_count",
	"dof_blur_enabled",
	"double_sided_material_count",
	"editor_only_light_count",
	"env_adjustment",
	"env_background_keep",
	"env_fog",
	"env_glow",
	"env_sdfgi",
	"env_sdfgi_cascades",
	"env_sdfgi_use_occlusion",
	"env_ssao",
	"env_ssil",
	"env_ssr",
	"env_ssr_max_steps",
	"env_volumetric_fog",
	"gpu_particle_collision_count",
	"gpu_particle_fixed_fps_high_count",
	"gpu_particle_high_amount_count",
	"gpu_particle_multi_pass_count",
	"gpu_particle_trail_count",
	"heightfield_high_res_count",
	"heightmap_material_count",
	"largest_identical_mesh_count",
	"light_count",
	"light_size_shadow_count",
	"lightmap_gi_count",
	"mesh_double_sided_shadow_count",
	"mesh_high_surface_count",
	"mesh_ignore_occlusion_count",
	"mesh_lod_bias_above_one_count",
	"mesh_without_visibility_range_count",
	"multimesh_count",
	"negative_light_count",
	"occluder_count",
	"omni_light_count",
	"omni_range_large_count",
	"omni_shadow_count",
	"omni_shadow_cube_count",
	"particle_node_count",
	"particle_per_pixel_material_count",
	"physics_body_3d_count",
	"positional_shadow_without_distance_fade_count",
	"proximity_fade_count",
	"reflection_probe_always_count",
	"reflection_probe_count",
	"reflection_probe_shadow_count",
	"refraction_material_count",
	"shader_material_count",
	"sky_custom_fov_count",
	"sky_quality_count",
	"sky_radiance_large_count",
	"spot_angle_wide_count",
	"spot_light_count",
	"spot_shadow_count",
	"subsurf_material_count",
	"texture_large_count",
	"texture_lossless_count",
	"texture_no_mipmaps_count",
	"texture_vram_uncompressed_count",
	"transparent_alpha_blend_count",
	"transparent_depth_prepass_count",
	"unshaded_material_count",
	"voxel_gi_count",
	"voxel_gi_subdiv_above_default_count",
]

const EXTRA_KEYS: PackedStringArray = [
	"anisotropic_material_count",
	"subviewport_msaa8_count",
	"subviewport_keep_count",
	"small_indexed_surface_count",
	"animation_player_count",
	"animation_physics_callback_count",
	"animation_tree_count",
	"skeleton_count",
	"skeleton_bone_count",
	"physical_bone_count",
	"soft_body_count",
	"rigid_body_3d_count",
	"rigid_ccd_count",
	"rigid_body_2d_count",
	"rigid_2d_ccd_count",
	"character_body_3d_count",
	"area_monitoring_count",
	"concave_shape_count",
	"heightmap_shape_count",
	"navigation_agent_3d_count",
	"navigation_avoidance_count",
	"navigation_region_3d_count",
	"navigation_agent_2d_count",
	"audio_player_count",
	"audio_player_3d_count",
	"audio_polyphony_count",
	"audio_unbounded_count",
	"audio_bus_count",
	"audio_bus_effect_count",
	"control_count",
	"control_clip_count",
	"canvas_clip_children_count",
	"container_count",
	"label_count",
	"rich_text_count",
	"default_font_text_count",
	"subviewport_count",
	"subviewport_always_count",
	"subviewport_msaa_count",
	"timer_count",
	"process_always_count",
	"multimesh_max_instances",
	"lightmap_unbaked_count",
	"lightmap_baked_count",
	"geometry_3d_count",
	"voxel_unbaked_count",
	"nodes_with_process_count",
	"nodes_with_physics_process_count",
	"script_file_process_count",
	"script_file_physics_process_count",
	"autoload_count",
	"import_mesh_lods_off_count",
	"import_mesh_shadow_off_count",
	"import_mesh_uncompressed_count",
	"import_audio_pcm_count",
	"import_texture_lossless_count",
	"import_texture_no_mipmaps_count",
	"import_texture_uncompressed_count",
	"import_texture_high_quality_count",
	"import_texture_hdr_uncompressed_count",
	"import_obj_lods_off_count",
	"import_obj_shadow_off_count",
	"import_gltf_embedded_uncompressed_count",
]


static func scan_path(scene_path: String) -> Dictionary:
	scene_path = scene_path.simplify_path()
	if not scene_path.begins_with("res://") or ".." in scene_path.split("/"):
		return {"scenes": [], "counts": _empty_counts(), "offenders": {}, "error": "Scene path must be a res:// path inside the project: %s" % scene_path}
	if not ResourceLoader.exists(scene_path):
		return {"scenes": [], "counts": _empty_counts(), "offenders": {}, "error": "Scene not found: %s" % scene_path}
	var packed = load(scene_path)
	if not packed is PackedScene:
		return {"scenes": [], "counts": _empty_counts(), "offenders": {}, "error": "Not a PackedScene: %s" % scene_path}
	var inst: Node = packed.instantiate()
	if inst == null:  # empty scene, or a missing instanced scene or placeholder
		return {"scenes": [], "counts": _empty_counts(), "offenders": {}, "error": "Scene could not be instantiated: %s" % scene_path}
	var result := scan(inst, scene_path)
	inst.free()
	return result


## project: also read the project's files; the running game passes false and the editor adds them (ScanScene.gather).
## extra_roots render together with explicit_root (the game's autoloads and nodes scripts add to the root), so they add up.
static func scan(explicit_root: Node = null, scene_file: String = "", project := true, extra_roots: Array = []) -> Dictionary:
	var counts := _empty_counts()
	var offenders := {}
	var scenes: Array = []
	var state := {
		"counts": counts,
		"offenders": offenders,
		"mesh_groups": {},
		"seen_materials": {},
		"seen_textures": {},
		"tag": "scene",
		"settings": Metrics._settings(),  # the values the rules see, read once per scan
	}
	# Without a scene, one is scanned: the open scene, else the main one (they never render together, so no merge is right).
	var tag := "scene"
	var free_root := false
	if explicit_root == null:
		var picked := _default_root()
		if not picked.is_empty():
			explicit_root = picked["node"]
			tag = str(picked["tag"])
			free_root = bool(picked["free"])
	if explicit_root != null:
		state["tag"] = tag
		state["root"] = explicit_root
		state["scene_file"] = scene_file if scene_file != "" else str(explicit_root.scene_file_path)
		scenes.append(_scene_label(tag, explicit_root))
		_walk(explicit_root, state)
		for extra in extra_roots:
			state["root"] = extra
			state["scene_file"] = str(extra.scene_file_path)
			scenes.append(_scene_label("autoload", extra))
			_walk(extra, state)
		_default_environment(state)
		_finish_mesh_groups(state)
		if free_root:
			explicit_root.free()
	if project:
		ProjectScan.apply(state)
	else:
		ProjectScan._audio_buses(state)  # the live bus state is in this process; it walks no files
	return {
		"scenes": scenes,
		"counts": counts,
		"offenders": offenders,
		"shader_scan": state.get("shader_scan", {}),
		"gridmap_scan": state.get("gridmap_scan", {}),
		"tilemap_scan": state.get("tilemap_scan", {}),
		"audio_scan": state.get("audio_scan", {}),
		"material_scan": {"max_passes_per_chain": 8, "truncated_chains": state.get("material_chain_truncations", 0)},
		"file_walk": state.get("file_walk", {}),
		"script_scan": state.get("script_scan", {}),
	}


static func _empty_counts() -> Dictionary:
	var counts := {}
	for key in SCENE_KEYS:
		counts[key] = 0
	for key in EXTRA_KEYS:
		counts[key] = 0
	for key in SceneChecks.KEYS:
		counts["check_" + key] = 0
	return counts


## The scene a scan without one covers: the scene open in the editor, else the main scene, else the running scene.
static func _default_root() -> Dictionary:
	if Engine.is_editor_hint() and Engine.has_singleton("EditorInterface"):
		var edited = Engine.get_singleton("EditorInterface").call("get_edited_scene_root")
		if edited != null:
			return {"tag": "edited", "node": edited, "free": false}
	var main_path := res_path(str(ProjectSettings.get_setting("application/run/main_scene", "")))
	if main_path != "" and ResourceLoader.exists(main_path):
		var packed = load(main_path)
		if packed is PackedScene:
			var inst = packed.instantiate()
			if inst != null:
				return {"tag": "main", "node": inst, "free": true}
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.current_scene != null:
		return {"tag": "current", "node": tree.current_scene, "free": false}
	return {}


## The editor stores the main scene as uid:// since 4.4, while scene_file_path is res://.
static func res_path(path: String) -> String:
	if path.begins_with("uid://"):
		var id := ResourceUID.text_to_id(path)
		if ResourceUID.has_id(id):
			return ResourceUID.get_id_path(id)
	return path


static func _scene_label(tag: String, node: Node) -> String:
	var path := str(node.scene_file_path)
	if path == "":
		path = node.name
	return "%s:%s" % [tag, path]


static func _walk(root: Node, state: Dictionary) -> void:
	# Iterative pre-order: GDScript's call stack stops at 1024 frames and generated scenes can nest deeper.
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		_inspect(node, state)
		var children := node.get_children()
		for index in range(children.size() - 1, -1, -1):
			stack.push_back(children[index])


static func _inspect(node: Node, state: Dictionary) -> void:
	var counts: Dictionary = state["counts"]
	var root: Node = state.get("root")
	var raw := _node_path(node)
	if root != null:
		raw = _path_from(node, root)
	var path := offender_path(str(state.get("scene_file", "")), raw)
	if node is Light3D and bool(node.get("editor_only")):
		counts["editor_only_light_count"] = int(counts["editor_only_light_count"]) + 1
		_note(state, "editor_only_lights", path)
		return
	SceneChecks.inspect(node, state, path)
	if node is GeometryInstance3D:
		counts["geometry_3d_count"] = int(counts["geometry_3d_count"]) + 1
	if node is DirectionalLight3D:
		_inspect_directional(node, counts, state, path)
	elif node is OmniLight3D:
		_inspect_omni(node, counts, state, path)
	elif node is SpotLight3D:
		_inspect_spot(node, counts, state, path)
	elif node.is_class("AreaLight3D"):
		# Godot 4.7+: a light like the others, which renderers cap separately from omni and spot lights.
		counts["light_count"] = int(counts["light_count"]) + 1
		_note(state, "lights", path)
		if _shown(node):
			counts["area_light_count"] = int(counts["area_light_count"]) + 1
	elif node is MeshInstance3D:
		_inspect_mesh(node, state, path)
	elif node is GPUParticles3D or node is GPUParticles2D:
		_inspect_gpu_particles(node, state, path)
	elif node is CPUParticles3D or node is CPUParticles2D:
		counts["cpu_particle_count"] = int(counts["cpu_particle_count"]) + 1
		counts["particle_node_count"] = int(counts["particle_node_count"]) + 1
		_note(state, "cpu_particles", path)
		_note(state, "particle_nodes", path)
		if node is CPUParticles3D:
			_inspect_particle_material(node, state, path)
	elif node is Decal:
		_inspect_decal(node, counts, state, path)
	elif node is ReflectionProbe:
		_inspect_probe(node, counts, state, path)
	elif node is VoxelGI:
		_inspect_voxel(node, counts, state, path)
	elif node is LightmapGI:
		counts["lightmap_gi_count"] = int(counts["lightmap_gi_count"]) + 1
		if node.light_data == null:
			counts["lightmap_unbaked_count"] = int(counts["lightmap_unbaked_count"]) + 1
			_note(state, "lightmap_unbaked", path)
		else:
			counts["lightmap_baked_count"] = int(counts["lightmap_baked_count"]) + 1
	elif node is WorldEnvironment:
		_inspect_world_env(node, state, path)
	elif node is Camera3D:
		_inspect_camera(node, counts, state, path)
	elif node is OccluderInstance3D:
		counts["occluder_count"] = int(counts["occluder_count"]) + 1
	elif node is MultiMeshInstance3D or node is MultiMeshInstance2D:
		counts["multimesh_count"] = int(counts["multimesh_count"]) + 1
		_note(state, "multimeshes", path)
		var multi = node.multimesh
		if multi != null and multi.mesh != null:
			var visible: int = multi.instance_count if multi.visible_instance_count < 0 else mini(multi.instance_count, multi.visible_instance_count)
			counts["multimesh_max_instances"] = maxi(int(counts["multimesh_max_instances"]), visible)
			if visible >= 256:
				_note(state, "multimesh_many_instances", path)
	elif node is Light2D:
		_inspect_light2d(node, counts, state, path)
	elif node is GPUParticlesCollisionHeightField3D:
		if node.resolution > GPUParticlesCollisionHeightField3D.RESOLUTION_1024:
			counts["heightfield_high_res_count"] = int(counts["heightfield_high_res_count"]) + 1
			_note(state, "heightfields", path)
	if node is PhysicsBody3D:
		counts["physics_body_3d_count"] = int(counts["physics_body_3d_count"]) + 1
		if int(counts["physics_body_3d_count"]) <= 8:
			_note(state, "physics_bodies", path)
	if node is CollisionShape3D:
		counts["collision_shape_count"] = int(counts["collision_shape_count"]) + 1
		if int(counts["collision_shape_count"]) <= 8:
			_note(state, "collision_shapes", path)
	if node is Node2D:
		counts["canvas_item_count"] = int(counts["canvas_item_count"]) + 1
	_inspect_extra(node, counts, state, path)


static func _inspect_extra(node: Node, counts: Dictionary, state: Dictionary, path: String) -> void:
	if node is AnimationPlayer:
		counts["animation_player_count"] = int(counts["animation_player_count"]) + 1
		if int(node.callback_mode_process) == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS:
			counts["animation_physics_callback_count"] = int(counts["animation_physics_callback_count"]) + 1
			_note(state, "animation_physics", path)
	elif node is AnimationTree:
		counts["animation_tree_count"] = int(counts["animation_tree_count"]) + 1
	if node is Skeleton3D:
		counts["skeleton_count"] = int(counts["skeleton_count"]) + 1
		counts["skeleton_bone_count"] = int(counts["skeleton_bone_count"]) + int(node.get_bone_count())
	if node is PhysicalBone3D:
		counts["physical_bone_count"] = int(counts["physical_bone_count"]) + 1
	if node is SoftBody3D:
		counts["soft_body_count"] = int(counts["soft_body_count"]) + 1
		_note(state, "soft_bodies", path)
	if node is RigidBody3D:
		counts["rigid_body_3d_count"] = int(counts["rigid_body_3d_count"]) + 1
		if node.continuous_cd:
			counts["rigid_ccd_count"] = int(counts["rigid_ccd_count"]) + 1
			_note(state, "rigid_ccd", path)
	if node is RigidBody2D:
		counts["rigid_body_2d_count"] = int(counts["rigid_body_2d_count"]) + 1
		if node.continuous_cd:
			counts["rigid_2d_ccd_count"] = int(counts["rigid_2d_ccd_count"]) + 1
			_note(state, "rigid_2d_ccd", path)
	if node is CharacterBody3D:
		counts["character_body_3d_count"] = int(counts["character_body_3d_count"]) + 1
	if node is Area3D:
		var fresh := Area3D.new()
		SceneChecks.check(state, "jolt_area_wind_ignored", not is_equal_approx(node.wind_force_magnitude, fresh.wind_force_magnitude) or not is_equal_approx(node.wind_attenuation_factor, fresh.wind_attenuation_factor) or not node.wind_source_path.is_empty(), path)
		fresh.free()
	if node is Area3D and node.monitoring:
		counts["area_monitoring_count"] = int(counts["area_monitoring_count"]) + 1
		_note(state, "areas_monitoring", path)
	if node is CollisionShape3D and node.shape != null:
		if node.shape is ConcavePolygonShape3D:
			counts["concave_shape_count"] = int(counts["concave_shape_count"]) + 1
			_note(state, "concave_shapes", path)
		elif node.shape is HeightMapShape3D:
			counts["heightmap_shape_count"] = int(counts["heightmap_shape_count"]) + 1
			_note(state, "heightmap_shapes", path)
	if node is NavigationAgent3D or node is NavigationAgent2D:
		var dimension_key := "navigation_agent_3d_count" if node is NavigationAgent3D else "navigation_agent_2d_count"
		counts[dimension_key] = int(counts[dimension_key]) + 1
		if node.avoidance_enabled:
			counts["navigation_avoidance_count"] = int(counts["navigation_avoidance_count"]) + 1
			_note(state, "avoidance_agents", path)
	if node is NavigationRegion3D:
		counts["navigation_region_3d_count"] = int(counts["navigation_region_3d_count"]) + 1
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		counts["audio_player_count"] = int(counts["audio_player_count"]) + 1
		if int(node.get("max_polyphony")) > 1:
			counts["audio_polyphony_count"] = int(counts["audio_polyphony_count"]) + 1
			_note(state, "audio_polyphony", path)
	if node is AudioStreamPlayer3D:
		counts["audio_player_3d_count"] = int(counts["audio_player_3d_count"]) + 1
		if float(node.max_distance) <= 0.0:
			counts["audio_unbounded_count"] = int(counts["audio_unbounded_count"]) + 1
			_note(state, "audio_unbounded", path)
	if node is Control:
		counts["control_count"] = int(counts["control_count"]) + 1
		if node.clip_contents:
			counts["control_clip_count"] = int(counts["control_clip_count"]) + 1
	if node is Container:
		counts["container_count"] = int(counts["container_count"]) + 1
	if node is Label:
		counts["label_count"] = int(counts["label_count"]) + 1
	if node is RichTextLabel:
		counts["rich_text_count"] = int(counts["rich_text_count"]) + 1
	if (node is Label or node is Label3D or node is RichTextLabel or node is Button or node is LineEdit or node is TextEdit) and _uses_default_font(node):
		counts["default_font_text_count"] = int(counts["default_font_text_count"]) + 1
		_note(state, "default_font_text", path)
	if node is CanvasItem and int(node.clip_children) != CanvasItem.CLIP_CHILDREN_DISABLED:
		counts["canvas_clip_children_count"] = int(counts["canvas_clip_children_count"]) + 1
		_note(state, "clip_children", path)
	if node is SubViewport:
		if node.msaa_3d == Viewport.MSAA_8X:
			counts["subviewport_msaa8_count"] += 1
			_note(state, "subviewport_msaa8", path)
		if node.render_target_clear_mode == SubViewport.CLEAR_MODE_NEVER:
			counts["subviewport_keep_count"] += 1
			_note(state, "subviewport_keep", path)
		counts["subviewport_count"] = int(counts["subviewport_count"]) + 1
		if int(node.render_target_update_mode) == SubViewport.UPDATE_ALWAYS:
			counts["subviewport_always_count"] = int(counts["subviewport_always_count"]) + 1
			_note(state, "subviewport_always", path)
		if int(node.msaa_3d) != Viewport.MSAA_DISABLED:
			counts["subviewport_msaa_count"] = int(counts["subviewport_msaa_count"]) + 1
			_note(state, "subviewport_msaa", path)
	if node is Timer:
		counts["timer_count"] = int(counts["timer_count"]) + 1
	if int(node.process_mode) == Node.PROCESS_MODE_ALWAYS:
		counts["process_always_count"] = int(counts["process_always_count"]) + 1
		_note(state, "process_always", path)
	var scr = node.get_script()
	if scr is GDScript:
		var flags := _process_flags(scr, state)
		if flags[0]:
			counts["nodes_with_process_count"] = int(counts["nodes_with_process_count"]) + 1
			_note(state, "nodes_with_process", path)
		if flags[1]:
			counts["nodes_with_physics_process_count"] = int(counts["nodes_with_physics_process_count"]) + 1
			_note(state, "nodes_with_physics_process", path)


## Per-frame light caps only see lights that are drawn: hidden ones (or under a hidden parent, in a tree) are skipped.
static func _shown(node: Node3D) -> bool:
	return node.is_visible_in_tree() if node.is_inside_tree() else node.visible


## [declares _process, declares _physics_process], matched like ProjectScan in code_only() text so comments, strings
## and _process_queue() do not count; cached per script because many nodes share one.
static func _process_flags(scr: GDScript, state: Dictionary) -> Array:
	var cache: Dictionary = state.get_or_add("process_flags", {})
	if not cache.has(scr):
		var code := ProjectScan.code_only(scr.source_code)
		cache[scr] = [
			RegEx.create_from_string("(?m)^\\s*(?:static\\s+)?func\\s+_process\\s*\\(").search(code) != null,
			RegEx.create_from_string("(?m)^\\s*(?:static\\s+)?func\\s+_physics_process\\s*\\(").search(code) != null,
		]
	return cache[scr]


static func _inspect_directional(node: DirectionalLight3D, counts: Dictionary, state: Dictionary, path: String) -> void:
	counts["light_count"] = int(counts["light_count"]) + 1
	_note(state, "lights", path)
	if node.light_negative:
		counts["negative_light_count"] = int(counts["negative_light_count"]) + 1
		_note(state, "negative_lights", path)
	if not node.shadow_enabled:
		return
	counts["directional_shadow_count"] = int(counts["directional_shadow_count"]) + 1
	if node.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS:
		counts["directional_pssm4_count"] = int(counts["directional_pssm4_count"]) + 1
		_note(state, "directional_pssm4", path)
	if node.directional_shadow_max_distance > 100.0:
		counts["directional_max_distance_above_default_count"] = int(counts["directional_max_distance_above_default_count"]) + 1
		_note(state, "directional_max_distance", path)
	_note_soft_shadow(node, counts, state, path)


static func _inspect_omni(node: OmniLight3D, counts: Dictionary, state: Dictionary, path: String) -> void:
	counts["light_count"] = int(counts["light_count"]) + 1
	if _shown(node):
		counts["omni_light_count"] = int(counts["omni_light_count"]) + 1
	_note(state, "lights", path)
	if node.light_negative:
		counts["negative_light_count"] = int(counts["negative_light_count"]) + 1
		_note(state, "negative_lights", path)
	if node.omni_range >= 20.0:
		counts["omni_range_large_count"] = int(counts["omni_range_large_count"]) + 1
		_note(state, "omni_range_large", path)
	if not node.shadow_enabled:
		return
	counts["omni_shadow_count"] = int(counts["omni_shadow_count"]) + 1
	_note(state, "omni_shadows", path)
	if node.omni_shadow_mode == OmniLight3D.SHADOW_CUBE:
		counts["omni_shadow_cube_count"] = int(counts["omni_shadow_cube_count"]) + 1
		_note(state, "omni_shadow_cube", path)
	if not node.distance_fade_enabled:
		counts["positional_shadow_without_distance_fade_count"] = int(counts["positional_shadow_without_distance_fade_count"]) + 1
		_note(state, "positional_shadow_no_fade", path)
	_note_soft_shadow(node, counts, state, path)


static func _inspect_spot(node: SpotLight3D, counts: Dictionary, state: Dictionary, path: String) -> void:
	counts["light_count"] = int(counts["light_count"]) + 1
	if _shown(node):
		counts["spot_light_count"] = int(counts["spot_light_count"]) + 1
	_note(state, "lights", path)
	if node.light_negative:
		counts["negative_light_count"] = int(counts["negative_light_count"]) + 1
		_note(state, "negative_lights", path)
	if node.spot_angle >= 120.0:
		counts["spot_angle_wide_count"] = int(counts["spot_angle_wide_count"]) + 1
		_note(state, "spot_wide", path)
	if not node.shadow_enabled:
		return
	counts["spot_shadow_count"] = int(counts["spot_shadow_count"]) + 1
	_note(state, "spot_shadows", path)
	if not node.distance_fade_enabled:
		counts["positional_shadow_without_distance_fade_count"] = int(counts["positional_shadow_without_distance_fade_count"]) + 1
		_note(state, "positional_shadow_no_fade", path)
	_note_soft_shadow(node, counts, state, path)


static func _note_soft_shadow(node: Light3D, counts: Dictionary, state: Dictionary, path: String) -> void:
	if node.light_size > 0.0 or node.light_angular_distance > 0.0:
		counts["light_size_shadow_count"] = int(counts["light_size_shadow_count"]) + 1
		_note(state, "light_size_shadows", path)


static func _inspect_mesh(node: MeshInstance3D, state: Dictionary, path: String) -> void:
	# Without a mesh the instance has no base, and renderer_scene_cull.cpp never culls, draws or shadows it, so none of
	# its render settings cost anything; scene_validation.mesh_missing reports the node.
	if node.mesh == null:
		return
	var counts: Dictionary = state["counts"]
	if node.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED:
		counts["mesh_double_sided_shadow_count"] = int(counts["mesh_double_sided_shadow_count"]) + 1
		_note(state, "double_sided_shadows", path)
	if node.lod_bias > 1.001:
		counts["mesh_lod_bias_above_one_count"] = int(counts["mesh_lod_bias_above_one_count"]) + 1
		_note(state, "lod_bias_high", path)
	# Occlusion culling only runs for the camera, which never draws a mesh whose range ends before it begins. Its other
	# costs still count: omni and spot shadows and dynamic VoxelGI skip the range check, and whether a material draws
	# there depends on per-material and per-renderer rules a static scan does not model.
	if node.ignore_occlusion_culling and not SceneChecks.range_hides_from_camera(node):
		counts["mesh_ignore_occlusion_count"] = int(counts["mesh_ignore_occlusion_count"]) + 1
		_note(state, "ignore_occlusion", path)
	if node.visibility_range_begin <= 0.0 and node.visibility_range_end <= 0.0:
		counts["mesh_without_visibility_range_count"] = int(counts["mesh_without_visibility_range_count"]) + 1
	var mesh = node.mesh
	if mesh != null:
		if mesh.get_surface_count() >= 3:
			counts["mesh_high_surface_count"] = int(counts["mesh_high_surface_count"]) + 1
			_note(state, "high_surface_meshes", path)
		var groups: Dictionary = state["mesh_groups"]
		var key := str(mesh.get_instance_id())
		if not groups.has(key):
			groups[key] = {"count": 0, "nodes": [], "label": mesh.resource_path if mesh.resource_path != "" else node.name}
		groups[key]["count"] = int(groups[key]["count"]) + 1
		if groups[key]["nodes"].size() < 8:
			groups[key]["nodes"].append(path)
		for surface in mesh.get_surface_count():
			if mesh is ArrayMesh and node.is_visible() and mesh.surface_get_primitive_type(surface) == Mesh.PRIMITIVE_TRIANGLES:
				var indices: int = mesh.surface_get_array_index_len(surface)
				if indices > 0 and indices <= 10:
					counts["small_indexed_surface_count"] += 1
					_note(state, "small_indexed_surfaces", path)
			_consider_material(node.get_active_material(surface), state, path, null, mesh, surface)
			_consider_material(node.material_overlay, state, path, null, mesh, surface)


static func _inspect_gpu_particles(node: Node, state: Dictionary, path: String) -> void:
	var counts: Dictionary = state["counts"]
	counts["particle_node_count"] = int(counts["particle_node_count"]) + 1
	_note(state, "particle_nodes", path)
	if node.amount >= 64:
		counts["gpu_particle_high_amount_count"] = int(counts["gpu_particle_high_amount_count"]) + 1
		_note(state, "gpu_particles_amount", path)
	if node.trail_enabled:
		counts["gpu_particle_trail_count"] = int(counts["gpu_particle_trail_count"]) + 1
		_note(state, "particle_trails", path)
	if node.fixed_fps >= 60:
		counts["gpu_particle_fixed_fps_high_count"] = int(counts["gpu_particle_fixed_fps_high_count"]) + 1
		_note(state, "particle_fixed_fps", path)
	if node is GPUParticles3D and node.draw_passes > 1:
		counts["gpu_particle_multi_pass_count"] = int(counts["gpu_particle_multi_pass_count"]) + 1
		_note(state, "particle_draw_passes", path)
	var process = node.process_material
	if process is ParticleProcessMaterial:
		var particle_material := process as ParticleProcessMaterial
		if particle_material.collision_mode != ParticleProcessMaterial.COLLISION_DISABLED:
			counts["gpu_particle_collision_count"] = int(counts["gpu_particle_collision_count"]) + 1
			_note(state, "particle_collision", path)
	if node is GPUParticles3D:
		_inspect_particle_material(node, state, path)


static func _inspect_particle_material(node: GeometryInstance3D, state: Dictionary, path: String) -> void:
	var passes := 1
	if node is GPUParticles3D:
		passes = node.draw_passes
	for index in passes:
		var mesh: Mesh
		if node is GPUParticles3D:
			mesh = node.get_draw_pass_mesh(index)
		elif node is CPUParticles3D:
			mesh = node.mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var material: Material = node.material_override if node.material_override != null else mesh.surface_get_material(surface)
			_consider_material(material, state, path, node, mesh, surface)
			_consider_material(node.material_overlay, state, path, node, mesh, surface)


static func _inspect_decal(node: Decal, counts: Dictionary, state: Dictionary, path: String) -> void:
	counts["decal_count"] = int(counts["decal_count"]) + 1
	_note(state, "decals", path)
	if not node.distance_fade_enabled:
		counts["decal_without_distance_fade_count"] = int(counts["decal_without_distance_fade_count"]) + 1
		_note(state, "decals_no_fade", path)
	if node.size.x >= 50.0 or node.size.y >= 50.0 or node.size.z >= 50.0:
		counts["decal_large_count"] = int(counts["decal_large_count"]) + 1
		_note(state, "decals_large", path)
	_consider_texture(node.texture_albedo, state, path)
	_consider_texture(node.texture_normal, state, path)
	_consider_texture(node.texture_orm, state, path)
	_consider_texture(node.texture_emission, state, path)


static func _inspect_probe(node: ReflectionProbe, counts: Dictionary, state: Dictionary, path: String) -> void:
	counts["reflection_probe_count"] = int(counts["reflection_probe_count"]) + 1
	if node.update_mode == ReflectionProbe.UPDATE_ALWAYS:
		counts["reflection_probe_always_count"] = int(counts["reflection_probe_always_count"]) + 1
		_note(state, "probes_always", path)
	if node.enable_shadows:
		counts["reflection_probe_shadow_count"] = int(counts["reflection_probe_shadow_count"]) + 1
		_note(state, "probes_shadows", path)


static func _inspect_voxel(node: VoxelGI, counts: Dictionary, state: Dictionary, path: String) -> void:
	# Without data, voxel_gi.cpp gives the instance an empty base, so it costs nothing at run time; only the unbaked
	# counter (and scene_validation.voxel_gi_data) report it.
	if node.data == null:
		counts["voxel_unbaked_count"] = int(counts["voxel_unbaked_count"]) + 1
		_note(state, "voxel_unbaked", path)
		return
	counts["voxel_gi_count"] = int(counts["voxel_gi_count"]) + 1
	_note(state, "voxel_gi", path)
	if int(node.subdiv) >= int(VoxelGI.SUBDIV_256):
		counts["voxel_gi_subdiv_above_default_count"] = int(counts["voxel_gi_subdiv_above_default_count"]) + 1
		_note(state, "voxel_subdiv", path)


static func _inspect_world_env(node: WorldEnvironment, state: Dictionary, path: String) -> void:
	var env = node.environment
	if env != null:
		state["world_environment_seen"] = true
		_inspect_environment(env, state, path)
	_inspect_attributes(node.camera_attributes, state, path)


static func _inspect_camera(node: Camera3D, counts: Dictionary, state: Dictionary, path: String) -> void:
	if node.far >= 4000.0:
		counts["camera_far_at_default_count"] = int(counts["camera_far_at_default_count"]) + 1
		_note(state, "camera_far", path)
	if node.environment != null:
		_inspect_environment(node.environment, state, path)
	state.get_or_add("cameras", []).append([node.current, node.environment != null])
	_inspect_attributes(node.attributes, state, path)


## Godot draws 3D with the project's default environment unless the active camera or a WorldEnvironment has one. The
## active camera is the one marked current, or the only camera; another camera's environment does not apply.
static func _default_environment(state: Dictionary) -> void:
	var cameras: Array = state.get("cameras", [])
	var camera_env: bool = cameras.any(func(camera): return camera[0] and camera[1]) or (cameras.size() == 1 and cameras[0][1])
	if bool(state.get("world_environment_seen", false)) or camera_env or int(state["counts"].get("geometry_3d_count", 0)) == 0:
		return
	var path := res_path(str(SceneChecks._setting(state, "rendering/environment/defaults/default_environment", "")))
	if path != "" and ResourceLoader.exists(path):
		var env = load(path)
		if env is Environment:
			_inspect_environment(env, state, path)
			SceneChecks.inspect_environment(env, state, path)


static func _inspect_environment(env: Environment, state: Dictionary, path: String) -> void:
	SceneChecks.check(state, "env_bg_canvas", env.background_mode == Environment.BG_CANVAS, path)
	var counts: Dictionary = state["counts"]
	if env.ssao_enabled:
		counts["env_ssao"] = 1
		_note(state, "env_ssao", path)
	if env.ssil_enabled:
		counts["env_ssil"] = 1
		_note(state, "env_ssil", path)
	if env.ssr_enabled:
		counts["env_ssr"] = 1
		_note(state, "env_ssr", path)
		counts["env_ssr_max_steps"] = maxi(int(counts["env_ssr_max_steps"]), env.ssr_max_steps)
	if env.glow_enabled:
		counts["env_glow"] = 1
	if env.fog_enabled:
		counts["env_fog"] = 1
	if env.volumetric_fog_enabled:
		counts["env_volumetric_fog"] = 1
		_note(state, "env_volumetric_fog", path)
	if env.sdfgi_enabled:
		counts["env_sdfgi"] = 1
		_note(state, "env_sdfgi", path)
		counts["env_sdfgi_cascades"] = maxi(int(counts["env_sdfgi_cascades"]), env.sdfgi_cascades)
		if env.sdfgi_use_occlusion:
			counts["env_sdfgi_use_occlusion"] = 1
	if env.adjustment_enabled:
		counts["env_adjustment"] = 1
	if env.background_mode == Environment.BG_KEEP:
		counts["env_background_keep"] = 1
	if env.sky_custom_fov > 0.0:
		counts["sky_custom_fov_count"] = 1
	if env.sky != null:
		if env.sky.process_mode == Sky.PROCESS_MODE_QUALITY:
			counts["sky_quality_count"] = 1
			_note(state, "sky_quality", "Environment.sky")
		SceneChecks.check(state, "sky_realtime", env.sky.process_mode == Sky.PROCESS_MODE_REALTIME, path)
		SceneChecks.check(state, "sky_realtime_radiance", env.sky.process_mode == Sky.PROCESS_MODE_REALTIME and env.sky.radiance_size != Sky.RADIANCE_SIZE_256, path)
		if int(env.sky.radiance_size) >= int(Sky.RADIANCE_SIZE_1024):
			counts["sky_radiance_large_count"] = 1
			_note(state, "sky_radiance", "Environment.sky")
	_note(state, "environments", "Environment")


static func _inspect_attributes(attrs, state: Dictionary, path: String) -> void:
	var practical: bool = attrs is CameraAttributesPractical and (attrs.dof_blur_far_enabled or attrs.dof_blur_near_enabled)
	if practical or (attrs is CameraAttributesPhysical and physical_dof(attrs)):
		state["counts"]["dof_blur_enabled"] = 1
		_note(state, "dof", path)


## Mirrors CameraAttributesPhysical::_update_frustum (scene/resources/camera_attributes.cpp): physical
## cameras blur wherever the circle of confusion becomes visible, which the default settings already do.
static func physical_dof(attrs: CameraAttributesPhysical) -> bool:
	var coc := Vector2(36, 24).length() / 1500.0
	var focal: float = attrs.frustum_focal_length
	var focus: float = maxf(attrs.frustum_focus_distance * 1000.0, focal + 1.0)
	var hyperfocal: float = focal + focal * focal / (attrs.exposure_aperture * coc)
	var near: float = hyperfocal * focus / (hyperfocal + focus - focal) / 1000.0
	var far: float = hyperfocal * focus / (hyperfocal - (focus - focal)) / 1000.0
	return (far < attrs.frustum_far and far > 0.0) or near > attrs.frustum_near


static func _inspect_light2d(node: Light2D, counts: Dictionary, state: Dictionary, path: String) -> void:
	# renderer_viewport.cpp skips a PointLight2D without a texture before lighting and shadow setup;
	# scene_validation.point_light_texture reports the node.
	if node is PointLight2D and node.texture == null:
		return
	counts["canvas_light_count"] = int(counts["canvas_light_count"]) + 1
	if node.shadow_enabled:
		counts["canvas_shadow_light_count"] = int(counts["canvas_shadow_light_count"]) + 1
		_note(state, "canvas_shadow_lights", path)
		if node.shadow_filter == Light2D.SHADOW_FILTER_PCF13:
			counts["canvas_pcf13_count"] = int(counts["canvas_pcf13_count"]) + 1
			_note(state, "canvas_pcf13", path)


static func _consider_material(mat: Material, state: Dictionary, path: String, particle_owner: GeometryInstance3D = null, mesh: Mesh = null, surface: int = -1) -> void:
	for index in 8:
		if mat == null:
			return
		SceneChecks.inspect_material(mat, state, path, particle_owner is GPUParticles3D)
		if mesh != null:
			SceneChecks.inspect_surface(mesh, surface, mat, state, path)
		_consider_material_pass(mat, state, path, particle_owner != null)
		if not (mat is BaseMaterial3D or (mat is ShaderMaterial and mat.shader != null and mat.shader.get_mode() == Shader.MODE_SPATIAL)):
			return
		mat = mat.next_pass
	if mat != null:
		state["material_chain_truncations"] = int(state.get("material_chain_truncations", 0)) + 1


static func _consider_material_pass(mat: Material, state: Dictionary, path: String, on_particle: bool) -> void:
	if mat == null:
		return
	var seen: Dictionary = state["seen_materials"]
	var id: int = mat.get_instance_id()
	var counts: Dictionary = state["counts"]
	var particle_key := "particle:%d" % id
	if on_particle and mat is BaseMaterial3D and mat.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL and not seen.has(particle_key):
		seen[particle_key] = true
		counts["particle_per_pixel_material_count"] = int(counts["particle_per_pixel_material_count"]) + 1
		_note(state, "particle_per_pixel", path)
	if seen.has(id):
		return
	seen[id] = true
	if mat is ShaderMaterial:
		counts["shader_material_count"] = int(counts["shader_material_count"]) + 1
		_note(state, "shader_materials", path)
		SceneChecks.shader_material_copy(mat, state, path)
		# VisualShader texture parameters generate the same filter hints as text shaders.
		if mat.shader != null and mat.shader.code.contains("_mipmap_anisotropic"):
			counts["anisotropic_material_count"] += 1
			_note(state, "anisotropic_materials", path)
		if mat.shader != null and mat.shader.get_mode() == Shader.MODE_SPATIAL:
			var code := RegEx.create_from_string("(?s)/\\*.*?\\*/|//[^\\n]*").sub(mat.shader.code, "", true)
			SceneChecks.check(state, "shader_discard", RegEx.create_from_string("\\bdiscard\\b").search(code) != null, path)
			SceneChecks.check(state, "shader_normal_roughness", code.contains("hint_normal_roughness_texture"), path)
			SceneChecks.check(state, "shader_screen_read", code.contains("hint_screen_texture") or code.contains("hint_depth_texture"), path)
			SceneChecks.check(state, "screen_texture", code.contains("hint_screen_texture"), path)
		return
	if not (mat is BaseMaterial3D):
		return
	var base: BaseMaterial3D = mat
	if base.texture_filter in [BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC, BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC]:
		counts["anisotropic_material_count"] += 1
		_note(state, "anisotropic_materials", path)
	var implicit_alpha: bool = base.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and (base.distance_fade_mode == BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA or base.proximity_fade_enabled or base.shadow_to_opacity)
	if base.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA or implicit_alpha:
		counts["transparent_alpha_blend_count"] = int(counts["transparent_alpha_blend_count"]) + 1
		_note(state, "alpha_blend", path)
		if base.depth_draw_mode == BaseMaterial3D.DEPTH_DRAW_ALWAYS:
			counts["alpha_blend_depth_always_count"] = int(counts["alpha_blend_depth_always_count"]) + 1
			_note(state, "depth_always", path)
	elif base.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS:
		counts["transparent_depth_prepass_count"] = int(counts["transparent_depth_prepass_count"]) + 1
		_note(state, "depth_prepass_transparency", path)
	if base.cull_mode == BaseMaterial3D.CULL_DISABLED:
		counts["double_sided_material_count"] = int(counts["double_sided_material_count"]) + 1
		_note(state, "double_sided_materials", path)
	if base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		counts["unshaded_material_count"] = int(counts["unshaded_material_count"]) + 1
		_note(state, "unshaded_materials", path)
	if base.subsurf_scatter_enabled:
		counts["subsurf_material_count"] = int(counts["subsurf_material_count"]) + 1
		_note(state, "subsurf_materials", path)
	SceneChecks.check(state, "transmittance_material", base.subsurf_scatter_transmittance_enabled, path)
	# Refraction samples the screen texture and proximity fade the depth texture.
	SceneChecks.check(state, "shader_screen_read", base.refraction_enabled or base.proximity_fade_enabled, path)
	SceneChecks.check(state, "screen_texture", base.refraction_enabled, path)
	if base.refraction_enabled:
		counts["refraction_material_count"] = int(counts["refraction_material_count"]) + 1
		_note(state, "refraction_materials", path)
	if base.heightmap_enabled and not base.uv1_triplanar:
		counts["heightmap_material_count"] = int(counts["heightmap_material_count"]) + 1
		_note(state, "heightmap_materials", path)
	if base.proximity_fade_enabled:
		counts["proximity_fade_count"] = int(counts["proximity_fade_count"]) + 1
		_note(state, "proximity_fade", path)
	_consider_texture(base.albedo_texture, state, path)
	_consider_texture(base.normal_texture, state, path)
	_consider_texture(base.orm_texture, state, path)
	_consider_texture(base.emission_texture, state, path)


static func _consider_texture(tex, state: Dictionary, path: String) -> void:
	if tex == null or not (tex is Texture2D):
		return
	var seen: Dictionary = state["seen_textures"]
	var id: int = tex.get_instance_id()
	if seen.has(id):
		return
	seen[id] = true
	var counts: Dictionary = state["counts"]
	if tex.get_width() > 2048 or tex.get_height() > 2048:
		counts["texture_large_count"] = int(counts["texture_large_count"]) + 1
		_note(state, "textures_large", path)
	var res_path := str(tex.resource_path)
	if res_path == "":
		return
	var imported := _read_import(res_path + ".import")
	if imported.is_empty():
		return
	var mode := str(imported.get("compress/mode", ""))
	if mode == "3":
		counts["texture_vram_uncompressed_count"] = int(counts["texture_vram_uncompressed_count"]) + 1
		_note(state, "textures_uncompressed", res_path)
	elif mode == "0":
		counts["texture_lossless_count"] = int(counts["texture_lossless_count"]) + 1
		_note(state, "textures_lossless", res_path)
	if str(imported.get("mipmaps/generate", "")).to_lower() == "false":
		counts["texture_no_mipmaps_count"] = int(counts["texture_no_mipmaps_count"]) + 1
		_note(state, "textures_no_mipmaps", res_path)


static func _read_import(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var out := {}
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("compress/mode=") or line.begins_with("mipmaps/generate=") or line.begins_with("process/size_limit="):
			var parts := line.split("=", true, 1)
			if parts.size() == 2:
				out[parts[0]] = parts[1].strip_edges()
	file.close()
	return out


static func _finish_mesh_groups(state: Dictionary) -> void:
	var groups: Dictionary = state["mesh_groups"]
	var largest := 0
	var nodes: Array = []
	for key in groups.keys():
		var group: Dictionary = groups[key]
		var count := int(group["count"])
		if count > largest:
			largest = count
			nodes = group["nodes"]
	state["counts"]["largest_identical_mesh_count"] = largest
	if largest >= 4:
		for item in nodes:
			_note(state, "identical_meshes", str(item))


## A text node draws with Godot's default font unless it, its LabelSettings or a theme names another font. In the running
## game Godot resolves the theme itself. Elsewhere the lookup is by hand: get_theme_font() does not see parent themes outside
## the tree, and in the editor it may resolve the editor's own theme.
static func _uses_default_font(node: Node) -> bool:
	if node is Label3D and node.font != null:
		return false
	if node is Label and node.label_settings != null and node.label_settings.font != null:
		return false
	var font_name := "normal_font" if node is RichTextLabel else "font"
	if node is Control and node.is_inside_tree() and not Engine.is_editor_hint():
		return node.get_theme_font(font_name) == ThemeDB.fallback_font
	if node is Control and node.has_theme_font_override(font_name):
		return false
	var themes: Array = [ThemeDB.get_project_theme()]
	var item: Node = null if node is Label3D else node
	while item != null:
		if (item is Control or item is Window) and item.theme != null:
			themes.append(item.theme)
		item = item.get_parent()
	themes = themes.filter(func(theme): return theme != null)
	# Godot looks a font up by the theme_type_variation chain first, then by the class names.
	var types: Array = []
	var variation := str(node.theme_type_variation) if node is Control else ""
	while variation != "" and not types.has(variation):
		types.append(variation)
		var base := ""
		for theme in themes:
			base = str(theme.get_type_variation_base(variation))
			if base != "":
				break
		variation = base
	var cls := node.get_class()
	while cls != "" and cls != "Node":
		types.append(cls)
		cls = ClassDB.get_parent_class(cls)
	for theme in themes:
		if theme.has_default_font() or types.any(func(type_name): return theme.has_font(font_name, type_name)):
			return false
	return true


static func _note(state: Dictionary, key: String, path: String) -> void:
	var offenders: Dictionary = state["offenders"]
	if not offenders.has(key):
		offenders[key] = []
	var listed: Array = offenders[key]
	if listed.size() >= 12:
		return
	if not listed.has(path):
		listed.append(path)


static func offender_path(scene_file: String, raw_node_path: String) -> String:
	var relative := scene_relative_node_path(raw_node_path)
	if scene_file == "":
		return relative
	if relative == scene_file or relative.begins_with(scene_file + "::"):
		return relative
	if relative == "":
		return scene_file
	return "%s::%s" % [scene_file, relative]


static func scene_relative_node_path(raw_node_path: String) -> String:
	## Editor scans walk to the SceneTree root, so a node in the open scene is
	## edited:root/@EditorNode@19513/.../@SubViewport@9904/HeavyTest/OmniLights/Omni1.
	## The reported path is the scene file plus the path from that scene's root.
	var text := raw_node_path
	var colon := text.find(":")
	if colon >= 0 and not text.begins_with("res://"):
		var tag := text.substr(0, colon)
		if tag == "edited" or tag == "main" or tag == "scene" or tag == "current":
			text = text.substr(colon + 1)
	var parts := text.split("/", false)
	var has_editor := false
	for part in parts:
		if _editor_internal_segment(str(part)):
			has_editor = true
			break
	if not has_editor:
		return "/".join(parts)
	var kept: Array[String] = []
	var skipping := true
	for part in parts:
		var name := str(part)
		if skipping and (name == "root" or _editor_internal_segment(name)):
			continue
		skipping = false
		kept.append(name)
	return "/".join(kept)


static func _editor_internal_segment(part: String) -> bool:
	if _editor_node_re == null:
		_editor_node_re = RegEx.new()
		_editor_node_re.compile("^@[^/@]+@[0-9]+$")
	return _editor_node_re.search(part) != null


static var _editor_node_re: RegEx = null


static func _path_from(node: Node, root: Node) -> String:
	var names: Array[String] = []
	var current: Node = node
	var guard := 0
	while current != null and guard < 256:
		names.push_front(str(current.name))
		if current == root:
			return "/".join(names)
		current = current.get_parent()
		guard += 1
	return _node_path(node)


static func _node_path(node: Node) -> String:
	var names: Array[String] = []
	var current: Node = node
	while current != null:
		names.push_front(str(current.name))
		current = current.get_parent()
	return "/".join(names)
