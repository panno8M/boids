extends Node3D
class_name BookUser

@export var book_title: Label

@export var right_page1: SubViewport
@export var right_page_material1: Material
@export var right_page2: SubViewport
@export var right_page_material2: Material
@export var left_page1: SubViewport
@export var left_page_material1: Material
@export var left_page2: SubViewport
@export var left_page_material2: Material

var current_right_page: SubViewport
var current_right_page_material: Material
var swap_right_page: SubViewport
var swap_right_page_material: Material
var current_left_page: SubViewport
var current_left_page_material: Material
var swap_left_page: SubViewport
var swap_left_page_material: Material

var holding: Bookfly
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

func update_page(right_page, left_page: SubViewport, index: int) -> void:
	right_page.get_node("Root/Label").text = "Right Page " + str(index)
	left_page.get_node("Root/Label").text = "Left Page " + str(index)

func flush_page(right_page, left_page: SubViewport, index: int) -> void:
	update_page(right_page, left_page, index)
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
