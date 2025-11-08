extends Node
class_name PageProvider

@export var page_presets: Dictionary[StringName, PackedScene]

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
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://page/page.gdshader")
	mat.set_shader_parameter("paper_tex", preload("res://page/Paper-Texture-3-1024x768.jpg"))
	mat.set_shader_parameter("overlay_tex", viewport.get_texture())
	mat.set_shader_parameter("paper_roughness", 1)
	return mat
