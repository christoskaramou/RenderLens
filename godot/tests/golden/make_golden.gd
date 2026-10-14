extends SceneTree

## Writes tests/golden/<case>.ctx: the rule-engine context of a case's scene with the fixed inputs in cases.json.
## Run inside a project that has the scene and the addon, then review the result before updating expected.json:
## godot --headless --path <project> --script res://tests/golden/make_golden.gd -- <case>...

const SceneScan = preload("res://addons/render_lens/scene_scan.gd")
const Metrics = preload("res://addons/render_lens/metrics_snapshot.gd")
const Advisor = preload("res://addons/render_lens/advisor_context.gd")


func _init() -> void:
	var cases: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/golden/cases.json"))
	for name in OS.get_cmdline_user_args():
		var spec: Dictionary = cases[name]
		var scanned: Dictionary = SceneScan.scan_path(spec.scene)
		var snap: Dictionary = Metrics.collect()
		snap.settings.merge(spec.settings, true)
		snap.metrics = spec.metrics
		var frame := {}
		if spec.mode == "measured":
			frame = Advisor.frame_from_measured(spec.median_ms, int(spec.target_fps), spec.bound, "golden", spec.cpu_ms, spec.gpu_ms)
		var ctx: Dictionary = Advisor.make(snap, scanned, frame, spec.passes)
		ctx.renderer = spec.renderer
		ctx.version_major = 4
		ctx.version_minor = 7
		ctx.adapter = {}
		var file := FileAccess.open("res://tests/golden/%s.ctx" % name, FileAccess.WRITE)
		file.store_string(var_to_str({"ctx": ctx, "frame": frame, "mode": spec.mode}))
		file.close()
		print("wrote ", name, ": ", scanned.get("scenes", []))
	quit()
