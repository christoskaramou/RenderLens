extends RefCounted

## Predicates adapted from Godot's configuration validation; no user methods run.
const KEYS: PackedStringArray = [
	"gpu_process_missing", "gpu_mesh_missing", "cpu_mesh_missing", "particles_animation_2d",
	"particles_animation_3d", "trails_skin", "trails_no_pose", "trails_multiple", "trails_material",
	"trails_renderer", "subemitter_renderer", "decal_textures", "decal_albedo", "decal_mask",
	"light_scale", "projector_shadows", "projector_renderer", "spot_shadows", "fog_renderer",
	"fog_environment", "occluder_missing", "occluder_empty", "occluder_bake_mask",
	"collision_parent", "collision_resource", "collision_polygon_parent", "collision_polygon_empty",
	"collision_polygon_points", "one_way_area", "collision_nonuniform", "rigid_scale",
	"concave_dynamic", "boundary_dynamic", "mesh_missing", "worldenv_empty", "worldenv_conflict",
	"area_projector", "area_texture", "area_shadows", "voxel_renderer",
	"visibility_range_invalid", "visibility_fade_begin", "visibility_fade_end", "geometry_transparency",
	"geometry_fade", "geometry_fade_cost", "point_light_texture", "light_occluder_missing", "light_occluder_empty",
	"particle_sdf_bake_mask", "particle_sdf_texture", "particle_sdf_large", "particle_heightfield_always",
	"particle_warmup", "particle_collision_scale", "viewport_container_child", "viewport_ssr_transparent",
	"sprite_frames_missing", "path_follow_parent", "path_follow_up_vector", "remote_transform_target",
	"material_next_pass", "material_triplanar_uv1", "material_triplanar_uv2", "material_deep_parallax",
	"material_clearcoat", "material_rim", "material_anisotropy", "material_detail", "material_normal",
	"material_height_triplanar", "material_msdf_triplanar", "material_unshaded_features", "material_particle_trails",
	"material_anisotropy_tangents",
	"navigation_agent_parent", "navigation_region_missing", "navigation_obstacle_rotation",
	"navigation_obstacle_scale", "navigation_obstacle_nonuniform", "navigation_obstacle_skew",
	"bone_attachment_parent", "bone_attachment_external", "bone_attachment_bone", "bone2d_hierarchy", "bone2d_rest",
	"animation_tree_root", "animation_mixer_root", "canvas_group_clip", "canvas_group_mipmaps", "canvas_group_margins", "particle_turbulence",
	"shape_cast_resource", "shape_cast_concave", "vehicle_wheel_parent", "joint_targets", "lightmap_shadowmask",
	"camera_cull_mask", "geometry_layers", "light_cull_mask", "navigation_layers", "particle_collider_mask", "particle_attractor_mask",
	"particle_vector_texture", "particle_vector_resolution", "range_exp_min", "tooltip_mouse_filter", "sprite_shaded",
	"particle_points_data", "particle_subemitter_target", "path_curve_data",
	"camera_dof_renderer", "camera_autoexposure_renderer", "viewport_dof_transparent", "skeleton_modifier_parent", "viewport_shrink_ignored",
	"canvas_nested_clip", "collision_object_empty",
	"look_at_axes", "look_at_bone", "look_at_target", "retarget_children", "retarget_profile",
	"navigation_link_endpoints", "scroll_container_children", "texture_rect_atlas_tile",
	"particle_trail_segments", "fog_aerial", "probe_lod_disabled", "viewport_lod_disabled",
	"viewport_supersampling", "viewport_msaa_2d", "camera_blur_amount",
	"gpu_depth_sort", "cpu_particle_sort", "heightfield_camera", "skin_dynamic_bounds",
	"fog_ambient_inject", "sdfgi_small_cells", "ssao_large_radius",
	"material_orm_pack", "backbuffer_full", "csg_composition", "navigation_neighbors", "richtext_sync", "hidden_video",
	"fog_sdfgi_inject", "light_volumetric_fog", "light_shadow_blur", "viewport_pick_sort", "viewport_hdr2d", "particle_sdf2d_quality",
	"mesh_cull_margin", "animated_texture", "sprite_opaque_prepass",
	"line_round_precision", "gradient_hdr_size", "skin_eight_weights",
	"rigid_sleep_disabled", "rigid_contact_budget",
	"font_msdf_size", "font_subpixel_large", "font_local_mipmaps", "font_oversampling", "textmesh_detail", "label_effect_passes", "panel_corner_detail",
	"compositor_msaa_resolve", "compositor_motion", "compositor_extra_buffers",
	"primitive_density", "path_dense_cache", "navigation_polygons",
	"viewport_shadow_atlas", "viewport_msaa_fxaa", "noise_texture_startup", "noise_texture_octaves",
	"shape_cast_results", "character_slide_budget", "softbody_precision", "audio_unbounded_distance",
	"gridmap_small_octants", "gridmap_navigation_regions",
	"tilemap_small_quadrants", "tilemap_y_sort_groups", "tilemap_navigation_regions", "tilemap_physics_chunking",
	"tilemap_occluders", "tilemap_animation_slices",
	"skeleton_zero_influence", "skeleton_ik_bones", "skeleton2d_zero_strength", "skeleton2d_jiggle_collision_mode", "skeleton2d_jiggle_colliders", "spring_bone_collision_pairs",
	"missing_node", "canvas_modulate_multiple", "timer_short_wait", "shader_globals_inactive",
	"container_plain", "button_group_toggle", "label_autowrap_width", "label_missing_glyphs", "label_msdf_pixel_range",
	"popup_transparency", "subviewport_cursor", "parallax_layer_parent", "voxel_gi_data",
	"occluder_culling_disabled", "tilemap_deprecated", "tilemap_ysort_z", "tilemap_layer_ysort", "tilemap_node_ysort",
	"tilemap_isometric_ysort", "physical_bone2d_parent", "physical_bone2d_bone", "physical_bone2d_joint",
	"physics_body_interpolation", "canvas_group_ancestor", "xr_camera_parent", "xr_node_parent", "xr_node_tracker",
	"xr_node_pose", "xr_interpolation", "xr_origin_camera", "xr_origin_scale", "xr_shaders_disabled", "xr_hand_tracking",
	"openxr_layer_transform", "openxr_layer_hole_punch", "openxr_layer_parent", "openxr_visibility_mask_parent",
	"openxr_render_model_parent", "openxr_render_model_extension", "openxr_render_model_pose",
	"multiplayer_spawner_path", "multiplayer_synchronizer_root", "spring_bone_collision_parent",
	"aim_modifier_axes", "iterate_ik_target", "spline_ik_path", "two_bone_ik_targets", "csg_empty_shape",
	"light_shadow_fade", "decal_normal_fade", "lightmap_directional", "parallax_layers",
	"multimesh_custom_aabb", "trail_mesh_detail", "occluder_dense", "label3d_font_size", "tilemap_kinematic", "shadow_blend_splits",
	"animation_value_transforms", "animation_cubic_3d", "gi_dynamic", "small_shadow_casters",
	"frame_texture_readback", "frame_mesh_bake", "frame_multimesh_buffer", "frame_global_shader_get", "frame_force_sync",
	"frame_find_nodes", "frame_group_calls", "frame_output_latency", "frame_window_title", "frame_capture_rect",
	"frame_tile_update", "frame_bone_global_pose", "frame_navigation_parse", "frame_image_texture_set", "frame_file_flush", "frame_impulse",
	"tile_runtime_update_all", "draw_line_loop", "shader_material_copies", "positional_light_dynamic_bake",
	"jolt_joint_ignored", "jolt_area_wind_ignored", "jolt_shape_bias_ignored", "sky_realtime_radiance", "lightmap_missing_nodes",
	"navmesh_cell_size_mismatch", "obstacle_vertex_height", "transmittance_material", "particle_vector_attractor", "particle_sdf_collider",
	"compositor_pre_opaque_resolved", "compositor_mobile_unsupported", "modifier_bone_missing", "animation_track_unresolved",
	"convex_polygon_concave", "texture_type_unsampled", "aspect_ratio_texture_rect", "sky_realtime", "microphone_stream",
	"openxr_layer_sort_zero", "material_normal_tangents", "shader_normal_roughness", "path_case_mismatch",
	"frame_rendering_sync", "frame_physics_3d_sync", "frame_physics_2d_sync", "navigation_runtime_bake", "navmesh_parses_meshes",
	"modifier_axis_colinear", "instance_uniform_conflict", "flow_fit_texture_rect", "xr_viewport_picking", "xr_pickable_listener",
	"env_bg_canvas", "shader_screen_read", "compositor_transparent_callback", "screen_texture",
	"shader_cooperative_alignment", "shader_cooperative_offset_width", "shader_matrix_muladd", "spring_bone_exclude_order",
	"script_deprecated_call", "script_draw_ignored", "script_theme_in_init", "script_jolt_server_call", "script_emit_particle",
	"ext_resource_uid_invalid", "shader_param_old_names", "mesh_old_surface_format", "animation_expression_base",
	"frame_navigation_force_update", "frame_navigation_bake", "viewport_sss_transparent", "modifier_node_missing", "jolt_singular_basis",
	"subviewport_3d_unused", "auto_exposure", "material_alpha_to_coverage", "color_correction_lut_large",
	"lightmap_data_embedded", "area_light_cost", "fog_density_texture_large",
	"tilemap_scene_tiles", "shader_discard", "body_many_shapes", "obstacle_static_and_dynamic", "frame_navigation_reachable",
]
const ANIMATION_LIBRARY_LIMIT := 32
const ANIMATION_LIMIT := 256
const TRACK_LIMIT := 1024
const LABEL_GLYPH_LIMIT := 4096
const KNOWN_MESHES: PackedStringArray = ["ArrayMesh", "ImmediateMesh", "PlaceholderMesh", "BoxMesh", "CapsuleMesh", "CylinderMesh", "PlaneMesh", "PointMesh", "PrismMesh", "QuadMesh", "SphereMesh", "TextMesh", "TorusMesh", "RibbonTrailMesh", "TubeTrailMesh"]


