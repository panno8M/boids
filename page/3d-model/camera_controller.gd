extends Control

@export var camera_origin: Node3D
@export var camera: Camera3D

var nearfar_sensitivity := 0.25
var move_sensitivity := 0.0015
var mouse_sensitivity := 0.2
var yaw := 0.0
var pitch := 0.0


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_pressed():
			if event.keycode == KEY_F:
				camera_origin.position = Vector3.ZERO
	if event is InputEventMouseButton:
		if event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					camera.position += Vector3.FORWARD * nearfar_sensitivity
				MOUSE_BUTTON_WHEEL_DOWN:
					camera.position += Vector3.BACK * nearfar_sensitivity
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if Input.is_key_pressed(KEY_SHIFT):
				camera_origin.position += camera_origin.quaternion * Vector3(-event.relative.x, event.relative.y, 0) * camera.position.z * move_sensitivity
			else:
				yaw -= event.relative.x * mouse_sensitivity
				pitch -= event.relative.y * mouse_sensitivity
				pitch = clamp(pitch, -89, 89)
				camera_origin.rotation_degrees = Vector3(pitch, yaw, 0)
