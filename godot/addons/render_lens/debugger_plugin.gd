@tool
extends EditorDebuggerPlugin

## Render Lens Debugger Plugin
## Handles communication with the running game for GPU profiling

signal gpu_data_received(data: Dictionary)
signal gpu_error(error: String)
signal gpu_ready(renderer: String, has_rd: bool)
signal metrics_received(data: Dictionary)

var sessions: Array[EditorDebuggerSession] = []
var ready_received := false
var last_messages_received: Array = []
var last_messages_sent: Array = []
var last_error := ""

const Parse = preload("res://addons/render_lens/debugger_parse.gd")
const MAX_MESSAGE_LOG := 10
const PAUSED_ERROR := "The game is paused in the debugger (breakpoint or error); continue it and measure again."

var _signatures := {}
var _profile_frames: Array = []
var _visual_frames: Array = []
var _profiling := false  # debug_data stays connected; frames are kept only while script_profile records
var _vram: Dictionary = {}
var _game_profile: Dictionary = {}
var _game_vram: Dictionary = {}
var _partial_gpu_frames: Array = []
var _capture_id := 0  # echoed by the game, so a late payload from a timed-out capture cannot complete the next one
var partial_gpu_fps := 0.0
var _debug_source: Object
var _measurement_id := 0
var _measurements := {}
var game_separate_render_thread := false  # reported by the game, which knows its --render-thread override
var _user_profilers := {}  # profilers the game already had on when script_profile started (the user's Profiler tabs)

func _setup_session(session_id: int) -> void:
	"""Called when a new debugger session is created"""
	var session := get_session(session_id)
	sessions.append(session)
	# A new game run reports its renderer and render thread model again; until then neither is known. A bound method,
	# not a lambda: a lambda would hold this plugin and the session would keep it alive at exit.
	session.started.connect(_on_session_started)
	
	print("[Render Lens Debugger] Session setup: %d (total sessions: %d)" % [session_id, sessions.size()])

func _on_session_started() -> void:
	ready_received = false
	game_separate_render_thread = false

func _has_capture(capture: String) -> bool:
	"""Register which messages we want to capture"""
	return capture == "render_lens"

func _capture(message: String, data: Array, session_id: int) -> bool:
	"""Handle messages from the game"""
	# Log received message
	last_messages_received.append({"time": Time.get_ticks_msec(), "message": message, "data_size": data.size(), "session_id": session_id})
	if last_messages_received.size() > MAX_MESSAGE_LOG:
		last_messages_received.pop_front()
	
	match message:
		"render_lens:measurement":
			if data.size() == 2 and _measurements.has(int(data[0])) and typeof(data[1]) == TYPE_DICTIONARY:
				_measurements[int(data[0])] = data[1]
			return true
		"render_lens:ready":
			if data.size() >= 2:
				ready_received = true
				game_separate_render_thread = data.size() >= 3 and bool(data[2])
				gpu_ready.emit(data[0], data[1])
				print("[Render Lens Debugger] Game ready: renderer=%s, RenderingDevice=%s" % [data[0], data[1]])
			return true
		
		"render_lens:ack":
			if data.size() > 0:
				print("[Render Lens Debugger] Ack: %s" % data[0])
			if data.size() >= 3 and str(data[0]) == "profile_start":
				_user_profilers = {"servers": bool(data[1]), "visual": bool(data[2])}
			return true
		
		"render_lens:progress":
			if data.size() >= 2:
				print("[Render Lens Debugger] Progress: %d frames, %d timestamps" % [data[0], data[1]])
			return true
		
		"render_lens:gpu_data":
			if data.size() > 0 and typeof(data[0]) == TYPE_DICTIONARY and capture_matches(data, 1, _capture_id):
				gpu_data_received.emit(with_frames(data[0], _partial_gpu_frames))
				print("[Render Lens Debugger] Received GPU data")
			return true
		
		"render_lens:gpu_error":
			if data.size() > 0 and capture_matches(data, 1, _capture_id):
				last_error = data[0]
				gpu_error.emit(data[0])
				print("[Render Lens Debugger] GPU error: %s" % data[0])
			return true
		
		"render_lens:metrics":
			if data.size() > 0 and typeof(data[0]) == TYPE_DICTIONARY:
				metrics_received.emit(data[0])
				print("[Render Lens Debugger] Received in-game metrics")
			return true

		"render_lens:gpu_frame":
			if not capture_matches(data, 2, _capture_id):
				return true
			if data.size() > 0 and typeof(data[0]) == TYPE_DICTIONARY:
				_partial_gpu_frames.append(data[0])
			if data.size() > 1:
				partial_gpu_fps = float(data[1])
			return true

		"render_lens:profile":
			if data.size() > 0 and typeof(data[0]) == TYPE_DICTIONARY:
				_game_profile = data[0]
				print("[Render Lens Debugger] Received game profile")
			return true

		"render_lens:vram":
			if data.size() > 0 and typeof(data[0]) == TYPE_DICTIONARY:
				_game_vram = data[0]
				print("[Render Lens Debugger] Received game VRAM estimate")
			return true
	
	return false

