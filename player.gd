extends CharacterBody3D
class_name Player

enum State {IDLE, HOLD, VIEW}

signal state_changed(old_state: State, new_state: State)

var holding: BookBase
var _state: State
var state: State:
	get: return _state
	set(value):
		state_changed.emit(_state, value)
		_state = value

@export var move_speed := 1.0
var mouse_sensitivity := 0.2
var yaw := 0.0
var pitch := 0.0
@export var vellum_spawner: VellumSpawner
var gravity := Vector3(0, -9.8/2, 0)
var gravity_enabled := true

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_ESCAPE:
					match Input2.mouse_mode_override:
						Input2.MouseMode.INHERIT:
							match Input2.mouse_mode:
								Input2.MouseMode.CAPTURED:
									Input2.mouse_mode_override = Input2.MouseMode.VISIBLE
								Input2.MouseMode.VISIBLE:
									Input2.mouse_mode_override = Input2.MouseMode.CAPTURED
						_:
							Input2.mouse_mode_override = Input2.MouseMode.INHERIT

func _unhandled_input(event):
	match state:
		State.VIEW:
			if event is InputEventKey:
				if event.pressed:
					match event.keycode:
						KEY_LEFT:
							holding.page_left()
						KEY_RIGHT:
							holding.page_right()
		_:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				if event is InputEventMouseMotion:
					yaw -= event.relative.x * mouse_sensitivity
					pitch -= event.relative.y * mouse_sensitivity
					pitch = clamp(pitch, -89, 89)
					$Camera3D.rotation_degrees = Vector3(pitch, 0, 0)
					rotation_degrees = Vector3(0, yaw, 0)

func execute(book: BookBase):
	if book: book.execute()

func take(book: BookBase):
	if book and not holding:
		holding = book
		holding.hold($Camera3D)
		state = State.HOLD

func release(_book: BookBase):
	if holding:
		holding.release()
		holding = null
		state = State.IDLE
		Input2.mouse_mode = Input2.MouseMode.CAPTURED

func open(_book: BookBase):
	if holding:
		holding.open()
		state = State.VIEW
		Input2.mouse_mode = Input2.MouseMode.VISIBLE

func close(_book: BookBase):
	if holding:
		holding.close()
		state = State.HOLD
		Input2.mouse_mode = Input2.MouseMode.CAPTURED

func vellum(_data):
	take(vellum_spawner.vellum)

func _physics_process(delta):
	var input_dir = Vector3.ZERO
	
	if state != State.VIEW:
		if Input2.is_action_double_pressed(&"character_move_upward"):
			gravity_enabled = not gravity_enabled

		if Input2.is_action_pressed(&"character_move_forward"):  input_dir.z -= 1
		if Input2.is_action_pressed(&"character_move_backward"): input_dir.z += 1
		if Input2.is_action_pressed(&"character_move_left"):     input_dir.x -= 1
		if Input2.is_action_pressed(&"character_move_right"):    input_dir.x += 1
		if Input2.is_action_pressed(&"character_move_upward"):   input_dir.y += 1
		if Input2.is_action_pressed(&"character_move_downward"): input_dir.y -= 1

	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()

	var direction = (transform.basis * input_dir).normalized()

	velocity = direction * move_speed

	if gravity_enabled:
		velocity += gravity

	move_and_slide()
