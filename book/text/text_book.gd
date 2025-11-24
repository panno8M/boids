extends BookBase
class_name TextBook

func open_callback() -> void:
	var file_name = path.get_file()
	current_left_page = PageProvider.add_preset_at_once("TextPage", file_name + ".0")
	current_right_page = PageProvider.add_preset_at_once("TextPage", file_name + ".1")
	swap_left_page = PageProvider.add_preset_at_once("TextPage", file_name + ".2")
	swap_right_page = PageProvider.add_preset_at_once("TextPage", file_name + ".3")
	var text = FileAccess.get_file_as_string(path)
	current_left_page.set_contents_from_string(text)
	current_right_page.set_contents_from_string(text)
	swap_left_page.set_contents_from_string(text)
	swap_right_page.set_contents_from_string(text)

func navigate_callback(_new_index: int) -> void:
	current_left_page.scroll_page()
	current_right_page.scroll_page()