func send_start_recording(frames: int) -> bool:
	"""Tell the game to start recording GPU passes"""
	var session := _get_active_session()
	if not session:
		last_error = "No active debugger session"
		gpu_error.emit(last_error)
		return false
	
	if not session.is_active():
		last_error = "Debugger session not active"
		gpu_error.emit(last_error)
		return false
	
	_partial_gpu_frames.clear()
	partial_gpu_fps = 0.0
	_capture_id += 1
	session.send_message("render_lens:start_gpu_recording", [frames, _capture_id])
	
	# Log sent message
	var session_idx := sessions.find(session)
	last_messages_sent.append({
		"time": Time.get_ticks_msec(),
		"message": "render_lens:start_gpu_recording",
		"data_size": 1,
		"session_id": session_idx,
		"session_active": session.is_active()
	})
	if last_messages_sent.size() > MAX_MESSAGE_LOG:
		last_messages_sent.pop_front()
	
	print("[Render Lens Debugger] Sent start_recording: %d frames to session %d (active: %s)" % [frames, session_idx, session.is_active()])
	return true

func request_measurement(operation: String, arguments: Dictionary, timeout: float) -> Dictionary:
	var session := _get_active_session()
	if session == null:
		return {"isError": true, "content": [{"type": "text", "text": "No running game. Start it from the editor before measuring."}]}
	if session.is_breaked():
		return {"isError": true, "content": [{"type": "text", "text": PAUSED_ERROR}]}
	_measurement_id += 1
	var id := _measurement_id
	_measurements[id] = null
	session.send_message("render_lens:measure", [id, operation, arguments])
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while _measurements[id] == null and session.is_active() and not session.is_breaked() and Time.get_ticks_msec() < deadline:
		await (Engine.get_main_loop() as SceneTree).create_timer(0.02).timeout
	var response = _measurements[id]
	_measurements.erase(id)
	if response == null:
		# Also when paused: the game handles debugger messages in its break loop, and a measurement a script error
		# stopped never clears its busy flag without this cancel.
		if session.is_active():
			session.send_message("render_lens:cancel_measurement", [id])
		if session.is_active() and session.is_breaked():
			return {"isError": true, "content": [{"type": "text", "text": PAUSED_ERROR}]}
		return {"isError": true, "content": [{"type": "text", "text": "Game measurement timed out or the game stopped. No editor measurements were substituted."}]}
	return response

func attach_debug_signals() -> int:
	## Kept so older callers compile. The panel walk required
	## has_method("toggle_profiler"), and that method is not in ClassDB on 4.4 or 4.7.
	return 1 if attach_session_debug_data() else 0


