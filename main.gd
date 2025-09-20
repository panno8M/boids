extends Node3D
class_name Main

var pausing: bool
var activated: bool
@onready var follow = $Path3D/PathFollow3D

func _process(delta: float) -> void:
	if not pausing:
		follow.progress += 0.1
