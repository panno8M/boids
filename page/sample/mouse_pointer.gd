extends Control
class_name MousePointer

@export_group("debug", "debug")
@export var debug_enabled: bool = true
@export var debug_color: Color = Color.RED
@export var debug_radius: float = 5

var prev_color: Color
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
	prev_color = Color(debug_color.r, debug_color.g, debug_color.b, 0.5)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		position = event.position
		prev_position = position - event.relative
		if debug_enabled:
			queue_redraw()

func _draw() -> void:
	if point:
		draw_circle(prev_position - position, debug_radius, prev_color)
		draw_circle(Vector2.ZERO, debug_radius, debug_color)
