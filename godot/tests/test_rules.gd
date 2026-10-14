extends SceneTree

## Rule engine, setting paths, and the heavy_test scene.
## godot --headless --path sample_project --script /workspace/tests/test_rules.gd

const Rules = preload("res://addons/render_lens/rule_engine.gd")
const Advisor = preload("res://addons/render_lens/advisor_context.gd")
const SceneScan = preload("res://addons/render_lens/scene_scan.gd")
const Metrics = preload("res://addons/render_lens/metrics_snapshot.gd")
const Audit = preload("res://addons/render_lens/tools/audit_project_rendering.gd")
const DebuggerParse = preload("res://addons/render_lens/debugger_parse.gd")
const Pacing = preload("res://addons/render_lens/pacing.gd")
const VramEstimate = preload("res://addons/render_lens/vram_estimate.gd")
const Invariants = preload("res://tests/golden/advice_invariants.gd")

const HEAVY_IDS: PackedStringArray = [
	"post.ssao_enabled",
	"post.ssr_enabled",
	"post.ssr_steps",
	"post.glow_enabled",
	"post.volumetric_fog",
	"post.fog_sdfgi_inject",
	"post.dof_enabled",
	"gi.ssil_enabled",
	"gi.sdfgi_enabled",
	"gi.probe_always",
	"shadows.omni_shadow_count",
	"shadows.spot_shadow_count",
	"geometry.multimesh_candidate",
	"geometry.no_visibility_range",
	"geometry.lod_bias_high",
	"lights.many_realtime",
	"materials.alpha_blend",
	"particles.gpu_amount",
	"particles.trails",
	"particles.cpu_nodes",
	"decals.no_distance_fade",
	"canvas.pcf13",
	"textures.large_dimension",
]


func _init() -> void:
	print("=== Rule engine tests ===")
	var failed := false
	if not _test_catalog():
		failed = true
	if not _test_settings():
		failed = true
	if not _test_synthetic():
		failed = true
	if not _test_heavy_scene():
		failed = true
	if not _test_noise_floor():
		failed = true
	if not _test_metrics_shape():
		failed = true
	if not _test_version_gates():
		failed = true
	if not _test_debugger_parse():
		failed = true
	if not _test_stress_scenes():
		failed = true
	if not _test_121_regressions():
		failed = true
	if not _test_122_regressions():
		failed = true
	if not _test_123_regressions():
		failed = true
	if not _test_runtime_warning_rules():
		failed = true
	if not _test_second_review_scans():
		failed = true
	if not _test_third_review():
		failed = true
	if not _test_advice_priority():
		failed = true
	if not _test_golden():
		failed = true
	if not _test_gpu_message_assembly():
		failed = true
	if not _test_vram_walk_edge_cases():
		failed = true
	if not _test_vram_containers_and_cap():
		failed = true
	if failed:
		print("FAILED")
		quit(1)
	else:
		print("All rule tests passed")
		quit(0)


func _test_catalog() -> bool:
	Rules.clear_cache()
	var rules := Rules.load_rules()
	print("rules: ", rules.size())
	if rules.size() < 120:
		print("FAIL catalog: expected at least 120 rules, got ", rules.size())
		return false
	var categories := {}
	var ids := {}
	for rule in rules:
		var rule_id := str(rule.get("id", ""))
		var source := str(rule.get("source", "")).strip_edges()
		if rule_id == "" or ids.has(rule_id):
			print("FAIL catalog: duplicate or empty id ", rule_id)
			return false
		ids[rule_id] = true
		if source == "":
			print("FAIL catalog: empty source on ", rule_id)
			return false
		if not source.begins_with("http"):
			print("FAIL catalog: source is not a URL on ", rule_id)
			return false
		var validation_id := str(rule.get("validation_id", ""))
		var category := str(rule.get("category", ""))
		if category.begins_with("api_") and validation_id == "":
			print("FAIL catalog: api rule missing validation_id ", rule_id)
			return false
		if validation_id != "":
			var id_re := RegEx.new()
			id_re.compile("^(BestPractices-[A-Za-z0-9-]+|D3D12_MESSAGE_ID_[A-Z0-9_]+)$")
			if id_re.search(validation_id) == null:
				print("FAIL catalog: bad validation_id on ", rule_id, " ", validation_id)
				return false
		if bool(rule.get("heuristic", false)) and str(rule.get("heuristic_rationale", "")).strip_edges() == "":
			print("FAIL catalog: heuristic without rationale on ", rule_id)
			return false
		categories[category] = int(categories.get(category, 0)) + 1
	var names: Array = categories.keys()
	names.sort()
	for category in names:
		print("  ", category, ": ", categories[category])
	return true


func _test_settings() -> bool:
	var version := _version_tag()
	print("Symbol check for ", version)
	var missing_settings := {}
	var missing_members: Array[String] = []
	var const_re := RegEx.new()
	const_re.compile("\\b([A-Z][A-Za-z0-9]*)\\.([A-Z][A-Z0-9_]+)\\b")
	for rule in Rules.load_rules():
		if not _rule_applies_here(rule):
			continue
		var rule_id := str(rule.get("id", ""))
		var paths := {}
		_gather_paths(rule.get("condition", {}), paths)
		var setting := str(rule.get("setting", ""))
		if setting.find("/") >= 0:
			paths[setting] = true
		for path in paths.keys():
			if not ProjectSettings.has_setting(path):
				if not missing_settings.has(path):
					missing_settings[path] = []
				missing_settings[path].append(rule_id)
		var node_property := str(rule.get("node_property", ""))
		# Import options are class-reference members, not ClassDB properties; build_rules.py verifies them against the XML.
		if node_property.find("/") >= 0 or node_property.begins_with("ResourceImporter"):
			continue
		if node_property.find(".") >= 0:
			var parts := node_property.split(".")
			if parts.size() == 2 and not _member_exists(parts[0], parts[1]):
				missing_members.append("%s %s" % [rule_id, node_property])
		elif node_property != "" and not ClassDB.class_exists(node_property):
			missing_members.append("%s class %s" % [rule_id, node_property])
		var blob := JSON.stringify(rule)
		for match in const_re.search_all(blob):
			var cls := match.get_string(1)
			var const_name := match.get_string(2)
			if ClassDB.class_exists(cls) and not _constant_exists(cls, const_name):
				missing_members.append("%s %s.%s" % [rule_id, cls, const_name])
	var ok := true
	if not missing_settings.is_empty():
		ok = false
		for path in missing_settings.keys():
			print("FAIL setting missing on ", version, ": ", path, " rules=", missing_settings[path])
	if not missing_members.is_empty():
		ok = false
		for item in missing_members:
			print("FAIL member ", item)
	if ok:
		print("  every cited setting, property, and enum exists")
	return ok


func _member_exists(type_name: String, member: String) -> bool:
	if not ClassDB.class_exists(type_name):
		return false
	for prop in ClassDB.class_get_property_list(type_name, false):
		if str(prop.get("name", "")) == member:
			return true
	for method in ClassDB.class_get_method_list(type_name, false):
		if str(method.get("name", "")) == member:
			return true
	return false


func _constant_exists(type_name: String, const_name: String) -> bool:
	var current := type_name
	while current != "":
		if ClassDB.class_has_integer_constant(current, const_name):
			return true
		current = ClassDB.get_parent_class(current)
	return false


func _test_synthetic() -> bool:
	print("Synthetic metrics")
	var snap: Dictionary = Metrics.collect()
	var settings: Dictionary = snap.get("settings", {}).duplicate()
	settings["rendering/lights_and_shadows/directional_shadow/size"] = 8192
	settings["rendering/scaling_3d/mode"] = 0
	settings["rendering/scaling_3d/scale"] = 0.5
	snap["settings"] = settings
	var scene := {"counts": SceneScan._empty_counts(), "offenders": {}}
	var passes := [
		{"name": "Render Opaque Pass", "exclusive_median_ms": 8.0, "share": 40.0},
		{"name": "Render Shadows", "exclusive_median_ms": 2.0, "share": 10.0},
	]
	var over := Advisor.frame_from_measured(20.0, 60, "gpu", "synthetic", 4.0, 20.0)
	var ctx: Dictionary = Advisor.make(snap, scene, over, passes)
	var findings: Array = Rules.evaluate(ctx, "measured")
	var ids := _ids(findings)
	for needed in ["shadows.directional_size_above_default", "resolution.bilinear_while_upscaling", "geometry.opaque_pass_share"]:
		if not ids.has(needed):
			print("FAIL synthetic missing ", needed)
			return false
	var packed: Dictionary = Rules.package(findings, over, 5, "measured")
	var top: Array = packed.get("top", [])
	if top.is_empty() or float(top[0].get("measured_share", 0.0)) + 0.001 < 40.0:
		print("FAIL synthetic rank")
		print(top)
		return false
	if not _ids(top).has("geometry.opaque_pass_share"):
		print("FAIL opaque pass was not in the top slice")
		return false
	var within_frame := Advisor.frame_from_measured(8.0, 60, "gpu", "synthetic", 2.0, 8.0)
	var within_ctx: Dictionary = Advisor.make(snap, scene, within_frame, passes)
	var within_findings: Array = Rules.evaluate(within_ctx, "measured")
	var within_packed: Dictionary = Rules.package(within_findings, within_frame, 5, "measured")
	if within_packed.get("within_budget") != true:
		print("FAIL expected within_budget")
		return false
	var within_top: Array = within_packed.get("top", [])
	if within_top.is_empty() or str(within_top[0].get("area", "")) != "performance" or not within_top.any(func(item): return item.get("area") == "visual"):
		print("FAIL within budget, performance should still lead and the visual area should follow")
		return false
	var saw_optional := false
	for item in within_packed.get("performance_findings", []):
		if str(item.get("id", "")) == "shadows.directional_size_above_default" and bool(item.get("optional", false)):
			saw_optional = true
	if not saw_optional:
		print("FAIL within-budget performance finding was not marked optional")
		return false
	print("  rank and headroom ok, findings ", findings.size())
	return true


