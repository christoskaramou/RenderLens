@tool
extends RefCounted


class ScriptedVideo extends VideoStreamTheora:
	pass


static func run(tree: SceneTree, check: Callable) -> void:
	var parent := Control.new()
	var video := VideoStreamPlayer.new()
	video.visible = false
	video.autoplay = true
	check.call(video, "hidden_video", false)
	video.stream = load("res://tests/fixtures/video_checks.ogv")
	assert(video.get_video_texture().get_width() == 32)
	check.call(video, "hidden_video", false)
	parent.add_child(video)
	tree.root.add_child(parent)
	assert(video.is_playing() == not Engine.is_editor_hint())
	check.call(video, "hidden_video", true)
	video.visible = true
	check.call(video, "hidden_video", false)
	parent.visible = false
	check.call(video, "hidden_video", true)
	video.paused = true
	check.call(video, "hidden_video", false)
	video.paused = false
	video.process_mode = Node.PROCESS_MODE_DISABLED
	check.call(video, "hidden_video", false)
	video.process_mode = Node.PROCESS_MODE_INHERIT
	parent.process_mode = Node.PROCESS_MODE_DISABLED
	check.call(video, "hidden_video", false)
	video.process_mode = Node.PROCESS_MODE_ALWAYS
	check.call(video, "hidden_video", true)
	parent.process_mode = Node.PROCESS_MODE_INHERIT
	video.process_mode = Node.PROCESS_MODE_INHERIT
	tree.paused = true
	check.call(video, "hidden_video", false)
	video.process_mode = Node.PROCESS_MODE_ALWAYS
	check.call(video, "hidden_video", true)
	tree.paused = false
	video.process_mode = Node.PROCESS_MODE_INHERIT
	if video.has_method("get_speed_scale"):
		video.set("speed_scale", 0.0)
		check.call(video, "hidden_video", false)
		video.set("speed_scale", 1.0)
	Engine.time_scale = 0.0
	check.call(video, "hidden_video", not video.has_method("get_speed_scale"))
	Engine.time_scale = 1.0
	video.stop()
	check.call(video, "hidden_video", Engine.is_editor_hint())
	video.autoplay = false
	check.call(video, "hidden_video", false)
	video.play()
	check.call(video, "hidden_video", not Engine.is_editor_hint())
	video.autoplay = true
	video.set_process_internal(false)
	check.call(video, "hidden_video", Engine.is_editor_hint())
	video.set_process_internal(true)
	check.call(video, "hidden_video", true)
	var scripted := ScriptedVideo.new()
	scripted.file = "res://tests/fixtures/video_checks.ogv"
	video.stream = scripted
	video.play()
	check.call(video, "hidden_video", false)
	video.stream = null
	check.call(video, "hidden_video", false)
	parent.free()

