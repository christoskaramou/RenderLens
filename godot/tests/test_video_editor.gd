@tool
extends EditorPlugin


func _enter_tree() -> void:
	call_deferred("_run_checks")


func _run_checks() -> void:
	assert(Engine.is_editor_hint())
	# Let editor startup leave its deferred initialization before changing pause state.
	await get_tree().create_timer(0.25).timeout
	while EditorInterface.get_resource_filesystem().is_scanning():
		await get_tree().process_frame
	print("BEGIN native video editor checks")
	load("res://tests/test_video_checks.gd").run(get_tree(), _expect)
	print("PASS native video editor autoplay, hidden ancestors and process-state exclusions")
	get_tree().quit()


func _expect(node: Node, key: String, expected: bool) -> void:
	var state := {"counts": {}, "offenders": {}}
	load("res://addons/render_lens/scene_checks.gd").inspect(node, state, "res://fixture.tscn::TestNode")
	assert((int(state.counts.get("check_" + key, 0)) > 0) == expected, key + " expected " + str(expected))
