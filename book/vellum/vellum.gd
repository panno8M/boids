extends BookBase
class_name Vellum

func open_callback() -> void:
	current_left_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.0")
	current_right_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.1")
	swap_left_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.2")
	swap_right_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.3")
