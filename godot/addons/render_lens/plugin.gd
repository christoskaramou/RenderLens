@tool
extends EditorPlugin

## Render Lens MCP Server Plugin
## Entry point for the Godot 4 editor plugin

var mcp_server: Node
var dock_panel: Control
var monitors: Node
var debugger_plugin: EditorDebuggerPlugin

const BRIDGE := "res://addons/render_lens/runtime/bridge.gd"

func _enter_tree() -> void:
	if str(ProjectSettings.get_setting("autoload/GpuRecorder", "")) == "*res://addons/render_lens/runtime/gpu_recorder.gd":
		remove_autoload_singleton("GpuRecorder")
	# Load and instantiate the MCP server
	var mcp_server_script = preload("res://addons/render_lens/mcp_server.gd")
	mcp_server = mcp_server_script.new()
	add_child(mcp_server)
	
	# Load and add the dock panel
	dock_panel = preload("res://addons/render_lens/dock_panel.tscn").instantiate()
	dock_panel.mcp_server = mcp_server
	add_control_to_dock(DOCK_SLOT_RIGHT_BR, dock_panel)
	
	# Register custom monitors
	var monitors_script = preload("res://addons/render_lens/monitors.gd")
	monitors = monitors_script.new()
	add_child(monitors)
	
	# Both packages measure the running game through this bridge.
	if FileAccess.file_exists("res://addons/render_lens/debugger_plugin.gd"):
		var debugger_script = load("res://addons/render_lens/debugger_plugin.gd")
		if debugger_script:
			debugger_plugin = debugger_script.new()
			add_debugger_plugin(debugger_plugin)
			
			# Connect debugger to MCP server
			mcp_server.debugger_plugin = debugger_plugin
			
			# Registered only when missing or stale, and removed only by _disable_plugin, so editor start/quit leaves project.godot alone.
			var registered := str(ProjectSettings.get_setting("autoload/RenderLensRuntime", "")).trim_prefix("*")
			if registered.begins_with("uid://") and ResourceUID.has_id(ResourceUID.text_to_id(registered)):
				registered = ResourceUID.get_id_path(ResourceUID.text_to_id(registered))
			if registered != BRIDGE:
				add_autoload_singleton("RenderLensRuntime", BRIDGE)
				# The editor defers its settings save; an immediate run must see the bridge.
				ProjectSettings.save()
	
	print("[Render Lens] Plugin loaded")

func _exit_tree() -> void:
	# Clean up
	if debugger_plugin:
		# A measure_change still running would lose its session; undo its change in the game first.
		debugger_plugin.send_experiment_restore()
		remove_debugger_plugin(debugger_plugin)

	if dock_panel:
		remove_control_from_docks(dock_panel)
		dock_panel.queue_free()
	
	if monitors:
		monitors.queue_free()
	
	if mcp_server:
		mcp_server.stop_server()
		mcp_server.queue_free()
	
	print("[Render Lens] Plugin unloaded")

func _disable_plugin() -> void:
	remove_autoload_singleton("RenderLensRuntime")
