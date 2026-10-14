extends RefCounted

## Applies and restores the changes measure_change tries in the running game. Nothing is saved: node and resource
## edits live only in the game process, and a setting is pushed through the viewport property or RenderingServer call
## Godot itself makes for it at startup, without touching ProjectSettings.

const Game = preload("res://addons/render_lens/game_bridge.gd")

## Settings the root viewport applies live (Viewport properties Godot sets from these settings at startup). Not VRS: a
## texture-based shading-rate map built once is lost when the mode changes and not rebuilt on restore (vrs.cpp).
const VIEWPORT_SETTINGS := {
	"rendering/anti_aliasing/quality/msaa_2d": "msaa_2d",
	"rendering/anti_aliasing/quality/msaa_3d": "msaa_3d",
	"rendering/anti_aliasing/quality/screen_space_aa": "screen_space_aa",
	"rendering/anti_aliasing/quality/use_taa": "use_taa",
	"rendering/anti_aliasing/quality/use_debanding": "use_debanding",
	"rendering/scaling_3d/mode": "scaling_3d_mode",
	"rendering/scaling_3d/scale": "scaling_3d_scale",
	"rendering/mesh_lod/lod_change/threshold_pixels": "mesh_lod_threshold",
	"rendering/textures/default_filters/anisotropic_filtering_level": "anisotropic_filtering_level",
	"rendering/textures/default_filters/texture_mipmap_bias": "texture_mipmap_bias",
	"rendering/viewport/hdr_2d": "use_hdr_2d",
	"rendering/2d/sdf/oversize": "sdf_oversize",
	"rendering/lights_and_shadows/positional_shadow/atlas_size": "positional_shadow_atlas_size",
	"rendering/lights_and_shadows/positional_shadow/atlas_16_bits": "positional_shadow_atlas_16_bits",
}
## Settings with a RenderingServer or Engine setter (_push). Every other setting is read once at startup.
const SERVER_SETTINGS := [
	"rendering/lights_and_shadows/directional_shadow/size",
	"rendering/lights_and_shadows/directional_shadow/16_bits",
	"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality",
	"rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality",
	"rendering/environment/ssao/quality",
	"rendering/environment/ssao/half_size",
	"rendering/environment/ssao/blur_passes",
	"rendering/environment/ssao/adaptive_target",
	"rendering/environment/ssil/quality",
	"rendering/environment/ssil/half_size",
	"rendering/environment/ssil/blur_passes",
	"rendering/environment/ssil/adaptive_target",
	"rendering/environment/screen_space_reflection/roughness_quality",
	"rendering/environment/screen_space_reflection/half_size",
	"rendering/environment/subsurface_scattering/subsurface_scattering_quality",
	"rendering/environment/volumetric_fog/volume_size",
	"rendering/environment/volumetric_fog/volume_depth",
	"rendering/global_illumination/gi/use_half_resolution",
	"rendering/global_illumination/sdfgi/frames_to_converge",
	"rendering/global_illumination/sdfgi/frames_to_update_lights",
	"rendering/global_illumination/sdfgi/probe_ray_count",
	"rendering/global_illumination/voxel_gi/quality",
	"rendering/camera/depth_of_field/depth_of_field_bokeh_shape",
	"rendering/camera/depth_of_field/depth_of_field_bokeh_quality",
	"rendering/camera/depth_of_field/depth_of_field_use_jitter",
	"rendering/environment/glow/upscale_mode",
	"rendering/textures/decals/filter",
	"rendering/textures/light_projectors/filter",
	"rendering/2d/shadow_atlas/size",
]
## Viewport settings Godot also reads from ProjectSettings every frame, so the experiment sets both: the 3D scale scales
## the mesh LOD distance (renderer_scene_render_rd.cpp, GLOBAL_GET in 4.4, GLOBAL_GET_CACHED in 4.7.2).
const PROJECT_READ_PER_FRAME := ["rendering/scaling_3d/scale"]
## What measure_change may change: the rendering properties advice suggests (the rules' node_property and experiment
## fields), plus visible on 3D nodes. Other setters, even stored ones on rendering classes, can have effects that writing
## the old value back does not undo (AnimatedSprite2D.animation stops playback, one_shot ends emission, Viewport.own_world_3d
## recreates the world), so no generic "any property" surface is offered. It also leaves out
## properties whose setters reset or resize renderer state a restore cannot bring back: particle amount, fixed_fps and
## trails (the simulation restarts), Sky process_mode and radiance_size, ReflectionProbe update_mode (the shared atlas),
## SubViewport render_target_update_mode (an UPDATE_ONCE that already ran) and the heightfield resolution.
const ALLOWED_PROPERTIES := {
	"Light3D": ["shadow_enabled", "distance_fade_enabled", "light_size", "light_volumetric_fog_energy"],
	"OmniLight3D": ["omni_shadow_mode", "omni_range"],
	"SpotLight3D": ["spot_angle", "spot_range"],
	"DirectionalLight3D": ["directional_shadow_mode", "directional_shadow_max_distance", "directional_shadow_blend_splits"],
	"Light2D": ["shadow_enabled", "shadow_filter"],
	"Environment": ["adjustment_enabled", "fog_enabled", "glow_enabled", "sdfgi_cascades", "sdfgi_enabled", "sdfgi_use_occlusion",
		"ssao_enabled", "ssil_enabled", "ssr_enabled", "ssr_max_steps", "volumetric_fog_enabled", "volumetric_fog_gi_inject"],
	"CameraAttributesPractical": ["dof_blur_far_enabled", "dof_blur_near_enabled"],
	"Camera3D": ["far"],
	# Not visibility_range_end: Godot keeps a per-mesh visibility hysteresis state that restoring the distance does not
	# reset (renderer_scene_cull.cpp), so a mesh can stay hidden.
	"GeometryInstance3D": ["cast_shadow", "ignore_occlusion_culling", "lod_bias"],
	"Decal": ["distance_fade_enabled", "size"],
	"BaseMaterial3D": ["cull_mode", "depth_draw_mode", "heightmap_enabled", "proximity_fade_enabled", "refraction_enabled",
		"shading_mode", "subsurf_scatter_enabled", "texture_filter", "transparency"],
	"Viewport": ["msaa_2d", "msaa_3d", "screen_space_aa", "use_taa", "use_debanding", "scaling_3d_mode", "scaling_3d_scale",
		"mesh_lod_threshold", "anisotropic_filtering_level", "texture_mipmap_bias", "positional_shadow_atlas_size"],
}
## Renderers a RenderingServer setting does anything on (setting prefix -> renderers; the rest run everywhere). The
## Compatibility setters for these are empty or set a flag nothing reads (drivers/gles3, 4.4 and 4.7.2), and Mobile does
## not run the Forward+-only effects; Compatibility runs SSAO from 4.6.
const SETTING_RENDERERS := {
	"rendering/environment/ssao/": ["forward_plus"],
	"rendering/environment/ssil/": ["forward_plus"],
	"rendering/environment/screen_space_reflection/": ["forward_plus"],
	"rendering/environment/subsurface_scattering/": ["forward_plus"],
	"rendering/environment/volumetric_fog/": ["forward_plus"],
	"rendering/global_illumination/": ["forward_plus"],
	"rendering/environment/glow/": ["forward_plus", "mobile"],
	"rendering/camera/depth_of_field/": ["forward_plus", "mobile"],
	"rendering/textures/decals/": ["forward_plus", "mobile"],
	"rendering/textures/light_projectors/": ["forward_plus", "mobile"],
}
## Shadow atlas sizes the renderer rounds to a power of two (light_storage.cpp) while the viewport getter echoes the request.
const POWER_OF_TWO := ["positional_shadow_atlas_size", "rendering/lights_and_shadows/positional_shadow/atlas_size",
	"rendering/lights_and_shadows/directional_shadow/size", "rendering/2d/shadow_atlas/size"]