## A default 3D scene with every project setting at its default must produce no performance or correctness findings
## (the godot-demo-projects audit showed default-firing rules on most untouched demos before this was enforced).
func _test_noise_floor() -> bool:
	print("Noise floor")
	var root := Node3D.new()
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	var omni := OmniLight3D.new()
	omni.shadow_enabled = true
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_SKY
	world.environment.sky = Sky.new()
	world.environment.sky.sky_material = ProceduralSkyMaterial.new()
	for node in [Camera3D.new(), sun, omni, mesh, world]:
		root.add_child(node)
	var scanned: Dictionary = SceneScan.scan(root, "res://fresh.tscn")
	root.free()
	# This test project ships deliberately bad import fixtures; a fresh project has none.
	for key in scanned.counts.keys():
		if str(key).begins_with("import_"):
			scanned.counts[key] = 0
	var snap: Dictionary = Metrics.collect()
	var settings: Dictionary = snap.get("settings", {})
	for key in settings.keys():
		if ProjectSettings.property_can_revert(key):
			settings[key] = ProjectSettings.property_get_revert(key)
	settings["rendering/renderer/rendering_method"] = "forward_plus"
	var ctx: Dictionary = Advisor.make(snap, scanned, {}, [])
	ctx["settings"] = settings
	var reported: Array = []
	for finding in Rules.evaluate(ctx, "static"):
		if finding.kind in ["performance", "correctness"]:
			reported.append(finding.id)
	if not reported.is_empty():
		print("FAIL default project reports ", reported)
		return false
	return true


func _test_heavy_scene() -> bool:
	print("heavy_test.tscn")
	var scanned: Dictionary = SceneScan.scan_path("res://heavy_test.tscn")
	if str(scanned.get("error", "")) != "":
		print("FAIL scan ", scanned.error)
		return false
	var snap: Dictionary = Metrics.collect()
	var ctx: Dictionary = Advisor.make(snap, scanned, {}, [])
	var findings: Array = Rules.evaluate(ctx, "static")
	var ids := _ids(findings)
	var missing: Array = []
	for rule_id in HEAVY_IDS:
		if not ids.has(rule_id):
			missing.append(rule_id)
	if not missing.is_empty():
		print("FAIL heavy_test missing ", missing)
		print("  counts ", scanned.get("counts", {}))
		return false
	if findings.size() < 8:
		print("FAIL heavy_test finding count ", findings.size())
		return false
	# Godot's own defaults are reported only when the measured frame is over budget.
	var defaults := ["post.camera_far_default", "shadows.directional_pssm4", "shadows.omni_cube", "shadows.no_distance_fade"]
	var slow: Dictionary = ctx.duplicate(true)
	slow["frame"] = {"median_ms": 50.0, "budget_ms": 16.667, "headroom_ms": -33.333, "over_budget": true}
	slow.get_or_add("metrics", {})["TIME_FPS"] = 20.0
	var slow_ids := _ids(Rules.evaluate(slow, "measured"))
	# A hitch drops the per-second TIME_FPS below target while the frame median is within budget.
	var hitch: Dictionary = ctx.duplicate(true)
	hitch["frame"] = {"median_ms": 15.0, "budget_ms": 16.667, "headroom_ms": 1.667, "over_budget": false}
	hitch.get_or_add("metrics", {})["TIME_FPS"] = 58.0
	var hitch_ids := _ids(Rules.evaluate(hitch, "measured"))
	# V-Sync on a 59.94 Hz display: the median is 0.1% over a 60 fps budget, which is not an overrun.
	var vsync: Dictionary = ctx.duplicate(true)
	vsync["frame"] = {"median_ms": 16.683, "budget_ms": 16.667, "headroom_ms": -0.016, "over_budget": true}
	for rule_id in _ids(Rules.evaluate(vsync, "measured")):
		hitch_ids[rule_id] = true
	for rule_id in defaults:
		if ids.has(rule_id) or not slow_ids.has(rule_id) or hitch_ids.has(rule_id):
			print("FAIL heavy_test default trade-off ", rule_id, " static=", ids.has(rule_id), " over budget=", slow_ids.has(rule_id), " within budget=", hitch_ids.has(rule_id))
			return false
	var audit: Dictionary = Audit.execute({"scene": "res://heavy_test.tscn", "top": 12})
	if audit.get("isError", false):
		print("FAIL audit ", audit)
		return false
	var body = JSON.parse_string(audit.content[0].text)
	print("  static findings ", findings.size(), " audit ", body.get("finding_count", 0))
	print("  audit categories ", body.get("category_counts", {}))
	# Godot defaults and 2D texture defaults are not findings; from 4.6 platform.windows_driver_vulkan applies.
	# The scene has no text nodes, so ui.default_font_msdf_off does not apply; post.glow_bicubic (Godot's default
	# upscale) waits for an over-budget frame like the other default trade-offs.
	var expected_audit := 36
	if Engine.get_version_info().minor >= 6:
		expected_audit = 37
	var original_findings := int(body.get("finding_count", 0)) - int(body.get("category_counts", {}).get("scene_validation", 0))
	if original_findings != expected_audit:
		print("FAIL heavy non-configuration count ", original_findings, " expected ", expected_audit)
		return false
	return true


func _test_metrics_shape() -> bool:
	var snap: Dictionary = Metrics.collect()
	var metrics: Dictionary = snap.get("metrics", {})
	for key in ["TIME_FPS", "TIME_PROCESS", "TIME_PHYSICS_PROCESS", "MEMORY_STATIC", "OBJECT_COUNT", "RENDER_TOTAL_DRAW_CALLS_IN_FRAME", "RENDER_VIDEO_MEM_USED", "PHYSICS_3D_ACTIVE_OBJECTS", "PIPELINE_COMPILATIONS_SPECIALIZATION"]:
		if not metrics.has(key):
			print("FAIL metrics missing ", key)
			return false
	var info: Dictionary = snap.get("rendering_info", {})
	if not info.has("VIDEO_MEM_USED") or not info.has("PIPELINE_COMPILATIONS_DRAW"):
		print("FAIL rendering_info")
		return false
	var settings: Dictionary = snap.get("settings", {})
	if not settings.has("rendering/renderer/rendering_method"):
		print("FAIL settings snapshot")
		return false
	print("  monitors ", snap.get("monitors", {}).size(), " settings ", settings.size())
	return true


func _test_version_gates() -> bool:
	var ver := _version_tag()
	print("Version gates ", ver)
	var snap: Dictionary = Metrics.collect()
	var settings: Dictionary = snap.get("settings", {}).duplicate()
	settings["physics/jolt_physics_3d/simulation/areas_detect_static_bodies"] = true
	settings["rendering/environment/screen_space_reflection/roughness_quality"] = 3
	settings["rendering/environment/screen_space_reflection/half_size"] = false
	settings["rendering/anti_aliasing/quality/screen_space_aa"] = 2
	settings["rendering/scaling_3d/mode"] = 5
	snap["settings"] = settings
	var scene := {"counts": SceneScan._empty_counts(), "offenders": {}}
	var ctx: Dictionary = Advisor.make(snap, scene, {}, [])
	var ids := _ids(Rules.evaluate(ctx, "static"))
	if ver == "4.4":
		for needed in ["physics.areas_detect_static", "post.ssr_roughness_quality"]:
			if not ids.has(needed):
				print("FAIL 4.4 gate missing ", needed)
				return false
		for blocked in ["post.ssr_half_size_off", "antialiasing.smaa_enabled", "resolution.nearest_upscale", "platform.windows_driver_vulkan"]:
			if ids.has(blocked):
				print("FAIL 4.4 evaluated a 4.7 rule ", blocked)
				return false
	elif ver == "4.7":
		for needed in ["post.ssr_half_size_off", "antialiasing.smaa_enabled", "resolution.nearest_upscale"]:
			if not ids.has(needed):
				print("FAIL 4.7 gate missing ", needed)
				return false
		for blocked in ["physics.areas_detect_static", "post.ssr_roughness_quality", "xr.foveation_ignored"]:
			if ids.has(blocked):
				print("FAIL 4.7 evaluated a 4.4 rule ", blocked)
				return false
	print("  version gates ok")
	return true


func _test_debugger_parse() -> bool:
	print("Debugger parse")
	var memory: Dictionary = DebuggerParse.parse_memory_usage([
		8,
		"res://heavy_albedo.png", "RGBA8", "texture", 100,
		"res://mesh.res", "vertex", "mesh", 40,
	])
	if not bool(memory.get("ok", false)) or int(memory.get("total_bytes", 0)) != 140:
		print("FAIL memory parse ", memory)
		return false
	var resources: Array = memory.get("resources", [])
	if resources.is_empty() or str(resources[0].get("path", "")) != "res://heavy_albedo.png":
		print("FAIL memory sort ", resources)
		return false
	var frame: Dictionary = DebuggerParse.parse_profile_frame([
		1, 0.016, 0.010, 0.004, 0.004, 0.002,
		1, "Rendering", 2, "draw", 0.003,
		5, 7, 3, 0.001, 0.002, 0.0,
	], {7: "Node._process"})
	if not bool(frame.get("ok", false)):
		print("FAIL profile frame ", frame.get("error", ""))
		return false
	var summary: Dictionary = DebuggerParse.summarize_profile([frame])
	if int(summary.get("frame_count", 0)) != 1:
		print("FAIL profile summary")
		return false
	if absf(float(summary.get("top_self_sec", 0.0)) - 0.001) > 0.000001:
		print("FAIL top_self ", summary.get("top_self_sec", 0.0))
		return false
	var functions: Array = summary.get("script_functions", [])
	if functions.is_empty() or str(functions[0].get("signature", "")) != "Node._process":
		print("FAIL signature ", functions)
		return false
	print("  memory and servers profile ok")
	return true



func _test_stress_scenes() -> bool:
	print("Stress scenes")
	var expected := {
		"res://heavy_scripts.tscn": ["scripts.many_process", "scripts.many_physics_process", "import.audio_pcm", "import.mesh_lods_off", "import.mesh_shadow_off", "import.mesh_uncompressed"],
		"res://heavy_physics.tscn": ["physics.continuous_cd", "physics.continuous_cd_2d", "physics.concave_shape", "physics.heightmap_shape", "physics.soft_body", "physics.many_character_bodies", "navigation.avoidance", "animation.physics_callback", "audio.polyphony", "audio.unbounded_3d", "gi.lightmap_unbaked", "gi.voxel_unbaked"],
		"res://heavy_ui.tscn": ["ui.subviewport_always", "ui.subviewport_msaa", "ui.clip_children"],
	}
	for path in expected.keys():
		var scanned: Dictionary = SceneScan.scan_path(path)
		if str(scanned.get("error", "")) != "":
			print("FAIL scan ", path, " ", scanned.error)
			return false
		var snap: Dictionary = Metrics.collect()
		var ctx: Dictionary = Advisor.make(snap, scanned, {}, [])
		var ids := _ids(Rules.evaluate(ctx, "static"))
		# Lossless and mipmap-less 2D imports are Godot's recommended 2D defaults.
		if ids.has("import.texture_lossless") or ids.has("import.texture_no_mipmaps"):
			print("FAIL ", path, " reports 2D texture defaults")
			return false
		var missing: Array = []
		for rule_id in expected[path]:
			if not ids.has(str(rule_id)):
				missing.append(rule_id)
		if not missing.is_empty():
			print("FAIL ", path, " missing ", missing)
			print("  counts ", scanned.get("counts", {}))
			return false
		print("  ", path, " ok")
	return true


