@tool
extends Resource
class_name TimeSource

func get_time() -> float:
	push_error("TimeSource.get_time() must be overridden")
	return 0.5
