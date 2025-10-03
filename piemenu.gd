extends Label
class_name PieMenu

@export var action: StringName
@export var item_list: Dictionary[String, Variant]
@export var threshold: float = 10.0
@export var radius: float = 100.0
@export var selected_item: Variant
var labels: Array[Label] = []
var mouse_begin: Vector2

signal item_selected(item: Variant)

func _ready():
	initialize(item_list)
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _draw():
	if not visible: return
	var count = item_list.size()
	var angle_step = TAU / count
	var center = size / 2
	var selecting = get_selecting_item()
	for i in range(count):
		var start_angle = item_to_angle(i, count) - angle_step/2
		var end_angle = start_angle + angle_step
		var color: Color
		if i == selecting: 
			color = Color(1, 0.5, 0, 0.4)
		else:
			color = Color(1, 1, 1, 0.1)
		draw_arc(center, radius, start_angle, end_angle, 32, color, 40)

func _unhandled_input(event):
	if not action.is_empty():
		if event.is_action_pressed(action):
			begin()
		elif event.is_action_released(action):
			selected_item = confirm()
		
var item_prev: int
func _process(_delta):
	if not visible: return
	var item =  get_selecting_item()
	for i in range(item_list.size()):
		if i == item:
			labels[i].modulate = Color.ORANGE_RED
		else:
			labels[i].modulate = Color.WHITE
	if item_prev != item:
		queue_redraw()
	item_prev = item

func initialize(item_list: Dictionary[String, Variant]) -> void:
	var keys = item_list.keys()
	for i in range(keys.size()):
		var item = keys[i]
		var label: Label
		if i < labels.size():
			label = labels[i]
			label.visible = true
		else:
			label = Label.new()
			labels.append(label)
			add_child(label)
		label.text = str(item)
		var pos = Vector2.RIGHT.rotated(item_to_angle(i, item_list.size())) * radius
		label.position = size / 2 + pos - label.size / 2
	for i in range(item_list.size(), labels.size()):
		labels[i].visible = false

func begin(title: String = ""):
	if visible: return
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_begin = get_global_mouse_position()
	if title.length() != 0:
		text = title
	position = mouse_begin - size/2
	initialize(item_list)
	visible = true

func confirm() -> Variant:
	if not visible: return
	var choice = get_selecting_item()
	visible = false	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if choice == -1:
		return ""
	else:
		var result = item_list[item_list.keys()[choice]]
		item_selected.emit(result)
		return result

func get_selecting_item() -> int:
	var mouse_pos = get_global_mouse_position()
	var delta = mouse_pos - mouse_begin
	if delta.length_squared() < threshold * threshold:
		return -1
	return angle_to_item(delta.angle(), item_list.size())

func angle_y_to_item(angle: float, item_count: int) -> int:
	var angle_step = TAU / item_count
	var a = angle
	if a < 0: a += TAU
	return int(round(a / angle_step)) % item_count

func angle_x_to_item(angle: float, item_count: int) -> int:
	return angle_y_to_item(angle + PI/2, item_count)

func angle_to_item(angle: float, item_count: int) -> int:
	return angle_x_to_item(angle, item_count)

func item_to_angle_y(item: int, item_count: int) -> float:
	var angle_step = TAU / item_count
	return item * angle_step

func item_to_angle_x(item: int, item_count: int) -> float:
	return item_to_angle_y(item, item_count) - PI/2

func item_to_angle(item: int, item_count: int) -> float:
	return item_to_angle_x(item, item_count)
