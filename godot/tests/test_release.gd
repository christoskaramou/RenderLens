extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scripts := DirAccess.get_files_at("res://addons/render_lens/tools")
	for file in scripts:
		if file.ends_with(".gd"):
			var loaded = load("res://addons/render_lens/tools/" + file)
			assert(loaded != null and loaded.can_instantiate(), "Tool did not compile: " + file)
	for file in ["plugin.gd", "debugger_plugin.gd", "frame_samples.gd", "runtime/bridge.gd"]:
		var loaded = load("res://addons/render_lens/" + file)
		assert(loaded != null and loaded.can_instantiate(), "Script did not compile: " + file)
	var Server = load("res://addons/render_lens/mcp_server.gd")
	for origin in ["http://localhost", "http://localhost:3000", "http://127.0.0.1:43788", "http://[::1]:1234"]:
		assert(Server._local_origin(origin), origin)
	for origin in ["http://localhost.attacker.example", "http://127.0.0.1.attacker.example", "http://localhost@evil.example", "null", "http://localhost:99999"]:
		assert(not Server._local_origin(origin), origin)
	var server = Server.new()
	var body := JSON.stringify({"name": "Κόσμος"})
	var response: String = server._build_http_response(200, "OK", "application/json", body)
	assert(response.contains("Content-Length: %d\r\n" % body.to_utf8_buffer().size()))
	# A tool whose script is missing (a partial or old install) is not listed. This runs in a disposable copy.
	var compare_script := ProjectSettings.globalize_path("res://addons/render_lens/tools/capture_compare.gd")
	assert(DirAccess.rename_absolute(compare_script, compare_script + ".off") == OK)
	var partial: Array = server._handle_tools_list({}).tools.map(func(tool): return tool.name)
	assert(DirAccess.rename_absolute(compare_script + ".off", compare_script) == OK)
	assert(not partial.has("capture_compare") and partial.has("advise"), "A tool without its script was listed: %s" % [partial])
	for tool in server._handle_tools_list({}).tools:
		assert(tool.name == "ping_render_lens" or FileAccess.file_exists("res://addons/render_lens/tools/%s.gd" % tool.name))
		assert(typeof(tool.inputSchema.properties) == TYPE_DICTIONARY)
		assert(not tool.inputSchema.properties.has("required"))
	assert(server._handle_tools_call({"name": "frame_timing", "arguments": {"frames": "ten"}}).isError)
	assert(server._handle_tools_call({"name": "frame_timing", "arguments": {"source": "auto"}}).isError)
	assert(server._handle_tools_call({"name": "frame_timing", "arguments": {"_cancel": {}}}).isError)
	assert(server._handle_tools_call({"name": "frame_timing", "arguments": {"unknown": {}}}).isError)
	assert(server._handle_tools_call({"name": "capture_compare", "arguments": {}}).isError)
	assert(server._handle_tools_call({"name": "api_validation_capture"}).isError)
	server.free()
	var Capture = load("res://addons/render_lens/tools/capture_viewport.gd")
	var low_processor := OS.low_processor_usage_mode
	assert((await Capture.execute({"max_width": 0})).isError)
	assert((await Capture.execute({"debug_draw": "unsupported"})).isError)
	assert(OS.low_processor_usage_mode == low_processor, "Invalid capture changed processor mode")
	# Headless Godot never draws (main.cpp skips RenderingServer.draw), like a minimized window: the capture must not wait forever.
	var undrawn: Dictionary = await Capture.execute({"settle_frames": 0})
	assert(undrawn.get("isError", false) and str(undrawn.content[0].text).find("drew no frame") >= 0, "A capture without a drawn frame did not fail: %s" % undrawn)
	assert(OS.low_processor_usage_mode == low_processor, "A capture without a drawn frame changed processor mode")
	var Collect = load("res://addons/render_lens/tools/collect_metrics.gd")
	assert((await Collect.execute({"source": "game"})).isError, "Missing game silently became editor metrics")
	_test_timing_and_ranking()
	_test_comparison()
	_test_adapted_rules()
	_test_bridge_recovery()
	_test_hardening()
	_test_third_review()
	await _test_experiment()
	await _test_wall_clock()
	_test_support_link()
	print("Release regressions passed")
	quit(0)

## The dock's tip link: shown, and opening a Ko-fi page (LinkButton opens its uri on press).
func _test_support_link() -> void:
	var dock: Node = load("res://addons/render_lens/dock_panel.tscn").instantiate()
	var link = dock.get_node_or_null("SupportLink")
	assert(link is LinkButton and link.visible and str(link.uri).begins_with("https://ko-fi.com/"), "The dock has no Ko-fi support link")
	var note = dock.get_node_or_null("SupportNote")
	assert(note is Label and note.visible and note.text.contains("improve"), "The dock has no note asking what to improve")
	dock.free()

