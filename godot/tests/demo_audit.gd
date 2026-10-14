extends SceneTree

## Static audit of every scene in a project, run by tests/run_demo_audit.py: the findings per scene, the advice package
## order invariants (tests/golden/advice_invariants.gd, copied next to this script) and scan errors.

const SceneScan = preload("res://addons/render_lens/scene_scan.gd")
const Advisor = preload("res://addons/render_lens/advisor_context.gd")
const Rules = preload("res://addons/render_lens/rule_engine.gd")
const Metrics = preload("res://addons/render_lens/metrics_snapshot.gd")


func _init() -> void:
	var out_path: String = OS.get_cmdline_user_args()[0]
	var scenes: Array = []
	_walk("res://", scenes)
	scenes.sort()
	# Loaded, not preloaded: the file is copied in only by the runner, and Godot 4.4's editor import parses every script.
	var Invariants = load("res://render_lens_invariants.gd")
	var snap: Dictionary = Metrics.collect()
	var report := {"scenes": {}, "errors": [], "violations": {}, "scene_count": scenes.size(), "ms": {}}
	for path in scenes.slice(0, 300):
		var started := Time.get_ticks_msec()
		var scanned: Dictionary = SceneScan.scan_path(path)
		if str(scanned.get("error", "")) != "":
			report.errors.append("%s: %s" % [path, scanned.error])
			continue
		var findings: Array = Rules.evaluate(Advisor.make(snap, scanned, {}, []), "static")
		var listed := {}
		for finding in findings:
			listed[finding.id] = finding.offenders
		report.scenes[path] = listed
		var broken: Array = Invariants.violations(Rules.package(findings, {}, 10, "static"))
		if not broken.is_empty():
			report.violations[path] = broken
		report.ms[path] = Time.get_ticks_msec() - started
	var file := FileAccess.open(out_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()
	print("AUDIT DONE %d scenes" % scenes.size())
	quit()


func _walk(root: String, out: Array) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name != "." and name != ".." and name != ".godot" and name != "addons":
			var full := root.path_join(name)
			if dir.current_is_dir():
				_walk(full, out)
			elif name.ends_with(".tscn") or name.ends_with(".scn"):
				out.append(full)
		name = dir.get_next()
	dir.list_dir_end()
