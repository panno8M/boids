extends Node

enum MouseMode {
	VISIBLE,
	HIDDEN,
	CAPTURED,
	CONFINED,
	CONFINED_HIDDEN,
	INHERIT,
	}

func _resolve_mouse_mode(mode: MouseMode) -> Input.MouseMode:
	match mode:
		MouseMode.INHERIT:
			return Input.mouse_mode
		_:
			return mode as Input.MouseMode

func _resolve_mouse_mode_override(mode: MouseMode) -> Input.MouseMode:
	match mode:
		MouseMode.INHERIT:
			return _resolve_mouse_mode(_mouse_mode)
		_:
			return mode as Input.MouseMode


var _mouse_mode: MouseMode
var mouse_mode: MouseMode:
	get: return _mouse_mode
	set(value):
		Input.mouse_mode = _resolve_mouse_mode(value)
		_mouse_mode = value

var _mouse_mode_override: MouseMode = MouseMode.INHERIT
var mouse_mode_override: MouseMode:
	get: return _mouse_mode_override
	set(value):
		Input.mouse_mode = _resolve_mouse_mode_override(value)
		_mouse_mode_override = value

func _ready():
	mouse_mode = MouseMode.CAPTURED
