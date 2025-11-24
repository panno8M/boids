extends Control

@export var controller: BoidController3D
@export var player: Player
@export var uv_picking_viewport: SubViewport

@onready var fps = $InfoPane/FPS
@onready var agents = $InfoPane/Agents
@onready var agent_name = $InfoPane/CurrentAgent/Name
@onready var agent_path = $InfoPane/CurrentAgent/Path

func _ready() -> void:
	$UVPreview.visible = false
	if uv_picking_viewport:
		$UVPreview.texture = uv_picking_viewport.get_texture()

func _process(delta: float) -> void:
	fps.text = str(Engine.get_frames_per_second())
	if controller:
		agents.text = str(controller.get_agent_count())
	if player:
		if player.latest_agent:
			agent_name.text = player.latest_agent.name
			agent_path.text = player.latest_agent.path

func _on_uv_picking_overlay_toggled(toggled_on: bool) -> void:
	$UVPreview.visible = toggled_on
