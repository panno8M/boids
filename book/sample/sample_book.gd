extends BookBase
class_name SampleBook

func initialize_callback() -> void:
	current_left_page = PageProvider.add_preset_at_once("SamplePage", "SamplePage.0")
	current_right_page = PageProvider.add_preset_at_once("SamplePage", "SamplePage.1")
	swap_left_page = PageProvider.add_preset_at_once("SamplePage", "SamplePage.2")
	swap_right_page = PageProvider.add_preset_at_once("SamplePage", "SamplePage.3")