func attach_session_debug_data() -> bool:
	## ScriptEditorDebugger emits debug_data before it consumes servers:profile_frame
	## and servers:memory_usage (4.7 _parse_message; 4.4 the same if/else before
	## plugins_capture). EditorDebuggerPlugin._capture never sees those messages.
	## The session API parents a tab under that debugger (add_debugger_tab -> tabs->add_child).
	## The parent chain is the debugger node. This does not search EditorInterface.get_base_control().
	if not Engine.is_editor_hint():
		return false
	if _debug_source != null and is_instance_valid(_debug_source) and _debug_source.has_signal("debug_data"):
		if not _debug_source.is_connected("debug_data", _on_debug_data):
			_debug_source.connect("debug_data", _on_debug_data)
		return true
	var session := _get_active_session()
	if session == null or not session.is_active():
		return false
	var hook := Control.new()
	hook.name = "RenderLensSessionHook"
	hook.visible = false
	session.add_session_tab(hook)
	var node: Node = hook
	var found: Node = null
	var guard := 0
	while node != null and guard < 16:
		guard += 1
		if node.has_signal("debug_data"):
			found = node
			break
		node = node.get_parent()
	if session.has_method("remove_session_tab"):
		session.remove_session_tab(hook)
	if found == null:
		return false
	_debug_source = found
	if not found.is_connected("debug_data", _on_debug_data):
		found.connect("debug_data", _on_debug_data)
	return true


func request_game_profile(frames: int) -> bool:
	var session := _get_active_session()
	if session == null or not session.is_active():
		last_error = "No active debugger session"
		return false
	_game_profile = {}
	_user_profilers = {}
	session.send_message("render_lens:profile_start", [frames])
	_log_sent("render_lens:profile_start", session)
	return true


func request_game_vram() -> bool:
	var session := _get_active_session()
	if session == null or not session.is_active():
		last_error = "No active debugger session"
		return false
	_game_vram = {}
	session.send_message("render_lens:vram_request", [])
	_log_sent("render_lens:vram_request", session)
	return true


func take_game_profile() -> Dictionary:
	return _game_profile.duplicate(true)


func take_game_vram() -> Dictionary:
	return _game_vram.duplicate(true)


func take_partial_gpu_frames() -> Array:
	return _partial_gpu_frames.duplicate(true)


## Messages without an id come from a runtime older than the capture ids and are accepted.
static func capture_matches(data: Array, index: int, current: int) -> bool:
	return data.size() <= index or int(data[index]) == current


## The game sends each GPU frame as render_lens:gpu_frame and then a summary with frame_count: all frames in one
## message can exceed the debugger's 8 MiB packet buffer (remote_debugger_peer.cpp), and Godot drops it.
static func with_frames(summary: Dictionary, frames: Array) -> Dictionary:
	var result := summary.duplicate()
	result["frames"] = frames.duplicate()
	result["partial"] = frames.size() < int(summary.get("frame_count", 0))
	return result


func _log_sent(message: String, session: EditorDebuggerSession) -> void:
	last_messages_sent.append({
		"time": Time.get_ticks_msec(),
		"message": message,
		"data_size": 1,
		"session_id": sessions.find(session),
		"session_active": session.is_active(),
	})
	if last_messages_sent.size() > MAX_MESSAGE_LOG:
		last_messages_sent.pop_front()


func _on_debug_data(msg: String, data: Array) -> void:
	if msg == "servers:memory_usage":
		_vram = Parse.parse_memory_usage(data)
	elif not _profiling:
		return  # the user's own Profiler session: nothing to parse or keep
	elif msg == "servers:function_signature":
		var sig: Dictionary = Parse.parse_signature(data)
		if bool(sig.get("ok", false)):
			_signatures[int(sig.get("id", -1))] = str(sig.get("name", ""))
	elif msg == "servers:profile_frame" or msg == "servers:profile_total":
		var frame: Dictionary = Parse.parse_profile_frame(data, _signatures)
		if bool(frame.get("ok", false)) and msg == "servers:profile_frame":
			_profile_frames.append(frame)
	elif msg == "visual:profile_frame":
		var visual: Dictionary = Parse.parse_visual_frame(data)
		if bool(visual.get("ok", false)):
			_visual_frames.append(visual)


