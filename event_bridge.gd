extends Control
class_name EventBridge

@export var main_camera: Camera3D
@export var player: Player
var image: Image
@onready var last_position: Vector2
var last_event_time: float
var last_page: PageBase

func _ready() -> void:
	get_window().size_changed.connect(_on_window_size_changed)
	_on_window_size_changed()

func _process(_delta: float) -> void:
	$SubViewport/Camera3D.global_transform = main_camera.global_transform

func _gui_input(input_event: InputEvent) -> void:
	if player.state != Player.State.VIEW: return
	image = get_image()
	var page_id = pick_page_id(get_viewport().get_mouse_position())
	var page = id_to_page(page_id)
	var page_changed = page != last_page
	if page_changed:
		if page: page.propagate_notification(NOTIFICATION_VP_MOUSE_ENTER)
		if last_page: last_page.propagate_notification(NOTIFICATION_VP_MOUSE_EXIT)
		last_event_time = 0
		last_position = Vector2.ZERO
	if page:
		stash_input(input_event)
		modify_input(input_event, page)
		page.push_input(input_event)
		restore_input(input_event)
	last_page = page

func _on_window_size_changed() -> void:
	$SubViewport.size = get_window().size
	
func get_image() -> Image:
	var tex = $SubViewport.get_texture()
	return tex.get_image()
	
func pick_uv(screen_pos: Vector2) -> Vector2:
	var color = image.get_pixelv(screen_pos)
	return Vector2(color.r, color.g)
	
func pick_page_id(screen_pos: Vector2) -> int:
	return int(round(image.get_pixelv(screen_pos).b * 10))

func id_to_page(id: int) -> PageBase:
	if not player.holding: return null
	match id:
		# FIXME: It does not function correctly during page scrolling.
		1: return player.holding.current_left_page
		2: return player.holding.swap_left_page
		3: return player.holding.swap_right_page
		4: return player.holding.current_right_page
		_: return null
		
func pick_page(screen_pos: Vector2) -> PageBase:
	return id_to_page(pick_page_id(screen_pos))

var p_relative: Vector2
var p_global_position: Vector2
var p_position: Vector2
var p_velocity: Vector2

func stash_input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseButton:
		p_position = input_event.position
		p_global_position = input_event.global_position
	elif input_event is InputEventMouseMotion:
		p_position = input_event.position
		p_global_position = input_event.global_position
		p_relative = input_event.relative
		p_velocity = input_event.velocity
	elif input_event is InputEventScreenTouch:
		p_position = input_event.position
	elif input_event is InputEventScreenDrag:
		p_position = input_event.position
		p_relative = input_event.relative
		p_velocity = input_event.velocity

func modify_input(input_event: InputEvent, page: PageBase) -> void:
	for mouse_event in [InputEventMouse, InputEventScreenDrag, InputEventScreenTouch]:
		if is_instance_of(input_event, mouse_event):
			input_event.position = pick_uv(input_event.position) * Vector2(page.size)
	if input_event is InputEventMouse:
		input_event.global_position = input_event.position
	for move_event in [InputEventMouseMotion, InputEventScreenDrag]:
		if is_instance_of(input_event, move_event):
			var now := Time.get_ticks_msec() / 1000.0
			var dt = now - last_event_time
			var page_changed = page != last_page
			if page_changed or dt == 0:
				input_event.relative = Vector2.ZERO
			else:
				input_event.relative = input_event.position - last_position
				input_event.velocity = input_event.relative / dt
			last_position = input_event.position
			last_event_time = now

func restore_input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseButton:
		input_event.position = p_position
		input_event.global_position = p_global_position
	elif input_event is InputEventMouseMotion:
		input_event.position = p_position
		input_event.global_position = p_global_position
		input_event.relative = p_relative
		input_event.velocity = p_velocity
	elif input_event is InputEventScreenTouch:
		input_event.position = p_position
	elif input_event is InputEventScreenDrag:
		input_event.position = p_position
		input_event.relative = p_relative
		input_event.velocity = p_velocity
