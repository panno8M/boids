extends Node

var page_presets: Dictionary[StringName, PackedScene] = {
	&"SamplePage": preload("res://page/sample/sample_page.tscn"),
	&"EmptyPage": preload("res://page/empty/empty_page.tscn"),
	&"TextPage": preload("res://page/text/text_page.tscn"),
	&"TextAtlasPage": preload("res://page/text_atlas/text_atlas_page.tscn"),
	&"ImagePage": preload("res://page/image/image_page.tscn"),
	&"AudioPage": preload("res://page/audio/audio_page.tscn"),
	&"AudioSpectrumPage": preload("res://page/audio/audio_spectrum_page.tscn"),
	&"TerminalPage": preload("res://page/terminal/terminal_page.tscn"),
	&"3DModelPage": preload("res://page/3d-model/3d_model_page.tscn"),
}

var pages: Dictionary[StringName, PageBase]

func _add_page(node: PageBase, page_name: StringName) -> PageBase:
	if page_name:
		node.name = page_name
	add_child(node)
	node.material = create_material(node)
	pages[page_name] = node
	return node
	
func add_page(node: PageBase, page_name: StringName = &"") -> PageBase:
	var new_name: StringName = node.name
	if page_name:
		new_name = page_name
	if has_page(new_name):
		remove_child(get_page(new_name))
	return _add_page(node, page_name)

func add_page_at_once(node: PageBase, page_name: StringName = &"") -> PageBase:
	var new_name: StringName = node.name
	if page_name:
		new_name = page_name
	if has_page(new_name):
		return get_page(new_name)
	else:
		return _add_page(node, page_name)

func add_preset(key: StringName, page_name: StringName = &"") -> PageBase:
	var new_name = key
	if page_name:
		new_name = page_name
	return add_page(preset(key), new_name)

func add_preset_at_once(key: StringName, page_name: StringName = &"") -> PageBase:
	var new_name = key
	if page_name:
		new_name = page_name
	if has_page(new_name):
		return get_page(new_name)
	else:
		return _add_page(preset(key), new_name)

func get_page(page_name: StringName) -> PageBase:
	return pages[page_name]

func has_page(page_name: StringName) -> bool:
	return page_name in pages
	
func preset(key: StringName) -> PageBase:
	return page_presets[key].instantiate()

func create_material(viewport: SubViewport) -> ShaderMaterial:
	var mat = preload("res://page/page_material.tres").duplicate()
	mat.set_shader_parameter("overlay_tex", viewport.get_texture())
	return mat
