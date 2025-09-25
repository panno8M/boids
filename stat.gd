extends Control

@export var controller: BoidController3D

func _process(delta: float) -> void:
	$FPS.text = str(Engine.get_frames_per_second())
	if controller:
		$Agents.text = str(controller.get_agent_count())