static func inspect(node: Node, state: Dictionary, path: String) -> void:
	_inspect_engine_warnings(node, state, path)
	if node is TileMapLayer:
		_inspect_tilemap(node, state, path)
	if node is CanvasItem and node.material is ShaderMaterial:
		shader_material_copy(node.material, state, path)
	if node is CollisionObject2D or node is CollisionObject3D:
		var shapes := 0
		for owner_id in node.get_shape_owners():
			if not node.is_shape_owner_disabled(owner_id):
				shapes += node.shape_owner_get_shape_count(owner_id)
		check(state, "body_many_shapes", shapes > 16, path)
	if node is NavigationObstacle2D or node is NavigationObstacle3D:
		check(state, "obstacle_static_and_dynamic", node.avoidance_enabled and node.radius > 0.0 and node.vertices.size() >= 3, path)
	if node is GridMap:
		_inspect_gridmap(node, state, path)
	if node is Path2D or node is Path3D:
		var cutoff := 1.0 if node is Path2D else 0.05
		check(state, "path_dense_cache", node.curve != null and node.curve.get_point_count() >= 2 and node.curve.bake_interval > 0.0 and node.curve.bake_interval < cutoff and not is_equal_approx(node.curve.bake_interval, cutoff), path)
	if node is RigidBody2D or node is RigidBody3D:
		check(state, "rigid_sleep_disabled", not node.freeze and not node.can_sleep, path)
		check(state, "rigid_contact_budget", not node.freeze and node.contact_monitor and node.max_contacts_reported > 32, path)
	if node is CharacterBody2D or node is CharacterBody3D:
		var has_shape := false
		for owner_id in node.get_shape_owners():
			if not node.is_shape_owner_disabled(owner_id) and node.shape_owner_get_shape_count(owner_id) > 0:
				has_shape = true
				break
		check(state, "character_slide_budget", has_shape and node.collision_mask != 0 and node.process_mode != Node.PROCESS_MODE_DISABLED and node.max_slides > (4 if node is CharacterBody2D else 6), path)
	if node is SoftBody3D:
		var enabled: bool = node.process_mode != Node.PROCESS_MODE_DISABLED or node.disable_mode == SoftBody3D.DISABLE_MODE_KEEP_ACTIVE
		check(state, "softbody_precision", enabled and node.mesh != null and node.mesh.get_surface_count() > 0 and node.simulation_precision > 5, path)
	if node is AudioStreamPlayer3D:
		check(state, "audio_unbounded_distance", node.stream != null and (node.autoplay or node.playing) and node.max_distance == 0.0, path)
	if node is VideoStreamPlayer:
		check(state, "hidden_video", _hidden_video(node), path)
	if node is Camera3D or node is WorldEnvironment:
		_inspect_compositor(node, state, path)
		var attributes: CameraAttributes = node.attributes if node is Camera3D else node.camera_attributes
		check(state, "camera_dof_renderer", _practical_dof(attributes), path)
		check(state, "camera_autoexposure_renderer", attributes != null and attributes.auto_exposure_enabled, path)
		check(state, "auto_exposure", attributes != null and attributes.auto_exposure_enabled, path)
		check(state, "camera_blur_amount", _practical_dof(attributes) and attributes.dof_blur_amount > 0.1 and not is_equal_approx(attributes.dof_blur_amount, 0.1), path)
		if node.environment != null:
			inspect_environment(node.environment, state, path)
	if node is Control:
		check(state, "tooltip_mouse_filter", node.mouse_filter == Control.MOUSE_FILTER_IGNORE and not node.tooltip_text.is_empty(), path)
	if node is Panel or node is PanelContainer:
		check(state, "panel_corner_detail", _panel_corner_detail(node), path)
	if node is Label or node is Button or node is Label3D:
		var font: Font = node.font if node is Label3D else node.get_theme_font("font")
		var size: int = node.font_size if node is Label3D else node.get_theme_font_size("font_size")
		if node is Label and node.label_settings != null:
			if node.label_settings.font != null:
				font = node.label_settings.font
			size = node.label_settings.font_size
		if not node.text.is_empty():
			_inspect_font(font, size, state, path, node is Control)
	if node is Label:
		var settings: LabelSettings = node.label_settings
		var outline: int = settings.outline_size if settings != null else node.get_theme_constant("outline_size")
		var outline_color: Color = settings.outline_color if settings != null else node.get_theme_color("font_outline_color")
		var shadow_color: Color = settings.shadow_color if settings != null else node.get_theme_color("font_shadow_color")
		check(state, "label_effect_passes", node.visible_characters != 0 and node.text.length() >= 128 and outline > 0 and outline_color.a > 0.0 and shadow_color.a > 0.0, path)
	if node is Range:
		var bad_min: bool = node.min_value < 0.0 or (Engine.get_version_info().minor == 4 and node.min_value == 0.0)
		check(state, "range_exp_min", node.exp_edit and bad_min, path)
	if node is SpriteBase3D or node is Label3D:
		check(state, "sprite_shaded", node.shaded and node.material_override == null, path)
		check(state, "sprite_opaque_prepass", node.alpha_cut == 2 and node.material_override == null, path)
	if node is Sprite2D or node is Sprite3D or node is TextureRect:
		var texture: Texture2D = node.texture
		var builtin: bool = node.material_override == null if node is Sprite3D else not node.material is ShaderMaterial and not node.use_parent_material
		check(state, "animated_texture", builtin and texture is AnimatedTexture and texture.frames > 1 and not texture.pause and not is_zero_approx(texture.speed_scale), path)
		check(state, "gradient_hdr_size", builtin and texture is GradientTexture2D and texture.use_hdr and texture.width * texture.height >= 512 * 512, path)
		if builtin:
			_inspect_noise(texture, state, path)
	if node is FogVolume and node.material is FogMaterial:
		_inspect_noise(node.material.density_texture, state, path)
	if node is Line2D:
		var drawable: bool = node.points.size() >= 2 and node.width > 0.0 and (node.is_visible_in_tree() if node.is_inside_tree() else node.visible)
		var rounded: bool = (node.points.size() >= 3 and node.joint_mode == Line2D.LINE_JOINT_ROUND) or ((not node.closed or node.points.size() == 2) and (node.begin_cap_mode == Line2D.LINE_CAP_ROUND or node.end_cap_mode == Line2D.LINE_CAP_ROUND))
		check(state, "line_round_precision", drawable and rounded and node.round_precision > 8, path)
	if node is NavigationAgent2D or node is NavigationAgent3D:
		check(state, "navigation_layers", node.navigation_layers == 0, path)
		check(state, "navigation_neighbors", node.avoidance_enabled and node.neighbor_distance > 0.0 and node.max_neighbors > 10, path)
	elif node is NavigationRegion2D or node is NavigationRegion3D or node is NavigationLink2D or node is NavigationLink3D:
		check(state, "navigation_layers", node.enabled and node.navigation_layers == 0, path)
	if node is NavigationLink2D or node is NavigationLink3D:
		check(state, "navigation_link_endpoints", node.enabled and node.start_position.is_equal_approx(node.end_position), path)
	if node is AnimationMixer and node.active and node.is_inside_tree():
		check(state, "animation_mixer_root", node.get_node_or_null(node.root_node) == null, path)
		check(state, "animation_track_unresolved", _animation_track_unresolved(node, state), path)
		if node is AnimationTree:
			check(state, "animation_expression_base", node.get_node_or_null(node.advance_expression_base_node) == null and _state_machine_expression(node.tree_root, 0), path)
	if node is CanvasItem and node.clip_children != CanvasItem.CLIP_CHILDREN_DISABLED:
		var ancestor: CanvasItem = null if node.top_level else node.get_parent() as CanvasItem
		var group_clip := false
		var nested_clip := false
		while ancestor != null:
			group_clip = group_clip or ancestor is CanvasGroup
			nested_clip = nested_clip or ancestor.clip_children != CanvasItem.CLIP_CHILDREN_DISABLED
			if ancestor.top_level:
				break
			ancestor = ancestor.get_parent() as CanvasItem
		check(state, "canvas_group_clip", group_clip, path)
		check(state, "canvas_nested_clip", nested_clip, path)
	if node is CollisionObject2D or node is CollisionObject3D:
		check(state, "collision_object_empty", node.is_inside_tree() and node.get_shape_owners().is_empty(), path)
		if node is CollisionObject3D:
			check(state, "collision_nonuniform", _nonuniform(node.scale), path)
	if node is GeometryInstance3D:
		check(state, "geometry_layers", node.layers == 0, path)
		var fade: bool = node.visibility_range_fade_mode != GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		check(state, "visibility_range_invalid", not is_zero_approx(node.visibility_range_end) and node.visibility_range_end <= node.visibility_range_begin, path)
		check(state, "visibility_fade_begin", fade and not is_zero_approx(node.visibility_range_begin) and is_zero_approx(node.visibility_range_begin_margin), path)
		check(state, "visibility_fade_end", fade and not is_zero_approx(node.visibility_range_end) and is_zero_approx(node.visibility_range_end_margin), path)
		check(state, "geometry_transparency", node.transparency > 0.0, path)
		check(state, "geometry_fade", fade, path)
		check(state, "geometry_fade_cost", not _draws_nothing(node) and fade and (node.visibility_range_end == 0.0 or node.visibility_range_end > node.visibility_range_begin) and ((node.visibility_range_begin > 0.0 and node.visibility_range_begin_margin > 0.0) or (node.visibility_range_end > 0.0 and node.visibility_range_end_margin > 0.0)), path)
	if node is GPUParticles3D or node is GPUParticles2D:
		check(state, "particle_turbulence", node.process_material is ParticleProcessMaterial and node.process_material.turbulence_enabled, path)
		if node.process_material is ParticleProcessMaterial:
			var process: ParticleProcessMaterial = node.process_material
			var points := process.emission_shape in [ParticleProcessMaterial.EMISSION_SHAPE_POINTS, ParticleProcessMaterial.EMISSION_SHAPE_DIRECTED_POINTS]
			check(state, "particle_points_data", points and (process.emission_point_texture == null or process.emission_point_count <= 0 or (process.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_DIRECTED_POINTS and process.emission_normal_texture == null)), path)
		if node.is_inside_tree() and not node.sub_emitter.is_empty():
			var target := node.get_node_or_null(node.sub_emitter)
			check(state, "particle_subemitter_target", target == node or not (target is GPUParticles3D if node is GPUParticles3D else target is GPUParticles2D), path)
		var steps: float = node.preprocess * (node.fixed_fps if node.fixed_fps > 0 else 30)
		check(state, "particle_warmup", steps >= 120.0, path)
		check(state, "gpu_process_missing", node.process_material == null, path)
		check(state, "trails_renderer", node.trail_enabled, path)
		check(state, "subemitter_renderer", not node.sub_emitter.is_empty(), path)
		if node is GPUParticles3D:
			check(state, "gpu_depth_sort", node.draw_order == GPUParticles3D.DRAW_ORDER_VIEW_DEPTH and node.amount > 1, path)
			_particles_3d(node, state, path)
		else:
			var mat: Material = node.material
			check(state, "particle_trail_segments", node.trail_enabled and node.trail_sections * node.trail_section_subdivisions > 32, path)
			if node.is_inside_tree() and node.process_material is ParticleProcessMaterial and node.process_material.collision_mode != ParticleProcessMaterial.COLLISION_DISABLED:
				var viewport := node.get_viewport()
				check(state, "particle_sdf2d_quality", viewport.sdf_scale == Viewport.SDF_SCALE_100_PERCENT or viewport.sdf_oversize > Viewport.SDF_OVERSIZE_120_PERCENT, path)
			check(state, "particles_animation_2d", _animated(node.process_material) and (mat == null or (mat is CanvasItemMaterial and not mat.particles_animation)), path)
	elif node is CPUParticles3D:
		check(state, "cpu_particle_sort", node.draw_order != CPUParticles3D.DRAW_ORDER_INDEX and node.amount >= 64, path)
		check(state, "cpu_mesh_missing", node.mesh == null, path)
		_particles_3d(node, state, path)
	elif node is CPUParticles2D:
		check(state, "cpu_particle_sort", node.draw_order == CPUParticles2D.DRAW_ORDER_LIFETIME and node.amount >= 64, path)
		check(state, "particles_animation_2d", _animated(node) and (node.material == null or (node.material is CanvasItemMaterial and not node.material.particles_animation)), path)
	elif node is Decal:
		check(state, "decal_textures", node.texture_albedo == null and node.texture_normal == null and node.texture_orm == null and node.texture_emission == null, path)
		check(state, "decal_albedo", node.texture_albedo == null and (node.texture_normal != null or node.texture_orm != null), path)
		check(state, "decal_mask", node.cull_mask == 0, path)
	elif node is Light3D:
		var active_light: bool = not node.editor_only and (node.is_visible_in_tree() if node.is_inside_tree() else node.visible)
		check(state, "light_shadow_blur", active_light and node.shadow_enabled and node.shadow_blur > 1.0, path)
		var fog_env := effective_environment(node)
		check(state, "light_volumetric_fog", active_light and node.light_energy > 0.0 and node.light_volumetric_fog_energy > 0.0 and fog_env != null and fog_env.volumetric_fog_enabled, path)
		check(state, "light_cull_mask", node.light_cull_mask == 0, path)
		check(state, "light_scale", not node.scale.is_equal_approx(Vector3.ONE), path)
		if node is OmniLight3D or node is SpotLight3D:
			check(state, "projector_shadows", node.light_projector != null and not node.shadow_enabled, path)
			check(state, "projector_renderer", node.light_projector != null, path)
		if node is SpotLight3D:
			check(state, "spot_shadows", node.shadow_enabled and node.spot_angle >= 90.0, path)
		# AreaLight3D is absent in 4.4; do not reference its type at parse time.
		if node.is_class("AreaLight3D"):
			check(state, "area_projector", node.light_projector != null, path)
			check(state, "area_texture", node.get("area_texture") != null, path)
			check(state, "area_shadows", node.shadow_enabled, path)
			check(state, "area_light_cost", active_light and node.light_energy > 0.0, path)
	elif node is FogVolume:
		check(state, "fog_renderer", true, path)
		var density: Texture3D = node.material.density_texture as Texture3D if node.material is FogMaterial else null
		check(state, "fog_density_texture_large", density != null and maxi(density.get_width(), maxi(density.get_height(), density.get_depth())) > 64, path)
		var env := effective_environment(node)
		check(state, "fog_environment", env != null and not env.volumetric_fog_enabled, path)
	elif node is VoxelGI:
		check(state, "voxel_renderer", true, path)
	elif node is OccluderInstance3D:
		check(state, "occluder_missing", node.occluder == null, path)
		check(state, "occluder_bake_mask", node.bake_mask == 0, path)
		if node.occluder is ArrayOccluder3D:
			check(state, "occluder_empty", node.occluder.indices.size() < 3, path)
		elif node.occluder is PolygonOccluder3D:
			check(state, "occluder_empty", node.occluder.polygon.size() < 3, path)
	elif node is CollisionShape3D or node is CollisionShape2D:
		var parent: Node = node.get_parent()
		check(state, "collision_parent", not (parent is CollisionObject3D if node is CollisionShape3D else parent is CollisionObject2D), path)
		check(state, "collision_resource", node.shape == null, path)
		if node is CollisionShape3D:
			check(state, "jolt_shape_bias_ignored", node.shape != null and not is_zero_approx(node.shape.custom_solver_bias), path)
			check(state, "collision_nonuniform", _nonuniform(node.scale), path)
			var moving: bool = parent is CharacterBody3D or (parent is RigidBody3D and not (parent.freeze and parent.freeze_mode == RigidBody3D.FREEZE_MODE_STATIC))
			check(state, "concave_dynamic", moving and node.shape is ConcavePolygonShape3D, path)
			check(state, "boundary_dynamic", parent is RigidBody3D and moving and node.shape is WorldBoundaryShape3D, path)
		else:
			check(state, "one_way_area", parent is Area2D and node.one_way_collision, path)
	elif node is CollisionPolygon3D or node is CollisionPolygon2D:
		var parent: Node = node.get_parent()
		check(state, "collision_polygon_parent", not (parent is CollisionObject3D if node is CollisionPolygon3D else parent is CollisionObject2D), path)
		check(state, "collision_polygon_empty", node.polygon.is_empty(), path)
		if node is CollisionPolygon3D:
			check(state, "collision_nonuniform", _nonuniform(node.scale), path)
		else:
			check(state, "one_way_area", parent is Area2D and node.one_way_collision, path)
			var minimum := 3 if node.build_mode == CollisionPolygon2D.BUILD_SOLIDS else 2
			check(state, "collision_polygon_points", not node.polygon.is_empty() and node.polygon.size() < minimum, path)
	elif node is RigidBody3D:
		check(state, "rigid_scale", absf(node.scale.x - 1.0) > 0.05 or absf(node.scale.y - 1.0) > 0.05 or absf(node.scale.z - 1.0) > 0.05, path)
	elif node is RigidBody2D:
		check(state, "rigid_scale", absf(node.transform.x.length() - 1.0) > 0.05 or absf(node.transform.y.length() - 1.0) > 0.05, path)
	elif node is MeshInstance3D or node is MeshInstance2D:
		check(state, "mesh_missing", node.mesh == null, path)
		check(state, "primitive_density", _primitive_vertex_floor(node.mesh) >= 8192.0, path)
		if node.mesh is TextMesh:
			check(state, "textmesh_detail", not node.mesh.text.strip_edges().is_empty() and (node.mesh.curve_step < 0.5 or node.mesh.font_size > 63), path)
		if node is MeshInstance3D and node.mesh is ArrayMesh and node.extra_cull_margin > 0.0:
			var bounds: AABB = node.mesh.custom_aabb
			if node.custom_aabb != AABB():
				bounds = node.custom_aabb
			elif bounds == AABB():
				bounds = node.mesh.get_aabb()
			var span := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
			check(state, "mesh_cull_margin", span > 0.0 and node.extra_cull_margin > span, path)
		if node is MeshInstance3D and node.mesh is ArrayMesh and node.is_inside_tree():
			var skeleton := node.get_node_or_null(node.skeleton) as Skeleton3D
			if skeleton != null and skeleton.get_bone_count() > 0:
				var boned := false
				var eight_weights := false
				for surface in range(node.mesh.get_surface_count()):
					var format: int = node.mesh.surface_get_format(surface)
					boned = boned or bool(format & Mesh.ARRAY_FORMAT_BONES)
					eight_weights = eight_weights or bool(format & Mesh.ARRAY_FORMAT_BONES and format & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS)
				check(state, "skin_dynamic_bounds", boned and node.custom_aabb == AABB() and node.mesh.custom_aabb == AABB(), path)
				check(state, "skin_eight_weights", eight_weights, path)
	elif node is WorldEnvironment:
		check(state, "worldenv_empty", node.environment == null and node.camera_attributes == null and node.compositor == null, path)
		if node.is_inside_tree():
			var world: World3D = node.get_viewport().find_world_3d()
			check(state, "worldenv_conflict", (node.environment != null and node.environment != world.environment) or (node.camera_attributes != null and node.camera_attributes != world.camera_attributes) or (node.compositor != null and _world_compositor_owner(node) != node), path)
	elif node is PointLight2D:
		check(state, "point_light_texture", node.texture == null, path)
	elif node is LightOccluder2D:
		check(state, "light_occluder_missing", node.occluder == null, path)
		check(state, "light_occluder_empty", node.occluder != null and node.occluder.polygon.is_empty(), path)
	elif node is GPUParticlesCollision3D:
		check(state, "particle_collider_mask", node.cull_mask == 0, path)
		if node.is_inside_tree():
			check(state, "particle_collision_scale", _nonuniform(node.global_basis.get_scale().abs()), path)
		if node is GPUParticlesCollisionSDF3D:
			check(state, "particle_sdf_collider", true, path)
			check(state, "particle_sdf_bake_mask", node.bake_mask == 0, path)
			check(state, "particle_sdf_texture", node.texture == null, path)
			if node.texture != null:
				check(state, "particle_sdf_large", maxi(node.texture.get_width(), maxi(node.texture.get_height(), node.texture.get_depth())) >= 256, path)
		elif node is GPUParticlesCollisionHeightField3D:
			check(state, "particle_heightfield_always", node.update_mode == GPUParticlesCollisionHeightField3D.UPDATE_MODE_ALWAYS, path)
			check(state, "heightfield_camera", node.follow_camera_enabled and node.update_mode == GPUParticlesCollisionHeightField3D.UPDATE_MODE_WHEN_MOVED, path)
	elif node is GPUParticlesAttractor3D:
		check(state, "particle_attractor_mask", node.cull_mask == 0, path)
		if node is GPUParticlesAttractorVectorField3D:
			check(state, "particle_vector_attractor", true, path)
			check(state, "particle_vector_texture", node.texture == null, path)
			if node.texture != null:
				var voxels: int = node.texture.get_width() * node.texture.get_height() * node.texture.get_depth()
				check(state, "particle_vector_resolution", not is_zero_approx(node.strength) and node.cull_mask != 0 and voxels > 64 * 64 * 64, path)
	elif node is SubViewportContainer:
		check(state, "viewport_shrink_ignored", not node.stretch and node.stretch_shrink > 1, path)
		var has_viewport := false
		for child in node.get_children():
			has_viewport = has_viewport or child is SubViewport
		check(state, "viewport_container_child", not has_viewport, path)
	elif node is SubViewport:
		var updates: bool = node.render_target_update_mode != SubViewport.UPDATE_DISABLED
		check(state, "viewport_shadow_atlas", updates and not node.disable_3d and node.positional_shadow_atlas_size > 0 and (node.positional_shadow_atlas_size > 2048 or not node.positional_shadow_atlas_16_bits), path)
		check(state, "viewport_msaa_fxaa", updates and not node.disable_3d and node.msaa_3d != Viewport.MSAA_DISABLED and node.screen_space_aa == Viewport.SCREEN_SPACE_AA_FXAA, path)
		check(state, "viewport_pick_sort", node.physics_object_picking and node.physics_object_picking_sort and not node.gui_disable_input, path)
		check(state, "viewport_hdr2d", updates and node.use_hdr_2d, path)
		check(state, "viewport_lod_disabled", updates and not node.disable_3d and node.mesh_lod_threshold == 0.0, path)
		check(state, "viewport_supersampling", updates and not node.disable_3d and node.scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR and node.scaling_3d_scale > 1.0, path)
		check(state, "viewport_msaa_2d", updates and node.msaa_2d >= Viewport.MSAA_4X, path)
		var env := effective_environment(node)
		check(state, "viewport_ssr_transparent", node.transparent_bg and env != null and env.ssr_enabled, path)
		check(state, "viewport_sss_transparent", node.transparent_bg and not node.disable_3d and int(_setting(state, "rendering/environment/subsurface_scattering/subsurface_scattering_quality", 1)) != 0 and _subtree_uses_sss(node), path)
		if node.is_inside_tree():
			var camera: Camera3D = node.get_camera_3d()
			var attributes: CameraAttributes = camera.attributes if camera != null and camera.attributes != null else node.find_world_3d().camera_attributes
			check(state, "viewport_dof_transparent", node.transparent_bg and _practical_dof(attributes), path)
	elif node is AnimatedSprite2D or node is AnimatedSprite3D:
		check(state, "sprite_frames_missing", node.sprite_frames == null, path)
	elif node is PathFollow2D or node is PathFollow3D:
		var parent: Node = node.get_parent()
		check(state, "path_follow_parent", not (parent is Path3D if node is PathFollow3D else parent is Path2D), path)
		if (node is PathFollow3D and parent is Path3D) or (node is PathFollow2D and parent is Path2D):
			check(state, "path_curve_data", parent.curve == null or parent.curve.get_point_count() < 2, path)
		if node is PathFollow3D and parent is Path3D:
			check(state, "path_follow_up_vector", parent.curve != null and not parent.curve.up_vector_enabled and node.rotation_mode == PathFollow3D.ROTATION_ORIENTED, path)
	elif node is RemoteTransform2D or node is RemoteTransform3D:
		if node.is_inside_tree():
			var target: Node = node.get_node_or_null(node.remote_path) if not node.remote_path.is_empty() else null
			var invalid: bool = not (target is Node3D if node is RemoteTransform3D else target is Node2D)
			check(state, "remote_transform_target", invalid or target == node or (target != null and (target.is_ancestor_of(node) or node.is_ancestor_of(target))), path)
	elif node is NavigationAgent3D or node is NavigationAgent2D:
		check(state, "navigation_agent_parent", not (node.get_parent() is Node3D if node is NavigationAgent3D else node.get_parent() is Node2D), path)
	elif node is NavigationRegion3D or node is NavigationRegion2D:
		check(state, "navigation_region_missing", node.enabled and (node.navigation_mesh == null if node is NavigationRegion3D else node.navigation_polygon == null), path)
		check(state, "navmesh_cell_size_mismatch", node.enabled and _navmesh_cell_mismatch(node, state), path)
		check(state, "navmesh_parses_meshes", node is NavigationRegion3D and node.enabled and node.navigation_mesh != null and node.navigation_mesh.geometry_parsed_geometry_type != NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS, path)
		if node is NavigationRegion3D:
			check(state, "navigation_polygons", node.enabled and node.navigation_layers != 0 and node.navigation_mesh != null and node.navigation_mesh.get_polygon_count() > 8192, path)
	elif node is NavigationObstacle3D and node.is_inside_tree():
		var rotation: Vector3 = node.global_rotation
		var scale: Vector3 = node.global_basis.get_scale()
		check(state, "navigation_obstacle_rotation", not is_zero_approx(rotation.x) or not is_zero_approx(rotation.z), path)
		check(state, "navigation_obstacle_scale", scale.x < 0.001 or scale.y < 0.001 or scale.z < 0.001, path)
		check(state, "navigation_obstacle_nonuniform", node.radius > 0.0 and not node.global_basis.is_conformal(), path)
		var raised := false
		for vertex in node.vertices:
			raised = raised or vertex.y != 0.0
		check(state, "obstacle_vertex_height", raised, path)
	elif node is NavigationObstacle2D and node.is_inside_tree():
		var scale: Vector2 = node.global_scale
		check(state, "navigation_obstacle_scale", scale.x < 0.001 or scale.y < 0.001, path)
		check(state, "navigation_obstacle_nonuniform", node.radius > 0.0 and not node.global_transform.is_conformal(), path)
		check(state, "navigation_obstacle_skew", node.radius > 0.0 and not is_zero_approx(node.get_global_transform().get_skew()), path)
	elif node is BoneAttachment3D:
		check(state, "bone_attachment_parent", not node.get_use_external_skeleton() and not node.get_parent() is Skeleton3D, path)
		if node.get_use_external_skeleton() and node.is_inside_tree():
			var target := node.get_node_or_null(node.get_external_skeleton()) if not node.get_external_skeleton().is_empty() else null
			check(state, "bone_attachment_external", not target is Skeleton3D, path)
		# A scene may store only bone_name; Godot resolves the index when the node enters the tree (_check_bind).
		var bone_skeleton := node.get_parent() as Skeleton3D if not node.get_use_external_skeleton() else null
		var resolvable: bool = node.bone_idx >= 0 or (bone_skeleton != null and bone_skeleton.find_bone(node.bone_name) >= 0) or (node.get_use_external_skeleton() and not node.is_inside_tree())
		check(state, "bone_attachment_bone", not resolvable, path)
	elif node is Bone2D:
		var ancestor := node.get_parent()
		while ancestor is Bone2D:
			ancestor = ancestor.get_parent()
		check(state, "bone2d_hierarchy", not ancestor is Skeleton2D, path)
		check(state, "bone2d_rest", node.rest == Transform2D(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO), path)
	elif node is Skeleton2D:
		_skeleton2d_checks(node, state, path)
	elif node is SkeletonModifier3D:
		check(state, "skeleton_modifier_parent", node.active and not node.get_parent() is Skeleton3D, path)
		check(state, "modifier_bone_missing", _modifier_bone_missing(node, node.get_parent() as Skeleton3D), path)
		check(state, "modifier_node_missing", node.is_inside_tree() and _modifier_node_missing(node), path)
		check(state, "modifier_axis_colinear", _modifier_axis_colinear(node, node.get_parent() as Skeleton3D), path)
		check(state, "skeleton_zero_influence", _skeleton_zero_influence(node), path)
		if node is SpringBoneSimulator3D:
			check(state, "spring_bone_collision_pairs", _spring_bone_collision_pairs(node) > 128, path)
			check(state, "spring_bone_exclude_order", _spring_bone_exclude_unordered(node), path)
		if node.is_class("SkeletonIK3D"):
			check(state, "skeleton_ik_bones", _skeleton_ik_bones(node), path)
		if node.active and node is LookAtModifier3D:
			check(state, "look_at_axes", int(node.forward_axis / 2) == node.primary_rotation_axis, path)
			var skeleton := node.get_parent() as Skeleton3D
			if node.is_inside_tree():
				check(state, "look_at_bone", skeleton != null and (node.bone < 0 or node.bone >= skeleton.get_bone_count()), path)
				check(state, "look_at_target", not node.target_node.is_empty() and not node.get_node_or_null(node.target_node) is Node3D, path)
		elif node.active and node is RetargetModifier3D:
			check(state, "retarget_profile", node.profile == null, path)
			var has_skeleton := false
			for child in node.get_children():
				has_skeleton = has_skeleton or child is Skeleton3D
			check(state, "retarget_children", not has_skeleton, path)
	elif node is AnimationTree:
		check(state, "animation_tree_root", node.tree_root == null, path)
	elif node is CanvasGroup:
		check(state, "canvas_group_mipmaps", node.use_mipmaps, path)
		check(state, "canvas_group_margins", node.clear_margin > 10.0 or node.fit_margin > 10.0, path)
	elif node is ScrollContainer:
		var content_count := 0
		for child in node.get_children():
			if child is Control and child.visible and not child.top_level:
				content_count += 1
		check(state, "scroll_container_children", content_count != 1, path)
	elif node is TextureRect and node.stretch_mode == TextureRect.STRETCH_TILE:
		var texture: Texture2D = node.texture
		var visited := {}
		while texture is AtlasTexture and visited.size() < 16 and not visited.has(texture.get_instance_id()):
			visited[texture.get_instance_id()] = true
			if texture.margin != Rect2():
				check(state, "texture_rect_atlas_tile", true, path)
				break
			texture = texture.atlas
	elif node is Camera3D:
		check(state, "camera_cull_mask", node.cull_mask == 0, path)
	elif node is ShapeCast2D or node is ShapeCast3D:
		check(state, "shape_cast_resource", node.shape == null, path)
		check(state, "shape_cast_concave", node is ShapeCast3D and node.shape is ConcavePolygonShape3D, path)
		check(state, "shape_cast_results", node.enabled and node.shape != null and not node.shape is ConcavePolygonShape3D and node.collision_mask != 0 and (node.collide_with_bodies or node.collide_with_areas) and node.max_results > 32, path)
	elif node is VehicleWheel3D:
		check(state, "vehicle_wheel_parent", not node.get_parent() is VehicleBody3D, path)
	elif (node is Joint2D or node is Joint3D) and node.is_inside_tree():
		var a := node.get_node_or_null(node.node_a) if not node.node_a.is_empty() else null
		var b := node.get_node_or_null(node.node_b) if not node.node_b.is_empty() else null
		var body_a: bool = a is PhysicsBody2D if node is Joint2D else a is PhysicsBody3D
		var body_b: bool = b is PhysicsBody2D if node is Joint2D else b is PhysicsBody3D
		var missing: bool = (not body_a or not body_b) if node is Joint2D else (not body_a and not body_b)
		check(state, "joint_targets", missing or a == b or (a != null and not body_a) or (b != null and not body_b), path)
		if node is Joint3D:
			check(state, "jolt_joint_ignored", _jolt_ignored_joint_param(node), path)
	elif node is LightmapGI:
		var missing_users := false
		if node.light_data != null and node.is_inside_tree():
			for index in mini(node.light_data.get_user_count(), 4096):
				missing_users = missing_users or node.get_node_or_null(node.light_data.get_user_path(index)) == null
		check(state, "lightmap_missing_nodes", missing_users, path)
		check(state, "lightmap_shadowmask", node.shadowmask_mode != LightmapGIData.SHADOWMASK_MODE_NONE and node.light_data != null and node.light_data.shadowmask_textures.is_empty(), path)
	elif node is ReflectionProbe:
		check(state, "probe_lod_disabled", node.mesh_lod_threshold == 0.0 and node.cull_mask != 0, path)
	elif node is BackBufferCopy:
		var visible: bool = node.is_visible_in_tree() if node.is_inside_tree() else node.visible
		check(state, "backbuffer_full", visible and (node.copy_mode == BackBufferCopy.COPY_MODE_VIEWPORT or (node.copy_mode == BackBufferCopy.COPY_MODE_RECT and node.rect == Rect2())), path)
	elif node is CSGShape3D and not node.get_parent() is CSGShape3D:
		for child in node.get_children():
			if child is CSGShape3D:
				check(state, "csg_composition", true, path)
				break
	elif node is RichTextLabel:
		check(state, "richtext_sync", not node.threaded and node.get_total_character_count() > 32768, path)