func _test_121_regressions() -> bool:
	print("1.2.1 regressions")
	var slow := Pacing.gpu_timeout_sec(60, 4.0)
	if absf(slow - 27.5) > 0.01:
		print("FAIL timeout at 4 fps expected 27.5 got ", slow)
		return false
	var five := Pacing.gpu_timeout_sec(60, 5.0)
	if absf(five - 23.0) > 0.01:
		print("FAIL timeout at 5 fps expected 23 got ", five)
		return false
	if absf(Pacing.gpu_timeout_sec(10, 120.0) - 15.0) > 0.01:
		print("FAIL timeout floor")
		return false
	if absf(Pacing.gpu_timeout_sec(300, 1.0) - 120.0) > 0.01:
		print("FAIL timeout cap")
		return false
	var with_warmup := Pacing.gpu_timeout_sec(60 + Pacing.GPU_WARMUP_FRAMES, 4.0)
	if with_warmup <= 15.0:
		print("FAIL slow scene budget did not grow past 15s")
		return false
	# Synthetic 4 fps scene: 10 warmup frames, then one recorded frame per process frame.
	# The old fixed 15.1 s wait already has frames, so the tool must return them.
	var produced := int(floor(15.1 * 4.0)) - Pacing.GPU_WARMUP_FRAMES
	if produced < 40:
		print("FAIL synthetic 4 fps scene produced too few frames ", produced)
		return false
	var slow_partial: Dictionary = Pacing.timeout_payload(produced, 15.1, 15.0, 4.0)
	if not bool(slow_partial.get("partial", false)):
		print("FAIL synthetic slow scene should return partial frames")
		return false
	var needed_sec := float(60 + Pacing.GPU_WARMUP_FRAMES) / 4.0
	if with_warmup < needed_sec:
		print("FAIL scaled timeout ", with_warmup, " does not cover ", needed_sec, "s at 4 fps")
		return false
	var empty: Dictionary = Pacing.timeout_payload(0, 15.1, 15.0, 4.0)
	if str(empty.get("error", "")) == "" or bool(empty.get("partial", false)):
		print("FAIL empty timeout should be an error")
		return false
	var partial: Dictionary = Pacing.timeout_payload(12, 27.5, 27.5, 4.0)
	if not bool(partial.get("partial", false)) or str(partial.get("error", "")) != "":
		print("FAIL partial frames should not be an error")
		return false
	var overhead := Pacing.pacing_note(5.0, 27.5, 1, 0, 60.0, 0.28)
	if overhead.find("Unattributed frame pacing") < 0 or overhead.find("vsync or frame-rate cap active") >= 0:
		print("FAIL pacing note at 5 fps: ", overhead)
		return false
	if overhead.find("0.28") < 0:
		print("FAIL pacing note dropped TIME_PROCESS: ", overhead)
		return false
	var capped := Pacing.pacing_note(30.0, 200.0, 1, 0, 60.0, 0.01)
	if capped.find("vsync or frame-rate cap active") < 0:
		print("FAIL 30 fps on a 60 Hz display should mention the cap: ", capped)
		return false
	var max_cap := Pacing.pacing_note(30.0, 200.0, 0, 30, 144.0, 0.01)
	if max_cap.find("vsync or frame-rate cap active") < 0:
		print("FAIL max_fps 30: ", max_cap)
		return false
	var view_note := Pacing.viewport_counter_note(38.128, 0.0)
	if view_note.find("timestamp span") < 0 or view_note.find("0") < 0:
		print("FAIL viewport note: ", view_note)
		return false
	if Pacing.viewport_counter_note(38.128, 12.0) != "":
		print("FAIL viewport note should be empty when the counter is live")
		return false
	var over := Advisor.frame_from_measured(38.128, 60, "gpu", "gpu_passes median timestamp-span frame", 0.0, 38.128)
	if not bool(over.get("over_budget", false)):
		print("FAIL expected over_budget")
		return false
	var pct := float(over.get("over_budget_percent", 0.0))
	if pct <= 0.0:
		print("FAIL over_budget_percent stayed 0")
		return false
	var packed: Dictionary = Rules.package([], over, 3, "measured")
	var head: Dictionary = packed.get("headroom", {})
	if not bool(head.get("over_budget", false)) or float(head.get("over_budget_percent", 0.0)) <= 0.0:
		print("FAIL headroom percent ", head)
		return false
	var under := Advisor.frame_from_measured(8.0, 60, "gpu", "synthetic", 2.0, 8.0)
	if float(under.get("over_budget_percent", 1.0)) != 0.0:
		print("FAIL under-budget percent")
		return false
	if VramEstimate.texture_bytes(256, 256, Image.FORMAT_RGBA8, false) != 262144:
		print("FAIL RGBA8 byte estimate")
		return false
	if VramEstimate.texture_bytes(256, 256, Image.FORMAT_DXT1, false) != 32768:
		print("FAIL DXT1 byte estimate ", VramEstimate.texture_bytes(256, 256, Image.FORMAT_DXT1, false))
		return false
	var box := BoxMesh.new()
	var mesh_bytes := VramEstimate.mesh_bytes(box)
	if mesh_bytes <= 0:
		print("FAIL mesh estimate")
		return false
	if FileAccess.file_exists("res://addons/render_lens/runtime/lens_profiler.gd"):
		var profiler = load("res://addons/render_lens/runtime/lens_profiler.gd").new()
		profiler._toggle(true, [2])
		profiler._tick(0.2, 0.15, 0.01, 0.016)
		profiler._tick(0.2, 0.15, 0.01, 0.016)
		if profiler.samples.size() != 2:
			print("FAIL profiler tick samples ", profiler.samples.size())
			return false
		var summary: Dictionary = DebuggerParse.summarize_profile(profiler.samples)
		if absf(float(summary.get("process_time_sec", 0.0)) - 0.15) > 0.0001:
			print("FAIL tick summary ", summary)
			return false
	print("  timeouts, pacing, registry, vram estimate, launch guard ok")
	return true


func _test_122_regressions() -> bool:
	print("1.2.2 regressions")
	if Pacing.sane_viewport_ms(16655152316416.0) >= 0.0:
		print("FAIL garbage viewport time was kept")
		return false
	if absf(Pacing.sane_viewport_ms(24.925) - 24.925) > 0.001:
		print("FAIL sane viewport 24.925")
		return false
	if Pacing.sane_viewport_ms(0.0) != 0.0:
		print("FAIL sane viewport 0")
		return false
	if FileAccess.file_exists("res://addons/render_lens/runtime/pass_timing.gd"):
		var PassTiming = load("res://addons/render_lens/runtime/pass_timing.gd")
		var agg: Dictionary = PassTiming.aggregate_frames([{
			"total_gpu_ms": 24.925,
			"total_cpu_ms": 2.0,
			"viewport_gpu_ms": 16655152316416.0,
			"passes": [{"name": "Opaque", "exclusive_gpu_ms": 1.63, "inclusive_gpu_ms": 1.63, "parent": "", "depth": 0}],
		}])
		if float(agg.get("median_viewport_gpu_ms", 0.0)) >= 0.0:
			print("FAIL aggregate kept garbage viewport median ", agg.get("median_viewport_gpu_ms"))
			return false
		if float(agg.get("viewport_rejected_max_ms", -1.0)) < 10000.0:
			print("FAIL rejected max ", agg.get("viewport_rejected_max_ms"))
			return false
		if float(agg.get("median_frame_gpu_ms", 0.0)) < 24.0:
			print("FAIL timestamp span median ", agg.get("median_frame_gpu_ms"))
			return false
		var rejected_note := Pacing.viewport_rejected_note(24.925, float(agg.get("viewport_rejected_max_ms", 0.0)))
		if rejected_note.find("omitted") < 0 or rejected_note.find("underflow") < 0:
			print("FAIL rejected note ", rejected_note)
			return false
	return true


func _test_123_regressions() -> bool:
	var edited := "edited:root/@EditorNode@19513/@Panel@2/@SubViewport@9904/HeavyTest/OmniLights/Omni1"
	var offender := SceneScan.offender_path("res://heavy_test.tscn", edited)
	if offender != "res://heavy_test.tscn::HeavyTest/OmniLights/Omni1":
		print("FAIL editor offender path ", offender)
		return false
	if SceneScan.offender_path("res://heavy_test.tscn", "HeavyTest/OmniLights/Omni1") != "res://heavy_test.tscn::HeavyTest/OmniLights/Omni1":
		print("FAIL clean offender path")
		return false
	if SceneScan.offender_path("res://heavy_test.tscn", "root/HeavyTest/Omni1") != "res://heavy_test.tscn::root/HeavyTest/Omni1":
		print("FAIL non-editor root path was stripped")
		return false
	var scanned: Dictionary = SceneScan.scan_path("res://heavy_test.tscn")
	var omni_off: Array = scanned.get("offenders", {}).get("omni_shadows", [])
	if omni_off.is_empty() or str(omni_off[0]) != "res://heavy_test.tscn::HeavyTest/OmniLights/Omni1":
		print("FAIL scanned omni path ", omni_off)
		return false
	for key in scanned.get("offenders", {}).keys():
		for item in scanned.get("offenders", {})[key]:
			var text := str(item)
			if text.find("@EditorNode@") >= 0 or text.begins_with("edited:"):
				print("FAIL editor path leaked ", text)
				return false
	if Pacing.embedded_play_note_for(0, true, true).find("embedded") < 0:
		print("FAIL default embed note")
		return false
	if Pacing.embedded_play_note_for(-1, true, true) != "":
		print("FAIL disabled embed still warns")
		return false
	if Pacing.embedded_play_note_for(0, false, true) != "":
		print("FAIL metadata embed off still warns")
		return false
	if Pacing.embedded_play_note_for(1, true, false) != "":
		print("FAIL embed without the feature")
		return false
	if Pacing.embedded_play_note_for(2, false, true).find("TIME_PROCESS") < 0:
		print("FAIL floating embed note")
		return false
	return true