## measure_change: the in-game apply/restore and the editor-side comparison, without a running game.
func _test_experiment() -> void:
	if not FileAccess.file_exists("res://addons/render_lens/runtime/experiment.gd"):
		return
	var Experiment = load("res://addons/render_lens/runtime/experiment.gd")
	var scene := Node3D.new()
	scene.name = "ExperimentScene"
	var world := WorldEnvironment.new()
	world.name = "World"
	world.environment = Environment.new()
	world.environment.ssr_enabled = true
	scene.add_child(world)
	for i in 2:
		var omni := OmniLight3D.new()
		omni.shadow_enabled = true
		scene.add_child(omni)
	root.add_child(scene)
	current_scene = scene
	var msaa := root.msaa_3d
	var applied: Dictionary = Experiment.run(self, {"action": "apply", "changes": [
		{"class": "OmniLight3D", "property": "shadow_enabled", "value": false},
		{"environment": true, "property": "ssr_enabled", "value": false},
		{"node": "World", "property": "environment:glow_enabled", "value": true},
		{"setting": "rendering/anti_aliasing/quality/msaa_3d", "value": 2},
		{"setting": "rendering/lights_and_shadows/positional_shadow/atlas_size.mobile", "value": 1024},
		{"setting": "rendering/environment/ssao/quality", "value": 0},
	]})
	assert(not applied.get("isError", false) and applied.applied[0].objects == 2, str(applied))
	assert(scene.get_child(1).shadow_enabled == false and scene.get_child(2).shadow_enabled == false)
	assert(not world.environment.ssr_enabled and world.environment.glow_enabled)
	assert(root.msaa_3d == Viewport.MSAA_4X and root.positional_shadow_atlas_size == 1024)
	assert(Experiment.run(self, {"action": "restore"}).restored == 7)
	assert(scene.get_child(1).shadow_enabled and scene.get_child(2).shadow_enabled and world.environment.ssr_enabled and not world.environment.glow_enabled)
	assert(root.msaa_3d == msaa)
	# All or nothing: a setting read only at startup fails the whole experiment and undoes what came before it.
	var refused: Dictionary = Experiment.run(self, {"action": "apply", "changes": [
		{"class": "OmniLight3D", "property": "shadow_enabled", "value": false},
		{"setting": "rendering/driver/depth_prepass/enable", "value": false},
	]})
	assert(refused.get("isError", false) and str(refused.content[0].text).contains("startup"), str(refused))
	assert(scene.get_child(1).shadow_enabled)
	assert(Experiment.run(self, {"action": "apply", "changes": [{"class": "OmniLight3D", "property": "no_such_property", "value": 1}]}).get("isError", false))
	assert(Experiment.run(self, {"action": "apply", "changes": [{"class": "Decal", "property": "size", "value": 1}]}).get("isError", false))
	# An experiment the editor never restored is undone by the next one.
	Experiment.run(self, {"action": "apply", "changes": [{"class": "OmniLight3D", "property": "shadow_enabled", "value": false}]})
	Experiment.run(self, {"action": "apply", "changes": [{"environment": true, "property": "ssr_enabled", "value": false}]})
	assert(scene.get_child(1).shadow_enabled and not world.environment.ssr_enabled)
	Experiment.run(self, {"action": "restore"})
	assert(world.environment.ssr_enabled)
	# An Engine-backed setting restores the game's live value, not the project's.
	var ticks := Engine.physics_ticks_per_second
	Engine.physics_ticks_per_second = 90
	Experiment.run(self, {"action": "apply", "changes": [{"setting": "physics/common/physics_ticks_per_second", "value": 30}]})
	assert(Engine.physics_ticks_per_second == 30)
	Experiment.run(self, {"action": "restore"})
	assert(Engine.physics_ticks_per_second == 90, "The live physics rate was not restored")
	Engine.physics_ticks_per_second = ticks
	# Objects without the property (a physical camera has no DOF toggles) are reported, not silently skipped.
	for attributes in [CameraAttributesPractical.new(), CameraAttributesPhysical.new()]:
		var camera := Camera3D.new()
		camera.attributes = attributes
		scene.add_child(camera)
	var dof: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"camera_attributes": true, "property": "dof_blur_far_enabled", "value": true}]})
	assert(dof.applied[0].objects == 1 and dof.applied[0].skipped == {"CameraAttributesPhysical": 1} and dof.notes.size() == 1, str(dof))
	Experiment.run(self, {"action": "restore"})
	var server_note: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/environment/ssao/quality", "value": 1}]})
	assert(server_note.notes.size() == 1 and str(server_note.notes[0]).contains("project's value"), str(server_note))
	Experiment.run(self, {"action": "restore"})
	# A script class_name also matches nodes whose script extends it.
	var base_path := "user://render_lens_experiment_base.gd"
	var base_file := FileAccess.open(base_path, FileAccess.WRITE)
	base_file.store_string("class_name RenderLensExperimentBase\nextends Node3D\n")
	base_file.close()
	var derived := GDScript.new()
	derived.source_code = 'extends "%s"\n' % base_path
	derived.reload()
	var enemy := Node3D.new()
	enemy.set_script(derived)
	scene.add_child(enemy)
	var by_class: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"class": "RenderLensExperimentBase", "property": "visible", "value": false}]})
	assert(by_class.applied[0].objects == 1 and not enemy.visible, str(by_class))
	Experiment.run(self, {"action": "restore"})
	assert(enemy.visible)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(base_path))
	# Only_above leaves cheaper objects alone; a value Godot refuses fails the whole experiment.
	var filters: Array = []
	for filter in [PointLight2D.SHADOW_FILTER_PCF13, PointLight2D.SHADOW_FILTER_NONE]:
		var light := PointLight2D.new()
		light.shadow_filter = filter
		scene.add_child(light)
		filters.append(light)
	var lowered: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"class": "Light2D", "property": "shadow_filter", "value": 1, "only_above": 1}]})
	assert(lowered.applied[0].objects == 1 and lowered.applied[0].already_lower == 1, str(lowered))
	assert(filters[0].shadow_filter == PointLight2D.SHADOW_FILTER_PCF5 and filters[1].shadow_filter == PointLight2D.SHADOW_FILTER_NONE)
	Experiment.run(self, {"action": "restore"})
	assert(filters[0].shadow_filter == PointLight2D.SHADOW_FILTER_PCF13)
	var refused_value: Dictionary = Experiment.run(self, {"action": "apply", "changes": [
		{"class": "OmniLight3D", "property": "shadow_enabled", "value": false},
		{"viewport": true, "property": "scaling_3d_scale", "value": 5.0},
	]})
	# Godot clamps the scale to 2.0 (viewport.cpp, 4.4 to 4.7.2), so the requested 5.0 is not what would be measured.
	assert(refused_value.get("isError", false) and scene.get_child(1).shadow_enabled and is_equal_approx(root.scaling_3d_scale, 1.0), str(refused_value))
	# The Environment an indexed path reached is restored, even after the node points at another one.
	var first_environment := world.environment
	Experiment.run(self, {"action": "apply", "changes": [{"node": "World", "property": "environment:ssr_enabled", "value": false}]})
	world.environment = Environment.new()
	world.environment.ssr_enabled = false
	Experiment.run(self, {"action": "restore"})
	assert(first_environment.ssr_enabled and not world.environment.ssr_enabled, "The restore followed the node to a new Environment")
	world.environment = first_environment
	# A path ending in a value component (a Vector3's x) changes and restores that component.
	var decal := Decal.new()
	decal.name = "Decal"
	scene.add_child(decal)
	var width := decal.size.x
	Experiment.run(self, {"action": "apply", "changes": [{"node": "Decal", "property": "size:x", "value": 4.0}]})
	assert(is_equal_approx(decal.size.x, 4.0))
	Experiment.run(self, {"action": "restore"})
	assert(is_equal_approx(decal.size.x, width))
	# Only the rendering properties advice suggests change (Environment.background_color is not one).
	var colour: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"node": "World", "property": "environment:background_color:r", "value": 0.25}]})
	assert(colour.get("isError", false) and str(colour.content[0].text).contains("rendering properties"), str(colour))
	var own_world: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"viewport": true, "property": "own_world_3d", "value": true}]})
	assert(own_world.get("isError", false) and not root.own_world_3d, str(own_world))
	var atlas: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/lights_and_shadows/positional_shadow/atlas_size", "value": -1}]})
	assert(atlas.get("isError", false), str(atlas))
	# The renderer rounds atlas sizes to a power of two, so other sizes are refused.
	for odd in [{"viewport": true, "property": "positional_shadow_atlas_size", "value": 3000}, {"setting": "rendering/lights_and_shadows/directional_shadow/size", "value": 3000}]:
		var rounded: Dictionary = Experiment.run(self, {"action": "apply", "changes": [odd]})
		assert(rounded.get("isError", false) and str(rounded.content[0].text).contains("power of two"), str(rounded))
	# The 2D atlas is rounded too; 0 turns positional shadows off; FSR above scale 1.0 falls back.
	assert(Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/2d/shadow_atlas/size", "value": 3000}]}).get("isError", false))
	var small_scale: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"viewport": true, "property": "scaling_3d_scale", "value": 0.2}]})
	assert(not small_scale.get("isError", false) and is_equal_approx(root.scaling_3d_scale, 0.2), str(small_scale))
	Experiment.run(self, {"action": "restore"})
	var off: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"viewport": true, "property": "positional_shadow_atlas_size", "value": 0}]})
	assert(not off.get("isError", false) and root.positional_shadow_atlas_size == 0, str(off))
	Experiment.run(self, {"action": "restore"})
	assert(Experiment._fsr_falls_back(root, "scaling_3d_scale", 1.5) == "" or root.scaling_3d_mode in [Viewport.SCALING_3D_MODE_FSR, Viewport.SCALING_3D_MODE_FSR2])
	var upscaled := SubViewport.new()
	upscaled.scaling_3d_scale = 1.5
	assert(Experiment._fsr_falls_back(upscaled, "scaling_3d_mode", Viewport.SCALING_3D_MODE_FSR2) != "" and Experiment._fsr_falls_back(upscaled, "scaling_3d_mode", Viewport.SCALING_3D_MODE_BILINEAR) == "")
	# TAA under FSR 2, whole numbers for integer settings, decals on Compatibility.
	upscaled.scaling_3d_scale = 0.5
	upscaled.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR2
	assert(Experiment._fsr_falls_back(upscaled, "use_taa", true) != "" and Experiment._fsr_falls_back(upscaled, "use_taa", false) == "")
	# Under MetalFX Temporal, TAA and 3D MSAA are off too; a runtime scale below the inspector range is fine.
	upscaled.scaling_3d_mode = 4
	assert(Experiment._fsr_falls_back(upscaled, "msaa_3d", 1) != "" and Experiment._fsr_falls_back(upscaled, "use_taa", true) != "")
	upscaled.free()
	var fraction: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/environment/ssao/blur_passes", "value": 2.5}]})
	assert(fraction.get("isError", false), str(fraction))
	assert(Experiment._hint_error({"type": TYPE_INT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0,6"}, 2.5, "blur") != "")
	var loose_decal := Decal.new()
	assert((Experiment._effect_ignored(loose_decal, "size") != "") == (RenderingServer.get_current_rendering_method() == "gl_compatibility"))
	loose_decal.free()
	# Volumetric fog light energy only renders on Forward+; the debanding material flag says how it is restored.
	var fog_light := OmniLight3D.new()
	assert((Experiment._effect_ignored(fog_light, "light_volumetric_fog_energy") != "") == (RenderingServer.get_current_rendering_method() != "forward_plus"))
	fog_light.free()
	# Lod_bias 0 (lowest LOD) is valid below its inspector hint; visibility_range_end is not offered.
	var lod_mesh := MeshInstance3D.new()
	lod_mesh.name = "LodMesh"
	scene.add_child(lod_mesh)
	var lowest: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"node": "LodMesh", "property": "lod_bias", "value": 0}]})
	assert(not lowest.get("isError", false) and lod_mesh.lod_bias == 0.0, str(lowest))
	Experiment.run(self, {"action": "restore"})
	assert(Experiment.run(self, {"action": "apply", "changes": [{"node": "LodMesh", "property": "visibility_range_end", "value": 10.0}]}).get("isError", false))
	var deband: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/anti_aliasing/quality/use_debanding", "value": true}]})
	assert(deband.notes.size() == (1 if RenderingServer.has_method("material_set_use_debanding") else 0), str(deband))
	Experiment.run(self, {"action": "restore"})
	# Setters that reset renderer state are not offered, values are checked against each property's hint,
	# and effects the renderer does not run are refused.
	var emitter := GPUParticles3D.new()
	emitter.name = "Emitter"
	scene.add_child(emitter)
	assert(Experiment.run(self, {"action": "apply", "changes": [{"node": "Emitter", "property": "amount", "value": 4}]}).get("isError", false))
	var bad_filter: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"class": "Light2D", "property": "shadow_filter", "value": 9}]})
	assert(bad_filter.get("isError", false) and str(bad_filter.content[0].text).contains("takes one of"), str(bad_filter))
	# The world's fallback (the project's default environment) is an Environment in use too.
	var fallback := Environment.new()
	var world_3d := root.find_world_3d()
	var previous_fallback := world_3d.fallback_environment
	world_3d.fallback_environment = fallback
	var glow_all: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"environment": true, "property": "glow_enabled", "value": true}]})
	assert(not glow_all.get("isError", false) and fallback.glow_enabled, str(glow_all))
	Experiment.run(self, {"action": "restore"})
	assert(not fallback.glow_enabled)
	world_3d.fallback_environment = previous_fallback
	# The world's own Environment is in use too; visible is not offered on Controls.
	var direct := Environment.new()
	var previous_direct := world_3d.environment
	world_3d.environment = direct
	Experiment.run(self, {"action": "apply", "changes": [{"environment": true, "property": "glow_enabled", "value": true}]})
	assert(direct.glow_enabled)
	Experiment.run(self, {"action": "restore"})
	world_3d.environment = previous_direct
	var label := Label.new()
	label.name = "Hud"
	scene.add_child(label)
	assert(Experiment.run(self, {"action": "apply", "changes": [{"node": "Hud", "property": "visible", "value": false}]}).get("isError", false) and label.visible)
	if ProjectSettings.has_setting("display/window/hdr/request_hdr_output"):
		var requested = ProjectSettings.get_setting("display/window/hdr/request_hdr_output")
		ProjectSettings.set_setting("display/window/hdr/request_hdr_output", true)
		assert(Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/viewport/hdr_2d", "value": false}]}).get("isError", false))
		ProjectSettings.set_setting("display/window/hdr/request_hdr_output", requested)
	var ssr: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"environment": true, "property": "ssr_enabled", "value": true}]})
	assert(ssr.get("isError", false) == (RenderingServer.get_current_rendering_method() != "forward_plus"), str(ssr))
	Experiment.run(self, {"action": "restore"})
	# A viewport feature the renderer does not run is refused: the getter would still report it.
	var method := RenderingServer.get_current_rendering_method()
	assert((Experiment._renderer_ignores("use_taa", true) != "") == (method != "forward_plus"))
	assert((Experiment._renderer_ignores("scaling_3d_mode", 2) != "") == (method != "forward_plus"))
	assert(Experiment._renderer_ignores("scaling_3d_mode", 0) == "" and Experiment._renderer_ignores("use_taa", false) == "")
	# Compatibility's empty viewport setters, MetalFX without confirmed support, and the current camera.
	assert((Experiment._renderer_ignores("anisotropic_filtering_level", 0) != "") == (method == "gl_compatibility"))
	# Round 14: MetalFX also depends on device scale limits Godot checks internally, so it is never tried live.
	assert(Experiment._renderer_ignores("scaling_3d_mode", 4) != "" and Experiment._renderer_ignores("scaling_3d_mode", 3) != "")
	var as_bool: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/environment/volumetric_fog/volume_size", "value": false}]})
	assert(as_bool.get("isError", false) and str(as_bool.content[0].text).contains("takes a number"), str(as_bool))
	var camera_switch: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"class": "Camera3D", "property": "current", "value": true}]})
	assert(camera_switch.get("isError", false) and str(camera_switch.content[0].text).contains("camera"), str(camera_switch))
	var camera_2d := Camera2D.new()
	scene.add_child(camera_2d)
	var disabled_2d: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"class": "Camera2D", "property": "enabled", "value": false}]})
	assert(disabled_2d.get("isError", false) and camera_2d.enabled, str(disabled_2d))
	# The same through an indexed path from another node.
	var holder := Node.new()
	holder.name = "CameraHolder"
	scene.add_child(holder)
	var holder_script := GDScript.new()
	holder_script.source_code = "extends Node\nvar camera: Camera2D\n"
	holder_script.reload()
	holder.set_script(holder_script)
	holder.set("camera", camera_2d)
	var through: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"node": "CameraHolder", "property": "camera:enabled", "value": false}]})
	assert(through.get("isError", false) and camera_2d.enabled, str(through))
	# A script is never swapped, since restoring it would reset its state.
	var unscripted: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"node": "CameraHolder", "property": "script", "value": null}]})
	assert(unscripted.get("isError", false) and holder.get_script() == holder_script, str(unscripted))
	# Runtime-only properties are refused.
	var player := AnimationPlayer.new()
	player.name = "Player"
	scene.add_child(player)
	var runtime_only: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"node": "Player", "property": "current_animation", "value": ""}]})
	assert(runtime_only.get("isError", false) and str(runtime_only.content[0].text).contains("not a stored property"), str(runtime_only))
	var frames := SpriteFrames.new()
	frames.add_animation("cheap")
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = frames
	scene.add_child(sprite)
	# A stored setter can still have side effects (an empty animation stops playback), so only rendering
	# objects change; visible works on any node.
	var animated: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"node": "Sprite", "property": "animation", "value": "cheap"}]})
	assert(animated.get("isError", false) and str(animated.content[0].text).contains("rendering properties") and sprite.animation == &"default", str(animated))
	# Round 17: visible only on Node3D (hiding a 2D node hides the Controls under it and drops their focus).
	assert(Experiment.run(self, {"action": "apply", "changes": [{"node": "Sprite", "property": "visible", "value": false}]}).get("isError", false) and sprite.visible)
	var hidden: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"node": "Decal", "property": "visible", "value": false}]})
	assert(not hidden.get("isError", false) and not decal.visible, str(hidden))
	Experiment.run(self, {"action": "restore"})
	assert(decal.visible)
	# A SubViewport's own world and its Environment are targets too.
	var own := SubViewport.new()
	own.own_world_3d = true
	scene.add_child(own)
	var own_environment := Environment.new()
	own.find_world_3d().environment = own_environment
	Experiment.run(self, {"action": "apply", "changes": [{"environment": true, "property": "glow_enabled", "value": true}]})
	assert(own_environment.glow_enabled)
	Experiment.run(self, {"action": "restore"})
	assert(not own_environment.glow_enabled)
	own.free()
	assert(Experiment._same(&"cheap", "cheap") and Experiment._same(NodePath("a/b"), "a/b") and not Experiment._same(&"a", "b"))
	# Round 24: VRS is not tried live at all, and Nearest/MetalFX above scale 1.0 render bilinear like FSR.
	assert(Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/vrs/mode", "value": 0}]}).get("isError", false))
	var supersampled := SubViewport.new()
	supersampled.scaling_3d_scale = 1.5
	assert(Experiment._fsr_falls_back(supersampled, "scaling_3d_mode", 5) != "")
	supersampled.free()
	# Resources are not swapped (a mesh change drops blend-shape weights), and VRS texture mode needs its
	# startup texture load.
	var shaped := MeshInstance3D.new()
	shaped.name = "Shaped"
	shaped.mesh = BoxMesh.new()
	scene.add_child(shaped)
	var swapped: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"node": "Shaped", "property": "mesh", "value": null}]})
	assert(swapped.get("isError", false) and shaped.mesh != null, str(swapped))
	assert(Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/vrs/mode", "value": 1}]}).get("isError", false))
	# A RenderingServer setting the current renderer ignores is refused (glow upscale on Compatibility, SSIL on Mobile).
	var glow: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/environment/glow/upscale_mode", "value": 0}]})
	assert(glow.get("isError", false) == (RenderingServer.get_current_rendering_method() == "gl_compatibility"), str(glow))
	Experiment.run(self, {"action": "restore"})
	var debanding: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/anti_aliasing/quality/use_debanding", "value": true}]})
	assert(not debanding.get("isError", false), str(debanding))
	assert(Experiment.run(self, {"action": "restore"}).restored == (2 if RenderingServer.has_method("material_set_use_debanding") else 1))
	# Godot reads the 3D scale setting every frame for mesh LOD, so the experiment sets it too and puts it back.
	var scale := float(ProjectSettings.get_setting("rendering/scaling_3d/scale"))
	Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/scaling_3d/scale", "value": 0.5}]})
	assert(is_equal_approx(root.scaling_3d_scale, 0.5) and is_equal_approx(float(ProjectSettings.get_setting("rendering/scaling_3d/scale")), 0.5))
	Experiment.run(self, {"action": "restore"})
	assert(is_equal_approx(float(ProjectSettings.get_setting("rendering/scaling_3d/scale")), scale))
	# An active feature override is what Godot reads every frame, so it is set and restored too.
	ProjectSettings.set_setting("rendering/scaling_3d/scale.render_lens_test", 1.5)
	Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/scaling_3d/scale", "value": 0.5}]})
	assert(is_equal_approx(float(ProjectSettings.get_setting("rendering/scaling_3d/scale.render_lens_test")), 0.5))
	Experiment.run(self, {"action": "restore"})
	assert(is_equal_approx(float(ProjectSettings.get_setting("rendering/scaling_3d/scale.render_lens_test")), 1.5))
	ProjectSettings.set_setting("rendering/scaling_3d/scale.render_lens_test", null)
	# Values Godot would refuse fail the experiment: a physics rate of 0 (Engine) and an SSAO quality outside its enum.
	for bad in [{"setting": "physics/common/physics_ticks_per_second", "value": 0}, {"setting": "rendering/environment/ssao/quality", "value": 99}]:
		var refused_setting: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"class": "OmniLight3D", "property": "shadow_enabled", "value": false}, bad]})
		assert(refused_setting.get("isError", false) and scene.get_child(1).shadow_enabled, str(refused_setting))
	# The game undoes an experiment on its own when no restore arrives within the lease (plugin disabled, editor closed).
	Experiment.run(self, {"action": "apply", "lease_seconds": 0.2, "changes": [{"class": "OmniLight3D", "property": "shadow_enabled", "value": false}]})
	assert(not scene.get_child(1).shadow_enabled)
	await create_timer(0.5).timeout
	assert(scene.get_child(1).shadow_enabled, "The lease did not restore the experiment")
	var late: Dictionary = Experiment.run(self, {"action": "restore"})
	assert(late.restored == 0 and late.expired, str(late))
	# A restore in time disarms the lease: it must not undo the next experiment.
	Experiment.run(self, {"action": "apply", "lease_seconds": 0.2, "changes": [{"class": "OmniLight3D", "property": "shadow_enabled", "value": false}]})
	Experiment.run(self, {"action": "restore"})
	Experiment.run(self, {"action": "apply", "changes": [{"class": "OmniLight3D", "property": "shadow_enabled", "value": false}]})
	await create_timer(0.5).timeout
	assert(not scene.get_child(1).shadow_enabled, "An old lease undid a later experiment")
	assert(not Experiment.run(self, {"action": "restore"}).expired)
	var roughness: Dictionary = Experiment.run(self, {"action": "apply", "changes": [{"setting": "rendering/environment/screen_space_reflection/roughness_quality", "value": 0}]})
	assert(roughness.get("isError", false) == (Engine.get_version_info().minor >= 6), str(roughness))
	Experiment.run(self, {"action": "restore"})
	current_scene = null
	scene.free()

	var Measure = load("res://addons/render_lens/tools/measure_change.gd")
	var faster: Dictionary = Measure._compare(10.0, 7.0, 10.2, 0.05)
	assert(faster.verdict == "faster" and is_equal_approx(faster.saving_ms, 3.1) and is_equal_approx(faster.noise_ms, 0.2), str(faster))
	assert(Measure._compare(10.0, 9.9, 10.3, 0.05).verdict == "within_noise")
	assert(Measure._compare(10.0, 12.0, 10.0, 0.05).verdict == "slower")
	assert(Measure._compare(10.0, 9.97, 10.0, 0.05).verdict == "within_noise", "a 0.03 ms change is under the floor")
	# The TPS run beside another game: frame times agreed by chance (9.418, 9.534) while GPU time drifted 10.677 -> 8.143
	# in the same phases, so the frame "slower" of 2.28 ms is within the run's drift.
	var drift: float = Measure._drift(10.677, 8.143)
	assert(is_equal_approx(drift, 2.534 / 9.41), str(drift))
	var unsteady: Dictionary = Measure._compare(9.418, 11.756, 9.534, 0.05, drift)
	assert(unsteady.verdict == "within_noise" and unsteady.noise_ms > 2.5, str(unsteady))
	assert(is_equal_approx(Measure._compare(10.0, 7.0, 10.2, 0.05, 0.002).noise_ms, 0.2), "a steady run keeps each value's own noise")
	assert(Measure._drift(0.0, 0.0) == 0.0)
	assert(Measure._pass_changes({"Opaque": 2.0}, {"Opaque": 2.4}, {"Opaque": 2.0}, [false, false, false], [{}, {}, {}], 0.3).is_empty(), "a pass moved less than the run's drift")
	var rows: Array = Measure._pass_changes({"Shadows": 3.0, "Opaque": 2.0}, {"Opaque": 2.01}, {"Shadows": 3.1, "Opaque": 2.0})
	assert(rows.size() == 1 and rows[0].name == "Shadows" and rows[0].with_change == 0.0, str(rows))
	# A pass missing from a capture cut off at the timestamp limit may only be past the limit, so it is not read as removed;
	# missing from a complete capture, it was removed (the heavy scene's omni shadows: A1/A2 cut off, B complete).
	var cut: Array = Measure._pass_changes({"Opaque": 2.0, "Late": 0.5}, {"Opaque": 1.0}, {"Opaque": 2.0, "Late": 0.5}, [false, true, false])
	assert(cut.size() == 1 and cut[0].name == "Opaque", str(cut))
	var removed: Array = Measure._pass_changes({"Omni": 2.8, "Opaque": 2.0}, {"Opaque": 2.0}, {"Omni": 2.8, "Opaque": 2.0}, [true, false, true])
	assert(removed.size() == 1 and removed[0].name == "Omni" and removed[0].with_change == 0.0, str(removed))
	# Cut off after one of two viewports' opaque passes, the A captures sum one run; B sums both. Not comparable.
	var repeated: Array = Measure._pass_changes({"Opaque": 1.0}, {"Opaque": 1.6}, {"Opaque": 1.0}, [true, false, true], [{"Opaque": 1}, {"Opaque": 2}, {"Opaque": 1}])
	assert(repeated.is_empty(), str(repeated))
	# Runs that varied between frames, or a pass missing from some frames (-1, from _capture), never compare across
	# cut-off captures, even when the medians or counts agree.
	var varied: Array = Measure._pass_changes({"Opaque": 1.5}, {"Opaque": 2.0}, {"Opaque": 1.5}, [true, false, true], [{"Opaque": -1}, {"Opaque": 2}, {"Opaque": -1}])
	assert(varied.is_empty(), str(varied))
	for bad in [{"frames": 5}, {}, {"finding": "no.such_rule"}, {"finding": "pass.ssr", "changes": [{"viewport": true}]}, {"settle_seconds": 20}]:
		assert((await Measure.execute(bad)).get("isError", false), str(bad))
	var plain: Dictionary = await Measure.execute({"finding": "scene_validation.mesh_missing"})
	assert(plain.get("isError", false) and str(plain.content[0].text).contains("no ready-made experiment"), str(plain))
	var no_game: Dictionary = await Measure.execute({"finding": "pass.ssr"})
	assert(no_game.get("isError", false), "measure_change ran without a game")