## Native get_configuration_warnings() predicates that are not script-callable; see docs/GODOT_COVERAGE.json.
static func _inspect_engine_warnings(node: Node, state: Dictionary, path: String) -> void:
	# Each warning's first version comes from diffing get_configuration_warnings() across 4.4, 4.5.2, 4.6.3 and 4.7.2.
	var minor: int = Engine.get_version_info().minor if Engine.get_version_info().major == 4 else 99
	var in_tree := node.is_inside_tree()
	if node.get_class() == "MissingNode":
		check(state, "missing_node", true, "%s [original_class=%s; original_scene=%s]" % [path, node.get("original_class"), node.get("original_scene")])
	if node is CanvasModulate:
		check(state, "canvas_modulate_multiple", in_tree and node.is_visible_in_tree() and node.get_tree().get_nodes_in_group("_canvas_modulate_%d" % node.get_canvas().get_id()).size() > 1, path)
	if node is Timer:
		check(state, "timer_short_wait", node.wait_time < 0.05 - 0.00001, path)
	if node is ShaderGlobalsOverride:
		check(state, "shader_globals_inactive", in_tree and not node.is_in_group("_shader_overrides_group_active_"), path)
	if node.get_class() == "Container":
		check(state, "container_plain", node.get_script() == null, path)
	if node is BaseButton:
		check(state, "button_group_toggle", node.button_group != null and not node.toggle_mode, path)
	if node is Label:
		_inspect_label_warnings(node, state, path, minor)
	if node is PopupPanel or node is PopupMenu or node is MenuButton or node is OptionButton:
		check(state, "popup_transparency", _popup_needs_transparency(node.get_popup() if node is MenuButton or node is OptionButton else node, state), path)
	if node is SubViewportContainer:
		check(state, "subviewport_cursor", node.mouse_default_cursor_shape != Control.CURSOR_ARROW, path)
	if node is ParallaxLayer:
		check(state, "parallax_layer_parent", not node.get_parent() is ParallaxBackground, path)
	if node is VoxelGI:
		check(state, "voxel_gi_data", node.data == null, path)
	if node is OccluderInstance3D:
		check(state, "occluder_culling_disabled", not bool(_setting(state, "rendering/occlusion_culling/use_occlusion_culling", false)), path)
	if node is TileMap:
		_inspect_tilemap_node(node, state, path)
	if node is PhysicalBone2D:
		var skeleton: Node = node.get_parent()
		while skeleton is PhysicalBone2D:
			skeleton = skeleton.get_parent()
		var joint := false
		for child in node.get_children(true):
			joint = joint or child is Joint2D
		check(state, "physical_bone2d_parent", not skeleton is Skeleton2D, path)
		check(state, "physical_bone2d_bone", skeleton is Skeleton2D and node.bone2d_index <= -1, path)
		check(state, "physical_bone2d_joint", not joint and node.get_parent() is PhysicalBone2D, path)
	var interpolation := bool(_setting(state, "physics/common/physics_interpolation", false))
	if minor >= 5 and (node is PhysicsBody2D or node is PhysicsBody3D):
		check(state, "physics_body_interpolation", interpolation and not _physics_interpolated(node), path)
	# Only the root result is exposed; an empty root brush makes Godot warn on the root and every child shape.
	if node is CSGShape3D and in_tree:
		var csg_root: Node = node
		while csg_root.get_parent() is CSGShape3D:
			csg_root = csg_root.get_parent()
		check(state, "csg_empty_shape", _csg_result_empty(csg_root), path)
	if minor >= 5 and node is CanvasGroup and in_tree:
		var ancestor := node.get_parent()
		var conflict := false
		while ancestor != null and not conflict:
			conflict = ancestor is CanvasGroup or (ancestor is CanvasItem and ancestor.clip_children != CanvasItem.CLIP_CHILDREN_DISABLED)
			ancestor = ancestor.get_parent()
		check(state, "canvas_group_ancestor", conflict, path)
	_inspect_xr_warnings(node, state, path, minor, interpolation)
	_inspect_documented_costs(node, state, path)
	# The multiplayer module can be compiled out, so its classes are matched by name.
	if node.is_class("MultiplayerSpawner"):
		var spawn: NodePath = node.get("spawn_path")
		if in_tree or not spawn.is_absolute():
			check(state, "multiplayer_spawner_path", spawn.is_empty() or not node.has_node(spawn), path)
	if node.is_class("MultiplayerSynchronizer"):
		var root: NodePath = node.get("root_path")
		if in_tree or not root.is_absolute():
			check(state, "multiplayer_synchronizer_root", root.is_empty() or not node.has_node(root), path)
	if node is SpringBoneCollision3D:
		check(state, "spring_bone_collision_parent", not node.get_parent() is SpringBoneSimulator3D, path)
		var simulator := node.get_parent()
		check(state, "modifier_bone_missing", simulator is SpringBoneSimulator3D and _modifier_bone_missing(node, simulator.get_parent() as Skeleton3D), path)
	if (node is CollisionObject3D or node is CollisionShape3D) and in_tree:
		# Jolt tests for an exactly singular basis; tiny but nonzero scales are valid.
		check(state, "jolt_singular_basis", node.global_basis.determinant() == 0.0, path)
	if node is CollisionShape2D and node.shape is ConvexPolygonShape2D:
		check(state, "convex_polygon_concave", _concave(node.shape.points), path)
	if node is Decal:
		check(state, "texture_type_unsampled", _unsampled_texture(node.texture_albedo) or _unsampled_texture(node.texture_normal) or _unsampled_texture(node.texture_orm) or _unsampled_texture(node.texture_emission), path)
	elif node is Light3D:
		check(state, "texture_type_unsampled", _unsampled_texture(node.light_projector) or _unsampled_texture(node.get("area_texture")), path)
	elif node is PointLight2D:
		check(state, "texture_type_unsampled", _unsampled_texture(node.texture), path)
	if node is TextureRect and node.get_parent() is AspectRatioContainer:
		check(state, "aspect_ratio_texture_rect", node.expand_mode in [TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL, TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL], path)
	if node is GeometryInstance3D:
		check(state, "instance_uniform_conflict", _instance_uniform_conflict(node), path)
	if node is TextureRect and node.get_parent() is FlowContainer:
		check(state, "flow_fit_texture_rect", node.get_parent().get_line_count() > 1 and node.expand_mode in [TextureRect.EXPAND_FIT_WIDTH, TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL, TextureRect.EXPAND_FIT_HEIGHT, TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL], path)
	if node is SubViewport:
		check(state, "xr_viewport_picking", node.use_xr and node.physics_object_picking, path)
	if node is CollisionObject3D:
		var listens: bool = node.get_signal_connection_list("input_event").size() > 0 or (node.get_script() != null and node.get_script().get_script_method_list().any(func(method): return method.name == "_input_event"))
		check(state, "xr_pickable_listener", node.input_ray_pickable and listens, path)
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		check(state, "microphone_stream", node.stream is AudioStreamMicrophone, path)

	# Godot 4.5+ warns about parallel AimModifier3D axes; no node path is read, so scans outside the tree check it too.
	if minor >= 5 and node.is_class("AimModifier3D"):
		var parallel := false
		for index in mini(int(node.get("setting_count")) if node.get("setting_count") != null else 0, 128):
			parallel = parallel or (node.call("is_using_euler", index) and int(node.call("get_forward_axis", index)) / 2 == int(node.call("get_primary_rotation_axis", index)))
		check(state, "aim_modifier_axes", parallel, path)
	# Absolute target paths cannot be resolved outside a tree.
	if minor >= 6 and in_tree and node is SkeletonModifier3D:
		_inspect_ik_settings(node, state, path)