## Second review (2026-10-12): node _process counts ignore comments and similar names, lights are counted per type
## for the Compatibility cap, and the WorldEnvironment DOF offender carries the scene path like every other offender.
func _test_second_review_scans() -> bool:
	var root := Node3D.new()
	root.name = "Root"
	var lookalike := GDScript.new()
	lookalike.source_code = "extends Node\n# func _process(delta): pass\nfunc _process_queue():\n\tpass\n"
	lookalike.reload()
	var real := GDScript.new()
	real.source_code = "extends Node\nfunc _process(_delta):\n\tpass\n"
	real.reload()
	for script in [lookalike, lookalike, real]:
		var node := Node.new()
		node.set_script(script)
		root.add_child(node)
	root.add_child(OmniLight3D.new())
	root.add_child(SpotLight3D.new())
	root.add_child(DirectionalLight3D.new())
	var env := WorldEnvironment.new()
	env.name = "Env"
	var attributes := CameraAttributesPractical.new()
	attributes.dof_blur_far_enabled = true
	env.camera_attributes = attributes
	root.add_child(env)
	var scanned: Dictionary = SceneScan.scan(root, "res://review.tscn", false)
	root.free()
	var counts: Dictionary = scanned.get("counts", {})
	if int(counts.get("nodes_with_process_count", -1)) != 1:
		print("FAIL nodes_with_process_count ", counts.get("nodes_with_process_count"))
		return false
	if int(counts.get("omni_light_count", -1)) != 1 or int(counts.get("spot_light_count", -1)) != 1 or int(counts.get("light_count", -1)) != 3:
		print("FAIL per-type light counts ", counts.get("omni_light_count"), " ", counts.get("spot_light_count"), " ", counts.get("light_count"))
		return false
	var dof: Array = scanned.get("offenders", {}).get("dof", [])
	if dof.is_empty() or not str(dof[0]).begins_with("res://review.tscn::"):
		print("FAIL DOF offender path ", dof)
		return false
	# A 3D scene without its own environment renders with the project's default_environment.
	var default_env := Environment.new()
	default_env.ssao_enabled = true
	var env_path := "res://review_default_env.tres"
	ResourceSaver.save(default_env, env_path)
	var env_key := "rendering/environment/defaults/default_environment"
	var saved_env = ProjectSettings.get_setting(env_key, "")
	ProjectSettings.set_setting(env_key, env_path)
	var level := Node3D.new()
	level.add_child(MeshInstance3D.new())
	var bare: Dictionary = SceneScan.scan(level, "res://level.tscn", false)
	var own_env := WorldEnvironment.new()
	own_env.environment = Environment.new()
	level.add_child(own_env)
	var covered: Dictionary = SceneScan.scan(level, "res://level.tscn", false)
	# The game's autoloads render with its scene and are scanned with it.
	var hud := Node3D.new()
	hud.name = "Hud"
	hud.add_child(OmniLight3D.new())
	var with_autoload: Dictionary = SceneScan.scan(level, "res://level.tscn", false, [hud])
	level.free()
	hud.free()
	ProjectSettings.set_setting(env_key, saved_env)
	DirAccess.remove_absolute(env_path)
	if int(bare.counts.get("env_ssao", 0)) != 1 or not bare.offenders.get("env_ssao", []).has(env_path) or int(covered.counts.get("env_ssao", 0)) != 0:
		print("FAIL default environment: bare=", bare.counts.get("env_ssao"), " own=", covered.counts.get("env_ssao"), " ", bare.offenders.get("env_ssao"))
		return false
	if int(with_autoload.counts.get("omni_light_count", 0)) != 1 or not with_autoload.scenes.has("autoload:Hud"):
		print("FAIL autoload roots: ", with_autoload.scenes, " omni=", with_autoload.counts.get("omni_light_count"))
		return false
	# Rules see the value Godot uses: a feature-tag override (".pc" on desktop) replaces the saved base value.
	var msaa_key := "rendering/anti_aliasing/quality/msaa_3d"
	ProjectSettings.set_setting(msaa_key + ".pc", 3)
	var with_override: Dictionary = Metrics.collect().get("settings", {})
	ProjectSettings.set_setting(msaa_key + ".pc", null)
	if int(with_override.get(msaa_key, -1)) != 3:
		print("FAIL feature-tag override ignored: ", with_override.get(msaa_key))
		return false
	# The default scan (no scene given) keeps each root's own counts; with the single main scene here it equals a scan by path.
	var defaults: Dictionary = SceneScan.scan()
	var by_path: Dictionary = SceneScan.scan_path(SceneScan.res_path(str(ProjectSettings.get_setting("application/run/main_scene"))))
	if defaults.scenes.size() != 1 or defaults.counts != by_path.counts:
		print("FAIL default-root scan: ", defaults.scenes, " differs from the main scene scanned by path")
		return false
	# Debug and editor tags describe this editor or a debug run, not the exported game.
	ProjectSettings.set_setting(msaa_key + ".debug", 3)
	var debug_only: Dictionary = Metrics.collect().get("settings", {})
	ProjectSettings.set_setting(msaa_key + ".debug", null)
	if int(debug_only.get(msaa_key, -1)) != int(ProjectSettings.get_setting(msaa_key)) or bool(debug_only.get("application/run/flush_stdout_on_print", true)):
		print("FAIL debug-only override applied: ", debug_only.get(msaa_key), " flush=", debug_only.get("application/run/flush_stdout_on_print"))
		return false
	return true


## Third review (2026-10-12): scanners read the settings the rules see, per-type light counts skip hidden lights and
## include area lights, offender keys list nodes, the default environment gets its detailed checks unless the active
## camera has an environment, and a BoneAttachment3D saved with only its bone name is not reported unbound.
func _test_third_review() -> bool:
	var minor: int = Engine.get_version_info().minor
	var interpolation_key := "physics/common/physics_interpolation"
	var saved_interpolation = ProjectSettings.get_setting(interpolation_key)
	ProjectSettings.set_setting(interpolation_key, true)
	ProjectSettings.set_setting(interpolation_key + ".pc", false)
	var bodies := Node3D.new()
	var body := RigidBody3D.new()
	body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	bodies.add_child(body)
	var body_scan: Dictionary = SceneScan.scan(bodies, "res://bodies.tscn", false)
	bodies.free()
	ProjectSettings.set_setting(interpolation_key + ".pc", null)
	ProjectSettings.set_setting(interpolation_key, saved_interpolation)
	if minor >= 5 and int(body_scan.counts.get("check_physics_body_interpolation", 0)) != 0:
		print("FAIL scanner read the saved physics_interpolation instead of its .pc override")
		return false
	var lights := Node3D.new()
	var hidden := OmniLight3D.new()
	hidden.visible = false
	lights.add_child(hidden)
	if ClassDB.class_exists("AreaLight3D"):
		lights.add_child(ClassDB.instantiate("AreaLight3D"))
	var light_scan: Dictionary = SceneScan.scan(lights, "res://lights.tscn", false)
	lights.free()
	var area := 1 if ClassDB.class_exists("AreaLight3D") else 0
	if int(light_scan.counts.omni_light_count) != 0 or int(light_scan.counts.light_count) != 1 + area or int(light_scan.counts.area_light_count) != area:
		print("FAIL light counts: omni=", light_scan.counts.omni_light_count, " area=", light_scan.counts.area_light_count, " total=", light_scan.counts.light_count)
		return false
	# Offender keys name the scanner's offender lists, so the findings list the nodes.
	var probes := Node3D.new()
	var probe := ReflectionProbe.new()
	probe.update_mode = ReflectionProbe.UPDATE_ALWAYS
	probes.add_child(probe)
	var skin := MeshInstance3D.new()
	skin.mesh = BoxMesh.new()
	var skin_material := StandardMaterial3D.new()
	skin_material.subsurf_scatter_enabled = true
	skin.material_override = skin_material
	probes.add_child(skin)
	var probe_scan: Dictionary = SceneScan.scan(probes, "res://probes.tscn", false)
	probes.free()
	for case in [["gi.probe_always_atlas", "forward_plus"], ["materials.subsurf_renderer", "mobile"]]:
		var ctx: Dictionary = Advisor.make(Metrics.collect(), probe_scan, {}, [])
		ctx["renderer"] = case[1]
		var ctx_settings: Dictionary = ctx.get_or_add("settings", {})
		ctx_settings["rendering/renderer/rendering_method"] = case[1]
		ctx_settings["rendering/reflections/reflection_atlas/reflection_size"] = 512
		var found := {}
		for finding in Rules.evaluate(ctx, "static"):
			if finding.id == case[0]:
				found = finding
		if found.is_empty() or found.get("offenders", []).is_empty():
			print("FAIL ", case[0], " lists no offenders: ", found)
			return false
	# Another camera's environment does not apply; the active one (current) has none, so the default environment does.
	var default_env := Environment.new()
	default_env.sdfgi_enabled = true
	default_env.sdfgi_min_cell_size = 0.1
	var env_path := "res://third_default_env.tres"
	ResourceSaver.save(default_env, env_path)
	var env_key := "rendering/environment/defaults/default_environment"
	var saved_env = ProjectSettings.get_setting(env_key, "")
	ProjectSettings.set_setting(env_key, env_path)
	var level := Node3D.new()
	level.add_child(MeshInstance3D.new())
	var side := Camera3D.new()
	side.environment = Environment.new()
	level.add_child(side)
	var active := Camera3D.new()
	active.current = true
	level.add_child(active)
	var env_scan: Dictionary = SceneScan.scan(level, "res://level.tscn", false)
	level.free()
	ProjectSettings.set_setting(env_key, saved_env)
	DirAccess.remove_absolute(env_path)
	if int(env_scan.counts.get("check_sdfgi_small_cells", 0)) != 1:
		print("FAIL default environment: detailed checks skipped or an inactive camera's environment counted")
		return false
	# Saved with only bone_name (set before parenting, as PackedScene does): Godot binds it on ENTER_TREE.
	var skeleton := Skeleton3D.new()
	skeleton.add_bone("hand")
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = "hand"
	skeleton.add_child(attachment)
	var bone_scan: Dictionary = SceneScan.scan(skeleton, "res://rig.tscn", false)
	skeleton.free()
	if int(bone_scan.counts.get("check_bone_attachment_bone", 0)) != 0:
		print("FAIL BoneAttachment3D with a resolvable bone_name reported unbound")
		return false
	return true


