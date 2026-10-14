extends Node

const Game = preload("res://addons/render_lens/game_bridge.gd")
const CANCEL_GRACE_MS := 5000
const OPERATIONS := ["frame_timing", "render_stats", "capture_viewport", "stutter_report", "session_summary"]

var _pro: Node
var _busy := false
var _request_id := -1
var _cancel := {}
var _cancelled_at := 0
# Loaded only under a debugger, so a shipped game never compiles the scanners, which name module classes (GridMap,
# CSGShape3D, XROrigin3D) that a custom export template can leave out.
var Metrics
var SceneScan
# Held so the experiment's undo list (a static var) lives as long as the game.
var Experiment

func _ready() -> void:
	# A paused SceneTree (a pause menu) is still a frame worth measuring; the GPU recorder child inherits this.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not EngineDebugger.is_active():
		return
	Metrics = load("res://addons/render_lens/metrics_snapshot.gd")
	if FileAccess.file_exists("res://addons/render_lens/runtime/gpu_recorder.gd"):
		_pro = load("res://addons/render_lens/runtime/gpu_recorder.gd").new()
		add_child(_pro)
	EngineDebugger.register_message_capture("render_lens", _on_message)
	# The game reports its own render thread model: --render-thread on the command line overrides the project setting.
	EngineDebugger.send_message("render_lens:ready", [Metrics.renderer(), RenderingServer.get_rendering_device() != null, Game.Pacing.separate_render_thread()])

func _on_message(message: String, data: Array) -> bool:
	match message.trim_prefix("render_lens:"):
		"measure":
			if data.size() == 3 and typeof(data[1]) == TYPE_STRING and typeof(data[2]) == TYPE_DICTIONARY:
				_measure(int(data[0]), str(data[1]), data[2])
			return true
		"cancel_measurement":
			if data.size() > 0 and int(data[0]) == _request_id:
				_cancel["cancelled"] = true
				_cancelled_at = Time.get_ticks_msec()
			return true
		"collect_metrics":
			EngineDebugger.send_message("render_lens:metrics", [Metrics.collect()])
			return true
		"experiment_restore":
			if Experiment != null:
				Experiment.restore(get_tree())
			return true
	return _pro._on_message(message, data) if _pro != null else false

func _measure(id: int, operation: String, arguments: Dictionary) -> void:
	# A tool stopped by a script error never clears _busy; cancelled work unwinds within a frame.
	if _busy and _cancel.get("cancelled", false) and Time.get_ticks_msec() - _cancelled_at > CANCEL_GRACE_MS:
		_busy = false
	if _busy:
		EngineDebugger.send_message("render_lens:measurement", [id, Game.error("A game measurement is still active")])
		return
	_busy = true
	_request_id = id
	_cancel = {"cancelled": false}
	arguments["_cancel"] = _cancel
	var result: Dictionary
	if operation == "scene_snapshot":
		var root := get_tree().current_scene
		# Autoloads and nodes scripts add to the root (a HUD, a persistent WorldEnvironment) render with the scene.
		var extra: Array = []
		for child in get_tree().root.get_children():
			if child != root and child != self:
				extra.append(child)
		if SceneScan == null:
			SceneScan = load("res://addons/render_lens/scene_scan.gd")  # only when asked, even under a remote debugger
		# Nodes only: walking up to 100,000 project files here would stall the running game; the editor reads them.
		result = SceneScan.scan(root, root.scene_file_path, false, extra) if root != null else {"error": "No running scene"}
		if not result.is_empty():
			result["source"] = "game"
	elif operation == "metrics_snapshot":
		result = Metrics.collect()
	elif operation == "experiment" and FileAccess.file_exists("res://addons/render_lens/runtime/experiment.gd"):
		if Experiment == null:
			Experiment = load("res://addons/render_lens/runtime/experiment.gd")
		result = Experiment.run(get_tree(), arguments)
	elif operation in OPERATIONS and FileAccess.file_exists("res://addons/render_lens/tools/%s.gd" % operation):
		result = await load("res://addons/render_lens/tools/%s.gd" % operation).execute(arguments)
	else:
		result = Game.error("Unavailable game operation: " + operation)
	if result.is_empty():
		# A script error makes the typed call return {}; report it instead of an empty measurement.
		result = Game.error("Render Lens hit a script error in the game during %s; the game's Output has the details." % operation)
	if _request_id == id:
		_busy = false
	EngineDebugger.send_message("render_lens:measurement", [id, result])

func _exit_tree() -> void:
	_cancel["cancelled"] = true
	if EngineDebugger.is_active():
		EngineDebugger.unregister_message_capture("render_lens")
