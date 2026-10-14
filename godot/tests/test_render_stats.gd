extends Node

## Simple test for render_stats tool

func _ready() -> void:
	print("\n========================================")
	print("Testing render_stats")
	print("========================================\n")
	
	# Load the tool
	var tool := preload("res://addons/render_lens/tools/render_stats.gd")
	
	# Execute
	var result: Dictionary = await tool.execute({})
	
	# Check result
	if result.has("isError"):
		print("❌ FAIL: %s" % result.content[0].text)
		get_tree().quit(1)
		return
	
	# Parse JSON
	var json := JSON.new()
	var parse_result := json.parse(result.content[0].text)
	
	if parse_result != OK:
		print("❌ FAIL: Invalid JSON response")
		get_tree().quit(1)
		return
	
	var stats: Dictionary = json.data
	
	print("✅ render_stats executed successfully\n")
	
	# Check required fields
	var required := ["context", "global", "viewports", "memory", "summary"]
	for field in required:
		if not stats.has(field):
			print("❌ Missing field: %s" % field)
			get_tree().quit(1)
			return
	
	# Print summary
	print("Summary:")
	for key in stats.summary:
		print("  %s: %s" % [key, stats.summary[key]])
	
	print("\nGlobal stats:")
	for key in stats.global:
		print("  %s: %s" % [key, stats.global[key]])
	
	print("\nViewport passes:")
	for vp in stats.viewports:
		print("  %s: %d draw calls" % [vp.type, vp.draw_calls])
	
	print("\nMemory:")
	for key in stats.memory:
		print("  %s: %.1f MB" % [key, stats.memory[key]])
	
	print("\n✅ ALL CHECKS PASSED")
	get_tree().quit(0)