static func _inspect_label_warnings(node: Label, state: Dictionary, path: String, minor: int) -> void:
	if minor >= 7:
		check(state, "label_autowrap_width", node.is_inside_tree() and node.autowrap_mode != TextServer.AUTOWRAP_OFF and node.call("get_combined_maximum_size").x <= 0 and node.custom_minimum_size.x <= 0, path)
	else:
		check(state, "label_autowrap_width", node.get_parent_control() is Container and node.autowrap_mode != TextServer.AUTOWRAP_OFF and node.custom_minimum_size == Vector2.ZERO, path)
	var settings: LabelSettings = node.label_settings
	var font: Font = settings.font if settings != null and settings.font != null else node.get_theme_font("font")
	var size: int = settings.font_size if settings != null else node.get_theme_font_size("font_size")
	if font == null:
		return
	check(state, "label_missing_glyphs", _missing_glyph(node.text.to_upper() if node.uppercase else node.text, font, size, minor >= 5), path)
	if minor < 6 or not font is FontFile or not font.multichannel_signed_distance_field or font.msdf_size <= 0:
		return
	var outline: int = settings.outline_size if settings != null else node.get_theme_constant("outline_size")
	if settings != null:
		for index in settings.get("stacked_outline_count"):
			outline += maxi(0, settings.call("get_stacked_outline_size", index))
		for index in settings.get("stacked_shadow_count"):
			outline = maxi(outline, settings.call("get_stacked_shadow_outline_size", index))
	var scale := float(size) / float(font.msdf_size)
	check(state, "label_msdf_pixel_range", scale > 0.0 and float(outline) / scale / 4.0 > float(font.msdf_pixel_range) / 2.0 - 1.0, path)


## Shapes the label text like Label does and reports glyphs no font (or fallback) can render.
static func _missing_glyph(text: String, font: Font, size: int, skip_index_zero: bool) -> bool:
	if text.is_empty() or text.length() > LABEL_GLYPH_LIMIT:
		return false
	var server := TextServerManager.get_primary_interface()
	for paragraph in text.split("\n"):
		var shaped := server.create_shaped_text()
		server.shaped_text_add_string(shaped, paragraph, font.get_rids(), size)
		var glyphs := server.shaped_text_get_glyphs(shaped)
		server.free_rid(shaped)
		for glyph: Dictionary in glyphs:
			if glyph.get("font_rid", RID()) == RID() and (not skip_index_zero or int(glyph.get("index", 0)) != 0):
				return true
	return false


## Checks on an Environment resource: a WorldEnvironment's, a camera's or the project's default environment.
static func inspect_environment(env: Environment, state: Dictionary, path: String) -> void:
	check(state, "fog_aerial", env.fog_enabled and env.fog_aerial_perspective > 0.0 and env.background_mode == Environment.BG_SKY and env.sky != null and env.sky.sky_material != null, path)
	check(state, "fog_ambient_inject", env.volumetric_fog_enabled and env.volumetric_fog_ambient_inject > 0.0, path)
	check(state, "sdfgi_small_cells", env.sdfgi_enabled and env.sdfgi_min_cell_size < 0.2 and not is_equal_approx(env.sdfgi_min_cell_size, 0.2), path)
	check(state, "ssao_large_radius", env.ssao_enabled and env.ssao_radius > 1.0, path)
	check(state, "fog_sdfgi_inject", env.volumetric_fog_enabled and env.sdfgi_enabled and env.volumetric_fog_gi_inject > 0.0001, path)
	check(state, "color_correction_lut_large", env.adjustment_enabled and env.adjustment_color_correction is Texture3D and env.adjustment_color_correction.get_width() > 65, path)


## A project setting as the exported game reads it: the scan's snapshot (MetricsSnapshot, the values the rules see),
## or the saved value when a node is inspected outside a scan.
static func _setting(state: Dictionary, path: String, default: Variant) -> Variant:
	return state.get("settings", {}).get(path, ProjectSettings.get_setting(path, default))


static func _popup_needs_transparency(popup: Node, state: Dictionary) -> bool:
	if popup == null or DisplayServer.is_window_transparency_available() or bool(_setting(state, "display/window/subwindows/embed_subwindows", true)):
		return false
	var style: StyleBox = popup.get_theme_stylebox("panel")
	if not style is StyleBoxFlat:
		return false
	return style.shadow_size > 0 or style.get_corner_radius(CORNER_TOP_LEFT) > 0 or style.get_corner_radius(CORNER_TOP_RIGHT) > 0 or style.get_corner_radius(CORNER_BOTTOM_LEFT) > 0 or style.get_corner_radius(CORNER_BOTTOM_RIGHT) > 0