## Rules for configurations that make Godot print a runtime warning (docs/GODOT_RUNTIME_WARNINGS.json):
## each case sets the renderer, settings and scene counts and checks the rule fires only where Godot warns.
## A 2026-10-12 demo run: advice on nodes Godot never draws, a process-time peak on a GPU-bound run, MSDF with no
## text, one combined shadow pass counted twice, and a VRAM percentage ranked as if it were frame time.
func _test_advice_priority() -> bool:
	print("Advice priority")
	var snap: Dictionary = Metrics.collect()
	var root := Node3D.new()
	root.name = "Root"
	# Named: auto-generated @Type@N names are dropped from offender paths as editor-internal.
	for i in 4:
		var decal := Decal.new()
		decal.name = "Decal%d" % i
		root.add_child(decal)
	for i in 4:
		var light := PointLight2D.new()
		light.name = "Light%d" % i
		light.shadow_enabled = true
		light.shadow_filter = Light2D.SHADOW_FILTER_PCF13
		root.add_child(light)
	for i in 2:
		var voxel := VoxelGI.new()
		voxel.name = "Voxel%d" % i
		voxel.subdiv = VoxelGI.SUBDIV_512
		root.add_child(voxel)
	# One VoxelGI with data, so gi.gi_dynamic is held back only by its meshes having no mesh.
	var baked := VoxelGI.new()
	baked.name = "Baked"
	baked.data = VoxelGIData.new()
	root.add_child(baked)
	for i in 2:
		var hollow := MeshInstance3D.new()
		hollow.name = "Hollow%d" % i
		hollow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		hollow.lod_bias = 2.0
		hollow.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
		hollow.visibility_range_end = 30.0
		hollow.visibility_range_end_margin = 5.0
		hollow.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		root.add_child(hollow)
	# A visibility range that ends before it begins hides a mesh from the camera, so its
	# ignore-occlusion flag (camera-only) stops counting. Its other costs still count: omni and spot shadows and dynamic
	# VoxelGI skip the range check, and which materials draw there is per-material and per-renderer.
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var ranged := Node3D.new()
	ranged.name = "Ranged"
	var unseen := MeshInstance3D.new()
	unseen.name = "Unseen"
	unseen.mesh = BoxMesh.new()
	unseen.material_override = glass
	unseen.lod_bias = 2.0
	unseen.ignore_occlusion_culling = true
	unseen.visibility_range_begin = 10.0
	unseen.visibility_range_end = 5.0
	unseen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ranged.add_child(unseen)
	var ranged_scan: Dictionary = SceneScan.scan(ranged, "res://ranged.tscn", false)
	ranged.free()
	var unseen_path := "res://ranged.tscn::Ranged/Unseen"
	if ranged_scan.offenders.has("ignore_occlusion") or ranged_scan.offenders.get("lod_bias_high", []) != [unseen_path] or ranged_scan.offenders.get("alpha_blend", []) != [unseen_path]:
		print("FAIL range-hidden mesh: ignore occlusion ", ranged_scan.offenders.get("ignore_occlusion", []), ", LOD bias ", ranged_scan.offenders.get("lod_bias_high", []), ", alpha ", ranged_scan.offenders.get("alpha_blend", []))
		return false
	var scanned: Dictionary = SceneScan.scan(root, "res://priority.tscn", false)
	var ctx: Dictionary = Advisor.make(snap, scanned, {}, [])
	ctx["renderer"] = "forward_plus"
	var packed: Dictionary = Rules.package(Rules.evaluate(ctx, "static"), {}, 40, "static")
	# Godot never draws these nodes (sources 4.4 to 4.7.2): a PointLight2D without a texture is skipped before lighting
	# and shadows, a MeshInstance3D without a mesh and a VoxelGI without data have no instance base. Their cost advice must
	# not fire; the missing-part finding reports them. A decal with no textures is still clustered, so its fade stays.
	var ids := _ids(packed.findings)
	for id in ["canvas.pcf13", "canvas.many_shadow_lights", "shadows.double_sided_casters", "geometry.lod_bias_high", "geometry.geometry_fade_cost", "gi.gi_dynamic", "gi.voxel_count", "gi.voxel_subdiv"]:
		if ids.has(id):
			print("FAIL ", id, " fired for nodes Godot never draws")
			return false
	for id in ["scene_validation.point_light_texture", "scene_validation.mesh_missing", "scene_validation.voxel_gi_data", "scene_validation.decal_textures", "decals.no_distance_fade"]:
		if not ids.has(id):
			print("FAIL ", id, " is missing")
			return false
	# Mixed: four lights that draw make the 2D shadow-light count, and the four without a texture are not among them.
	for i in 4:
		var drawn := PointLight2D.new()
		drawn.name = "Drawn%d" % i
		drawn.shadow_enabled = true
		drawn.texture = PlaceholderTexture2D.new()
		root.add_child(drawn)
	var mixed: Dictionary = SceneScan.scan(root, "res://priority.tscn", false)
	root.free()
	if int(mixed.counts.canvas_shadow_light_count) != 4 or not mixed.offenders.canvas_shadow_lights.all(func(path): return str(path).contains("Drawn")):
		print("FAIL the 2D shadow-light count included lights without a texture: ", mixed.counts.canvas_shadow_light_count)
		return false
	var empty_scene := {"counts": SceneScan._empty_counts(), "offenders": {}}
	var cpu_snap: Dictionary = snap.duplicate()
	# The re-run's TIME_PROCESS peak (33.7 ms) and one capture's process p95 (114.7 ms) were spikes; the median held.
	cpu_snap["metrics"] = {"PROCESS_MEDIAN_SEC": 0.0134, "TIME_PROCESS": 0.0337}
	# The first run (bound gpu) and the re-run of the same scene (10.1 of 12.7 ms on the GPU, bound unknown).
	for gpu_case in [["gpu", 12.7], ["unknown", 10.1]]:
		var waiting := Advisor.make(cpu_snap, empty_scene, Advisor.frame_from_measured(12.7, 60, gpu_case[0], "synthetic", 13.4, gpu_case[1]), [])
		if _ids(Rules.evaluate(waiting, "measured")).has("cpu.process_time"):
			print("FAIL a process-time peak that is mostly the GPU wait was blamed on scripts: ", gpu_case)
			return false
	var cpu_heavy := Advisor.make(cpu_snap, empty_scene, Advisor.frame_from_measured(14.0, 60, "unknown", "synthetic", 13.4, 2.0), [])
	if not _ids(Rules.evaluate(cpu_heavy, "measured")).has("cpu.process_time"):
		print("FAIL cpu.process_time no longer fires when the process peak is far above the GPU time")
		return false
	# Text that names its own font must not raise the default-font MSDF note.
	var own_fonts := Control.new()
	var override := Label.new()
	override.add_theme_font_override("font", SystemFont.new())
	own_fonts.add_child(override)
	var settings_font := Label.new()
	settings_font.label_settings = LabelSettings.new()
	settings_font.label_settings.font = SystemFont.new()
	own_fonts.add_child(settings_font)
	var themed := Control.new()
	themed.theme = Theme.new()
	themed.theme.default_font = SystemFont.new()
	themed.add_child(Button.new())
	own_fonts.add_child(themed)
	var label3d := Label3D.new()
	label3d.font = SystemFont.new()
	own_fonts.add_child(label3d)
	# A font set for a theme type variation, on the Label's own theme and on a parent's theme.
	own_fonts.add_child(_variation_label("CustomLabel", true))
	var variation_parent := Control.new()
	variation_parent.theme = Theme.new()
	variation_parent.theme.set_type_variation("ParentLabel", "Label")
	variation_parent.theme.set_font("font", "ParentLabel", SystemFont.new())
	var variation_child := Label.new()
	variation_child.theme_type_variation = "ParentLabel"
	variation_parent.add_child(variation_child)
	own_fonts.add_child(variation_parent)
	var own_scan: Dictionary = SceneScan.scan(own_fonts, "res://own_fonts.tscn", false)
	# Named: the scanner drops auto-generated @Label@N segments from offender paths as editor-internal.
	var plain := Label.new()
	plain.name = "PlainLabel"
	own_fonts.add_child(plain)
	var fontless := _variation_label("FontlessLabel", false)
	fontless.name = "FontlessLabel"
	own_fonts.add_child(fontless)
	var default_scan: Dictionary = SceneScan.scan(own_fonts, "res://own_fonts.tscn", false)
	own_fonts.free()
	if int(own_scan.counts.default_font_text_count) != 0 or int(default_scan.counts.default_font_text_count) != 2:
		print("FAIL default-font text counts outside the tree: own fonts ", own_scan.counts.default_font_text_count, ", plus a plain Label and a fontless variation ", default_scan.counts.default_font_text_count)
		return false
	# In the running game Godot resolves the font itself: default, explicit override, theme variation.
	var live := Control.new()
	live.add_child(Label.new())
	var live_override := Label.new()
	live_override.add_theme_font_override("font", SystemFont.new())
	live.add_child(live_override)
	live.add_child(_variation_label("CustomLabel", true))
	get_root().add_child(live)
	var live_scan: Dictionary = SceneScan.scan(live, "res://live_fonts.tscn", false)
	live.free()
	if int(live_scan.counts.default_font_text_count) != 1:
		print("FAIL default-font text count in the tree: ", live_scan.counts.default_font_text_count, " (expected only the plain Label)")
		return false
	var font_snap: Dictionary = snap.duplicate(true)
	font_snap.settings["gui/theme/default_font_multichannel_signed_distance_field"] = false
	font_snap.settings["gui/theme/custom_font"] = ""
	var msdf: Array = Rules.evaluate(Advisor.make(font_snap, default_scan, {}, []), "static").filter(func(item): return item.id == "ui.default_font_msdf_off")
	if _ids(Rules.evaluate(Advisor.make(font_snap, own_scan, {}, []), "static")).has("ui.default_font_msdf_off") or msdf.size() != 1 or msdf[0].offenders.size() != 2:
		print("FAIL the MSDF note must follow text that uses the default font, and name it")
		return false
	font_snap.settings["gui/theme/custom_font"] = "res://font.ttf"
	if _ids(Rules.evaluate(Advisor.make(font_snap, default_scan, {}, []), "static")).has("ui.default_font_msdf_off"):
		print("FAIL a project custom font replaces the default font, so its MSDF setting does not matter")
		return false
	var counts: Dictionary = SceneScan._empty_counts()
	counts["spot_shadow_count"] = 6
	var combined := "Render GI + Render Directional/SpotLight Shadows (Parallel)"
	var pass_ctx := Advisor.make(snap, {"counts": counts, "offenders": {}}, Advisor.frame_from_measured(12.7, 60, "gpu", "synthetic", 2.0, 12.7), [{"name": combined, "exclusive_median_ms": 5.6, "share": 44.8}])
	var shadow: Array = Rules.evaluate(pass_ctx, "measured")
	var spot: Array = shadow.filter(func(item): return item.id == "shadows.spot_shadow_count")
	if _ids(shadow).has("pass.shadows") or spot.size() != 1 or not str(spot[0].measured_evidence.text).contains(Rules.COMBINED_PASS_NOTE):
		print("FAIL one combined shadow pass was reported twice or without its combined note: ", _ids(shadow).keys())
		return false
	var vram_snap: Dictionary = snap.duplicate()
	var mib := 1024.0 * 1024.0
	vram_snap["metrics"] = {"VRAM_LARGEST_BYTES": 600.0 * mib, "VRAM_LISTED_HALF": 500.0 * mib, "VRAM_LISTED_TOTAL_BYTES": 1000.0 * mib, "RENDER_VIDEO_MEM_USED": 2500.0 * mib}
	var vram_frame := Advisor.frame_from_measured(12.7, 60, "gpu", "synthetic", 2.0, 12.7)
	var vram: Array = Rules.evaluate(Advisor.make(vram_snap, empty_scene, vram_frame, []), "measured").filter(func(item): return item.id == "memory.vram_largest_share")
	if vram.size() != 1 or float(vram[0].measured_share) != 0.0:
		print("FAIL a share of VRAM was ranked as a share of the frame")
		return false
	# In a demo run, a 6 MiB texture was "most of the Video RAM list" because the list held 12 MiB.
	vram_snap["metrics"] = {"VRAM_LARGEST_BYTES": 6291480.0, "VRAM_LISTED_HALF": 6012810.0}
	if _ids(Rules.evaluate(Advisor.make(vram_snap, empty_scene, vram_frame, []), "measured")).has("memory.vram_largest_share"):
		print("FAIL a 6 MiB resource was reported as dominating Video RAM")
		return false
	# A recheck: SSR measured 0.61% yet post.ssr_steps, with no pass of its own, ranked seventh. Rules that
	# tune a timed feature share its pass; volumetric fog's time is in Render Fog, not the Update Volumetric Fog marker.
	var feature_counts: Dictionary = SceneScan._empty_counts()
	feature_counts["env_ssr"] = 1
	feature_counts["env_ssr_max_steps"] = 128
	feature_counts["env_volumetric_fog"] = 1
	var feature_ctx := Advisor.make(snap, {"counts": feature_counts, "offenders": {}}, Advisor.frame_from_measured(12.7, 60, "gpu", "synthetic", 2.0, 12.7), [
		{"name": "Process SSR", "exclusive_median_ms": 0.079, "share": 0.61},
		{"name": "Update Volumetric Fog", "exclusive_median_ms": 0.0, "share": 0.0},
		{"name": "Render Fog", "exclusive_median_ms": 2.0, "share": 15.7},
	])
	feature_ctx["renderer"] = "forward_plus"
	var feature_pack: Dictionary = Rules.package(Rules.evaluate(feature_ctx, "measured"), feature_ctx.frame, 40, "measured")
	var perf_ids: Array = feature_pack.performance_findings.map(func(item): return item.id)
	# One entry per measured pass: post.ssr_steps is listed under the SSR entry, whose 0.61% ranks after the fog cost.
	var ssr: Array = feature_pack.performance_findings.filter(func(item): return str(item.measured_evidence.pass.name if item.measured_evidence.pass != null else "") == "Process SSR")
	var fog: Array = feature_pack.performance_findings.filter(func(item): return item.id == "post.volumetric_fog")
	if ssr.size() != 1 or not is_equal_approx(float(ssr[0].measured_share), 0.61) or ssr[0].severity != "low" or not ssr[0].get("same_pass", []).any(func(member): return member.id == "post.ssr_steps") or perf_ids.find(ssr[0].id) < perf_ids.find("post.volumetric_fog"):
		print("FAIL the SSR pass must be one low entry at 0.61% with post.ssr_steps under it, after measured costs: ", perf_ids)
		return false
	# A grouped finding keeps the entry's demoted severity, priority and area, also in the full list.
	var steps: Dictionary = ssr[0].same_pass.filter(func(member): return member.id == "post.ssr_steps")[0]
	if steps.severity != "low" or not steps.optional or steps.area != "performance" or steps.grouped_under != ssr[0].id:
		print("FAIL post.ssr_steps under the 0.61% SSR entry kept its own priority: ", [steps.severity, steps.optional, steps.get("area"), steps.get("grouped_under")])
		return false
	# The inline MCP row of a grouped suggestion must keep what an assistant needs to judge it.
	var inline: Dictionary = Audit._brief(ssr[0]).same_pass.filter(func(member): return member.id == "post.ssr_steps")[0]
	for field in ["tradeoff", "expected_effect", "verify_step", "source", "suggestion"]:
		if str(inline.get(field, "")) == "" or inline[field] != steps[field]:
			print("FAIL the inline same_pass row of post.ssr_steps lost its ", field)
			return false
	if inline.severity != "low" or not inline.optional:
		print("FAIL the inline same_pass row of post.ssr_steps lost its demoted priority")
		return false
	if fog.size() != 1 or not is_equal_approx(float(fog[0].measured_share), 15.7) or perf_ids[0] != "post.volumetric_fog":
		print("FAIL volumetric fog must be measured from Render Fog: ", perf_ids)
		return false
	# On Forward+ 4.4 to 4.6 Mobile's "Render Shadows" label is also inside the sun/spot/GI timestamp;
	# the omni shadow rules must take the omni pass, and on Mobile the whole "Render Shadows" label.
	var omni_counts: Dictionary = SceneScan._empty_counts()
	omni_counts["omni_shadow_count"] = 3
	omni_counts["omni_shadow_cube_count"] = 1
	var over := Advisor.frame_from_measured(30.0, 60, "unknown", "synthetic", 20.0, 25.0)
	# Without GI, Forward+ 4.4 to 4.6 emits a plain "Render Shadows" for the sun and spot lights too.
	for case in [["forward_plus", [{"name": "Render OmniLight Shadows", "exclusive_median_ms": 0.1, "share": 0.4}, {"name": "Render GI + Render Shadows (Parallel)", "exclusive_median_ms": 10.5, "share": 42.0}], 0.4], ["forward_plus", [{"name": "Render OmniLight Shadows", "exclusive_median_ms": 0.1, "share": 0.4}, {"name": "Render Shadows", "exclusive_median_ms": 10.5, "share": 42.0}], 0.4], ["mobile", [{"name": "Render Shadows", "exclusive_median_ms": 17.0, "share": 69.0}], 69.0]]:
		var omni_ctx := Advisor.make(snap, {"counts": omni_counts, "offenders": {}}, over, case[1])
		omni_ctx["renderer"] = case[0]
		var omni_rows: Array = Rules.evaluate(omni_ctx, "measured").filter(func(row): return row.id in ["shadows.omni_shadow_count", "shadows.omni_cube"])
		if omni_rows.size() != 2:
			print("FAIL the omni shadow rules did not both fire on ", case[0], ": ", omni_rows.map(func(row): return row.id))
			return false
		for item in omni_rows:
			if not is_equal_approx(float(item.measured_share), case[2]):
				print("FAIL ", item.id, " on ", case[0], " took ", item.measured_share, "% instead of ", case[2], "%")
				return false
	var saved_fps := Engine.max_fps
	Engine.max_fps = 30
	var caps: Dictionary = Pacing.uncap()
	var lifted := Engine.max_fps
	Pacing.restore(caps)
	var restored := Engine.max_fps
	Engine.max_fps = saved_fps
	if lifted != 0 or restored != 30 or int(caps.max_fps) != 30:
		print("FAIL measuring must lift max_fps and restore it: ", lifted, " ", restored)
		return false
	print("  priority ok")
	return true


