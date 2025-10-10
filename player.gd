extends Node3D
class_name Player

var move_speed := 10.0
var mouse_sensitivity := 0.2
var yaw := 0.0
var pitch := 0.0
var velocity := Vector3.ZERO
@export var closest_agent: BoidAgent3D
@export var latest_agent: BoidAgent3D

func get_closest_agent(camera: Camera3D, distance: float = 1000.0, mask: int = 0xFFFFFFFF) -> BoidAgent3D:
	var screen_center = get_viewport().size / 2

	var from = camera.project_ray_origin(screen_center)
	var to = from + camera.project_ray_normal(screen_center) * distance

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = mask
	query.collide_with_areas = true

	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result:
		return result.collider.get_parent() as BoidAgent3D
	return null

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

	closest_agent = get_closest_agent($Camera3D)
	if closest_agent:
		latest_agent = closest_agent
