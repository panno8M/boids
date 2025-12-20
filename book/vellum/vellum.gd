extends BookBase
class_name Vellum

func initialize_callback() -> void:
	pages = [
		PagePair.new(
			PageProvider.add_preset_at_once("TerminalPage", "Vellum"),
			PageProvider.add_preset_at_once("EmptyPage")
		)
	]