## Fixed inputs (tests/golden/<case>.ctx, from cases.json) must give the reviewed advice in expected.json, and the
## package must keep the order invariants. Live GPU timings move too much for exact orders, so these inputs are fixed.
func _test_golden() -> bool:
	print("Golden advice")
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/golden/expected.json"))
	for name in expected:
		if str(name).begins_with("_"):
			continue
		var fixture: Dictionary = str_to_var(FileAccess.get_file_as_string("res://tests/golden/%s.ctx" % name))
		var packed: Dictionary = Rules.package(Rules.evaluate(fixture.ctx, fixture.mode), fixture.frame, 40, fixture.mode)
		var problems: Array = Invariants.violations(packed)
		var want: Dictionary = expected[name]
		var got := {"performance": packed.performance_findings, "visual": packed.optional_quality, "missing": packed.configuration_findings, "to_check": packed.to_check, "info": packed.info}
		for area in got:
			var ids: Array = got[area].map(func(item): return item.id)
			if ids != want[area]:
				problems.append("%s: got %s, expected %s" % [area, ids, want[area]])
		var same := {}
		for item in packed.performance_findings:
			if item.has("same_pass"):
				same[item.id] = item.same_pass.map(func(member): return member.id)
		if same != want.same_pass:
			problems.append("same_pass: got %s, expected %s" % [same, want.same_pass])
		if not problems.is_empty():
			print("FAIL golden ", name, ": ", problems)
			return false
	print("  golden ok")
	return true


## A Label whose own theme defines a type variation of Label, with or without a font for it.
func _variation_label(variation: String, with_font: bool) -> Label:
	var label := Label.new()
	label.theme = Theme.new()
	label.theme.set_type_variation(variation, "Label")
	if with_font:
		label.theme.set_font("font", variation, SystemFont.new())
	label.theme_type_variation = variation
	return label


