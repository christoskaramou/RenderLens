extends Node3D

const Variants = preload("res://variants.gd")


func _ready() -> void:
	var scene: Node = load("res://heavy_test.tscn").instantiate()
	for name in FileAccess.get_file_as_string("res://variant.txt").strip_edges().split("+"):
		if not Variants.apply(scene, name):
			push_error("unknown variant " + name)
	add_child(scene)
