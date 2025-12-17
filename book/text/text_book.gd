extends BookBase
class_name TextBook

@onready var text_edit = $SubViewport/Text

func open_callback() -> void:
	var file_name = path.get_file()
	current_left_page = PageProvider.add_preset_at_once("TextAtlasPage", file_name + ".0")
	current_right_page = PageProvider.add_preset_at_once("TextAtlasPage", file_name + ".1")
	swap_left_page = PageProvider.add_preset_at_once("TextAtlasPage", file_name + ".2")
	swap_right_page = PageProvider.add_preset_at_once("TextAtlasPage", file_name + ".3")

	current_left_page.reference.initialize($SubViewport, 0)
	current_right_page.reference.initialize($SubViewport, 1)
	swap_left_page.reference.initialize($SubViewport, 2)
	swap_right_page.reference.initialize($SubViewport, 3)

	text_edit.get_v_scroll_bar().add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	text_edit.get_v_scroll_bar().add_theme_stylebox_override("scroll_focus", StyleBoxEmpty.new())
	text_edit.text = FileAccess.get_file_as_string(path)
	max_page = (text_edit.get_total_visible_line_count() + 1) / 70
	text_edit.clear_undo_history()

var _page_index: int
func navigate_end_callback() -> void:
	_page_index = current_page

func _process(_delta: float) -> void:
	const page_lines = 35
	text_edit.scroll_vertical = _page_index * page_lines * 2