static func _inspect_tilemap_node(node: TileMap, state: Dictionary, path: String) -> void:
	check(state, "tilemap_deprecated", true, path)
	var sorted_z := {}
	var any_sorted := false
	var all_sorted := true
	for layer in node.get_layers_count():
		if node.is_layer_y_sort_enabled(layer):
			sorted_z[node.get_layer_z_index(layer)] = true
			any_sorted = true
		else:
			all_sorted = false
	var mixed := false
	for layer in node.get_layers_count():
		mixed = mixed or (not node.is_layer_y_sort_enabled(layer) and sorted_z.has(node.get_layer_z_index(layer)))
	check(state, "tilemap_ysort_z", mixed, path)
	check(state, "tilemap_layer_ysort", not node.y_sort_enabled and any_sorted, path)
	check(state, "tilemap_node_ysort", node.y_sort_enabled and not any_sorted, path)
	check(state, "tilemap_isometric_ysort", node.tile_set != null and node.tile_set.tile_shape == TileSet.TILE_SHAPE_ISOMETRIC and (not node.y_sort_enabled or not all_sorted), path)


## Effective physics interpolation; resolves inherited modes for scenes that are not in a tree.
static func _physics_interpolated(node: Node) -> bool:
	if node.is_inside_tree():
		return node.is_physics_interpolated()
	var current := node
	while current != null:
		if current.physics_interpolation_mode != Node.PHYSICS_INTERPOLATION_MODE_INHERIT:
			return current.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_ON
		current = current.get_parent()
	return true


static func _inspect_xr_warnings(node: Node, state: Dictionary, path: String, minor: int, interpolation: bool) -> void:
	var shown: bool = node.is_inside_tree() and node is Node3D and node.visible
	if node is XRCamera3D or node is XRNode3D:
		var parent := node.get_parent()
		check(state, "xr_camera_parent" if node is XRCamera3D else "xr_node_parent", shown and parent != null and not parent is XROrigin3D, path)
		check(state, "xr_interpolation", minor >= 5 and shown and interpolation and node.is_physics_interpolated(), path)
	if node is XRNode3D:
		check(state, "xr_node_tracker", shown and str(node.tracker).is_empty(), path)
		check(state, "xr_node_pose", shown and str(node.pose).is_empty(), path)
	if node is XROrigin3D:
		var camera := false
		for child in node.get_children(true):
			camera = camera or child is XRCamera3D
		check(state, "xr_origin_camera", shown and not camera, path)
		check(state, "xr_origin_scale", minor >= 6 and shown and not node.scale.is_equal_approx(Vector3.ONE), path)
		check(state, "xr_shaders_disabled", not bool(_setting(state, "xr/shaders/enabled", false)), path)
	if node is XRHandModifier3D:
		check(state, "xr_hand_tracking", bool(_setting(state, "xr/openxr/enabled", false)) and not bool(_setting(state, "xr/openxr/extensions/hand_tracking", false)), path)
	if node.is_class("OpenXRCompositionLayer"):
		var basis: Basis = node.transform.basis
		check(state, "openxr_layer_transform", not (basis.transposed() * basis).is_equal_approx(Basis.IDENTITY), path)
		check(state, "openxr_layer_hole_punch", node.get("enable_hole_punch") and int(node.get("sort_order")) >= 0, path)
		check(state, "openxr_layer_sort_zero", int(node.get("sort_order")) == 0, path)
		check(state, "openxr_layer_parent", minor <= 6 and shown and not node.get_parent() is XROrigin3D, path)
	if node.is_class("OpenXRVisibilityMask"):
		check(state, "openxr_visibility_mask_parent", shown and not node.get_parent() is XRCamera3D, path)
	var model := node.is_class("OpenXRRenderModel")
	var manager := node.is_class("OpenXRRenderModelManager")
	if minor >= 5 and (model or manager) and node.get_parent() != null:
		var parent_ok := node.get_parent() is XROrigin3D or (model and node.get_parent().is_class("OpenXRRenderModelManager"))
		var tracker := int(node.get("tracker")) if manager else 0
		if manager and tracker > 1:
			var ancestor := node.get_parent()
			while ancestor != null and not parent_ok:
				parent_ok = ancestor is XROrigin3D
				ancestor = ancestor.get_parent()
		check(state, "openxr_render_model_parent", not parent_ok, path)
		check(state, "openxr_render_model_extension", not bool(_setting(state, "xr/openxr/extensions/render_model", false)), path)
		check(state, "openxr_render_model_pose", manager and tracker <= 1 and not str(node.get("make_local_to_pose")).is_empty(), path)


## Property costs stated in the Godot class reference or tutorials; see docs/GODOT_PERF_NOTES.json and docs/GODOT_TUTORIAL_NOTES.json.
static func _inspect_documented_costs(node: Node, state: Dictionary, path: String) -> void:
	var shown := true
	if node is Node3D or node is CanvasItem:
		shown = node.is_visible_in_tree() if node.is_inside_tree() else node.visible
	if node is OmniLight3D or node is SpotLight3D:
		check(state, "light_shadow_fade", shown and not node.editor_only and node.shadow_enabled and node.distance_fade_enabled and node.distance_fade_shadow >= node.distance_fade_begin + node.distance_fade_length, path)
		check(state, "positional_light_dynamic_bake", shown and not node.editor_only and node.light_bake_mode == Light3D.BAKE_DYNAMIC, path)
	if node is SubViewport:
		check(state, "subviewport_3d_unused", not node.disable_3d and not _has_node3d(node), path)
	if node is DirectionalLight3D:
		check(state, "shadow_blend_splits", shown and not node.editor_only and node.shadow_enabled and node.directional_shadow_blend_splits and node.directional_shadow_mode != DirectionalLight3D.SHADOW_ORTHOGONAL, path)
	if node is Decal:
		# A zero cull mask skips the decal before normal fading: the shader tests the mask first (Forward+, and Mobile 4.4) and
		# Mobile 4.5 to 4.7.2 pairs it with no mesh (renderer_scene_cull.cpp).
		check(state, "decal_normal_fade", shown and node.cull_mask != 0 and node.normal_fade > 0.0, path)
	if node is LightmapGI:
		check(state, "lightmap_directional", node.directional and node.light_data != null, path)
		check(state, "lightmap_data_embedded", node.light_data != null and (node.light_data.resource_path.is_empty() or node.light_data.resource_path.contains(".tscn::")), path)
	if node is MultiMeshInstance3D and node.multimesh != null:
		check(state, "multimesh_custom_aabb", shown and node.multimesh.instance_count >= 4096 and node.multimesh.custom_aabb == AABB(), path)
	if node is GPUParticles3D and node.trail_enabled:
		var detailed := false
		for index in node.draw_passes:
			var mesh: Mesh = node.get_draw_pass_mesh(index)
			detailed = detailed or (mesh is RibbonTrailMesh and mesh.section_segments > 3) or (mesh is TubeTrailMesh and (mesh.radial_steps > 8 or mesh.section_rings > 3))
		check(state, "trail_mesh_detail", detailed, path)
	if node is OccluderInstance3D:
		var occluder: Occluder3D = node.occluder
		check(state, "occluder_dense", (occluder is ArrayOccluder3D and occluder.indices.size() / 3 > 10000) or (occluder is PolygonOccluder3D and occluder.polygon.size() > 64), path)
	if node is Label3D:
		var font: Font = node.font if node.font != null else ThemeDB.fallback_font
		var msdf: bool = font is FontFile and font.multichannel_signed_distance_field
		check(state, "label3d_font_size", shown and not node.text.is_empty() and node.font_size > 64 and not msdf, path)
	if node is TileMap:
		check(state, "tilemap_kinematic", node.collision_animatable, path)
	if node is GeometryInstance3D:
		check(state, "gi_dynamic", shown and not _draws_nothing(node) and node.gi_mode == GeometryInstance3D.GI_MODE_DYNAMIC, path)
	if node is MeshInstance3D and node.mesh != null and shown and node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
		# Godot's example is debris; 0.2 units is a review cutoff, not a measured shadow cost.
		var basis: Basis = node.global_basis if node.is_inside_tree() else node.basis
		var extent: Vector3 = node.mesh.get_aabb().size * basis.get_scale().abs()
		check(state, "small_shadow_casters", extent.length() > 0.0 and maxf(extent.x, maxf(extent.y, extent.z)) < 0.2, path)
	if node is AnimationMixer:
		_inspect_animation_tracks(node, state, path)


## Animation class-reference costs: value tracks for 3D transforms and cubic 3D transform tracks.
static func _inspect_animation_tracks(mixer: AnimationMixer, state: Dictionary, path: String) -> void:
	var root: Node = mixer.get_node_or_null(mixer.root_node) if not mixer.root_node.is_absolute() or mixer.is_inside_tree() else null
	var value_transforms := false
	var cubic := false
	var seen := 0
	for library_name in mixer.get_animation_library_list().slice(0, ANIMATION_LIBRARY_LIMIT):
		var library := mixer.get_animation_library(library_name)
		for animation_name in library.get_animation_list():
			seen += 1
			if seen > ANIMATION_LIMIT:
				break
			var animation := library.get_animation(animation_name)
			var cubic_tracks := 0
			for track in mini(animation.get_track_count(), TRACK_LIMIT):
				var kind := animation.track_get_type(track)
				if kind in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D] and animation.track_get_interpolation_type(track) in [Animation.INTERPOLATION_CUBIC, Animation.INTERPOLATION_CUBIC_ANGLE]:
					cubic_tracks += 1
				elif kind == Animation.TYPE_VALUE and root != null and not value_transforms:
					var track_path := animation.track_get_path(track)
					if track_path.get_concatenated_subnames() in ["position", "rotation", "rotation_degrees", "quaternion", "scale"]:
						value_transforms = root.get_node_or_null(NodePath(track_path.get_concatenated_names())) is Node3D
			# Godot recommends linear interpolation for complex imported 3D animations; 16 tracks is a review cutoff.
			cubic = cubic or cubic_tracks >= 16
	check(state, "animation_value_transforms", value_transforms, path)
	check(state, "animation_cubic_3d", cubic, path)


## Godot 4.7 IK modifiers skip a setting each frame when its target or Path3D does not resolve.
static func _inspect_ik_settings(node: SkeletonModifier3D, state: Dictionary, path: String) -> void:
	var count := mini(int(node.get("setting_count")) if node.get("setting_count") != null else 0, 128)
	var skipped := false
	if node.is_class("IterateIK3D"):
		for index in count:
			skipped = skipped or not node.get_node_or_null(node.call("get_target_node", index)) is Node3D
		check(state, "iterate_ik_target", skipped, path)
	elif node.is_class("SplineIK3D"):
		for index in count:
			var spline := node.get_node_or_null(node.call("get_path_3d", index)) as Path3D
			skipped = skipped or spline == null or spline.curve == null or spline.curve.point_count == 0
		check(state, "spline_ik_path", skipped, path)
	elif node.is_class("TwoBoneIK3D"):
		for index in count:
			skipped = skipped or not node.get_node_or_null(node.call("get_target_node", index)) is Node3D or not node.get_node_or_null(node.call("get_pole_node", index)) is Node3D
		check(state, "two_bone_ik_targets", skipped, path)


static func _inspect_noise(texture: Texture, state: Dictionary, path: String) -> void:
	if not (texture is NoiseTexture2D or texture is NoiseTexture3D) or texture.noise == null:
		return
	var texels := float(texture.width) * float(texture.height)
	if texture is NoiseTexture3D:
		texels *= float(texture.depth)
	check(state, "noise_texture_startup", texels >= 1048576.0, path)
	var noise: Noise = texture.noise
	if noise is FastNoiseLite:
		var octaves: bool = noise.fractal_type != FastNoiseLite.FRACTAL_NONE and noise.fractal_octaves > 5
		var warp: bool = noise.domain_warp_enabled and noise.domain_warp_fractal_type != FastNoiseLite.DOMAIN_WARP_FRACTAL_NONE and noise.domain_warp_fractal_octaves > 5
		check(state, "noise_texture_octaves", texels >= 65536.0 and (octaves or warp), path)


static func _primitive_vertex_floor(mesh: Mesh) -> float:
	if mesh is PlaneMesh:
		return (float(mesh.subdivide_width) + 2.0) * (float(mesh.subdivide_depth) + 2.0)
	if mesh is BoxMesh:
		var x := float(mesh.subdivide_width) + 2.0
		var y := float(mesh.subdivide_height) + 2.0
		var z := float(mesh.subdivide_depth) + 2.0
		return 2.0 * (x * y + y * z + x * z)
	if mesh is SphereMesh or mesh is CylinderMesh or mesh is CapsuleMesh:
		var sides := (float(mesh.radial_segments) + 1.0) * (float(mesh.rings) + 2.0)
		return sides * 3.0 if mesh is CapsuleMesh else sides
	if mesh is TorusMesh:
		return (float(mesh.rings) + 1.0) * (float(mesh.ring_segments) + 1.0)
	return 0.0


static func _panel_corner_detail(node: Control) -> bool:
	if not (node.is_visible_in_tree() if node.is_inside_tree() else node.visible):
		return false
	var style: StyleBox = node.get_theme_stylebox("panel")
	if not style is StyleBoxFlat or style.get_class() != "StyleBoxFlat" or style.get_script() != null or style.corner_detail <= 8:
		return false
	var size: Vector2 = node.size + Vector2(style.get_expand_margin(SIDE_LEFT) + style.get_expand_margin(SIDE_RIGHT), style.get_expand_margin(SIDE_TOP) + style.get_expand_margin(SIDE_BOTTOM))
	var border: int = 0
	var rounded: bool = false
	for side in range(4):
		var width: int = style.get_border_width(side)
		var radius: int = style.get_corner_radius(side)
		if width < 0 or radius < 0:
			return false
		border = maxi(border, width)
		rounded = rounded or radius > 0
	# Exclude degenerate or border-filled rectangles where native radius adaptation can remove rounding.
	if not size.is_finite() or is_zero_approx(size.x) or is_zero_approx(size.y) or minf(size.x, size.y) <= 2.0 * border:
		return false
	return rounded and ((style.draw_center and style.bg_color.a > 0.0) or (border > 0 and style.border_color.a > 0.0) or (style.shadow_size > 0 and style.shadow_color.a > 0.0))


