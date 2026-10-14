@tool
extends SceneTree

## Validation script that checks tool scripts load without parse errors
## Run with: godot --headless --script tests/validate_tool_scripts.gd

func _init():
	print("=== MCP Tool Validation ===")
	
	# Check that EditorPlugin exists and tools are loaded
	var plugin_path := "res://addons/render_lens/plugin.gd"
	var mcp_server_path := "res://addons/render_lens/mcp_server.gd"
	
	if not FileAccess.file_exists(plugin_path):
		print("❌ Plugin file not found")
		quit(1)
		return
	
	if not FileAccess.file_exists(mcp_server_path):
		print("❌ MCP server file not found")
		quit(1)
		return
	
	# Load the MCP server script to check it parses
	var mcp_script := load(mcp_server_path)
	if mcp_script == null:
		print("❌ Failed to load MCP server script")
		quit(1)
		return
	
	# Check that tools directory exists and has .gd files
	var tools_dir := "res://addons/render_lens/tools/"
	if not DirAccess.dir_exists_absolute(tools_dir):
		print("❌ Tools directory not found")
		quit(1)
		return
	
	# List and validate tool scripts
	var dir := DirAccess.open(tools_dir)
	if dir == null:
		print("❌ Failed to open tools directory")
		quit(1)
		return
	
	var tool_count := 0
	var failed_tools: Array[String] = []
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".gd") and not file_name.ends_with(".gd.uid"):
			tool_count += 1
			var tool_path := tools_dir + file_name
			var tool_script := load(tool_path)
			if tool_script == null:
				failed_tools.append(file_name)
				print("❌ Failed to load: %s" % file_name)
			else:
				print("✅ Loaded: %s" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	print("\n=== Summary ===")
	print("Tools checked: %d" % tool_count)
	print("Failed: %d" % failed_tools.size())
	
	if failed_tools.size() > 0:
		print("\nFailed tools:")
		for tool in failed_tools:
			print("  - %s" % tool)
		quit(1)
	else:
		print("\nAll tools loaded successfully ✅")
		quit(0)