func _test_bridge_recovery() -> void:
	# Without a debugger session each reply logs "No active debugger"; the runner expects exactly these.
	var bridge = load("res://addons/render_lens/runtime/bridge.gd").new()
	bridge._busy = true
	bridge._request_id = 7
	bridge._cancel = {"cancelled": false}
	bridge._measure(8, "unavailable", {})
	assert(bridge._busy and bridge._request_id == 7, "A running measurement was replaced")
	bridge._on_message("render_lens:cancel_measurement", [7])
	bridge._measure(8, "unavailable", {})
	assert(bridge._busy and bridge._request_id == 7, "A cancelled measurement was replaced inside its grace period")
	bridge._cancelled_at = Time.get_ticks_msec() - bridge.CANCEL_GRACE_MS - 1
	bridge._measure(8, "unavailable", {})
	assert(not bridge._busy and bridge._request_id == 8, "A measurement stopped by a script error kept the bridge busy")
	# A pause menu (paused SceneTree) must not stop the recorder; without a debugger (a shipped game) no scanner is loaded.
	root.add_child(bridge)
	assert(bridge.process_mode == Node.PROCESS_MODE_ALWAYS, "The bridge pauses with the game's SceneTree")
	assert(bridge.SceneScan == null and bridge.Metrics == null, "The bridge loaded the scanners without a debugger")
	root.remove_child(bridge)
	bridge.free()
	var bridge_source := FileAccess.get_file_as_string("res://addons/render_lens/runtime/bridge.gd")
	assert(bridge_source.count("preload(") == 1, "bridge.gd preloads more than game_bridge.gd; a shipped game compiles every preload")


