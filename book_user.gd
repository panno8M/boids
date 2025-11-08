extends Node3D
class_name BookUser

enum BookKind {SAMPLE, TEXT}

@export var book_title: Label

@export var right_page1: PageView
@export var right_page_material1: Material
@export var right_page2: PageView
@export var right_page_material2: Material
@export var left_page1: PageView
@export var left_page_material1: Material
@export var left_page2: PageView
@export var left_page_material2: Material

var current_right_page: PageView
var current_right_page_material: Material
var swap_right_page: PageView
var swap_right_page_material: Material
var current_left_page: PageView
var current_left_page_material: Material
var swap_left_page: PageView
var swap_left_page_material: Material

var holding: Bookfly
var book_kind: BookKind
var page_index: int

func _ready() -> void:
	init_pages()

func swap_pages() -> void:
	var tmp
	tmp = current_right_page
	current_right_page = swap_right_page
	swap_right_page = tmp
	tmp = current_left_page
	current_left_page = swap_left_page
	swap_left_page = tmp

	tmp = current_right_page_material
	current_right_page_material = swap_right_page_material
	swap_right_page_material = tmp
	tmp = current_left_page_material
	current_left_page_material = swap_left_page_material
	swap_left_page_material = tmp

func init_pages() -> void:
	current_right_page = right_page1
	current_right_page_material = right_page_material1
	swap_right_page = right_page2
	swap_right_page_material = right_page_material2
	current_left_page = left_page1
	current_left_page_material = left_page_material1
	swap_left_page = left_page2
	swap_left_page_material = left_page_material2

func update_page(right_page, left_page: PageView, kind: BookKind, index: int) -> void:
	left_page.page_index = index * 2 + 1
	right_page.page_index = index * 2 + 2
	
	match kind:
		BookKind.TEXT:
			left_page.current.get_node("Text").scroll_vertical = (left_page.page_index - 1) * 34
			right_page.current.get_node("Text").scroll_vertical = (right_page.page_index - 1) * 34

func flush_page(right_page, left_page: PageView, index: int) -> void:
	update_page(right_page, left_page, book_kind, index)
	swap_pages()

func page_left() -> void:
	if holding.page_left(current_right_page_material, current_left_page_material):
		page_index -= 1
		flush_page(current_right_page, current_left_page, page_index)

func page_right() -> void:
	if holding.page_right(current_right_page_material, current_left_page_material):
		page_index += 1
		flush_page(current_right_page, current_left_page, page_index)

func hold(book: Bookfly) -> bool:
	if book and not holding:
		holding = book
		holding.transfer(self)
		book_title.text = holding.path.get_file().get_basename()
		book_title.visible = true
		book_kind = detect_book_kind(holding.path)
		return true
	else:
		return false

func release(controller: BoidController3D) -> bool:
	if holding:
		holding.release(controller)
		book_title.visible = false
		holding = null
		return true
	else:
		return false

func open() -> bool:
	if holding:
		page_index = 0
		match book_kind:
			BookKind.TEXT:
				open_text_file(holding.path)
			BookKind.SAMPLE:
				open_sample_file(holding.path)
				
		holding.open(current_right_page_material, current_left_page_material)
		call_deferred("flush_page", current_right_page, current_left_page, page_index)
		book_title.visible = false
		return true
	else:
		return false

func close() -> bool:
	if holding:
		holding.close()
		book_title.visible = true
		return true
	else:
		return false

func detect_book_kind(_path: String) -> BookKind:
	#if is_text_file(path):
	#	return BookKind.TEXT
	#else:
	#	return BookKind.SAMPLE
	return BookKind.TEXT

func is_text_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false

	var bytes = FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return false

	var sample_size = min(4096, bytes.size())
	var sample = bytes.slice(0, sample_size)

	var non_text_count = 0
	for b in sample:
		if b == 0:
			return false
		if b < 0x09 or (b > 0x0D and b < 0x20):
			non_text_count += 1

	return float(non_text_count) / float(sample_size) < 0.01

func renamed(node: Node, new_name: StringName) -> Node:
	node.name = new_name
	return node

func open_text_file(file_path: String) -> void:
	var file_name = file_path.get_file().replace(".", "_")
	if left_page1.has_page(file_name):
		left_page1.set_page(file_name)
		left_page2.set_page(file_name)
		right_page1.set_page(file_name)
		right_page2.set_page(file_name)
	else:
		var text = FileAccess.get_file_as_string(holding.path)
		left_page1.add_preset(PageView.PageKind.TEXT, file_name)
		left_page1.current.page_text = text
		left_page2.add_preset(PageView.PageKind.TEXT, file_name)
		left_page2.current.page_text = text
		right_page1.add_preset(PageView.PageKind.TEXT, file_name)
		right_page1.current.page_text = text
		right_page2.add_preset(PageView.PageKind.TEXT, file_name)
		right_page2.current.page_text = text

func open_sample_file(_path: String) -> void:
	if not left_page1.has_page("SamplePage"):
		left_page1.add_preset(PageView.PageKind.SAMPLE)
	if not left_page2.has_page("SamplePage"):
		left_page2.add_preset(PageView.PageKind.SAMPLE)
	if not right_page1.has_page("SamplePage"):
		right_page1.add_preset(PageView.PageKind.SAMPLE)
	if not right_page2.has_page("SamplePage"):
		right_page2.add_preset(PageView.PageKind.SAMPLE)