func request_video_memory() -> bool:
	var session := _get_active_session()
	if session == null or not session.is_active():
		last_error = "No active debugger session"
		return false
	_vram = {}
	session.send_message("servers:memory", [])
	last_messages_sent.append({
		"time": Time.get_ticks_msec(),
		"message": "servers:memory",
		"data_size": 0,
		"session_id": sessions.find(session),
		"session_active": true,
	})
	return true


func start_servers_profiler(max_functions: int, include_visual: bool) -> bool:
	var session := _get_active_session()
	if session == null or not session.is_active():
		last_error = "No active debugger session"
		return false
	_signatures.clear()
	_profile_frames.clear()
	_visual_frames.clear()
	_profiling = true
	# RemoteDebugger expects [enable, [max_functions, include_native]]. Godot 4.4 appends the given array to [enable]
	# (ScriptEditorDebugger::toggle_profiler); 4.5+ sends [enable, array], where a nested array drops max_functions.
	var options := [max_functions, false]
	session.toggle_profiler("servers", true, [options] if Engine.get_version_info().minor < 5 else options)
	if include_visual:
		session.toggle_profiler("visual", true, [])
	return true


func stop_servers_profiler(include_visual: bool) -> void:
	_profiling = false
	var session := _get_active_session()
	if session == null or not session.is_active():
		return
	# Turning off a profiler the user had on would silently stop Godot's Profiler or Visual Profiler tab.
	if not bool(_user_profilers.get("servers", false)):
		session.toggle_profiler("servers", false, [])
	if include_visual and not bool(_user_profilers.get("visual", false)):
		session.toggle_profiler("visual", false, [])


func profile_frame_count() -> int:
	return _profile_frames.size()


func take_profile() -> Dictionary:
	return {
		"frames": _profile_frames.duplicate(),
		"visual_frames": _visual_frames.duplicate(),
		"debug_panels": 1 if _debug_source != null else 0,
	}


func take_vram() -> Dictionary:
	return _vram.duplicate(true)


## Undo measure_change's experiment without waiting for a reply: the game handles debugger messages in its break loop,
## so this reaches a paused game, and the bridge applies it even while another measurement is running.
func send_experiment_restore() -> bool:
	var session := _get_active_session()
	if session == null or not session.is_active():
		return false
	session.send_message("render_lens:experiment_restore", [])
	return true


func stop_gpu_recording() -> void:
	var session := _get_active_session()
	if session == null or not session.is_active():
		return
	session.send_message("render_lens:stop_gpu_recording", [])
	_log_sent("render_lens:stop_gpu_recording", session)


func send_collect_metrics() -> bool:
	"""Ask the running game for a Performance and RenderingServer snapshot."""
	var session := _get_active_session()
	if not session:
		last_error = "No active debugger session"
		return false
	if not session.is_active():
		last_error = "Debugger session not active"
		return false
	session.send_message("render_lens:collect_metrics", [])
	last_messages_sent.append({
		"time": Time.get_ticks_msec(),
		"message": "render_lens:collect_metrics",
		"data_size": 0,
		"session_id": sessions.find(session),
		"session_active": session.is_active()
	})
	if last_messages_sent.size() > MAX_MESSAGE_LOG:
		last_messages_sent.pop_front()
	return true

func _get_active_session() -> EditorDebuggerSession:
	"""Get the active debugger session"""
	# Return the first active session
	for session in sessions:
		if session.is_active():
			return session
	return null

func get_debug_status() -> Dictionary:
	"""Get current debug status for diagnostics"""
	var status: Dictionary = {
		"session_count": sessions.size(),
		"active_sessions": _count_active_sessions(),
		"ready_received": ready_received,
		"last_error": last_error,
		"last_messages_received": last_messages_received.duplicate(),
		"last_messages_sent": last_messages_sent.duplicate()
	}
	return status

func _count_active_sessions() -> int:
	"""Count active sessions"""
	var count := 0
	for session in sessions:
		if session.is_active():
			count += 1
	return count

func get_sessions() -> Array[EditorDebuggerSession]:
	"""Get all sessions (for compatibility)"""
	return sessions
