extends BookBase
class_name ImageBook

func initialize_callback() -> void:
	var file_name = path.get_file()
	pages = [
		PagePair.new(
			PageProvider.add_preset_at_once("ImagePage", file_name),
			PageProvider.add_preset_at_once("EmptyPage")
		)
	]
	pages[0].left.set_contents_from_image_path(path)