## Settings Godot applies to an Engine property, which also has a getter, so the live value is restored exactly.
const ENGINE_SETTINGS := {
	"physics/common/physics_ticks_per_second": "physics_ticks_per_second",
	"physics/common/max_physics_steps_per_frame": "max_physics_steps_per_frame",
}

## Undo entries of the active experiment: {object, property, old}, {setting, viewport_property, old},
## {setting, engine_property, old}, {setting, project_value} or {setting} (a RenderingServer setting, pushed again from
## the project's value).
static var _undo: Array = []
## Live setting values while an experiment runs; _value() prefers them over the project's.
static var _live := {}
## Bumped by every apply and restore, so a lease timer only undoes the experiment it was armed for.
static var _generation := 0
## The lease ran out and undid the experiment before the editor asked (measure_change then discards its capture).
static var _expired := false


static func run(tree: SceneTree, arguments: Dictionary) -> Dictionary:
	match str(arguments.get("action", "")):
		"apply":
			# An experiment the editor never restored (its tool was stopped) is undone first.
			restore(tree)
			_expired = false
			var result := apply(tree, arguments.get("changes", []))
			if not result.get("isError", false) and float(arguments.get("lease_seconds", 0.0)) > 0.0:
				_arm(tree, float(arguments.lease_seconds))
			return result
		"restore":
			var expired := _expired
			_expired = false
			return {"restored": restore(tree), "expired": expired}
	return Game.error("experiment action must be apply or restore")


