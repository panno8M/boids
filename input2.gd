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

func is_action_pressed(action: StringName, exact_match: bool = false) -> bool:
	return Input.is_action_pressed(action, exact_match)
func is_action_just_pressed(action: StringName, exact_match: bool = false) -> bool:
	return Input.is_action_just_pressed(action, exact_match)

var frame_cache := {}
var last_action_time := {}
var double_click_threshold := 0.3

func is_action_double_pressed(action: StringName, exact_match: bool = false) -> bool:
	var frame := get_tree().get_frame()
	var cache: Dictionary = frame_cache.get(action, {})
	if cache.has("frame") and cache.frame == frame:
		return cache.result

	var result := false
	if is_action_just_pressed(action, exact_match):
		var now := Time.get_ticks_msec() * 0.001
		if last_action_time.has(action) and now - last_action_time[action] <= double_click_threshold:
			result = true
			last_action_time.erase(action)
		else:
			last_action_time[action] = now
	frame_cache[action] = {frame: frame, result: result}
	return result

func _ready():
	mouse_mode = MouseMode.CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventAction and event.pressed():
		print(event)
		var action := (event as InputEventAction).action
		var now := Time.get_ticks_msec()
		last_action_time[action] = now