func _test_comparison() -> void:
	var Context = load("res://addons/render_lens/context.gd")
	var ctx := {"schema_version": 2, "source": "game", "scene": "res://a.tscn"}
	var other := ctx.duplicate()
	other.scene = "res://b.tscn"
	assert(Context.compute_hash(ctx) != Context.compute_hash(other))
	other = ctx.duplicate()
	other.source = "editor"
	assert(Context.compute_hash(ctx) != Context.compute_hash(other))
	other = ctx.duplicate()
	other.schema_version = 1
	assert(Context.compute_hash(ctx) != Context.compute_hash(other))
	var Compare = load("res://addons/render_lens/tools/capture_compare.gd")
	var before := {"timing": {"median_ms": 10.0}, "gpu": {"median_ms": 5.0}}
	var after := {"timing": {"median_ms": 14.0}, "gpu": {"median_ms": 8.0}}
	assert(Compare._compare_captures(before, after).regression_count == 2, "Saved median fields were ignored")
	assert(Compare._compare_captures({}, {}).has("error"), "Empty captures passed comparison")
	assert(Compare._compare_captures(before, {"timing": {"median_ms": "bad"}}).has("error"))

func _test_timing_and_ranking() -> void:
	var Advisor = load("res://addons/render_lens/advisor_context.gd")
	var Rules = load("res://addons/render_lens/rule_engine.gd")
	var Frame = load("res://addons/render_lens/tools/frame_timing.gd")
	var rows: Array = []
	for i in range(100):
		rows.append({"frame_ms": 10.0 if i < 99 else 180.0, "process_ms": 5.0, "gpu_ms": 3.0, "cpu_ms": 1.0})
	var timing: Dictionary = Frame._compute_stats(rows, 60)
	timing["source"] = "game"
	assert(is_equal_approx(timing.timing.median_ms, 10.0), "One hitch became the median")
	var frame: Dictionary = Advisor.choose_frame(60, timing, {"TIME_PROCESS": 0.180}, {})
	assert(is_equal_approx(frame.median_ms, 10.0), "Periodic peak replaced sampled median")
	assert(frame.bound == "unknown", "Synchronization gap was blamed on CPU work")
	timing.source = "editor"
	assert(Advisor.choose_frame(60, timing, {}, {}).is_empty(), "Editor timing used for game advice")
	var findings := [
		{"id": "geometry.no_visibility_range", "kind": "performance", "severity": "high", "measured_share": 0.0},
		{"id": "scripts.profile_top_self", "kind": "performance", "severity": "medium", "measured_share": 80.0},
	]
	var ranked: Dictionary = Rules.package(findings, {"bound": "cpu", "median_ms": 100.0, "budget_ms": 16.67, "cpu_gap_ms": 90.0, "cpu_scene": {"mesh_without_visibility_range_count": 30}}, 2)
	assert(ranked.top[0].id == "scripts.profile_top_self", "Unmeasured mesh counts outranked measured script cost")
	assert(not ranked.top[1].has("cpu_cost_ms"))
	if FileAccess.file_exists("res://addons/render_lens/tools/stutter_report.gd"):
		var Stutter = load("res://addons/render_lens/tools/stutter_report.gd")
		var samples: Array = []
		for i in range(40):
			samples.append({"frame": i, "total_ms": 100.0 if i == 35 else 10.0, "cpu_ms": 1.0, "gpu_ms": 1.0, "process_ms": 99.0 if i == 35 else 1.0, "physics_ms": 0.0, "shader_compile": false})
		var report: Dictionary = Stutter._analyze_stutters(samples)
		assert(report.hitch_count == 1, "A wall-clock stall with flat render costs was missed")
		assert(report.hitches[0].side == "unknown", "Process time alone was identified as script work")

