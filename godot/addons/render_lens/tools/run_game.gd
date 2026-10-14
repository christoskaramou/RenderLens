extends Node

## run_game Tool
## Start the game session in the editor

const Context = preload("res://addons/render_lens/context.gd")

static func execute(params: Dictionary) -> Dictionary:
	"""Execute run_game tool"""
	# In Godot 4.2+, EditorInterface is a global singleton class
	if not EditorInterface:
		return _build_error("EditorInterface not available (not running in editor)")
	
	# Check if already playing
	if EditorInterface.is_playing_scene():
		return _build_error("Game is already running")
	
	# Start the game
	var use_main_scene: bool = params.get("use_main_scene", true)
	if use_main_scene:
		var main_scene := str(ProjectSettings.get_setting("application/run/main_scene", ""))
		if not await main_scene_known(main_scene, 60.0):
			return _build_error("The main scene %s is not known to the editor yet (its file scan has not finished, or the scene was removed)." % main_scene)
		EditorInterface.play_main_scene()
	else:
		if not await current_scene_open():
			return _build_error("No scene is open in the editor, so there is no current scene to run; open one or run the main scene (use_main_scene true).")
		EditorInterface.play_current_scene()
	
	# First-run shader compilation can take longer than five seconds.
	var timeout := 30.0
	var start_time := Time.get_ticks_msec()
	var game_started := false
	var debugger_ready := false
	
	# Get debugger plugin if available (passed by mcp_server)
	var debugger_plugin = params.get("_debugger_plugin")
	
	# Use reference type for lambda capture (GDScript captures by value)
	var state := {"ready": false, "renderer": "", "has_rd": false}
	
	# Both packages use the game measurement bridge.
	var on_ready: Callable
	if debugger_plugin:
		on_ready = func(renderer: String, has_rd: bool):
			state.renderer = renderer
			state.has_rd = has_rd
			state.ready = true
		debugger_plugin.gpu_ready.connect(on_ready)
	
	# Non-blocking wait loop - await each frame to allow message processing
	while true:
		await Engine.get_main_loop().process_frame
		
		var elapsed_ms := Time.get_ticks_msec() - start_time
		var elapsed_sec := elapsed_ms / 1000.0
		
		# Check timeout
		if elapsed_sec >= timeout:
			break
		
		# Check if game is running
		if not game_started and EditorInterface.is_playing_scene():
			game_started = true
		elif game_started and not EditorInterface.is_playing_scene():
			if debugger_plugin and on_ready.is_valid():
				debugger_plugin.gpu_ready.disconnect(on_ready)
			return _build_error("The game stopped while starting (it may have crashed; the Output panel has its log).")
		
		# Without the debugger plugin the game starting is enough; with it, wait for its ready signal
		if game_started and not debugger_plugin:
			debugger_ready = true
		
		if debugger_plugin and state.ready:
			debugger_ready = true
		
		# Return only if both conditions met
		if game_started and debugger_ready:
			# Cleanup signal
			if debugger_plugin and on_ready.is_valid():
				debugger_plugin.gpu_ready.disconnect(on_ready)
			
			var result := {
				"status": "running",
				"scene": "main" if use_main_scene else "current",
				"debugger_ready": debugger_plugin != null and debugger_ready,
				"elapsed_ms": "%.0f" % elapsed_ms
			}
			
			if debugger_plugin and debugger_ready:
				result["renderer"] = state.renderer
				result["has_rendering_device"] = state.has_rd
			
			return {
				"content": [{
					"type": "text",
					"text": JSON.stringify(result, "\t")
				}]
			}
	
	# Cleanup signal on timeout
	if debugger_plugin and on_ready.is_valid():
		debugger_plugin.gpu_ready.disconnect(on_ready)
	
	# Calculate elapsed time for timeout messages
	var final_elapsed_ms := Time.get_ticks_msec() - start_time
	var final_elapsed_sec := final_elapsed_ms / 1000.0
	
	# Partial success - game started but debugger not ready
	if game_started and EditorInterface.is_playing_scene():
		return {
			"content": [{
				"type": "text",
				"text": JSON.stringify({
					"status": "running",
					"scene": "main" if use_main_scene else "current",
					"debugger_ready": false,
					"warning": "Game started but the measurement bridge was not ready after %.1fs. Wait for loading to finish before measuring." % final_elapsed_sec,
					"elapsed_ms": "%.0f" % final_elapsed_ms
				}, "\t")
			}]
		}
	
	return _build_error("Game did not start within %.1f seconds" % final_elapsed_sec)

# Note: Signal handling moved inline to execute()

## Right after the editor starts, its first scan may not have registered a uid:// main scene yet (4.4+ stores it that
## way), and play_main_scene then fails with "Unrecognized UID" and starts nothing. Waits up to timeout_sec for it.
static func main_scene_known(main_scene: String, timeout_sec: float) -> bool:
	if not main_scene.begins_with("uid://"):
		return true
	var id := ResourceUID.text_to_id(main_scene)
	var waited := 0.0
	while not ResourceUID.has_id(id) and waited < timeout_sec:
		await Engine.get_main_loop().create_timer(0.25).timeout
		waited += 0.25
	return ResourceUID.has_id(id)


## The editor reopens the last session's scenes, then opens one named on its command line, only after its startup scan
## and layout load, between progress updates that run the main loop (editor_node.cpp _sources_changed, 4.4 to 4.7.2): until
## then no scene, or not the final one, is current (seen 2026-10-14 with the TPS demo on 4.7.2). Godot removes its startup
## lock file a second after that (_remove_lock_file, os.cpp), so the wait lasts while the file exists or no scene is open,
## within the editor's first minute; later, no open scene means there is none.
static func current_scene_open() -> bool:
	var lock := OS.get_user_data_dir().path_join(".recovery_mode_lock")
	while Time.get_ticks_msec() < 60000 and (FileAccess.file_exists(lock) or EditorInterface.get_edited_scene_root() == null):
		await Engine.get_main_loop().create_timer(0.25).timeout
	return EditorInterface.get_edited_scene_root() != null


static func _build_error(message: String) -> Dictionary:
	return {
		"isError": true,
		"content": [{
			"type": "text",
			"text": message
		}]
	}