func _test_runtime_warning_rules() -> bool:
	print("Runtime-warning rules")
	var minor: int = Engine.get_version_info().minor
	var base: Dictionary = Metrics.collect()
	var defaults: Dictionary = base.get("settings", {}).duplicate()
	for key in defaults.keys():
		if ProjectSettings.property_can_revert(key):
			defaults[key] = ProjectSettings.property_get_revert(key)
	# [rule, renderer, settings, scene counts, expected]
	var cases := [
		["resolution.upscaler_renderer", "mobile", {"rendering/scaling_3d/mode": 2}, {}, true],
		["resolution.upscaler_renderer", "gl_compatibility", {"rendering/scaling_3d/mode": 3, "rendering/renderer/rendering_method": "gl_compatibility"}, {}, true],
		["resolution.upscaler_renderer", "mobile", {"rendering/scaling_3d/mode": 3, "rendering/renderer/rendering_method": "mobile"}, {}, false],
		["resolution.upscaler_renderer", "forward_plus", {"rendering/scaling_3d/mode": 2}, {}, false],
		["resolution.upscaler_downsampling", "forward_plus", {"rendering/scaling_3d/mode": 1, "rendering/scaling_3d/scale": 1.5}, {}, true],
		["resolution.upscaler_downsampling", "forward_plus", {"rendering/scaling_3d/mode": 0, "rendering/scaling_3d/scale": 1.5}, {}, false],
		["resolution.upscaler_downsampling", "forward_plus", {"rendering/scaling_3d/mode": 1, "rendering/scaling_3d/scale": 0.77}, {}, false],
		["antialiasing.taa_with_temporal_upscaler", "forward_plus", {"rendering/anti_aliasing/quality/use_taa": true, "rendering/scaling_3d/mode": 2}, {}, true],
		["antialiasing.taa_with_temporal_upscaler", "forward_plus", {"rendering/anti_aliasing/quality/use_taa": true}, {}, false],
		["antialiasing.taa_renderer", "mobile", {"rendering/anti_aliasing/quality/use_taa": true}, {}, true],
		["antialiasing.taa_renderer", "forward_plus", {"rendering/anti_aliasing/quality/use_taa": true}, {}, false],
		["antialiasing.screen_space_aa_renderer", "gl_compatibility", {"rendering/anti_aliasing/quality/screen_space_aa": 1}, {}, minor >= 5],
		["antialiasing.screen_space_aa_renderer", "mobile", {"rendering/anti_aliasing/quality/screen_space_aa": 1}, {}, false],
		["antialiasing.msaa_2d_renderer", "gl_compatibility", {"rendering/anti_aliasing/quality/msaa_2d": 1}, {}, true],
		["antialiasing.msaa_2d_renderer", "forward_plus", {"rendering/anti_aliasing/quality/msaa_2d": 1}, {}, false],
		["canvas.hdr_output_forces_hdr_2d", "forward_plus", {"display/window/hdr/request_hdr_output": true, "rendering/viewport/hdr_2d": false}, {}, minor >= 7],
		["canvas.hdr_output_forces_hdr_2d", "forward_plus", {"display/window/hdr/request_hdr_output": true, "rendering/viewport/hdr_2d": true}, {}, false],
		["gi.probe_always_atlas", "forward_plus", {"rendering/reflections/reflection_atlas/reflection_size": 512}, {"reflection_probe_always_count": 1}, true],
		["gi.probe_always_atlas", "forward_plus", {"rendering/reflections/reflection_atlas/reflection_size": 256}, {"reflection_probe_always_count": 1}, false],
		["gi.probe_always_atlas", "gl_compatibility", {"rendering/reflections/reflection_atlas/reflection_size": 512}, {"reflection_probe_always_count": 1}, false],
		["physics.jolt_joint_ignored", "forward_plus", {"physics/3d/physics_engine": "Jolt Physics"}, {"check_jolt_joint_ignored": 1}, true],
		["physics.jolt_joint_ignored", "forward_plus", {"physics/3d/physics_engine": "DEFAULT"}, {"check_jolt_joint_ignored": 1}, false],
		["physics.jolt_area_wind_ignored", "forward_plus", {"physics/3d/physics_engine": "Jolt Physics"}, {"check_jolt_area_wind_ignored": 1}, minor <= 6],
		["physics.jolt_shape_bias_ignored", "forward_plus", {"physics/3d/physics_engine": "Jolt Physics"}, {"check_jolt_shape_bias_ignored": 1}, true],
		["materials.subsurf_renderer", "mobile", {}, {"subsurf_material_count": 1}, true],
		["materials.subsurf_renderer", "forward_plus", {}, {"subsurf_material_count": 1}, false],
		["scene_validation.particle_sdf_renderer", "gl_compatibility", {}, {"check_particle_sdf_collider": 1}, true],
		["scene_validation.particle_sdf_renderer", "mobile", {}, {"check_particle_sdf_collider": 1}, false],
		["scene_validation.camera_autoexposure_renderer", "gl_compatibility", {}, {"check_camera_autoexposure_renderer": 1}, true],
		["scene_validation.camera_autoexposure_renderer", "mobile", {}, {"check_camera_autoexposure_renderer": 1}, minor >= 6],
		["gi.lightmap_missing_nodes", "forward_plus", {}, {"check_lightmap_missing_nodes": 1}, minor >= 5],
		["antialiasing.metalfx_temporal_msaa", "forward_plus", {"rendering/scaling_3d/mode": 4, "rendering/anti_aliasing/quality/msaa_3d": 2}, {}, true],
		["antialiasing.metalfx_temporal_msaa", "forward_plus", {"rendering/scaling_3d/mode": 4}, {}, false],
		["sky.realtime_roughness_layers", "forward_plus", {"rendering/reflections/sky_reflections/roughness_layers": 6}, {"check_sky_realtime": 1}, minor <= 5],
		["sky.realtime_roughness_layers", "forward_plus", {}, {"check_sky_realtime": 1}, false],
		["audio.microphone_input_disabled", "forward_plus", {"audio/driver/enable_input": false}, {"check_microphone_stream": 1}, true],
		["audio.microphone_input_disabled", "forward_plus", {"audio/driver/enable_input": true}, {"check_microphone_stream": 1}, false],
		["scene_validation.viewport_sss_transparent", "forward_plus", {"rendering/viewport/transparent_background": true}, {"subsurf_material_count": 1}, minor >= 5],
		["scene_validation.viewport_sss_transparent", "forward_plus", {"rendering/viewport/transparent_background": true, "rendering/environment/subsurface_scattering/subsurface_scattering_quality": 0}, {"subsurf_material_count": 1}, false],
		["scene_validation.viewport_sss_transparent", "forward_plus", {}, {"subsurf_material_count": 1}, false],
		["physics.jolt_singular_basis", "forward_plus", {"physics/3d/physics_engine": "Jolt Physics"}, {"check_jolt_singular_basis": 1}, true],
		["xr.frame_synthesis_renderer", "forward_plus", {"xr/openxr/enabled": true, "xr/openxr/extensions/frame_synthesis": true}, {}, minor >= 6],
		["xr.frame_synthesis_renderer", "mobile", {"xr/openxr/enabled": true, "xr/openxr/extensions/frame_synthesis": true}, {}, false],
		["cpu.rendering_server_sync_per_frame", "forward_plus", {"rendering/driver/threads/thread_model": 2}, {"check_frame_rendering_sync": 1}, true],
		["cpu.rendering_server_sync_per_frame", "forward_plus", {}, {"check_frame_rendering_sync": 1}, false],
		["cpu.physics_server_sync_per_frame", "forward_plus", {"physics/2d/run_on_separate_thread": true}, {"check_frame_physics_2d_sync": 1}, true],
		["cpu.physics_server_sync_per_frame", "forward_plus", {"physics/2d/run_on_separate_thread": true}, {"check_frame_physics_3d_sync": 1}, false],
		["navigation.runtime_bake_visual_meshes", "forward_plus", {}, {"check_navigation_runtime_bake": 1, "check_navmesh_parses_meshes": 1}, true],
		["navigation.runtime_bake_visual_meshes", "forward_plus", {}, {"check_navmesh_parses_meshes": 1}, false],
		["xr.object_picking_stereo", "forward_plus", {"xr/openxr/enabled": true, "physics/common/enable_object_picking": true}, {"check_xr_pickable_listener": 1}, true],
		["xr.object_picking_stereo", "forward_plus", {"physics/common/enable_object_picking": true}, {"check_xr_pickable_listener": 1}, false],
		["xr.object_picking_stereo", "forward_plus", {}, {"check_xr_viewport_picking": 1}, true],
		["xr.canvas_background_multiview", "mobile", {"xr/openxr/enabled": true}, {"check_env_bg_canvas": 1}, true],
		["xr.canvas_background_multiview", "forward_plus", {"xr/openxr/enabled": true}, {"check_env_bg_canvas": 1}, false],
		["xr.foveation_subsampled_disabled", "mobile", {"xr/openxr/enabled": true, "xr/openxr/foveation_with_subsampled_images": true}, {"env_glow": 1}, minor >= 7],
		["xr.foveation_subsampled_disabled", "mobile", {"xr/openxr/enabled": true, "xr/openxr/foveation_with_subsampled_images": true}, {}, false],
		["xr.screen_texture", "forward_plus", {"xr/openxr/enabled": true}, {"check_screen_texture": 1}, true],
		["xr.screen_texture", "forward_plus", {}, {"check_screen_texture": 1}, false],
		["physics.jolt_server_call_ignored", "forward_plus", {"physics/3d/physics_engine": "Jolt Physics"}, {"check_script_jolt_server_call": 1}, true],
		["physics.jolt_server_call_ignored", "forward_plus", {}, {"check_script_jolt_server_call": 1}, false],
		["scene_validation.emit_particle_compatibility", "gl_compatibility", {}, {"check_script_emit_particle": 1}, true],
		["scene_validation.emit_particle_compatibility", "forward_plus", {}, {"check_script_emit_particle": 1}, false],
		["renderer.gl_light_limit", "gl_compatibility", {"rendering/limits/opengl/max_renderable_lights": 32}, {"light_count": 40, "omni_light_count": 20, "spot_light_count": 20}, false],
		["renderer.gl_light_limit", "gl_compatibility", {"rendering/limits/opengl/max_renderable_lights": 32}, {"light_count": 36, "omni_light_count": 33}, true],
		["renderer.gl_light_limit", "gl_compatibility", {"rendering/limits/opengl/max_renderable_lights": 32}, {"area_light_count": 33}, true],
		["renderer.gl_light_limit", "forward_plus", {"rendering/limits/opengl/max_renderable_lights": 32}, {"omni_light_count": 33}, false],
		# ClusterBuilderRD caps each type at the limit on its own; Mobile has no cluster builder.
		["renderer.cluster_elements_scene", "forward_plus", {"rendering/limits/cluster_builder/max_clustered_elements": 512}, {"light_count": 601, "omni_light_count": 300, "spot_light_count": 300}, false],
		["renderer.cluster_elements_scene", "forward_plus", {"rendering/limits/cluster_builder/max_clustered_elements": 512}, {"omni_light_count": 513}, true],
		["renderer.cluster_elements_scene", "mobile", {"rendering/limits/cluster_builder/max_clustered_elements": 512}, {"omni_light_count": 513}, false],
	]
	for case in cases:
		var settings := defaults.duplicate()
		settings["rendering/renderer/rendering_method"] = case[1]
		for key in case[2]:
			settings[key] = case[2][key]
		var scene := {"counts": SceneScan._empty_counts(), "offenders": {}}
		for key in case[3]:
			scene.counts[key] = case[3][key]
		var ctx: Dictionary = Advisor.make(base, scene, {}, [])
		ctx["settings"] = settings
		ctx["renderer"] = case[1]
		var fired := _ids(Rules.evaluate(ctx, "static")).has(case[0])
		if fired != case[4]:
			print("FAIL runtime-warning rule ", case)
			return false
	print("  ", cases.size(), " gating cases ok")
	return true


## The game sends each GPU frame as its own message and then a summary without frames: all frames in one message can
## exceed Godot's 8 MiB debugger packet, which Godot drops (the capture then timed out as partial on heavy scenes).
func _test_gpu_message_assembly() -> bool:
	var plugin = load("res://addons/render_lens/debugger_plugin.gd")
	var frames := [{"frame": 0, "passes": []}, {"frame": 1, "passes": []}, {"frame": 2, "passes": []}]
	for complete in [true, false]:
		var result: Dictionary = plugin.with_frames({"frame_count": 3 if complete else 4, "scene": "res://fixture.tscn"}, frames)
		if result.frames.size() != 3 or bool(result.partial) == complete or result.scene != "res://fixture.tscn":
			print("FAIL GPU summary assembly (complete=%s): %s" % [complete, result])
			return false
	# Capture ids: a late frame from capture 1 must not join capture 2; messages without an id (older runtime) still count.
	if plugin.capture_matches([{}, 60.0, 1], 2, 2) or not plugin.capture_matches([{}, 60.0, 2], 2, 2) or not plugin.capture_matches([{}, 60.0], 2, 2):
		print("FAIL GPU capture id filter")
		return false
	return true