func _test_adapted_rules() -> void:
	var Rules = load("res://addons/render_lens/rule_engine.gd")
	var Scan = load("res://addons/render_lens/scene_scan.gd")
	var root := Node3D.new()
	root.name = "RunningOnly"
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	var material := StandardMaterial3D.new()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mesh.material_override = material
	root.add_child(mesh)
	var viewport := SubViewport.new()
	viewport.msaa_3d = Viewport.MSAA_8X
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	root.add_child(viewport)
	var scan: Dictionary = Scan.scan(root, "res://running_only.tscn")
	assert(scan.scenes.size() == 1, "An unrelated main/edited scene entered the live scan")
	assert(scan.counts.anisotropic_material_count == 1)
	assert(scan.counts.subviewport_msaa8_count == 1)
	assert(scan.counts.subviewport_keep_count == 1)
	mesh.mesh.material = material
	mesh.material_override = StandardMaterial3D.new()
	assert(Scan.scan(root, "res://running_only.tscn").counts.anisotropic_material_count == 0, "Overridden material was reported as active")
	root.free()
	var ctx := {"version_major": 4, "version_minor": 4, "renderer": "mobile", "adapter": {"vendor": "ARM", "name": "Mali"}, "settings": {"rendering/anti_aliasing/quality/msaa_3d": 3, "rendering/textures/default_filters/anisotropic_filtering_level": 2}, "scene": scan.counts, "offenders": scan.offenders}
	var arm: Array = Rules.evaluate(ctx, "static")
	assert(arm.any(func(row): return row.id == "gpu_best_practices.arm_msaa8"))
	assert(arm.any(func(row): return row.id == "gpu_best_practices.arm_anisotropic_materials"))
	for row in arm:
		if row.category == "gpu_best_practices":
			assert(row.heuristic and row.upstream_check != "")
	ctx.adapter = {"vendor": "NVIDIA", "name": "RTX"}
	var desktop: Array = Rules.evaluate(ctx, "static")
	assert(not desktop.any(func(row): return str(row.id).begins_with("gpu_best_practices.arm_")), "Arm rules fired on NVIDIA")
	ctx.adapter = {}
	assert(not Rules.evaluate(ctx, "static").any(func(row): return str(row.id).begins_with("gpu_best_practices.arm_")), "Unknown vendor treated as Arm")
	for rule in Rules.load_rules():
		assert(not str(rule.get("condition", {})).contains("API:"), "Catalog still needs validation logs")

