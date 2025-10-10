extends Control

@export var controller: BoidController3D
@export var player: Player

func _process(delta: float) -> void:
	$FPS.text = str(Engine.get_frames_per_second())
	if controller:
		$Agents.text = str(controller.get_agent_count())
	if player:
		if player.latest_agent:
			$CurrentAgent/Name.text = player.latest_agent.name
			$CurrentAgent/Path.text = player.latest_agent.path
