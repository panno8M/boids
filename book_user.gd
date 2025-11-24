extends Node3D
class_name BookUser

enum BookKind {SAMPLE, TEXT, IMAGE, AUDIO}
enum State {IDLE, HOLD, VIEW}

@export var book_title: Label

var current_right_page: PageBase
var swap_right_page: PageBase
var current_left_page: PageBase
var swap_left_page: PageBase

var holding: Bookfly
var state: State
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

func init_pages() -> void:
	var page = PageProvider.add_preset("EmptyPage")
	
	current_left_page = page
	current_right_page = page
	swap_left_page = page
	swap_right_page = page

func update_page(right_page, left_page: PageBase, kind: BookKind, index: int) -> void:
	left_page.page_index = index * 2
	right_page.page_index = index * 2 + 1
	
	match kind:
		BookKind.TEXT:
			left_page.scroll_page()
			right_page.scroll_page()

func page_left() -> void:
	swap_pages()
	if holding.page_left(current_right_page.material, current_left_page.material):
		page_index -= 1
		update_page(current_right_page, current_left_page, book_kind, page_index)

func page_right() -> void:
	swap_pages()
	if holding.page_right(current_right_page.material, current_left_page.material):
		page_index += 1
		update_page(current_right_page, current_left_page, book_kind, page_index)

func hold(book: Bookfly) -> bool:
	if book and not holding:
		holding = book
		holding.transfer(self)
		book_title.text = holding.path.get_file().get_basename()
		book_title.visible = true
		state = State.HOLD
		return true
	else:
		return false

func release(controller: BoidController3D) -> bool:
	if holding:
		match book_kind:
			BookKind.AUDIO:
				close_audio_file()
		holding.release(controller)
		book_title.visible = false
		holding = null
		state = State.IDLE
		CursorManager.mouse_mode = CursorManager.MouseMode.CAPTURED
		return true
	else:
		return false

func open() -> bool:
	if holding:
		book_kind = detect_book_kind(holding.path)
		page_index = 0
		match book_kind:
			BookKind.TEXT:
				open_text_file(holding.path)
			BookKind.SAMPLE:
				open_sample_file(holding.path)
			BookKind.IMAGE:
				open_image_file(holding.path)
			BookKind.AUDIO:
				open_audio_file(holding.path)
				
		holding.open(current_right_page.material, current_left_page.material)
		call_deferred("update_page", current_right_page, current_left_page, book_kind, page_index)
		book_title.visible = false
		state = State.VIEW
		CursorManager.mouse_mode = CursorManager.MouseMode.VISIBLE
		return true
	else:
		return false

func close() -> bool:
	if holding:
		match book_kind:
			BookKind.AUDIO:
				close_audio_file()
		holding.close()
		book_title.visible = true
		state = State.HOLD
		CursorManager.mouse_mode = CursorManager.MouseMode.CAPTURED
		return true
	else:
		return false

const image_exts = ["png", "jpg", "jpeg", "svg", "svgz", "bmp", "tga", "webp", "exr", "hdr", "qoi", "dds", "ktx", "ktx2", "pvr"]
const valid_audio_exts = ["mp3", "wav", "ogg"]

func detect_book_kind(path: String) -> BookKind:
	var ext = path.get_extension()
	if ext in image_exts:
		return BookKind.IMAGE
	elif ext in valid_audio_exts:
		return BookKind.AUDIO
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

func open_text_file(file_path: String) -> void:
	var file_name = file_path.get_file()
	var req_init = not PageProvider.has_page(file_name + ".0")
	current_left_page = PageProvider.add_preset_at_once("TextPage", file_name + ".0")
	current_right_page = PageProvider.add_preset_at_once("TextPage", file_name + ".1")
	swap_left_page = PageProvider.add_preset_at_once("TextPage", file_name + ".2")
	swap_right_page = PageProvider.add_preset_at_once("TextPage", file_name + ".3")
	if req_init:
		var text = FileAccess.get_file_as_string(holding.path)
		current_left_page.set_contents_from_string(text)
		current_right_page.set_contents_from_string(text)
		swap_left_page.set_contents_from_string(text)
		swap_right_page.set_contents_from_string(text)

func open_image_file(file_path: String) -> void:
	var file_name = file_path.get_file()
	current_left_page = PageProvider.add_preset_at_once("ImagePage", file_name)
	current_left_page.set_contents_from_image_path(file_path)
	current_right_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.0")
	swap_left_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.1")
	swap_right_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.2")

var audio_page: PageBase
func open_audio_file(file_path: String) -> void:
	var file_name = file_path.get_file()
	audio_page = PageProvider.add_preset_at_once("AudioPage", file_name)
	var spectrum_page = PageProvider.add_preset_at_once("AudioSpectrumPage")
	audio_page.set_contents_from_path(file_path)
	current_left_page = audio_page
	current_right_page = spectrum_page
	swap_left_page = PageProvider.add_preset_at_once("EmptyPage", "EmptyPage.1")
	swap_right_page = spectrum_page
func close_audio_file() -> void:
	if audio_page:
		(audio_page.audio as AudioStreamPlayer).stop()
		audio_page = null

func open_sample_file(_path: String) -> void:
	current_left_page = PageProvider.add_preset_at_once("SamplePage", "SamplePage.0")
	current_right_page = PageProvider.add_preset_at_once("SamplePage", "SamplePage.1")
	swap_left_page = PageProvider.add_preset_at_once("SamplePage", "SamplePage.2")
	swap_right_page = PageProvider.add_preset_at_once("SamplePage", "SamplePage.3")
