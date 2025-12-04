extends Node3D
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
var velocity := Vector3.ZERO
@export var controller: BoidController3D
@export var vellum_spawner: VellumSpawner

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
		holding.play_hold($Camera3D)
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

func _process(delta):
	var acc = Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		acc.z -= 1
	if Input.is_key_pressed(KEY_S):
		acc.z += 1
	if Input.is_key_pressed(KEY_A):
		acc.x -= 1
	if Input.is_key_pressed(KEY_D):
		acc.x += 1
	if Input.is_key_pressed(KEY_SPACE):
		acc.y += 1
	if Input.is_key_pressed(KEY_SHIFT):
		acc.y -= 1

	const power := 0.05

	if acc != Vector3.ZERO:
		velocity = (velocity + acc.limit_length(power)).limit_length()
	else:
		velocity = velocity.limit_length(max(0, velocity.length()-power))
	if velocity != Vector3.ZERO:
		translate(velocity * move_speed * delta)