static func _hidden_video(node: VideoStreamPlayer) -> bool:
	if not node.is_inside_tree() or node.is_visible_in_tree() or node.paused or not node.can_process():
		return false
	var stream: VideoStream = node.stream
	if stream == null or stream.get_class() != "VideoStreamTheora" or stream.get_script() != null:
		return false
	if Engine.is_editor_hint():
		if not node.autoplay:
			return false
	elif not node.is_processing_internal() or not node.is_playing():
		return false
	# Godot 4.4 uses its audio clock; later players expose a scaled process clock.
	if node.has_method("get_speed_scale") and (float(node.get("speed_scale")) <= 0.0 or Engine.time_scale <= 0.0):
		return false
	var texture: Texture2D = node.get_video_texture()
	return texture != null and texture.get_width() > 0 and texture.get_height() > 0


static func _skeleton2d_checks(node: Skeleton2D, state: Dictionary, path: String) -> void:
	if not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_script() != null or not node.can_process():
		return
	var stack := node.get_modification_stack()
	if stack == null or stack.get_script() != null or stack.is_queued_for_deletion() or not stack.get_is_setup() or stack.get_skeleton() != node or not stack.enabled:
		return
	for index in mini(stack.get_modification_count(), 128):
		var modification := stack.get_modification(index)
		if modification == null or modification.get_script() != null:
			continue
		var native := modification.get_class()
		if native not in ["SkeletonModification2DTwoBoneIK", "SkeletonModification2DLookAt", "SkeletonModification2DJiggle", "SkeletonModification2DCCDIK", "SkeletonModification2DFABRIK"]:
			continue
		if not modification.enabled:
			continue
		var mode: int = modification.execution_mode
		if not ((mode == 0 and node.is_processing_internal()) or (mode == 1 and node.is_physics_processing_internal())):
			continue
		var where := "%s [modification=%d; %s]" % [path, index, native]
		check(state, "skeleton2d_zero_strength", stack.strength == 0.0, where)
		if native == "SkeletonModification2DJiggle":
			var jiggle := modification as SkeletonModification2DJiggle
			var joints := jiggle.get_jiggle_data_chain_length()
			check(state, "skeleton2d_jiggle_collision_mode", jiggle.use_colliders and joints > 0 and mode == 0, where)
			check(state, "skeleton2d_jiggle_colliders", jiggle.use_colliders and jiggle.collision_mask != 0 and joints > 16 and mode == 1, "%s [configured joints=%d]" % [where, joints])


static func _spring_bone_collision_pairs(node: SpringBoneSimulator3D) -> int:
	var skeleton := node.get_parent() as Skeleton3D
	if not node.is_inside_tree() or not node.active or node.get_script() != null or skeleton == null or skeleton.get_script() != null:
		return 0
	if skeleton.get_bone_count() == 0 or not skeleton.can_process() or not (skeleton.is_processing_internal() or skeleton.is_physics_processing_internal()):
		return 0
	var colliders := {}
	for index in mini(node.get_child_count(), 128):
		var child := node.get_child(index)
		if child is SpringBoneCollision3D and child.get_script() == null:
			colliders[child] = true
	var pairs := 0
	for setting in mini(node.get_setting_count(), 128):
		var joints := node.get_joint_count(setting)
		if joints <= 0:
			continue
		var all_children := node.are_all_child_collisions_enabled(setting)
		var eligible := colliders.duplicate() if all_children else {}
		var count := node.get_exclude_collision_count(setting) if all_children else node.get_collision_count(setting)
		if all_children and count > 128:
			continue
		for index in mini(count, 128):
			var target := node.get_node_or_null(node.get_exclude_collision_path(setting, index) if all_children else node.get_collision_path(setting, index))
			if all_children:
				eligible.erase(target)
			elif colliders.has(target):
				eligible[target] = true
		# Do not call the cache getter: rebuilding native collision caches can clear project paths.
		pairs = mini(129, pairs + mini(joints, 129) * eligible.size())
		if pairs > 128:
			break
	return pairs


static func _skeleton_zero_influence(node: SkeletonModifier3D) -> bool:
	if not node.is_inside_tree() or not node.active or node.influence != 0.0 or node.get_script() != null:
		return false
	var skeleton := node.get_parent() as Skeleton3D
	return skeleton != null and skeleton.get_bone_count() > 0 and skeleton.can_process() and (skeleton.is_processing_internal() or skeleton.is_physics_processing_internal())


static func _skeleton_ik_bones(node: SkeletonModifier3D) -> bool:
	var skeleton := node.get_parent() as Skeleton3D
	if not node.active or node.get_script() != null or skeleton == null:
		return false
	var root := skeleton.find_bone(str(node.get("root_bone")))
	var tip := skeleton.find_bone(str(node.get("tip_bone")))
	return root < 0 or tip < 0 or root >= tip


static func _inspect_font(font: Font, size: int, state: Dictionary, path: String, canvas_text: bool) -> void:
	for depth in range(8):
		if font is FontVariation:
			canvas_text = canvas_text and font.get_script() == null
			font = font.base_font
		else:
			break
	# SystemFont documents the same MSDF and subpixel costs; oversampling was verified for FontFile only.
	var system := font is SystemFont
	if not system and (not font is FontFile or font.data.is_empty()):
		return
	var fixed: int = 0 if system else font.fixed_size
	check(state, "font_msdf_size", font.multichannel_signed_distance_field and font.msdf_size > 48, path)
	check(state, "font_subpixel_large", not font.multichannel_signed_distance_field and fixed == 0 and size > 20 and font.subpixel_positioning in [TextServer.SUBPIXEL_POSITIONING_ONE_HALF, TextServer.SUBPIXEL_POSITIONING_ONE_QUARTER], path)
	check(state, "font_local_mipmaps", font.generate_mipmaps, path)
	check(state, "font_oversampling", not system and canvas_text and font.get_script() == null and not font.multichannel_signed_distance_field and fixed == 0 and is_finite(font.oversampling) and font.oversampling > 2.0, path)


static func _world_compositor_owner(node: Node) -> Node:
	# World3D exposes no compositor getter; use WorldEnvironment's native selection group.
	var group := "_world_compositor_%d" % node.get_viewport().find_world_3d().scenario.get_id()
	return node.get_tree().get_first_node_in_group(group)


static func _inspect_compositor(node: Node, state: Dictionary, path: String) -> void:
	if node.compositor == null or not node.is_inside_tree():
		return
	var viewport := node.get_viewport()
	if viewport.disable_3d or (viewport is SubViewport and viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED):
		return
	var camera := viewport.get_camera_3d()
	if node is Camera3D:
		if camera != node:
			return
	else:
		if camera != null and camera.compositor != null:
			return
		if _world_compositor_owner(node) != node:
			return
	var resolve := false
	var motion := false
	var buffers := false
	var msaa := viewport.msaa_3d != Viewport.MSAA_DISABLED
	var prepass := bool(_setting(state, "rendering/driver/depth_prepass/enable", true))
	for effect in node.compositor.compositor_effects:
		if effect == null or not effect.enabled:
			continue
		var pre_opaque: bool = effect.effect_callback_type == CompositorEffect.EFFECT_CALLBACK_TYPE_PRE_OPAQUE
		check(state, "compositor_pre_opaque_resolved", msaa and pre_opaque and (effect.access_resolved_color or (effect.access_resolved_depth and not prepass)), path)
		check(state, "compositor_mobile_unsupported", effect.effect_callback_type == CompositorEffect.EFFECT_CALLBACK_TYPE_POST_OPAQUE or (msaa and effect.access_resolved_depth), path)
		check(state, "compositor_transparent_callback", effect.effect_callback_type in [CompositorEffect.EFFECT_CALLBACK_TYPE_PRE_TRANSPARENT, CompositorEffect.EFFECT_CALLBACK_TYPE_POST_TRANSPARENT], path)
		if effect.effect_callback_type in [CompositorEffect.EFFECT_CALLBACK_TYPE_PRE_OPAQUE, CompositorEffect.EFFECT_CALLBACK_TYPE_POST_OPAQUE, CompositorEffect.EFFECT_CALLBACK_TYPE_PRE_TRANSPARENT]:
			resolve = resolve or effect.access_resolved_color or effect.access_resolved_depth
		motion = motion or effect.needs_motion_vectors
		buffers = buffers or effect.needs_separate_specular or (effect.needs_normal_roughness and effective_environment(node) != null)
	check(state, "compositor_msaa_resolve", resolve and viewport.msaa_3d != Viewport.MSAA_DISABLED, path)
	check(state, "compositor_motion", motion and not viewport.use_taa and viewport.scaling_3d_mode in [Viewport.SCALING_3D_MODE_BILINEAR, Viewport.SCALING_3D_MODE_FSR], path)
	check(state, "compositor_extra_buffers", buffers, path)


static func effective_environment(node: Node) -> Environment:
	if not node.is_inside_tree():
		return null
	var viewport: Viewport = node if node is Viewport else node.get_viewport()
	var camera := viewport.get_camera_3d()
	if camera != null and camera.environment != null:
		return camera.environment
	var world := viewport.find_world_3d()
	return world.environment if world.environment != null else world.fallback_environment


static func inspect_material(mat: Material, state: Dictionary, path: String, on_particle: bool) -> void:
	if not state.has("checked_material_uses"):
		state["checked_material_uses"] = {}
	var key := "%d:%s" % [mat.get_instance_id(), on_particle]
	if state.checked_material_uses.has(key):
		return
	state.checked_material_uses[key] = true
	var spatial: bool = mat is BaseMaterial3D or (mat is ShaderMaterial and mat.shader != null and mat.shader.get_mode() == Shader.MODE_SPATIAL)
	check(state, "material_next_pass", spatial and mat.next_pass != null, path)
	if not mat is BaseMaterial3D:
		return
	var base := mat as BaseMaterial3D
	# material.cpp emits alpha to coverage only for Alpha Scissor and Alpha Hash.
	check(state, "material_alpha_to_coverage", base.alpha_antialiasing_mode != BaseMaterial3D.ALPHA_ANTIALIASING_OFF and base.transparency in [BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR, BaseMaterial3D.TRANSPARENCY_ALPHA_HASH], path)
	_inspect_noise(base.albedo_texture, state, path)
	var lit := base.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL
	check(state, "material_orm_pack", base is StandardMaterial3D and lit and base.metallic > 0.0 and base.metallic_texture != null and base.roughness > 0.0 and base.roughness_texture != null and not (base.ao_enabled and base.ao_on_uv2), path)
	check(state, "material_particle_trails", base.use_particle_trails and not on_particle, path)
	check(state, "material_height_triplanar", base.heightmap_enabled and base.uv1_triplanar, path)
	check(state, "material_msdf_triplanar", base.albedo_texture_msdf and base.uv1_triplanar, path)
	check(state, "material_unshaded_features", base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and (base.clearcoat_enabled or base.rim_enabled), path)
	check(state, "material_triplanar_uv1", base.uv1_triplanar and base.albedo_texture != null, path)
	check(state, "material_triplanar_uv2", base.uv2_triplanar and base.detail_enabled and base.detail_uv_layer == BaseMaterial3D.DETAIL_UV_2 and base.detail_albedo != null, path)
	check(state, "material_deep_parallax", base.heightmap_enabled and base.heightmap_deep_parallax and base.heightmap_texture != null and not base.uv1_triplanar, path)
	check(state, "parallax_layers", base.heightmap_enabled and base.heightmap_deep_parallax and base.heightmap_texture != null and not base.uv1_triplanar and (base.heightmap_max_layers > 32 or base.heightmap_min_layers > 8), path)
	check(state, "material_clearcoat", lit and base.clearcoat_enabled and base.clearcoat > 0.0, path)
	check(state, "material_rim", lit and base.rim_enabled and base.rim > 0.0, path)
	check(state, "material_anisotropy", lit and base.anisotropy_enabled and not is_zero_approx(base.anisotropy), path)
	check(state, "material_detail", base.detail_enabled and (base.detail_albedo != null or (lit and base.detail_normal != null)), path)
	check(state, "material_normal", lit and base.normal_enabled and base.normal_texture != null and not is_zero_approx(base.normal_scale), path)


static func inspect_surface(mesh: Mesh, surface: int, mat: Material, state: Dictionary, path: String) -> void:
	if not mesh is ArrayMesh or not mat is BaseMaterial3D:
		return
	# Godot generates tangent space in the material shader for either triplanar mode.
	if mat.uv1_triplanar or mat.uv2_triplanar:
		return
	check(state, "material_anisotropy_tangents", mat.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL and mat.anisotropy_enabled and not is_zero_approx(mat.anisotropy) and (mesh.surface_get_format(surface) & Mesh.ARRAY_FORMAT_TANGENT) == 0, path)
	# Normal mapping writes NORMAL_MAP and height mapping reads TANGENT/BINORMAL; both make the shader require tangents.
	check(state, "material_normal_tangents", mat.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL and (mat.normal_enabled or mat.heightmap_enabled) and (mesh.surface_get_format(surface) & Mesh.ARRAY_FORMAT_TANGENT) == 0, path)


static func _nonuniform(scale: Vector3) -> bool:
	return not (is_zero_approx(scale.x - scale.y) and is_zero_approx(scale.y - scale.z))


static func _practical_dof(attributes: CameraAttributes) -> bool:
	return attributes is CameraAttributesPractical and (attributes.dof_blur_near_enabled or attributes.dof_blur_far_enabled)


static func _animated(source: Object) -> bool:
	return (source is ParticleProcessMaterial or source is CPUParticles2D or source is CPUParticles3D) and (source.anim_speed_max != 0.0 or source.anim_offset_max != 0.0 or source.anim_speed_curve != null or source.anim_offset_curve != null)


