extends Control

@export var controller: BoidController3D
@export var book_menu: BookMenu
@export var uv_picking_viewport: SubViewport

@onready var fps = $InfoPane/FPS
@onready var agents = $InfoPane/Agents
@onready var agent_name = $InfoPane/CurrentAgent/Name
@onready var agent_path = $InfoPane/CurrentAgent/Path

func _ready() -> void:
	$UVPreview.visible = false
	if uv_picking_viewport:
		$UVPreview.texture = uv_picking_viewport.get_texture()

func _process(_delta: float) -> void:
	fps.text = str(Engine.get_frames_per_second())
	if controller:
		agents.text = str(controller.get_agent_count())
	if book_menu:
		if book_menu.latest_book:
			agent_name.text = book_menu.latest_book.name
			agent_path.text = book_menu.latest_book.path

func _on_uv_picking_overlay_toggled(toggled_on: bool) -> void:
	$UVPreview.visible = toggled_on
