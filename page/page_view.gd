extends SubViewport
class_name PageView

enum PageKind {SAMPLE, TEXT}

@export var sample_page: PackedScene
@export var text_page: PackedScene

var current: Node

var page_text: String:
	get:
		return current.get("page_text")
	set(value):
		current.set("page_text", value)

var _page_index: int
var page_index: int:
	get:
		return _page_index
	set(value):
		_page_index = value
		if current:
			current.get_node("Index").text = str(value)

func add_page(node: Node) -> Node:
	if has_page(node.name):
		remove_child(get_page(node.name))
	current = node
	add_child(current)
	return set_page(node.name)

func add_preset(kind: PageKind, page_name: StringName = &"") -> Node:
	return add_page(preset(kind, page_name))

func set_page(page_name: StringName) -> Node:
	var result: Node
	for child in get_children():
		if child.name == page_name:
			child.visible = true
			child.process_mode = Node.PROCESS_MODE_INHERIT
			result = child
		else:
			child.visible = false
			child.process_mode = Node.PROCESS_MODE_DISABLED
	return result
	
func get_page(page_name: StringName) -> Node:
	return get_node(NodePath(page_name))

func has_page(page_name: StringName) -> bool:
	return has_node(NodePath(page_name))
	
func preset(kind: PageKind, page_name: StringName = &"") -> Node:
	var result: Node
	match kind:
		PageKind.SAMPLE:
			result = sample_page.instantiate()
		PageKind.TEXT:
			result = text_page.instantiate()
		_:
			result = sample_page.instantiate()
	if page_name:
		result.name = page_name
	return result
