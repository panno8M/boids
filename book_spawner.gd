extends BookSpawner
class_name BookSpawner2

static var singleton: BookSpawner2

func _ready() -> void:
	singleton = self
