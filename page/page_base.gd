extends SubViewport
class_name PageBase

var material: Material

var _page_index: int
var page_index: int:
	get:
		return _page_index
	set(value):
		_page_index = value
		get_node("Index").text = str(value + 1)
