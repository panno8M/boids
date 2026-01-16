extends TextureRect
class_name SubViewportReference

var data: SubViewportReferenceData

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _input(input_event: InputEvent) -> void:
	stash_input(input_event)
	modify_input(input_event)
	data.sub_viewport.push_input(input_event)
	restore_input(input_event)

func change_data(new_data: SubViewportReferenceData) -> void:
	data = new_data
	texture = data.texture
	size = Vector2(data.size)

func initialize(viewport: SubViewport, page_size: Vector2i, page_offset: Vector2i) -> void:
	change_data(SubViewportReferenceData.initialize(viewport, page_size, page_offset))

func is_mouse_event(input_event: InputEvent) -> bool:
	return input_event is InputEventMouse or input_event is InputEventScreenDrag or input_event is InputEventScreenTouch

var p_relative: Vector2
var p_global_position: Vector2
var p_position: Vector2
var p_velocity: Vector2
var last_position: Vector2
var last_event_time: float

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

func modify_input(input_event: InputEvent) -> void:
	for mouse_event in [InputEventMouse, InputEventScreenDrag, InputEventScreenTouch]:
		if is_instance_of(input_event, mouse_event):
			input_event.position = input_event.position - position + Vector2(data.size * data.offset)
	if input_event is InputEventMouse:
		input_event.global_position = input_event.position
	for move_event in [InputEventMouseMotion, InputEventScreenDrag]:
		if is_instance_of(input_event, move_event):
			var now := Time.get_ticks_msec() / 1000.0
			var dt = now - last_event_time
			if dt == 0:
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
