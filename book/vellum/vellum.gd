extends BookBase
class_name Vellum

func initialize_callback() -> void:
	current_left_page = PageProvider.add_preset_at_once("TerminalPage", "Vellum")
	current_right_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.0")
	swap_left_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.1")
	swap_right_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.2")
