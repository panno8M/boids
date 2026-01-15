extends PieMenu
class_name BookMenu

@export var player: Player
@export var camera: Camera3D
@export var status: Label

var closest_book: BookBase
var latest_book: BookBase

func _ready():
	super._ready()
	player.state_changed.connect(_on_player_state_changed)

func _process(_delta: float) -> void:
	if not selecting:
		closest_book = get_closest_book()
		if closest_book:
			status.text = closest_book.path.get_file()
			latest_book = closest_book
		else:
			status.text = ""
		if player.state == Player.State.IDLE:
			item_list = presets["Idle" if closest_book else "Global"]

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if closest_book:
					begin(closest_book)
				else:
					begin(null)
			else:
				var item = confirm()
				match typeof(item.selection):
					TYPE_STRING_NAME:
						if player.has_method(item.selection):
							player.call(item.selection, item.data)

func _on_player_state_changed(_old_state: Player.State, new_state: Player.State) -> void:
	match new_state:
		Player.State.IDLE:
			set_item_list_from_presets("Idle")
			status.visible = true
		Player.State.HOLD:
			set_item_list_from_presets("Hold")
			status.visible = false
		Player.State.VIEW:
			set_item_list_from_presets("View")
			status.visible = false

func get_closest_book(distance: float = 10000.0, mask: int = 0xFFFFFFFF) -> BoidAgent3D:
	var screen_center = get_global_mouse_position()

	var from = camera.project_ray_origin(screen_center)
	var to = from + camera.project_ray_normal(screen_center) * distance

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = mask
	query.collide_with_areas = true

	var result = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result:
		return result.collider.get_parent() as BookBase
	return null