static func _particles_3d(node: GeometryInstance3D, state: Dictionary, path: String) -> void:
	var meshes := 0
	var trail_meshes := 0
	var unknown_poses := false
	var animation_material := false
	var bad_trail_material := false
	var passes: int = node.draw_passes if node is GPUParticles3D else 1
	for i in passes:
		var mesh: Mesh = node.get_draw_pass_mesh(i) if node is GPUParticles3D else node.mesh
		if mesh == null:
			continue
		meshes += 1
		unknown_poses = unknown_poses or not KNOWN_MESHES.has(mesh.get_class())
		if mesh is RibbonTrailMesh or mesh is TubeTrailMesh:
			trail_meshes += 1
		for j in mesh.get_surface_count():
			var material: Material = node.material_override if node.material_override != null else mesh.surface_get_material(j)
			if material is ShaderMaterial:
				# Custom shaders can implement animation/trails; their semantics are unknown.
				animation_material = true
			elif material is BaseMaterial3D:
				animation_material = animation_material or material.billboard_mode == BaseMaterial3D.BILLBOARD_PARTICLES
				bad_trail_material = bad_trail_material or not material.use_particle_trails
			else:
				bad_trail_material = true
	if node is GPUParticles3D:
		check(state, "gpu_mesh_missing", meshes == 0, path)
	check(state, "particles_animation_3d", meshes > 0 and not animation_material and _animated(node.process_material if node is GPUParticles3D else node), path)
	if not node is GPUParticles3D or not node.trail_enabled:
		return
	check(state, "trails_skin", trail_meshes > 0 and node.draw_skin != null, path)
	check(state, "trails_no_pose", trail_meshes == 0 and node.draw_skin == null and not unknown_poses, path)
	check(state, "trails_multiple", trail_meshes > 1 and node.draw_skin == null, path)
	check(state, "trails_material", (trail_meshes > 0 or node.draw_skin != null) and bad_trail_material, path)


static func _inspect_tilemap(node: TileMapLayer, state: Dictionary, path: String) -> void:
	var tiles := node.tile_set
	if not node.enabled or tiles == null:
		return
	var coverage: Dictionary = state.get("tilemap_scan", {"inspected_cells": 0, "skipped_cells": 0, "runtime_layers_skipped": 0, "resource_limits_reached": 0, "max_cells": 4096})
	state["tilemap_scan"] = coverage
	if node.get_class() != "TileMapLayer":
		coverage.runtime_layers_skipped += 1
		return
	var script: Script = node.get_script()
	if script != null:
		for method in script.get_script_method_list():
			if str(method.name).replace("_", "").to_lower() in ["usetiledataruntimeupdate", "tiledataruntimeupdate"]:
				coverage.runtime_layers_skipped += 1
				return
	# physics_quadrant_size exists from Godot 4.5.
	var physics_chunking: bool = node.get("physics_quadrant_size") != null and node.collision_enabled and int(node.get("physics_quadrant_size")) == 1
	var cells := node.get_used_cells()
	var amount := mini(cells.size(), maxi(0, 4096 - int(coverage.inspected_cells)))
	coverage.inspected_cells += amount
	coverage.skipped_cells += cells.size() - amount
	var data_cache := {}
	var render_cells := 0
	var navigation_regions := 0
	var physics_cells := 0
	var occluders := 0
	var animation_frames := 0
	var scene_cells := 0
	var y_groups := {}
	for index in amount:
		var coords: Vector2i = cells[index]
		var source_id := node.get_cell_source_id(coords)
		var atlas_coords := node.get_cell_atlas_coords(coords)
		var alternative := node.get_cell_alternative_tile(coords)
		var key := Vector4i(source_id, atlas_coords.x, atlas_coords.y, alternative)
		if not data_cache.has(key):
			var data := {"render": 0, "navigation": 0, "physics": 0, "y_sort": 0, "occluders": 0, "animation_frames": 0, "scene": 0}
			if tiles.has_source(source_id):
				var scenes := tiles.get_source(source_id) as TileSetScenesCollectionSource
				data.scene = int(scenes != null and scenes.has_scene_tile_id(alternative) and scenes.get_scene_tile_scene(alternative) != null)
				var atlas := tiles.get_source(source_id) as TileSetAtlasSource
				if atlas != null and atlas.has_tile(atlas_coords) and atlas.has_alternative_tile(atlas_coords, alternative):
					var tile := atlas.get_tile_data(atlas_coords, alternative)
					data.render = int(atlas.texture != null)
					data.y_sort = tile.y_sort_origin
					var frames := atlas.get_tile_animation_frames_count(atlas_coords)
					data.animation_frames = frames if frames > 1 and atlas.texture != null else 0
					if node.visible and node.occlusion_enabled:
						var layers := tiles.get_occlusion_layers_count()
						coverage.resource_limits_reached += int(layers > 32)
						for layer in mini(layers, 32):
							if tiles.get_occlusion_layer_light_mask(layer) == 0 and not tiles.get_occlusion_layer_sdf_collision(layer):
								continue
							var polygons := tile.get_occluder_polygons_count(layer)
							coverage.resource_limits_reached += int(polygons > 32)
							for index_polygon in mini(polygons, 32):
								var polygon := tile.get_occluder_polygon(layer, index_polygon)
								if polygon != null and polygon.polygon.size() >= (3 if polygon.closed else 2):
									data.occluders += 1
					if node.navigation_enabled:
						var layers := tiles.get_navigation_layers_count()
						coverage.resource_limits_reached += int(layers > 32)
						for layer in mini(layers, 32):
							var polygon := tile.get_navigation_polygon(layer)
							if tiles.get_navigation_layer_layers(layer) != 0 and polygon != null and (polygon.get_polygon_count() > 0 or polygon.get_outline_count() > 0):
								data.navigation += 1
					if physics_chunking:
						var layers := tiles.get_physics_layers_count()
						coverage.resource_limits_reached += int(layers > 32)
						for layer in mini(layers, 32):
							if tiles.get_physics_layer_collision_layer(layer) == 0 and tiles.get_physics_layer_collision_mask(layer) == 0:
								continue
							var polygons := tile.get_collision_polygons_count(layer)
							coverage.resource_limits_reached += int(polygons > 32)
							for polygon in mini(polygons, 32):
								if tile.get_collision_polygon_points(layer, polygon).size() >= 3:
									data.physics = 1
									break
			data_cache[key] = data
		var data: Dictionary = data_cache[key]
		render_cells += data.render
		navigation_regions += data.navigation
		physics_cells += data.physics
		occluders += data.occluders
		animation_frames += data.animation_frames
		scene_cells += data.scene
		if node.y_sort_enabled and data.render > 0:
			var y: float = node.map_to_local(coords).y + data.y_sort + node.y_sort_origin
			y_groups[int(y * 100.0)] = true
	check(state, "tilemap_small_quadrants", node.visible and not node.y_sort_enabled and node.rendering_quadrant_size <= 4 and render_cells > 256, path)
	check(state, "tilemap_y_sort_groups", node.visible and node.y_sort_enabled and render_cells > 256 and y_groups.size() > 64, path)
	check(state, "tilemap_navigation_regions", node.navigation_enabled and navigation_regions > 256, path)
	check(state, "tilemap_physics_chunking", physics_chunking and physics_cells > 256, path)
	check(state, "tilemap_occluders", node.visible and node.occlusion_enabled and occluders > 256, path)
	check(state, "tilemap_animation_slices", node.visible and animation_frames > 4096, path)
	check(state, "tilemap_scene_tiles", scene_cells > 256, path)


static func _inspect_gridmap(node: GridMap, state: Dictionary, path: String) -> void:
	var library := node.mesh_library
	var small_octants := node.visible and node.cell_octant_size <= 2 and (node.get("baked_meshes") as Array).is_empty()
	if library == null or not (small_octants or node.bake_navigation):
		return
	var coverage: Dictionary = state.get("gridmap_scan", {"inspected_cells": 0, "skipped_cells": 0, "max_cells": 4096})
	var cells := node.get_used_cells()
	var amount := mini(cells.size(), maxi(0, 4096 - int(coverage.inspected_cells)))
	coverage.inspected_cells += amount
	coverage.skipped_cells += cells.size() - amount
	state["gridmap_scan"] = coverage
	var items := {}
	var library_items := library.get_item_list()
	var mesh_cells := 0
	var navigation_cells := 0
	for index in amount:
		var item := node.get_cell_item(cells[index])
		if not items.has(item):
			var flags := Vector2i.ZERO
			if library_items.has(item):
				var mesh := library.get_item_mesh(item)
				flags.x = int(mesh != null and mesh.get_class() in KNOWN_MESHES and mesh.get_surface_count() > 0)
				var navigation := library.get_item_navigation_mesh(item)
				flags.y = int(navigation != null and navigation.get_polygon_count() > 0 and library.get_item_navigation_layers(item) != 0)
			items[item] = flags
		mesh_cells += items[item].x
		navigation_cells += items[item].y
	check(state, "gridmap_small_octants", small_octants and mesh_cells > 256, path)
	check(state, "gridmap_navigation_regions", node.bake_navigation and navigation_cells > 256, path)


## True when any descendant is a Node3D; a walk cut off after 4096 nodes counts as 3D.
static func _has_node3d(root: Node) -> bool:
	var pending: Array[Node] = [root]
	var visited := 0
	while not pending.is_empty():
		for child in pending.pop_back().get_children():
			visited += 1
			if child is Node3D or visited > 4096:
				return true
			pending.append(child)
	return false


## Reports a ShaderMaterial that repeats another one's shader and every value an instance uniform cannot hold, so it
## differs at most in scalars, vectors and colors: shader_language.cpp rejects instance samplers, matrices and arrays.
## Each material instance counts once.
static func shader_material_copy(mat: ShaderMaterial, state: Dictionary, path: String) -> void:
	var seen: Dictionary = state.get_or_add("shader_material_ids", {})
	if mat.shader == null or seen.has(mat.get_instance_id()):
		return
	seen[mat.get_instance_id()] = true
	var fixed: Array = []
	for uniform in mat.shader.get_shader_uniform_list():
		if int(uniform.type) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_VECTOR3, TYPE_VECTOR3I, TYPE_VECTOR4, TYPE_VECTOR4I, TYPE_COLOR]:
			continue
		var value: Variant = mat.get_shader_parameter(uniform.name)
		fixed.append("%s=%d" % [uniform.name, value.get_instance_id() if value is Object else hash(value)])
	var groups: Dictionary = state.get_or_add("shader_material_groups", {})
	# Render priority and the next pass belong to the material itself, so materials that differ there cannot be shared.
	fixed.append("priority=%d,next=%d" % [mat.render_priority, mat.next_pass.get_instance_id() if mat.next_pass != null else 0])
	var group := "%d:%s" % [mat.shader.get_instance_id(), ",".join(fixed)]
	groups[group] = int(groups.get(group, 0)) + 1
	check(state, "shader_material_copies", groups[group] > 1, path)


## Forward+ disables subsurface scattering in transparent viewports (4.5+); looks for SSS materials drawn inside one.
static func _subtree_uses_sss(viewport: Node) -> bool:
	var stack: Array[Node] = [viewport]
	var visited := 0
	while not stack.is_empty() and visited < 4096:
		var current: Node = stack.pop_back()
		visited += 1
		if current is GeometryInstance3D:
			var materials: Array = [current.material_override]
			if current is MeshInstance3D and current.mesh != null:
				for surface in mini(current.mesh.get_surface_count(), 64):
					materials.append(current.get_active_material(surface))
			for material in materials:
				if material is BaseMaterial3D and material.subsurf_scatter_enabled:
					return true
		for child in current.get_children():
			if not child is Viewport:
				stack.append(child)
	return false


## Godot 4.7 warns when a spring-bone center node or a bone-constraint reference node does not resolve to a Node3D.
static func _modifier_node_missing(node: Node) -> bool:
	if node.get_script() != null:
		return false
	for property in node.get_property_list():
		var name: String = property.name
		if property.type == TYPE_NODE_PATH and (name.ends_with("/center_node") or name.ends_with("/reference_node")):
			var target: NodePath = node.get(name)
			if not target.is_empty() and not node.get_node_or_null(target) is Node3D:
				return true
	return false


## AnimationNodeStateMachinePlayback evaluates transition expressions on the tree's advance_expression_base_node and warns
## when that node does not resolve. Nested state machines are followed four levels deep.
static func _state_machine_expression(tree_node: AnimationNode, depth: int) -> bool:
	if not tree_node is AnimationNodeStateMachine or depth > 4:
		return false
	for index in mini(tree_node.get_transition_count(), 1024):
		if not tree_node.get_transition(index).advance_expression.strip_edges().is_empty():
			return true
	if tree_node.has_method("get_node_list"):
		for name in tree_node.get_node_list():
			if _state_machine_expression(tree_node.get_node(name), depth + 1):
				return true
	return false


## SpringBoneSimulator3D::_find_collisions merges the deny list into the child-collision list assuming the excluded child
## indices are strictly increasing; an unsorted or duplicate exclude list leaves excluded collisions active (reproduced on 4.4 and 4.7.2).
static func _spring_bone_exclude_unordered(node: SpringBoneSimulator3D) -> bool:
	if node.get_script() != null:
		return false
	var collisions: Array[Node] = []
	for child in node.get_children():
		if child is SpringBoneCollision3D:
			collisions.append(child)
	for index in mini(node.setting_count, 128):
		if not node.are_all_child_collisions_enabled(index):
			continue
		var previous := -1
		for entry in mini(node.get_exclude_collision_count(index), 128):
			var exclude := node.get_exclude_collision_path(index, entry)
			# get_node_or_null prints an engine error for an absolute path outside the tree (scans by path).
			if exclude.is_absolute() and not node.is_inside_tree():
				continue
			var found := collisions.find(node.get_node_or_null(exclude))
			if found < 0:
				continue
			if found <= previous:
				return true
			previous = found
	return false