static func apply(tree: SceneTree, changes) -> Dictionary:
	if typeof(changes) != TYPE_ARRAY or changes.is_empty():
		return Game.error("changes must be a non-empty array")
	var applied: Array = []
	var notes: Array = []
	for change in changes:
		var outcome := _apply_one(tree, change)
		if outcome.has("error"):
			restore(tree)
			return Game.error(str(outcome.error))
		if outcome.has("note"):
			notes.append(outcome.note)
		applied.append(outcome)
	return {"applied": applied, "notes": notes}


## The game undoes the experiment by itself when no restore arrives in time: the editor plugin was disabled, the editor
## closed, or its tool was stopped. The timer runs while the game is paused and ignores time_scale.
static func _arm(tree: SceneTree, seconds: float) -> void:
	var generation := _generation
	tree.create_timer(seconds, true, false, true).timeout.connect(func():
		if generation == _generation and not _undo.is_empty():
			restore(tree)
			_expired = true
	)


static func restore(tree: SceneTree) -> int:
	_generation += 1
	var count := _undo.size()
	for i in range(_undo.size() - 1, -1, -1):
		var entry: Dictionary = _undo[i]
		if entry.has("setting"):
			_live.erase(entry.setting)
			if entry.has("viewport_property"):
				tree.root.set(entry.viewport_property, entry.old)
			elif entry.has("engine_property"):
				Engine.set(entry.engine_property, entry.old)
			elif entry.has("project_value"):
				ProjectSettings.set_setting(entry.setting, entry.project_value)
			elif entry.has("server_method"):
				RenderingServer.call(entry.server_method, entry.old)
			else:
				_push(entry.setting)
		elif is_instance_valid(entry.object):
			entry.object.set_indexed(entry.property, entry.old)
	_undo.clear()
	_live.clear()
	return count


