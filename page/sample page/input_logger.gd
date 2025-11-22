extends TextEdit

func _input(event: InputEvent) -> void:
	text = text + "\n" + str(event)
	scroll_vertical = 10000
