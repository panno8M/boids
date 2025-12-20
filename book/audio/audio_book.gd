extends BookBase
class_name AudioBook

var audio_page: PageBase

func initialize_callback() -> void:
	var file_name = path.get_file()
	audio_page = PageProvider.add_preset_at_once("AudioPage", file_name)
	var spectrum_page = PageProvider.add_preset_at_once("AudioSpectrumPage")
	audio_page.set_contents_from_path(path)
	pages = [
		PagePair.new(audio_page, spectrum_page)
	]

func open_callback() -> void:
	audio_page.audio.play()

func close_callback() -> void:
	audio_page.audio.stop()
