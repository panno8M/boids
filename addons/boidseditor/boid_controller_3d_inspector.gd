extends EditorInspectorPlugin

const starttext = "▶ Start Simulation"
const stoptext = "■ Stop Simulation"
const running = true
const pausing = true

func alpha(color: Color, alpha: float) -> Color:
	var result = color
	result.a = alpha
	return result

func defaultButtonStyle(bg_color: Color) -> StyleBoxFlat:
	var result = StyleBoxFlat.new()
	result.bg_color = bg_color
	return result

func _can_handle(object: Object) -> bool:
	return object is Main

func _parse_begin(object: Object) -> void:
	var main = object as Main
	var controllers: Array[BoidController3D]
	for child in main.get_children():
		if child is BoidController3D:
			controllers.append(child as BoidController3D)

	var green := defaultButtonStyle(alpha(Color.GREEN, 0.2))
	var yellow := defaultButtonStyle(alpha(Color.YELLOW, 0.2))
	var orange := defaultButtonStyle(alpha(Color.ORANGE, 0.2))
	var red := defaultButtonStyle(alpha(Color.RED, 0.2))
	
	var pause = Button.new()
	pause.toggle_mode = true
	pause.add_theme_stylebox_override("normal", yellow)
	pause.add_theme_stylebox_override("pressed", orange)
	var activate = Button.new()
	activate.toggle_mode = true
	activate.add_theme_stylebox_override("normal", green)
	activate.add_theme_stylebox_override("pressed", red)

	for controller in controllers:
		controller.pausing = main.pausing
	pause.button_pressed = main.pausing
	pause.text = "Paused" if main.pausing else "Pause"
	pause.toggled.connect(func(next: bool):
		main.pausing = next
		if not main.activated and next:
			pause.button_pressed = false
			return
		for controller in controllers:
			controller.pausing = next
		pause.text = "Paused" if next else "Pause"
		)
	
	for controller in controllers:
		controller.editor_preview = main.activated
	activate.button_pressed = main.activated
	activate.text = stoptext if main.activated else starttext
	activate.toggled.connect(func(next: bool):
		main.activated = next
		for controller in controllers:
			controller.editor_preview = next
		pause.button_pressed = false
		activate.text = stoptext if next else starttext
		)

	add_custom_control(activate)
	add_custom_control(pause)