func _test_wall_clock() -> void:
	var Samples = load("res://addons/render_lens/frame_samples.gd")
	var old_cap := Engine.max_fps
	Engine.max_fps = 5
	await create_timer(0.6).timeout
	var capture: Dictionary = await Samples.collect(0, 0, 1.1)
	Engine.max_fps = old_cap
	assert(capture.elapsed_seconds < 1.8, "Duration was converted to an assumed 60 FPS frame count")
	assert(capture.samples.size() >= 3 and capture.samples.size() <= 7, "5 FPS capture: %d samples in %.3f seconds, last=%s" % [capture.samples.size(), capture.elapsed_seconds, str(capture.samples.back() if not capture.samples.is_empty() else {})])
	assert(float(capture.samples.back().frame_ms) > 150.0, "Sampler measured rendering work instead of actual frame interval")
	# A hitch in the frame that crosses the deadline belongs to the capture (session rows lost it at each boundary).
	create_timer(0.05).timeout.connect(func(): OS.delay_msec(150))
	var crossing: Dictionary = await Samples.collect(0, 0, 0.1)
	var longest := 0.0
	for row in crossing.samples:
		longest = maxf(longest, float(row.frame_ms))
	assert(longest >= 140.0, "The frame crossing the capture deadline was dropped: longest %.1f ms" % longest)


