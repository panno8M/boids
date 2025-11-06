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
	match kind:
		BookKind.SAMPLE:
			left_page.init(PageView.PageKind.SAMPLE)
			right_page.init(PageView.PageKind.SAMPLE)

		BookKind.TEXT:
			left_page.init(PageView.PageKind.TEXT)
			right_page.init(PageView.PageKind.TEXT)
			
			left_page.page_text = FileAccess.get_file_as_string(holding.path)

	right_page.page_index = index * 2 + 2
	left_page.page_index = index * 2 + 1

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
		holding.open(current_right_page_material, current_left_page_material)
		page_index = 0
		flush_page(current_right_page, current_left_page, page_index)
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

func detect_book_kind(path: String) -> BookKind:
	if is_text_file(path):
		return BookKind.TEXT
	else:
		return BookKind.SAMPLE

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
