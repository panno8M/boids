extends BookBase
class_name ImageBook

func initialize_callback() -> void:
	var file_name = path.get_file()
	current_left_page = PageProvider.add_preset_at_once("ImagePage", file_name)
	current_left_page.set_contents_from_image_path(path)
	current_right_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.0")
	swap_left_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.1")
	swap_right_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.2")