func _test_third_review() -> void:
	# A spike is blamed on the component that grew: an unchanged 10 ms GPU frame does not explain a 20 ms physics spike.
	if FileAccess.file_exists("res://addons/render_lens/tools/stutter_report.gd"):
		var Stutters = load("res://addons/render_lens/tools/stutter_report.gd")
		var frames: Array = []
		for i in 40:
			frames.append({"total_ms": 16.0, "gpu_ms": 10.0, "cpu_ms": 1.0, "physics_ms": 1.0, "shader_compile": false})
		frames.append({"total_ms": 34.0, "gpu_ms": 10.0, "cpu_ms": 1.0, "physics_ms": 21.0, "shader_compile": false})
		var analysis: Dictionary = Stutters._analyze_stutters(frames)
		assert(analysis.hitch_count == 1 and analysis.hitches[0].side == "physics", "Spike attribution: %s" % [analysis.hitches])
	# Platform overrides resolve in Godot's own order (registration), not the property list's.
	var Metrics = load("res://addons/render_lens/metrics_snapshot.gd")
	var msaa_key := "rendering/anti_aliasing/quality/msaa_3d"
	ProjectSettings.set_setting(msaa_key + ".windows", 2)
	ProjectSettings.set_setting(msaa_key + ".pc", 3)
	# The list a property walk gives can differ from Godot's (built-in overrides first); the result must not depend on it.
	var resolved = Metrics._shipped_value(msaa_key, [msaa_key + ".pc", msaa_key + ".windows"])
	var expected = ProjectSettings.get_setting_with_override(msaa_key)
	ProjectSettings.set_setting(msaa_key + ".windows", null)
	ProjectSettings.set_setting(msaa_key + ".pc", null)
	assert(int(resolved) == int(expected), "Override order: got %s, Godot reads %s" % [resolved, expected])
	# A folder that refuses a new capture file is skipped for the next one.
	var Helper = load("res://addons/render_lens/file_helper.gd")
	Helper._dir = ""
	var moved: String = Helper.ensure_captures_dir({Helper.CAPTURES_DIR: true})
	Helper._dir = ""
	assert(moved == Helper.FALLBACK_DIR, "A refused captures folder was used again: %s" % moved)
	var back: String = Helper.write_json({"probe": true}, "refused")
	assert(back.begins_with(Helper.CAPTURES_DIR + "/"), "A refusal outlived its capture: %s" % back)
	DirAccess.remove_absolute(back)
	# A queued tool whose client is not connected (closed since the last network poll) is dropped before it runs.
	var server = load("res://addons/render_lens/mcp_server.gd").new()
	var closed := StreamPeerTCP.new()
	server.connected_clients["closed"] = {"peer": closed}
	server.pending_async_tools = [{"peer": closed, "request_id": 3, "tool_name": "render_stats", "tool_params": {}, "headers": {}, "start_time": Time.get_ticks_msec()}]
	server._process_async_tool_queue()
	assert(server.pending_async_tools.is_empty() and server.active_tool_execution.is_empty(), "A closed client's queued tool ran")
	server.connected_clients.clear()
	server.free()


func _test_hardening() -> void:
	# The dock log keeps its last lines and no undo snapshots of the whole log.
	var dock = load("res://addons/render_lens/dock_panel.tscn").instantiate()
	root.add_child(dock)
	for i in dock.MAX_LOG_LINES + 100:
		dock._add_log("line %d" % i)
	assert(dock.log_text.get_line_count() <= dock.MAX_LOG_LINES + 1 and not dock.log_text.has_undo(), "The dock log grew without limit")
	dock.free()
	var Helper = load("res://addons/render_lens/file_helper.gd")
	var server = load("res://addons/render_lens/mcp_server.gd").new()
	# Protocol: echo a supported version, answer the latest otherwise.
	for version in ["2024-11-05", "2025-03-26", "2025-06-18"]:
		assert(server._handle_initialize({"protocolVersion": version}).protocolVersion == version, version)
	assert(server._handle_initialize({"protocolVersion": "2025-99-99"}).protocolVersion == "2025-06-18")
	assert(server._handle_initialize({"protocolVersion": "1999-01-01"}).protocolVersion == "2025-06-18")
	var project_path: String = ProjectSettings.globalize_path("res://")
	assert(server._handle_initialize({}).instructions.contains(project_path), "initialize does not identify the project")
	var ping: Dictionary = JSON.parse_string(server._tool_ping().content[0].text)
	assert(ping.project.path == project_path and ping.project.name == str(ProjectSettings.get_setting("application/config/name", "")))
	# JSON-RPC errors are HTTP 200; a body that is not JSON-RPC is 400.
	assert(server._build_jsonrpc_error_response(1, -32601, "x").begins_with("HTTP/1.1 200 "))
	assert(server._build_jsonrpc_error_response(null, -32700, "x", 400).begins_with("HTTP/1.1 400 "))
	# Queued tools wait for the active one (session_summary runs up to 615 s) and are not failed at the single-tool limit.
	server.active_tool_execution = {"tool_name": "session_summary"}
	var now := Time.get_ticks_msec()
	# (Expiry past 675 s is not exercised: it logs an engine error that run_regressions treats as a failure.)
	var waiting := StreamPeerBuffer.new()
	server.connected_clients["waiting"] = {"peer": waiting}
	server.pending_async_tools = [{"peer": waiting, "request_id": 1, "tool_name": "render_stats", "tool_params": {}, "headers": {}, "start_time": now - 400000}]
	server._process_async_tool_queue()
	assert(server.pending_async_tools.size() == 1, "A tool queued behind a long one timed out at the single-tool limit")
	# A queued tool whose client disconnected is dropped instead of running for nobody.
	server.pending_async_tools.append({"peer": StreamPeerBuffer.new(), "request_id": 2, "tool_name": "session_summary", "tool_params": {}, "headers": {}, "start_time": now})
	server._process_async_tool_queue()
	assert(server.pending_async_tools.size() == 1 and server.pending_async_tools[0].request_id == 1, "A disconnected client's queued tool was kept")
	server.connected_clients.clear()
	server.pending_async_tools.clear()
	server.active_tool_execution = {}
	server.free()
	# Captures: same-second PNGs stay distinct, the folder carries its ignore markers, and old files are pruned by count.
	var image := Image.create(2, 2, false, Image.FORMAT_RGB8)
	var first: String = Helper.write_png(image, "hardening")
	var second: String = Helper.write_png(image, "hardening")
	assert(first != "" and second != "" and first != second, "Two captures in one second share a path")
	var dir: String = first.get_base_dir()
	assert(FileAccess.file_exists(dir + "/.gdignore") and FileAccess.get_file_as_string(dir + "/.gitignore") == "*\n")
	DirAccess.remove_absolute(first)
	DirAccess.remove_absolute(second)
	var scratch := "user://hardening_cleanup"
	DirAccess.make_dir_recursive_absolute(scratch)
	for i in range(5):
		var file := FileAccess.open("%s/c%d.json" % [scratch, i], FileAccess.WRITE)
		file.store_string("{}")
		file.close()
	Helper.cleanup_old_captures(scratch, 2)
	assert(DirAccess.get_files_at(scratch).size() == 2, "Cleanup did not keep the newest 2")
	for name in DirAccess.get_files_at(scratch):
		DirAccess.remove_absolute(scratch + "/" + name)
	DirAccess.remove_absolute(scratch)
	# Path arguments: only saved captures may be compared, only project res:// scenes scanned.
	for bad in ["user://x.json", "res://project.godot", "res://.render_lens/captures/../../project.godot", "C:/Windows/win.ini", "/etc/passwd"]:
		assert(not Helper.is_capture_path(bad), bad)
	assert(Helper.is_capture_path("res://.render_lens/captures/a.json") and Helper.is_capture_path("user://.render_lens/captures/a.json"))
	# A captures folder that became read-only after its markers were written falls back to user://.
	if OS.get_name() == "Windows":
		Helper._dir = ""
		assert(Helper.ensure_captures_dir() == Helper.CAPTURES_DIR)
		var marker: String = Helper.CAPTURES_DIR + "/.gitignore"
		FileAccess.set_read_only_attribute(marker, true)
		var chosen: String = Helper.ensure_captures_dir()  # the cached folder is checked again, not trusted
		FileAccess.set_read_only_attribute(marker, false)
		Helper._dir = ""
		assert(chosen == Helper.FALLBACK_DIR, "A read-only captures folder with existing markers was chosen: %s" % chosen)
	# capture_compare reads only saved captures.
	if FileAccess.file_exists("res://addons/render_lens/tools/capture_compare.gd"):
		var Compare = load("res://addons/render_lens/tools/capture_compare.gd")
		for bad in ["user://x.json", "res://project.godot", "res://.render_lens/captures/../../project.godot", "C:/Windows/win.ini", "/etc/passwd"]:
			assert(Compare._load_capture(bad).error.begins_with("Path must be"), bad)
		var oversize: String = Helper.FALLBACK_DIR + "/oversize_test.json"
		assert(Helper.ensure_captures_dir() != "")
		DirAccess.make_dir_recursive_absolute(Helper.FALLBACK_DIR)
		var big := FileAccess.open(oversize, FileAccess.WRITE)
		var chunk := PackedByteArray()
		chunk.resize(1024 * 1024)
		for i in range(64):
			big.store_buffer(chunk)
		big.store_8(32)
		big.close()
		assert(Compare._load_capture(oversize).error.contains("64 MiB"), "Oversize capture was read")
		DirAccess.remove_absolute(oversize)
	var Scan = load("res://addons/render_lens/scene_scan.gd")
	for bad in ["user://a.tscn", "res://../a.tscn", "res://a/../../a.tscn", "C:/a.tscn", "/a.tscn"]:
		assert(Scan.scan_path(bad).error.begins_with("Scene path must be"), bad)
	_test_server_connections()


