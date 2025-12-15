extends PageBase

@export var page_lines: int = 35
@onready var text_edit = $Text

func set_contents_from_string(string: String) -> void:
	text_edit.text = string + "\n".repeat(40)

func scroll_page(page: int = -1) -> void:
	var idx = page
	if idx < 0:
		idx = page_index
	text_edit.scroll_vertical = idx * page_lines