## Spring bones (4.4+), IterateIK3D and TwoBoneIK3D (4.6+) warn when a joint's rotation axis, or the pole direction, is parallel
## to the bone's forward vector in the rest pose. Forwards that come from an extended end bone are not inspected.
static func _modifier_axis_colinear(node: Node, skeleton: Skeleton3D) -> bool:
	if skeleton == null or node.get_script() != null or node.get("setting_count") == null:
		return false
	var count := mini(int(node.get("setting_count")), 128)
	var bones := skeleton.get_bone_count()
	var all_axes := ClassDB.class_get_integer_constant(node.get_class(), "ROTATION_AXIS_ALL") if node is SpringBoneSimulator3D or node.is_class("IterateIK3D") else -1
	if node is SpringBoneSimulator3D:
		# Joint arrays are rebuilt deferred, so walk the chain from the end bone to the root bone on the skeleton.
		for index in count:
			if node.is_config_individual(index):
				continue
			var axis := int(node.get_rotation_axis(index))
			if axis == all_axes:
				continue
			var rot: Vector3 = node.call("get_rotation_axis_vector", index) if node.has_method("get_rotation_axis_vector") else [Vector3.RIGHT, Vector3.UP, Vector3.BACK][clampi(axis, 0, 2)]
			var start := int(node.get_root_bone(index))
			var bone := int(node.get_end_bone(index))
			var steps := 0
			while bone >= 0 and bone < bones and bone != start and steps < 256:
				var fwd := skeleton.get_bone_rest(bone).origin
				if not rot.is_zero_approx() and not fwd.is_zero_approx() and is_equal_approx(absf(rot.normalized().dot(fwd.normalized())), 1.0):
					return true
				bone = skeleton.get_bone_parent(bone)
				steps += 1
	elif node.is_class("IterateIK3D"):
		for index in count:
			for joint in mini(int(node.call("get_joint_count", index)), 256) - 1:
				var axis := int(node.call("get_joint_rotation_axis", index, joint))
				var next_bone := int(node.call("get_joint_bone", index, joint + 1))
				if axis == all_axes or next_bone < 0 or next_bone >= bones:
					continue
				# Godot 4.4 and 4.5 have no axis-vector getter; their axis enum is X, Y, Z.
				var rot: Vector3 = node.call("get_joint_rotation_axis_vector", index, joint) if node.has_method("get_joint_rotation_axis_vector") else [Vector3.RIGHT, Vector3.UP, Vector3.BACK][clampi(axis, 0, 2)]
				var fwd := skeleton.get_bone_rest(next_bone).origin
				if not rot.is_zero_approx() and not fwd.is_zero_approx() and is_equal_approx(absf(rot.normalized().dot(fwd.normalized())), 1.0):
					return true
	elif node.is_class("TwoBoneIK3D"):
		for index in count:
			var middle := int(node.call("get_middle_bone", index))
			var end := int(node.call("get_end_bone", index))
			var root := int(node.call("get_root_bone", index))
			if int(node.call("get_pole_direction", index)) == 0 or root < 0 or middle < 0 or middle >= bones or end < 0 or end >= bones:
				continue
			if node.call("is_end_bone_extended", index) and float(node.call("get_end_bone_length", index)) > 0.0:
				continue
			var reach := skeleton.get_bone_global_rest(end).origin - skeleton.get_bone_global_rest(middle).origin
			if reach.is_zero_approx():
				continue
			var fwd := skeleton.get_bone_global_rest(middle).basis.get_rotation_quaternion().inverse() * reach
			var pole: Vector3 = node.call("get_pole_direction_vector", index)
			if not pole.is_zero_approx() and is_equal_approx(absf(pole.normalized().dot(fwd.normalized())), 1.0):
				return true
	return false


## RendererSceneCull merges the instance uniforms of the material override (or every surface material) and the overlay;
## a name declared with a different type or index than the first declaration does not display (servers/rendering/instance_uniforms.cpp).
static func _instance_uniform_conflict(node: GeometryInstance3D) -> bool:
	var materials: Array = []
	if node.material_override != null:
		materials.append(node.material_override)
	elif node is MeshInstance3D and node.mesh != null:
		for surface in mini(node.mesh.get_surface_count(), 64):
			materials.append(node.get_active_material(surface))
	materials.append(node.material_overlay)
	# A conflict needs two shader materials; skipping single-material meshes keeps big scenes cheap.
	materials = materials.filter(func(material): return material is ShaderMaterial and material.shader != null)
	if materials.size() < 2:
		return false
	var seen := {}
	for material in materials:
		var uniforms := instance_uniforms(material.shader.code)
		for name in uniforms:
			if seen.has(name) and seen[name] != uniforms[name]:
				return true
			seen[name] = uniforms[name]
	return false


## `instance uniform` declarations as {name: [type, index]}; the index is instance_index(n) or the declaration order of
## the unindexed ones (ShaderLanguage). Comments are ignored; #include files are not followed.
static func instance_uniforms(code: String) -> Dictionary:
	if code.find("instance") < 0:
		return {}
	var stripped := RegEx.create_from_string("(?s)/\\*.*?\\*/|//[^\\n]*").sub(code, "", true)
	var found := {}
	var next_index := 0
	var explicit := RegEx.create_from_string("instance_index\\s*\\(\\s*(\\d+)\\s*\\)")
	for match in RegEx.create_from_string("\\binstance\\s+uniform\\s+(?:(?:lowp|mediump|highp)\\s+)?(\\w+)\\s+(\\w+)([^;]*);").search_all(stripped):
		var hint := explicit.search(match.get_string(3))
		var index := int(hint.get_string(1)) if hint != null else next_index
		if hint == null:
			next_index += 1
		found[match.get_string(2)] = [match.get_string(1), index]
	return found


## Decal, Light3D projector/area and PointLight2D textures of these classes print a warning and are not sampled directly.
const UNSAMPLED_TEXTURES := ["AnimatedTexture", "AtlasTexture", "CameraTexture", "CanvasTexture", "MeshTexture", "Texture2DRD", "ViewportTexture"]


static func _unsampled_texture(texture: Variant) -> bool:
	if not texture is Texture:
		return false
	for name in UNSAMPLED_TEXTURES:
		if texture.is_class(name):
			return true
	return false


## ConvexPolygonShape2D::set_points: counter-clockwise points must pass a left test at every vertex (polygons of four or more points).
static func _concave(points: PackedVector2Array) -> bool:
	var ordered := points.duplicate()
	if Geometry2D.is_polygon_clockwise(ordered):
		ordered.reverse()
	var size := ordered.size()
	if size <= 3:
		return false
	for i in size:
		var a := ordered[i]
		var b := ordered[(i + 1) % size]
		var c := ordered[(i + 2) % size]
		if (b - a).cross(c - a) < 0.0:
			return true
	return false


## Jolt Physics warns for joint parameters it does not implement when they differ from Godot's defaults
## (modules/jolt_physics/joints). PhysicalBone3D joint settings are not inspected.
static func _jolt_ignored_joint_param(node: Joint3D) -> bool:
	var fresh: Joint3D = ClassDB.instantiate(node.get_class())
	if fresh == null:
		return false
	var ignored := node.solver_priority != fresh.solver_priority
	var params: Array = []
	if node is HingeJoint3D:
		params = [HingeJoint3D.PARAM_BIAS, HingeJoint3D.PARAM_LIMIT_BIAS, HingeJoint3D.PARAM_LIMIT_SOFTNESS, HingeJoint3D.PARAM_LIMIT_RELAXATION]
	elif node is PinJoint3D:
		params = [PinJoint3D.PARAM_BIAS, PinJoint3D.PARAM_DAMPING, PinJoint3D.PARAM_IMPULSE_CLAMP]
	elif node is ConeTwistJoint3D:
		params = [ConeTwistJoint3D.PARAM_BIAS, ConeTwistJoint3D.PARAM_SOFTNESS, ConeTwistJoint3D.PARAM_RELAXATION]
	elif node is SliderJoint3D:
		params = range(SliderJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, SliderJoint3D.PARAM_MAX)
	for param in params:
		ignored = ignored or not is_equal_approx(node.get_param(param), fresh.get_param(param))
	if node is Generic6DOFJoint3D:
		for param in [Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, Generic6DOFJoint3D.PARAM_LINEAR_RESTITUTION, Generic6DOFJoint3D.PARAM_LINEAR_DAMPING,
				Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS, Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING, Generic6DOFJoint3D.PARAM_ANGULAR_RESTITUTION,
				Generic6DOFJoint3D.PARAM_ANGULAR_FORCE_LIMIT, Generic6DOFJoint3D.PARAM_ANGULAR_ERP]:
			for axis in ["x", "y", "z"]:
				ignored = ignored or not is_equal_approx(node.call("get_param_" + axis, param), fresh.call("get_param_" + axis, param))
	fresh.free()
	return ignored


## Godot 4.5+ warns when a region's navigation mesh cell is smaller than its map's; the default map uses the project settings.
static func _navmesh_cell_mismatch(node: Node, state: Dictionary) -> bool:
	# In the tree the region's own map decides (nav_region_3d.cpp compares with it; a custom map can use other cells).
	var map: RID = node.get_navigation_map() if node.is_inside_tree() else RID()
	if node is NavigationRegion3D:
		var mesh: NavigationMesh = node.navigation_mesh
		if mesh == null or not bool(_setting(state, "navigation/3d/warnings/navmesh_cell_size_mismatch", true)):
			return false
		var cell := NavigationServer3D.map_get_cell_size(map) if map.is_valid() else float(_setting(state, "navigation/3d/default_cell_size", 0.25))
		var height := NavigationServer3D.map_get_cell_height(map) if map.is_valid() else float(_setting(state, "navigation/3d/default_cell_height", 0.25))
		return cell > mesh.cell_size + 0.00001 or height > mesh.cell_height + 0.00001
	var polygon: NavigationPolygon = node.navigation_polygon
	if polygon == null or not bool(_setting(state, "navigation/2d/warnings/navmesh_cell_size_mismatch", true)):
		return false
	var cell_2d := NavigationServer2D.map_get_cell_size(map) if map.is_valid() else float(_setting(state, "navigation/2d/default_cell_size", 1.0))
	return cell_2d > polygon.cell_size + 0.00001


## Skeleton modifiers re-resolve stored bones when they enter the skeleton (e.g. TwoBoneIK3D::_validate_bone_names):
## a stored bone name the skeleton lacks, or a stored index past its bone count, makes Godot warn "bone index ... is out of range".
## Chain joint lists are derived from the root and end bones and are not inspected.
static func _modifier_bone_missing(node: Node, skeleton: Skeleton3D) -> bool:
	if skeleton == null or node.get_script() != null:
		return false
	var values := {}
	for property in node.get_property_list():
		var name: String = property.name
		if (property.type in [TYPE_STRING, TYPE_STRING_NAME] and name.ends_with("bone_name")) or (property.type == TYPE_INT and name.ends_with("bone")):
			values[name] = node.get(name)
	for name in values:
		if not name.ends_with("bone_name"):
			continue
		var index_key: String = name.trim_suffix("_name")
		if not str(values[name]).is_empty():
			if skeleton.find_bone(str(values[name])) < 0:
				return true
		elif values.has(index_key) and int(values[index_key]) >= skeleton.get_bone_count():
			return true
	return false


## AnimationMixer builds a cache for every enabled track of every library and warns when a track's node path does not resolve
## from root_node (animation/warnings/check_invalid_track_paths, on by default).
static func _animation_track_unresolved(node: AnimationMixer, state: Dictionary) -> bool:
	var root := node.get_node_or_null(node.root_node)
	if root == null or not bool(_setting(state, "animation/warnings/check_invalid_track_paths", true)):
		return false
	var tracks := 0
	for library_name in node.get_animation_library_list():
		var library := node.get_animation_library(library_name)
		for animation_name in library.get_animation_list():
			var animation := library.get_animation(animation_name)
			for track in animation.get_track_count():
				tracks += 1
				if tracks > TRACK_LIMIT:
					return false
				if animation.track_is_enabled(track) and not _track_resolves(root, animation.track_get_path(track)):
					return true
	return false


## Node::get_node_and_resource as the mixer calls it (p_last_is_property true): the node must exist and every subname but
## the last must be a valid property, followed while it holds a Resource. The GDScript binding passes false, which also
## requires the last subname to be a property and so rejects bone and blend-shape tracks ("Skeleton3D:Hips").
static func _track_resolves(root: Node, path: NodePath) -> bool:
	var object: Object = root.get_node_or_null(path)
	if object == null:
		return false
	for index in path.get_subname_count() - 1:
		var subname := path.get_subname(index)
		if not (subname in object):
			return false
		var value = object.get(subname)
		if not is_instance_valid(value) or not (value is Resource):
			break
		object = value
	return true


## Geometry Godot never draws, checked in its 4.4 to 4.7.2 sources: a MeshInstance3D without a mesh has no instance base
## (renderer_scene_cull.cpp), a CSG shape under another CSG shape never gets one (csg_shape.cpp update_shape returns for
## it; the root draws the combined result), and a CSG root whose result has no surfaces has empty bounds that culling
## rejects. A CSG result is only known inside the tree.
static func _draws_nothing(node: Node) -> bool:
	if node is MeshInstance3D:
		return node.mesh == null
	if node is CSGShape3D:
		return not node.is_root_shape() or (node.is_inside_tree() and _csg_result_empty(node))
	return false


## A visibility range that ends before it begins, margins included, fails Godot's camera check at every distance
## (renderer_scene_cull.cpp _visibility_range_check, with or without fade). Directional cascades use that check too, but
## omni and spot shadow culling (_light_instance_update_shadow) does not, so the node still casts those shadows.
static func range_hides_from_camera(node: Node) -> bool:
	return node is GeometryInstance3D and node.visibility_range_begin > 0.0 and node.visibility_range_end > 0.0 \
		and node.visibility_range_end + node.visibility_range_end_margin < node.visibility_range_begin - node.visibility_range_begin_margin


static func _csg_result_empty(csg_root: Node) -> bool:
	var meshes: Array = csg_root.get_meshes()
	return meshes.size() == 2 and meshes[1] is Mesh and meshes[1].get_surface_count() == 0


static func check(state: Dictionary, key: String, condition: bool, path: String) -> void:
	if not condition:
		return
	var counter := "check_" + key
	state["counts"][counter] = int(state["counts"].get(counter, 0)) + 1
	if not state["offenders"].has(counter):
		state["offenders"][counter] = []
	var paths: Array = state["offenders"][counter]
	if paths.size() < 12 and not paths.has(path):
		paths.append(path)