static func _apply_one(tree: SceneTree, change) -> Dictionary:
	if typeof(change) != TYPE_DICTIONARY or not change.has("value"):
		return {"error": "Each change needs a value and one of node, class, environment, camera_attributes, viewport or setting"}
	var value = change.value
	if change.has("setting"):
		# A feature override ("size.mobile") is the same live setter.
		var path := str(change.setting)
		var last := path.get_file()
		if last.contains("."):
			path = path.get_base_dir().path_join(last.get_slice(".", 0))
		if _not_power_of_two(path, value) != "":
			return {"error": _not_power_of_two(path, value)}
		if VIEWPORT_SETTINGS.has(path):
			var property: String = VIEWPORT_SETTINGS[path]
			# Godot 4.7 keeps HDR 2D on while HDR output is requested, whatever hdr_2d says (scene_tree.cpp).
			if path == "rendering/viewport/hdr_2d" and ProjectSettings.has_setting("display/window/hdr/request_hdr_output") and bool(ProjectSettings.get_setting_with_override("display/window/hdr/request_hdr_output")):
				return {"error": "HDR output keeps HDR 2D on, so changing rendering/viewport/hdr_2d alone would not change the game"}
			if _renderer_ignores(property, value) != "":
				return {"error": _renderer_ignores(property, value)}
			if _fsr_falls_back(tree.root, property, value) != "":
				return {"error": _fsr_falls_back(tree.root, property, value)}
			if _out_of_hint(path, value) != "":
				return {"error": _out_of_hint(path, value)}
			_undo.append({"setting": path, "viewport_property": property, "old": tree.root.get(property)})
			tree.root.set(property, value)
			if not _same(tree.root.get(property), value):
				return {"error": "Godot did not accept %s = %s on the root viewport (it is %s)" % [property, value, tree.root.get(property)]}
			if path == "rendering/anti_aliasing/quality/use_debanding" and RenderingServer.has_method("material_set_use_debanding"):
				_undo.append({"setting": path, "server_method": "material_set_use_debanding", "old": bool(ProjectSettings.get_setting_with_override(path))})
				RenderingServer.call("material_set_use_debanding", bool(value))
			if path in PROJECT_READ_PER_FRAME:
				# Never saved: ProjectSettings.save() is not called. An active feature override ("scale.mobile") is what
				# Godot reads, so overrides are set too.
				for key in [path] + _overrides(path):
					_undo.append({"setting": key, "project_value": ProjectSettings.get_setting(key)})
					ProjectSettings.set_setting(key, value)
			var outcome := {"setting": path, "live_target": "root viewport " + property, "value": tree.root.get(property)}
			if path == "rendering/anti_aliasing/quality/use_debanding" and RenderingServer.has_method("material_set_use_debanding"):
				# The material flag has no getter either (see the RenderingServer settings below).
				outcome["note"] = "%s also sets the material debanding flag, which is restored to the project's value; if the game sets it at run time, set it again." % path
			return outcome
		if ENGINE_SETTINGS.has(path):
			if _out_of_hint(path, value) != "":
				return {"error": _out_of_hint(path, value)}
			var engine_property: String = ENGINE_SETTINGS[path]
			_undo.append({"setting": path, "engine_property": engine_property, "old": Engine.get(engine_property)})
			Engine.set(engine_property, int(value))
			if not _same(Engine.get(engine_property), value):
				return {"error": "Godot did not accept %s = %s (it is %s)" % [path, value, Engine.get(engine_property)]}
			return {"setting": path, "live_target": "Engine." + engine_property, "value": Engine.get(engine_property)}
		if path in SERVER_SETTINGS:
			if path == "rendering/environment/screen_space_reflection/half_size" and not RenderingServer.has_method("environment_set_ssr_half_size"):
				return {"error": "%s has no live setter before Godot 4.6; measure it with two runs instead" % path}
			# From 4.6 the setter only warns that it is deprecated (render_forward_clustered.cpp).
			if path == "rendering/environment/screen_space_reflection/roughness_quality" and Engine.get_version_info().minor >= 6:
				return {"error": "%s does nothing from Godot 4.6, so there is nothing to measure" % path}
			var invalid := _out_of_hint(path, value)
			if invalid != "":
				return {"error": invalid}
			var method := RenderingServer.get_current_rendering_method()
			for prefix in SETTING_RENDERERS:
				var runs_on: Array = SETTING_RENDERERS[prefix]
				# Compatibility runs SSAO from 4.6, but its setter keeps only the quality (drivers/gles3).
				if path == "rendering/environment/ssao/quality" and Engine.get_version_info().minor >= 6:
					runs_on = runs_on + ["gl_compatibility"]
				if path.begins_with(prefix) and not runs_on.has(method):
					return {"error": "%s does nothing on %s, so there is nothing to measure" % [path, method]}
			_undo.append({"setting": path})
			_live[path] = value
			_push(path)
			# RenderingServer has no getter for these, so a value the game set at run time (an options menu) is not known.
			return {"setting": path, "live_target": "RenderingServer", "value": value,
				"note": "%s is restored to the project's value; if the game sets it at run time (an options menu), set it again." % path}
		return {"error": "%s is read once at startup, so it cannot be tried in a running game; measure it with two runs (advise or gpu_passes before and after editing the setting)" % path}
	var property := str(change.get("property", ""))
	if property == "":
		return {"error": "A node, class, environment, camera_attributes or viewport change needs a property"}
	var targets := _targets(tree, change)
	if targets.is_empty():
		return {"error": "No object in the running scene matches %s" % JSON.stringify(change)}
	# only_above: change only objects whose current value is higher, so a preset that lowers a setting never raises it
	# on objects that already use something cheaper.
	var only_above = change.get("only_above")
	var changed := 0
	var lower := 0
	var skipped := {}
	var parts := property.split(":")
	for target in targets:
		if not parts[0] in target:
			skipped[target.get_class()] = int(skipped.get(target.get_class(), 0)) + 1
			continue
		# Undo the object the path reaches (the Environment of environment:ssr_enabled), so a resource swapped in later
		# is not the one restored.
		var owner: Object = target
		var leaf := property
		for depth in range(parts.size() - 1, 0, -1):
			var inner = target.get_indexed(":".join(parts.slice(0, depth)))
			if inner is Object:
				owner = inner
				leaf = ":".join(parts.slice(depth))
				break
		# Making a camera current, or disabling the current Camera2D, hands the viewport to its first eligible camera, and
		# undoing it does not hand it back (camera_3d.cpp and camera_2d.cpp clear_current). Checked on the object the path
		# reaches, so camera:enabled through another node is caught too.
		if (owner is Camera3D or owner is Camera2D) and leaf.get_slice(":", 0) in ["current", "enabled"]:
			return {"error": "Switching the active camera cannot be undone exactly, so it is not tried live"}
		# Attaching a script again creates a new instance with its initial state (Object.set_script), so the game's
		# runtime state would be lost.
		if leaf.get_slice(":", 0) == "script":
			return {"error": "Changing a script cannot be undone without losing its state, so it is not tried live"}
		# Only what a scene or resource file stores, the way a project edit would change it: runtime-only properties
		# (AnimationPlayer.current_animation schedules a deferred stop) can have effects that writing the old value back
		# does not undo.
		if not _stored(owner, leaf.get_slice(":", 0)):
			return {"error": "%s is not a stored property of %s, so it is not tried live" % [leaf.get_slice(":", 0), owner.get_class()]}
		if not _allowed(owner, leaf.get_slice(":", 0)):
			return {"error": "measure_change changes only the rendering properties advice suggests, not %s.%s; allowed: %s, and visible on 3D nodes" % [owner.get_class(), leaf.get_slice(":", 0), JSON.stringify(ALLOWED_PROPERTIES)]}
		# The project setting a viewport property mirrors has an inspector range (scale 0.25 to 2.0) the viewport does not
		# enforce, so only the enum hints below apply; a negative atlas size is caught by the power-of-two check.
		if owner is Viewport and _fsr_falls_back(owner, leaf, value) != "":
			return {"error": _fsr_falls_back(owner, leaf, value)}
		if _not_power_of_two(leaf, value) != "":
			return {"error": _not_power_of_two(leaf, value)}
		var ignored := _renderer_ignores(leaf, value) if owner is Viewport else _effect_ignored(owner, leaf.get_slice(":", 0))
		if ignored != "":
			return {"error": ignored}
		# A value outside the property's own enum or range is stored and echoed by some setters while the renderer
		# rejects it (GPUParticlesCollisionHeightField3D.resolution), so check the hint first.
		# Enum hints only: a node's range hint is an inspector limit, not a runtime one (lod_bias 0 is valid below its 0.001).
		var hinted := _hint_error(_property_info(owner, leaf.get_slice(":", 0)), value, "%s.%s" % [owner.get_class(), leaf], false)
		if hinted != "" and not leaf.contains(":"):
			return {"error": hinted}
		var old = owner.get_indexed(leaf)
		# A resource swapped out and back is not the same state (MeshInstance3D drops its blend-shape weights when its mesh
		# changes, mesh_instance_3d.cpp), so experiments change values, not resources.
		if typeof(old) == TYPE_OBJECT:
			return {"error": "%s holds a resource; replacing it is not tried live" % property}
		if only_above != null and not (typeof(old) in [TYPE_INT, TYPE_FLOAT] and float(old) > float(only_above)):
			lower += 1
			continue
		_undo.append({"object": owner, "property": leaf, "old": old})
		owner.set_indexed(leaf, value)
		if not _same(owner.get_indexed(leaf), value):
			return {"error": "Godot did not accept %s = %s on %s (it is %s)" % [property, value, target, owner.get_indexed(leaf)]}
		changed += 1
	if changed == 0 and lower > 0:
		return {"error": "No object has %s above %s, so there is nothing to try" % [property, only_above]}
	if changed == 0:
		return {"error": "No matching object has the property %s (found %s)" % [property, JSON.stringify(skipped)]}
	var outcome := {"property": property, "value": value, "objects": changed}
	if lower > 0:
		outcome["already_lower"] = lower
	if not skipped.is_empty():
		# A physical camera has no dof_blur toggles, for example; the experiment then covers only part of the scene.
		outcome["skipped"] = skipped
		outcome["note"] = "%s left unchanged on objects without it: %s" % [property, JSON.stringify(skipped)]
	return outcome


