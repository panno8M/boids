extends BookBase
class_name AudioBook

var audio_page: PageBase

func initialize_callback() -> void:
	var file_name = path.get_file()
	audio_page = PageProvider.add_preset_at_once("AudioPage", file_name)
	var spectrum_page = PageProvider.add_preset_at_once("AudioSpectrumPage")
	audio_page.set_contents_from_path(path)
	current_left_page = audio_page
	current_right_page = spectrum_page
	swap_left_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.1")
	swap_right_page = spectrum_page

func close_callback() -> void:
	(audio_page.audio as AudioStreamPlayer).stop()