func _test_server_connections() -> void:
	var server = load("res://addons/render_lens/mcp_server.gd").new()
	# OAuth authorize: the query is separate from the path; only loopback redirect_uris get the code, with the client's state.
	var shim = server.oauth_shim
	var ok: String = shim.handle_authorize_request("redirect_uri=http%3A%2F%2F127.0.0.1%3A5555%2Fcb&state=a%20b")
	assert(ok.begins_with("HTTP/1.1 302") and ok.contains("Location: http://127.0.0.1:5555/cb?code=local-auth-code&state=a%20b\r\n"), ok)
	for bad in ["", "state=x", "redirect_uri=https://evil.example/cb", "redirect_uri=http://localhost@evil.example/", "redirect_uri=http://localhost.evil.example/", "redirect_uri=http://127.0.0.1/%0D%0AX:1"]:
		assert(shim.handle_authorize_request(bad).begins_with("HTTP/1.1 400"), bad)
	# MCP-Protocol-Version: an unsupported value is a 400, initialize is exempt, and a missing header is accepted.
	var call := JSON.stringify({"jsonrpc": "2.0", "id": 1, "method": "tools/list"})
	assert(server._handle_jsonrpc_request_parsed(call, {"mcp-protocol-version": "1999-01-01"}).http_response.begins_with("HTTP/1.1 400"))
	assert(server._handle_jsonrpc_request_parsed(call, {"mcp-protocol-version": "2025-06-18"}).http_response.begins_with("HTTP/1.1 200"))
	assert(server._handle_jsonrpc_request_parsed(call, {}).http_response.begins_with("HTTP/1.1 200"))
	var init := JSON.stringify({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}})
	assert(server._handle_jsonrpc_request_parsed(init, {"mcp-protocol-version": "1999-01-01"}).http_response.begins_with("HTTP/1.1 200"))
	# Closed connections are dropped: get_status() is cached until poll().
	server.tcp_server = TCPServer.new()
	var port := 45871
	while server.tcp_server.listen(port, "127.0.0.1") != OK:
		port += 1
		assert(port < 45971, "no free port")
	server.is_running = true
	var clients: Array = []
	for i in range(5):
		var client := StreamPeerTCP.new()
		assert(client.connect_to_host("127.0.0.1", port) == OK)
		clients.append(client)
	var deadline := Time.get_ticks_msec() + 3000
	while server.connected_clients.size() < 5 and Time.get_ticks_msec() < deadline:
		server._process(0.0)
		OS.delay_msec(10)
	assert(server.connected_clients.size() == 5, "clients not accepted: %d" % server.connected_clients.size())
	for client in clients:
		client.poll()
		client.disconnect_from_host()
	deadline = Time.get_ticks_msec() + 3000
	while not server.connected_clients.is_empty() and Time.get_ticks_msec() < deadline:
		server._process(0.0)
		OS.delay_msec(10)
	assert(server.connected_clients.is_empty(), "closed connections stayed registered: %d" % server.connected_clients.size())
	# A client that never reads cannot block the loop: the 700 KB reply is flushed with put_partial_data.
	var stalled := StreamPeerTCP.new()
	assert(stalled.connect_to_host("127.0.0.1", port) == OK)
	var body := JSON.stringify({"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "x".repeat(700000)}})
	var request := ("POST /mcp HTTP/1.1\r\nContent-Length: %d\r\n\r\n%s" % [body.to_utf8_buffer().size(), body]).to_utf8_buffer()
	deadline = Time.get_ticks_msec() + 3000
	while stalled.get_status() == StreamPeerTCP.STATUS_CONNECTING and Time.get_ticks_msec() < deadline:
		stalled.poll()
		server._process(0.0)
		OS.delay_msec(10)
	var sent := 0
	while sent < request.size() and Time.get_ticks_msec() < deadline:
		var partial: Array = stalled.put_partial_data(request.slice(sent))
		sent += partial[1]
		server._process(0.0)
	var start := Time.get_ticks_msec()
	for i in range(20):
		server._process(0.0)
		OS.delay_msec(5)
	assert(Time.get_ticks_msec() - start < 1500, "A client that stopped reading blocked the server")
	stalled.disconnect_from_host()
	server.stop_server()
	# A peer that accepts nothing: the write is dropped after WRITE_STALL_MS, never waited on.
	var mock := GDScript.new()
	mock.source_code = "extends RefCounted\nfunc put_partial_data(_data):\n\treturn [OK, 0]\n"
	mock.reload()
	var waiting := {"peer": mock.new(), "out": PackedByteArray([1, 2, 3]), "write_progress_ms": Time.get_ticks_msec()}
	assert(server._flush_client(waiting) and waiting.out.size() == 3)
	waiting.write_progress_ms -= server.WRITE_STALL_MS + 1
	assert(not server._flush_client(waiting), "A stalled writer was not dropped")
	server.free()
