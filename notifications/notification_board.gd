extends Node3D
class_name NotificationBoard

@export var poster_template: PackedScene

var posters: Array[NotificationPoster]

func _ready() -> void:
	get_node("/root/NotificationServerProxy").notification_recieved.connect(_on_notification_server_notification_recieved)

func _on_notification_server_notification_recieved(n: Notification) -> void:
	print(n)
	var poster = poster_template.instantiate()
	poster.initialize(n)
	add_poster(poster)

func pick_random_from_shape(shape: Shape3D) -> Vector3:
	if not shape:
		return Vector3.ZERO
	elif shape is BoxShape3D:
		var box = shape as BoxShape3D
		return (randv3(box.size) - box.size/2)
	else:
		return Vector3.ZERO

func pick_random(shape: CollisionShape3D) -> Vector3:
	return shape.position + pick_random_from_shape(shape.shape)

func add_poster(poster: NotificationPoster) -> void:
	posters.push_back(poster)
	poster.position = set_z(pick_random($Area3D/CollisionShape3D), posters.size() * 0.0001)
	add_child(poster)

static func randv3(v3: Vector3) -> Vector3:
	return Vector3(randf_range(0, v3.x), randf_range(0, v3.y), randf_range(0, v3.z))
static func set_z(v3: Vector3, new_z: float) -> Vector3:
	return Vector3(v3.x, v3.y, new_z)
