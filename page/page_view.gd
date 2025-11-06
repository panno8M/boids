extends SubViewport
class_name PageView

enum PageKind {SAMPLE, TEXT}

@export var sample_page: PackedScene
@export var text_page: PackedScene
@export var page_kind: PageKind

var page: Node

var page_text: String:
	get:
		if page and page_kind == PageKind.TEXT:
			return page.get_node("Text").text
		else:
			return ""
	set(value):
		if page and page_kind == PageKind.TEXT:
			page.get_node("Text").text = value
		else:
			pass

var _page_index: int
var page_index: int:
	get:
		return _page_index
	set(value):
		_page_index = value
		if page:
			page.get_node("Index").text = str(value)

func _ready() -> void:
	init(page_kind)

func init(kind: PageKind) -> void:
	if page:
		remove_child(page)
	page_kind = kind
	match kind:
		PageKind.SAMPLE:
			page = sample_page.instantiate()
		PageKind.TEXT:
			page = text_page.instantiate()
	page.name = "Root"
	add_child(page)
