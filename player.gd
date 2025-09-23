extends Node3D

var move_speed := 10.0
var mouse_sensitivity := 0.2
var yaw := 0.0
var pitch := 0.0
var velocity := Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -89, 89)
		rotation_degrees = Vector3(pitch, yaw, 0)

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
