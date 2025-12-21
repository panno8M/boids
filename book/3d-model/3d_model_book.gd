extends BookBase

func initialize_callback() -> void:
	var file_name = path.get_file()
	pages = [
		PagePair.new(
			PageProvider.add_preset_at_once("3DModelPage", file_name),
			PageProvider.add_preset_at_once("EmptyPage")
		)
	]
	pages[0].left.set_contents_from_3d_model_path(path)
