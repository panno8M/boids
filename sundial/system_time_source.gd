@tool
extends TimeSource
class_name SystemTimeSource
@export var multiplier: float = 1

func get_time() -> float:
	var t := Time.get_datetime_dict_from_system()
	return (t.hour + t.minute / 60.0 + t.second / 3600.0) / 24.0
