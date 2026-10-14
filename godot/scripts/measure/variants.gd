extends RefCounted

# Single-toggle variants of heavy_test.tscn, one per fired rule suggestion.

static func apply(scene: Node, name: String) -> bool:
	var env: Environment = scene.get_node("WorldEnvironment").environment
	match name:
		"baseline", "gi_half_resolution":
			pass # gi_half_resolution is applied through override.cfg by the driver
		"sdfgi_off": env.sdfgi_enabled = false
		"ssil_off": env.ssil_enabled = false
		"ssao_off": env.ssao_enabled = false
		"ssr_off": env.ssr_enabled = false
		"ssr_steps_64": env.ssr_max_steps = 64
		"glow_off": env.glow_enabled = false
		"volumetric_fog_off": env.volumetric_fog_enabled = false
		"fog_gi_inject_0": env.volumetric_fog_gi_inject = 0.0
		"dof_off":
			var attributes: CameraAttributesPractical = scene.get_node("Camera3D").attributes
			attributes.dof_blur_far_enabled = false
			attributes.dof_blur_near_enabled = false
		"omni_shadows_off":
			for light in scene.get_node("OmniLights").get_children():
				light.shadow_enabled = false
		"spot_shadows_off":
			for light in scene.get_node("SpotLights").get_children():
				light.shadow_enabled = false
		"directional_distance_100":
			scene.get_node("DirectionalLight3D").directional_shadow_max_distance = 100.0
		_:
			return false
	return true