static func _targets(tree: SceneTree, change: Dictionary) -> Array:
	var root := tree.current_scene
	var out: Array = []
	if change.has("viewport"):
		out.append(tree.root)
	elif change.has("node"):
		var node: Node = root.get_node_or_null(NodePath(str(change.node))) if root != null else null
		if node != null:
			out.append(node)
	elif change.has("class"):
		for node in _nodes(tree):
			if node.is_class(str(change["class"])) or _script_is(node.get_script(), str(change["class"])):
				out.append(node)
	elif change.has("environment") or change.has("camera_attributes"):
		# Every Environment or CameraAttributes in use: WorldEnvironment nodes and cameras.
		var key := "environment" if change.has("environment") else "camera_attributes"
		for node in _nodes(tree):
			var resource = null
			if node is WorldEnvironment:
				resource = node.environment if key == "environment" else node.camera_attributes
			elif node is Camera3D:
				resource = node.environment if key == "environment" else node.attributes
			if resource != null and not out.has(resource):
				out.append(resource)
		# The project's default environment reaches the renderer as the world's fallback (scene_tree.cpp,
		# renderer_scene_cull.cpp), with no node holding it.
		# Each viewport's world (a SubViewport can own one): its Environment (set directly or by a WorldEnvironment) and its
		# fallback, or its camera attributes.
		var viewports: Array = [tree.root] + _nodes(tree).filter(func(node): return node is Viewport)
		for viewport in viewports:
			var world: World3D = viewport.find_world_3d()
			if world == null:
				continue
			var candidates: Array = [world.environment, world.fallback_environment] if key == "environment" else [world.camera_attributes]
			for resource in candidates:
				if resource != null and not out.has(resource):
					out.append(resource)
	return out