## The game-side VRAM walk reads every object property: a typed script variable can still hold a freed node (an "is" test
## on it is a script error that pauses the game in the debugger), and hidden GPUParticles3D draw passes print engine errors.
## The runner fails on any SCRIPT ERROR or engine ERROR printed here.
func _test_vram_walk_edge_cases() -> bool:
	var holder := Node3D.new()
	var script := GDScript.new()
	script.source_code = "extends Node3D\n@export var target: Node3D\nvar hidden_target: Node3D\n"
	script.reload()
	holder.set_script(script)
	var gone := Node3D.new()
	holder.set("target", gone)
	holder.set("hidden_target", gone)
	gone.free()
	var particles := GPUParticles3D.new()
	particles.draw_pass_1 = BoxMesh.new()
	holder.add_child(particles)
	var unset_view := Sprite3D.new()  # a ViewportTexture without a viewport: get_size() would print an engine error
	unset_view.set("texture", ViewportTexture.new())
	holder.add_child(unset_view)
	root.add_child(holder)
	var report: Dictionary = VramEstimate.collect(holder)
	holder.free()
	if report.is_empty():
		print("FAIL VRAM walk returned nothing")
		return false
	# The editor stores the main scene as uid:// (4.4+); comparing it with a res:// scene_file_path scanned it twice.
	var main_uid := ResourceUID.id_to_text(ResourceLoader.get_resource_uid("res://heavy_scripts.gd"))
	if SceneScan.res_path(main_uid) != "res://heavy_scripts.gd" or SceneScan.res_path("res://other.tscn") != "res://other.tscn":
		print("FAIL uid main scene path ", SceneScan.res_path(main_uid))
		return false
	# The project walk skips what the editor skips: folders with .gdignore or a nested project.godot, and dot folders.
	for folder in ["res://walk_ignored", "res://walk_nested", "res://.walk_dot"]:
		DirAccess.make_dir_absolute(folder)
		FileAccess.open(folder + "/probe.gd", FileAccess.WRITE).store_string("extends Node\n")
	FileAccess.open("res://walk_ignored/.gdignore", FileAccess.WRITE).store_string("")
	FileAccess.open("res://walk_nested/project.godot", FileAccess.WRITE).store_string("")
	var walked: Dictionary = load("res://addons/render_lens/project_scan.gd").project_files({})
	for folder in ["res://walk_ignored", "res://walk_nested", "res://.walk_dot"]:
		for name in ["probe.gd", ".gdignore", "project.godot"]:
			DirAccess.remove_absolute(folder + "/" + name)
		DirAccess.remove_absolute(folder)
	for walked_script in walked[".gd"]:
		if str(walked_script).contains("walk_"):
			print("FAIL project walk entered an ignored folder: ", walked_script)
			return false
	# Script scans match declarations and calls in code, not in comments or similarly named functions.
	var ProjectScan = load("res://addons/render_lens/project_scan.gd")
	FileAccess.open("res://scan_fixture.gd", FileAccess.WRITE).store_string("extends Node\n\n# func _process(delta): $Region.bake_navigation_mesh()\nfunc _process_queue():\n\tpass\n")
	var scanned := {"counts": {}, "offenders": {}}
	ProjectScan._scripts(scanned, ["res://scan_fixture.gd"], {})
	DirAccess.remove_absolute("res://scan_fixture.gd")
	if scanned.counts.has("check_navigation_runtime_bake") or int(scanned.counts.get("script_file_process_count", 0)) != 0:
		print("FAIL comment or _process_queue counted as code: ", scanned.counts)
		return false
	if ProjectScan.path_case_mismatches("load(\"res://art/hero sprite.png\")", {"res://art/hero sprite.png": "res://Art/hero sprite.png"}, false) != ["res://art/hero sprite.png"]:
		print("FAIL res:// path with a space")
		return false
	# Hitch rates use the captured time: one hitch in 120 s at 5 fps is occasional (an assumed 60 fps made it 10 s, recurring).
	var slow_frames := []
	for index in 600:
		slow_frames.append({"total_ms": 1000.0 if index == 300 else 200.0, "cpu_ms": 0.0, "gpu_ms": 0.0, "process_ms": 0.0, "physics_ms": 0.0, "shader_compile": false})
	var stutters: Dictionary = load("res://addons/render_lens/tools/stutter_report.gd")._analyze_stutters(slow_frames)
	if stutters.get("verdict", "") != "occasional":
		print("FAIL stutter verdict at 5 fps: ", stutters.get("verdict", ""), " hitches ", stutters.get("hitch_count", -1))
		return false
	# Out-of-range durations are refused before any game request (a negative one made the editor's wait negative).
	var refused: Dictionary = load("res://addons/render_lens/tools/session_summary.gd").execute({"duration": -5.0})
	if not refused.get("isError", false) or not str(refused.content[0].text).contains("between 30 and 600"):
		print("FAIL session_summary duration validation: ", refused)
		return false
	# Scene and VRAM walks are iterative: 1100 nested nodes exceed GDScript's 1024-frame call stack.
	var deep := Node3D.new()
	var tip: Node = deep
	for depth in 1100:
		var child := Node3D.new()
		tip.add_child(child)
		tip = child
	root.add_child(deep)
	var deep_scan: Dictionary = SceneScan.scan(deep, "")
	var deep_vram: Dictionary = VramEstimate.collect(deep)
	# The running game scans only its nodes (project files are read by the editor in ScanScene.gather).
	var nodes_only: Dictionary = SceneScan.scan(deep, "", false)
	deep.free()
	if deep_scan.is_empty() or deep_vram.is_empty():
		print("FAIL deep scene walk")
		return false
	if int(deep_scan.file_walk.get("entries", 0)) <= 0 or not nodes_only.file_walk.is_empty():
		print("FAIL project files read by a nodes-only scan: ", nodes_only.file_walk)
		return false
	# The game's live audio buses can differ from the editor's, so the game reads them itself (the editor merge skips them).
	if not nodes_only.audio_scan.has("enabled_effects") or int(nodes_only.counts.get("audio_bus_count", 0)) != AudioServer.get_bus_count():
		print("FAIL nodes-only scan skipped the live audio buses: ", nodes_only.audio_scan)
		return false
	return true


func _finding_by_validation_id(findings: Array, validation_id: String) -> Dictionary:
	for item in findings:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if str(item.get("validation_id", "")) == validation_id:
			return item
	return {}


func _rule_applies_here(rule: Dictionary) -> bool:
	var info := Engine.get_version_info()
	return Rules.version_applies(rule.get("applies_to", {}), int(info.major) * 1000 + int(info.minor))


func _ids(findings: Array) -> Dictionary:
	var ids := {}
	for item in findings:
		ids[str(item.get("id", ""))] = true
	return ids


func _version_tag() -> String:
	var info := Engine.get_version_info()
	return "%d.%d" % [int(info.get("major", 0)), int(info.get("minor", 0))]


func _gather_paths(node, into: Dictionary) -> void:
	if typeof(node) == TYPE_ARRAY:
		for child in node:
			_gather_paths(child, into)
		return
	if typeof(node) != TYPE_DICTIONARY:
		return
	for key in node.keys():
		var value = node[key]
		if key in ["setting_eq", "setting_neq", "setting_gt", "setting_gte", "setting_lt", "setting_lte", "adapter_listed_in_setting"]:
			if typeof(value) == TYPE_DICTIONARY and str(value.get("path", "")) != "":
				into[str(value.get("path", ""))] = true
		else:
			_gather_paths(value, into)


## The VRAM walk follows SpriteFrames frames and Mesh surface materials, and reports a truncated list when it hits its resource cap.
func _test_vram_containers_and_cap() -> bool:
	var holder := Node3D.new()
	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	var frame_a := ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8))
	var frame_b := ImageTexture.create_from_image(Image.create(8, 8, false, Image.FORMAT_RGBA8))
	frames.add_frame("default", frame_a)
	frames.add_frame("default", frame_b)
	sprite.sprite_frames = frames
	holder.add_child(sprite)
	var albedo := ImageTexture.create_from_image(Image.create(16, 16, false, Image.FORMAT_RGBA8))
	var material := StandardMaterial3D.new()
	material.albedo_texture = albedo
	var box := BoxMesh.new()
	box.material = material
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = box
	holder.add_child(mesh_instance)
	root.add_child(holder)
	var report: Dictionary = VramEstimate.collect(holder)
	var listed := {}
	for item in report.resources:
		listed[item.path] = true
	holder.free()
	for tex in [frame_a, frame_b, albedo]:
		if not listed.has("texture:%d" % tex.get_instance_id()):
			print("FAIL VRAM walk missed a SpriteFrames frame or mesh material texture")
			return false
	if report.truncated or not report.has("device"):
		print("FAIL VRAM report truncated or missing device on a tiny scene")
		return false
	var big := Node2D.new()
	for i in VramEstimate.RESOURCE_CAP + 1:
		var tiled := Sprite2D.new()
		tiled.texture = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
		big.add_child(tiled)
	root.add_child(big)
	var capped: Dictionary = VramEstimate.collect(big)
	big.free()
	if not capped.truncated or int(capped.resource_count) != VramEstimate.RESOURCE_CAP or int(capped.resource_cap) != VramEstimate.RESOURCE_CAP:
		print("FAIL VRAM cap not reported: truncated=", capped.truncated, " count=", capped.resource_count)
		return false
	# Exactly at the cap, textures behind a container (SpriteFrames) are left out too, so the report is truncated.
	var full := Node2D.new()
	for i in VramEstimate.RESOURCE_CAP:
		var tiled := Sprite2D.new()
		tiled.texture = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
		full.add_child(tiled)
	var late := AnimatedSprite2D.new()
	late.sprite_frames = SpriteFrames.new()
	late.sprite_frames.add_frame("default", ImageTexture.create_from_image(Image.create(2, 2, false, Image.FORMAT_RGBA8)))
	full.add_child(late)
	root.add_child(full)
	var behind: Dictionary = VramEstimate.collect(full)
	full.free()
	if not behind.truncated:
		print("FAIL VRAM cap left out SpriteFrames textures without reporting truncation")
		return false
	# A scene of exactly the node budget is walked completely.
	var exact := Node.new()
	for i in 7999:
		exact.add_child(Node.new())
	var walked: Dictionary = VramEstimate.collect(exact)
	exact.free()
	if walked.truncated:
		print("FAIL VRAM walk of exactly 8,000 nodes reported truncation")
		return false
	return true
