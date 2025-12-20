extends BookBase
class_name SampleBook

func initialize_callback() -> void:
	pages = [
		PagePair.new(
			PageProvider.add_preset_at_once("SamplePage", "SamplePage.0"),
			PageProvider.add_preset_at_once("SamplePage", "SamplePage.1")
		),
		PagePair.new(
			PageProvider.add_preset_at_once("SamplePage", "SamplePage.2"),
			PageProvider.add_preset_at_once("SamplePage", "SamplePage.3")
		),
		PagePair.new(
			PageProvider.add_preset_at_once("SamplePage", "SamplePage.4"),
			PageProvider.add_preset_at_once("SamplePage", "SamplePage.5")
		),
	]