## Viewport features a renderer does not run: Godot 4.4 and 4.5 refuse them with an error, 4.6 and later warn and skip
## them, and either way the Viewport getter returns the requested value (renderer_viewport.cpp).
static func _renderer_ignores(property: String, value) -> String:
	var method := RenderingServer.get_current_rendering_method()
	# Compatibility reads these at startup or does not implement them: empty setters in render_scene_buffers_gles3.h and
	# texture_storage.h (VRS), and 2D MSAA only warns (texture_storage.cpp), 4.4 to 4.7.2.
	if method == "gl_compatibility" and property in ["anisotropic_filtering_level", "texture_mipmap_bias", "use_debanding", "fsr_sharpness", "msaa_2d"]:
		return "%s is read at startup on gl_compatibility; measure it with two runs instead" % property
	# Godot substitutes another upscaler for MetalFX when the device lacks it or the scale is outside its device limits
	# (renderer_viewport.cpp), which a script cannot fully check, so the viewport would report MetalFX but run something else.
	if property == "scaling_3d_mode" and int(value) in [3, 4]:
		return "MetalFX scaling depends on device limits Godot checks internally; measure it with two runs instead"
	if property == "use_taa" and bool(value) and method != "forward_plus":
		return "TAA only runs on Forward+ (this game uses %s)" % method
	# 1 FSR, 2 FSR2, 4 MetalFX Temporal: Forward+ only; 3 MetalFX Spatial: Forward+ or Mobile.
	if property == "scaling_3d_mode" and ((int(value) in [1, 2, 4] and method != "forward_plus") or (int(value) == 3 and method == "gl_compatibility")):
		return "3D scaling mode %d does not run on %s" % [int(value), method]
	if property == "screen_space_aa" and int(value) != 0 and method == "gl_compatibility":
		return "Screen-space AA does not run on gl_compatibility"
	return ""


## Environment and material effects a renderer does not run: Godot stores the flag (environment_storage.cpp warns) but
## nothing renders, so there is no cost to measure. Compatibility runs SSAO from 4.6.
static func _effect_ignored(object: Object, property: String) -> String:
	var method := RenderingServer.get_current_rendering_method()
	var forward_only := {
		"Environment": ["ssr_enabled", "ssr_max_steps", "ssil_enabled", "sdfgi_enabled", "sdfgi_cascades", "sdfgi_use_occlusion",
			"volumetric_fog_enabled", "volumetric_fog_gi_inject"],
		"BaseMaterial3D": ["subsurf_scatter_enabled"],
		"Light3D": ["light_volumetric_fog_energy"],
	}
	# Compatibility renders no decals; its decal setters are empty (drivers/gles3/storage/texture_storage.cpp).
	if object is Decal and method == "gl_compatibility":
		return "Decals do not render on gl_compatibility"
	# Depth of field runs on Forward+ and Mobile; Compatibility stores the flag and warns (camera_attributes_storage.cpp).
	if object is CameraAttributes and property.begins_with("dof_") and method == "gl_compatibility":
		return "Depth of field does not run on gl_compatibility"
	if object is Environment and property == "ssao_enabled" and method != "forward_plus" and not (method == "gl_compatibility" and Engine.get_version_info().minor >= 6):
		return "SSAO does not run on %s" % method
	for owner in forward_only:
		if object.is_class(owner) and forward_only[owner].has(property) and method != "forward_plus":
			return "%s only runs on Forward+ (this game uses %s)" % [property, method]
	return ""


## Every mode but bilinear only downscales: above a 3D scale of 1.0 Godot renders bilinear instead (renderer_viewport.cpp,
## 4.4 to 4.7.2), while the viewport getter still reports the requested mode.
static func _fsr_falls_back(viewport: Viewport, property: String, value) -> String:
	# Under FSR 2, a temporal upscaler, Godot turns TAA off (renderer_viewport.cpp), while use_taa still reads true.
	if property == "use_taa" and typeof(value) == TYPE_BOOL and value and int(viewport.scaling_3d_mode) == Viewport.SCALING_3D_MODE_FSR2:
		return "TAA is off under FSR 2, which does its own temporal antialiasing, so turning it on would change nothing"
	# MetalFX Temporal (mode 4) turns TAA and 3D MSAA off too (renderer_viewport.cpp, 4.4 to 4.7.2).
	if int(viewport.scaling_3d_mode) == 4 and (property == "msaa_3d" or (property == "use_taa" and typeof(value) == TYPE_BOOL and value)):
		return "MetalFX Temporal turns TAA and 3D MSAA off, so changing %s would change nothing" % property
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return ""
	var mode := int(value) if property == "scaling_3d_mode" else int(viewport.scaling_3d_mode)
	var scale := float(value) if property == "scaling_3d_scale" else float(viewport.scaling_3d_scale)
	# FSR 1/2 (1, 2), MetalFX (3, 4) and Nearest (5, 4.7+) only downscale: above 1.0 Godot renders bilinear.
	if property in ["scaling_3d_mode", "scaling_3d_scale"] and mode in [1, 2, 3, 4, 5] and scale > 1.0:
		return "3D scaling mode %d only downscales; at a 3D scale of %s Godot renders bilinear instead, so the change would not be what is measured" % [mode, scale]
	return ""


