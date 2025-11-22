extends Control
class_name MousePointer

@export var color: Color = Color.RED
@export var radius: float = 5

var prev_color: Color
var curr_position: Vector2
var prev_position: Vector2
var point: bool = true

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VP_MOUSE_ENTER:
			print("enter!")
			point = true
			queue_redraw()
		NOTIFICATION_VP_MOUSE_EXIT:
			point = false
			queue_redraw()

func _ready() -> void:
	prev_color = Color(color.r, color.g, color.b, 0.5)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		curr_position = event.position
		prev_position = curr_position - event.relative
		queue_redraw()

func _draw() -> void:
	if point:
		draw_circle(prev_position, radius, prev_color)
		draw_circle(curr_position, radius, color)
