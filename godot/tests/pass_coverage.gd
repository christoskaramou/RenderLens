extends Node3D

## Turns on every feature whose GPU pass a rule names, so tests/test_game_bridge.py can check each name against a live
## gpu_passes capture (run_regressions.py --graphics). The main viewport uses TAA; a SubViewport uses FSR2.

func _ready() -> void:
	# Forward+-only features (MOBILE_NO_TIMESTAMP in run_regressions.py) are left off on Mobile, where Godot 4.4 and
	# 4.5 log errors and 4.6+ warnings for them.
	var forward_plus := str(ProjectSettings.get_setting_with_override("rendering/renderer/rendering_method")) == "forward_plus"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ssao_enabled = forward_plus
	env.ssil_enabled = forward_plus
	env.ssr_enabled = forward_plus
	env.sdfgi_enabled = forward_plus
	env.glow_enabled = true
	env.volumetric_fog_enabled = forward_plus
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 3, 8)
	var attributes := CameraAttributesPractical.new()
	attributes.dof_blur_far_enabled = true
	attributes.dof_blur_near_enabled = true
	camera.attributes = attributes
	add_child(camera)
	camera.look_at(Vector3.ZERO)
	get_viewport().use_taa = forward_plus

	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)
	var omni := OmniLight3D.new()
	omni.shadow_enabled = true
	omni.position = Vector3(-2, 2, 1)
	add_child(omni)
	var spot := SpotLight3D.new()
	spot.shadow_enabled = true
	spot.position = Vector3(2, 3, 1)
	spot.rotation_degrees = Vector3(-90, 0, 0)
	add_child(spot)

	var ground := PlaneMesh.new()
	ground.size = Vector2(20, 20)
	_mesh(ground, Vector3.ZERO, StandardMaterial3D.new())
	_mesh(BoxMesh.new(), Vector3(-2, 0.5, 0), StandardMaterial3D.new())
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(1, 1, 1, 0.5)
	glass.refraction_enabled = true
	_mesh(BoxMesh.new(), Vector3(0, 0.5, 0), glass)
	var skin := StandardMaterial3D.new()
	skin.subsurf_scatter_enabled = forward_plus
	_mesh(SphereMesh.new(), Vector3(2, 0.5, 0), skin)

	var particles := GPUParticles3D.new()
	particles.amount = 64
	particles.collision_base_size = 0.1
	var process := ParticleProcessMaterial.new()
	process.collision_mode = ParticleProcessMaterial.COLLISION_RIGID
	particles.process_material = process
	particles.draw_pass_1 = SphereMesh.new()
	particles.position = Vector3(0, 3, -2)
	add_child(particles)
	var heightfield := GPUParticlesCollisionHeightField3D.new()
	heightfield.size = Vector3(10, 4, 10)
	# The default "When Moved" renders the heightfield once at startup, before the capture.
	heightfield.update_mode = GPUParticlesCollisionHeightField3D.UPDATE_MODE_ALWAYS
	add_child(heightfield)

	# A second viewport on the same world, upscaled with FSR2 (TAA and FSR2 do not run in one viewport).
	var upscaled := SubViewport.new()
	upscaled.size = Vector2i(320, 180)
	upscaled.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	upscaled.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2 if forward_plus else Viewport.SCALING_3D_MODE_BILINEAR
	upscaled.scaling_3d_scale = 0.5
	var upscaled_camera := Camera3D.new()
	upscaled_camera.position = camera.position
	upscaled.add_child(upscaled_camera)
	add_child(upscaled)
	upscaled_camera.look_at(Vector3.ZERO)

	# 2D lights with shadows over an occluder, drawn on top of the 3D view.
	var layer := CanvasLayer.new()
	add_child(layer)
	var backdrop := ColorRect.new()
	backdrop.size = Vector2(200, 200)
	backdrop.color = Color(0.5, 0.5, 0.5, 0.3)
	layer.add_child(backdrop)
	var occluder := LightOccluder2D.new()
	occluder.occluder = OccluderPolygon2D.new()
	occluder.occluder.polygon = PackedVector2Array([Vector2(80, 80), Vector2(120, 80), Vector2(120, 120), Vector2(80, 120)])
	layer.add_child(occluder)
	var glow := GradientTexture2D.new()
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	var point := PointLight2D.new()
	point.texture = glow
	point.shadow_enabled = true
	point.position = Vector2(60, 60)
	point.texture_scale = 4.0
	layer.add_child(point)
	var directional := DirectionalLight2D.new()
	directional.shadow_enabled = true
	layer.add_child(directional)


func _mesh(mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	node.material_override = material
	add_child(node)
	return node