static func _not_power_of_two(name: String, value) -> String:
	# 0 on the viewport property turns positional shadows off (Viewport.positional_shadow_atlas_size).
	if name == "positional_shadow_atlas_size" and typeof(value) in [TYPE_INT, TYPE_FLOAT] and float(value) == 0.0:
		return ""
	if POWER_OF_TWO.has(name) and typeof(value) in [TYPE_INT, TYPE_FLOAT] and (int(value) <= 0 or int(value) & (int(value) - 1) != 0 or float(value) != floorf(float(value))):
		return "%s is rounded to a power of two by the renderer; ask for one (2048, 4096, 8192), not %s" % [name, value]
	return ""


static func _property_info(object: Object, property: String) -> Dictionary:
	for info in object.get_property_list():
		if str(info.name) == property:
			return info
	return {}


static func _overrides(path: String) -> Array:
	var out: Array = []
	for property in ProjectSettings.get_property_list():
		if str(property.name).begins_with(path + "."):
			out.append(str(property.name))
	return out


## RenderingServer has no getters, and it rejects a quality index outside the setting's enum (printing an error) or keeps
## its old value; check the value against the hint ProjectSettings documents for it first.
static func _out_of_hint(path: String, value) -> String:
	if typeof(value) not in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT]:
		return "%s needs a number or a boolean" % path
	for property in ProjectSettings.get_property_list():
		if str(property.name) == path:
			return _hint_error(property, value, path)
	return ""


## An enum value outside its items ("Low,High" numbers them from 0; "Low:2,High:4" gives each its value), or a number
## outside a range hint that has no or_greater / or_less.
static func _hint_error(info: Dictionary, value, label: String, ranges := true) -> String:
	if info.is_empty():
		return ""
	# JSON true/false into a number (volume_size = false would push 0), or a number into a boolean.
	var numeric: bool = int(info.get("type", 0)) in [TYPE_INT, TYPE_FLOAT]
	if numeric and typeof(value) == TYPE_BOOL:
		return "%s takes a number, not %s" % [label, value]
	if int(info.get("type", 0)) == TYPE_BOOL and typeof(value) != TYPE_BOOL:
		return "%s takes true or false, not %s" % [label, value]
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return ""
	# An integer property or setting truncates 2.5 to 2 while the result would report 2.5.
	if int(info.get("type", 0)) == TYPE_INT and float(value) != floorf(float(value)):
		return "%s takes a whole number, not %s" % [label, value]
	var hint_string := str(info.get("hint_string", ""))
	var parts := hint_string.split(",")
	if int(info.get("hint", 0)) == PROPERTY_HINT_ENUM and int(info.get("type", 0)) == TYPE_INT:
		var allowed: Array = []
		for index in parts.size():
			allowed.append(int(parts[index].get_slice(":", 1)) if parts[index].contains(":") else index)
		if float(value) != floorf(float(value)) or not allowed.has(int(value)):
			return "%s takes one of %s (%s), not %s" % [label, allowed, hint_string, value]
	if ranges and int(info.get("hint", 0)) == PROPERTY_HINT_RANGE and parts.size() >= 2:
		if float(value) < float(parts[0]) and not hint_string.contains("or_less"):
			return "%s takes %s to %s, not %s" % [label, parts[0], parts[1], value]
		if float(value) > float(parts[1]) and not hint_string.contains("or_greater"):
			return "%s takes %s to %s, not %s" % [label, parts[0], parts[1], value]
	return ""


## Godot stores JSON numbers in int, float and bool properties alike, and JSON strings in String, StringName and NodePath
## properties; compare them as numbers and as text.
static func _same(a, b) -> bool:
	if typeof(a) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT]:
		return is_equal_approx(float(a), float(b))
	if typeof(a) in [TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH] and typeof(b) in [TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH]:
		return str(a) == str(b)
	return typeof(a) == typeof(b) and a == b


static func _allowed(object: Object, property: String) -> bool:
	# Node3D only: hiding a CanvasItem also hides the Controls under it, and a focused Control loses its keyboard focus,
	# which showing it again does not take back.
	if property == "visible" and object is Node3D:
		return true
	return ALLOWED_PROPERTIES.keys().any(func(name): return object.is_class(name) and ALLOWED_PROPERTIES[name].has(property))


static func _stored(object: Object, property: String) -> bool:
	for info in object.get_property_list():
		if str(info.name) == property:
			return int(info.usage) & PROPERTY_USAGE_STORAGE != 0
	return false


## A script class_name matches the script or any script it extends (is_class() only knows native classes).
static func _script_is(script: Script, name: String) -> bool:
	while script != null:
		if script.get_global_name() == name:
			return true
		script = script.get_base_script()
	return false


static func _nodes(tree: SceneTree) -> Array:
	# Autoloads and nodes scripts add to the root render with the scene, as in scene_snapshot.
	var out: Array = []
	var stack: Array = tree.root.get_children()
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		out.append(node)
		stack.append_array(node.get_children())
	return out


static func _value(path: String):
	return _live[path] if _live.has(path) else ProjectSettings.get_setting_with_override(path)


static func _push(path: String) -> void:
	var dir := "rendering/lights_and_shadows/directional_shadow/"
	var ssao := "rendering/environment/ssao/"
	var ssil := "rendering/environment/ssil/"
	var dof := "rendering/camera/depth_of_field/"
	var fog := "rendering/environment/volumetric_fog/"
	match path:
		"rendering/lights_and_shadows/directional_shadow/size", "rendering/lights_and_shadows/directional_shadow/16_bits":
			RenderingServer.directional_shadow_atlas_set_size(int(_value(dir + "size")), bool(_value(dir + "16_bits")))
		"rendering/lights_and_shadows/directional_shadow/soft_shadow_filter_quality":
			RenderingServer.directional_soft_shadow_filter_set_quality(int(_value(path)))
		"rendering/lights_and_shadows/positional_shadow/soft_shadow_filter_quality":
			RenderingServer.positional_soft_shadow_filter_set_quality(int(_value(path)))
		"rendering/environment/ssao/quality", "rendering/environment/ssao/half_size", "rendering/environment/ssao/blur_passes", "rendering/environment/ssao/adaptive_target":
			RenderingServer.environment_set_ssao_quality(int(_value(ssao + "quality")), bool(_value(ssao + "half_size")), float(_value(ssao + "adaptive_target")), int(_value(ssao + "blur_passes")), float(_value(ssao + "fadeout_from")), float(_value(ssao + "fadeout_to")))
		"rendering/environment/ssil/quality", "rendering/environment/ssil/half_size", "rendering/environment/ssil/blur_passes", "rendering/environment/ssil/adaptive_target":
			RenderingServer.environment_set_ssil_quality(int(_value(ssil + "quality")), bool(_value(ssil + "half_size")), float(_value(ssil + "adaptive_target")), int(_value(ssil + "blur_passes")), float(_value(ssil + "fadeout_from")), float(_value(ssil + "fadeout_to")))
		"rendering/environment/screen_space_reflection/roughness_quality":
			RenderingServer.environment_set_ssr_roughness_quality(int(_value(path)))
		"rendering/environment/screen_space_reflection/half_size":
			RenderingServer.call("environment_set_ssr_half_size", bool(_value(path)))
		"rendering/environment/subsurface_scattering/subsurface_scattering_quality":
			RenderingServer.sub_surface_scattering_set_quality(int(_value(path)))
		"rendering/environment/volumetric_fog/volume_size", "rendering/environment/volumetric_fog/volume_depth":
			RenderingServer.environment_set_volumetric_fog_volume_size(int(_value(fog + "volume_size")), int(_value(fog + "volume_depth")))
		"rendering/global_illumination/gi/use_half_resolution":
			RenderingServer.gi_set_use_half_resolution(bool(_value(path)))
		"rendering/global_illumination/sdfgi/frames_to_converge":
			RenderingServer.environment_set_sdfgi_frames_to_converge(int(_value(path)))
		"rendering/global_illumination/sdfgi/frames_to_update_lights":
			RenderingServer.environment_set_sdfgi_frames_to_update_light(int(_value(path)))
		"rendering/global_illumination/sdfgi/probe_ray_count":
			RenderingServer.environment_set_sdfgi_ray_count(int(_value(path)))
		"rendering/global_illumination/voxel_gi/quality":
			RenderingServer.voxel_gi_set_quality(int(_value(path)))
		"rendering/camera/depth_of_field/depth_of_field_bokeh_shape":
			RenderingServer.camera_attributes_set_dof_blur_bokeh_shape(int(_value(path)))
		"rendering/camera/depth_of_field/depth_of_field_bokeh_quality", "rendering/camera/depth_of_field/depth_of_field_use_jitter":
			RenderingServer.camera_attributes_set_dof_blur_quality(int(_value(dof + "depth_of_field_bokeh_quality")), bool(_value(dof + "depth_of_field_use_jitter")))
		"rendering/environment/glow/upscale_mode":
			RenderingServer.environment_glow_set_use_bicubic_upscale(int(_value(path)) > 0)
		"rendering/textures/decals/filter":
			RenderingServer.decals_set_filter(int(_value(path)))
		"rendering/textures/light_projectors/filter":
			RenderingServer.light_projectors_set_filter(int(_value(path)))
		"rendering/2d/shadow_atlas/size":
			RenderingServer.canvas_set_shadow_texture_size(int(_value(path)))
