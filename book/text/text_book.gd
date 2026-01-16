extends BookBase
class_name TextBook

@onready var text_edit = $SubViewport/Text

var curr: PagePair
const page_lines = 35

func  swap_reference():
	var tmp: SubViewportReferenceData
	tmp = pages[0].left.reference.data
	pages[0].left.reference.change_data(pages[1].left.reference.data)
	pages[1].left.reference.change_data(tmp)
	tmp = pages[0].right.reference.data
	pages[0].right.reference.change_data(pages[1].right.reference.data)
	pages[1].right.reference.change_data(tmp)

func max_page() -> int:
	return (text_edit.get_total_visible_line_count() + 1) / (page_lines * 2)

func prev_page() -> PagePair:
	if current_page_index == 0:
		return null
	else:
		curr = pages[(current_page_index + 1) % 2]
		return curr

func next_page() -> PagePair:
	if current_page_index == max_page():
		return null
	else:
		curr = pages[(current_page_index + 1) % 2]
		return curr

func curr_page() -> PagePair:
	return curr

func initialize_callback() -> void:
	var file_name = path.get_file()
	pages = [
		PagePair.new(
			PageProvider.add_preset_at_once("TextAtlasPage", file_name + ".0"),
			PageProvider.add_preset_at_once("TextAtlasPage", file_name + ".1")
		),
		PagePair.new(
			PageProvider.add_preset_at_once("TextAtlasPage", file_name + ".2"),
			PageProvider.add_preset_at_once("TextAtlasPage", file_name + ".3")
		),
	]
	var sub = $SubViewport
	var page_size = Vector2i(sub.size.x, sub.size.y / 4)
	pages[0].left.reference.initialize(sub, page_size, Vector2i(0, 0))
	pages[0].right.reference.initialize(sub, page_size, Vector2i(0, 1))
	pages[1].left.reference.initialize(sub, page_size, Vector2i(0, 2))
	pages[1].right.reference.initialize(sub, page_size, Vector2i(0, 3))
	curr = pages[0]

	text_edit.get_v_scroll_bar().add_theme_stylebox_override("scroll", StyleBoxEmpty.new())
	text_edit.get_v_scroll_bar().add_theme_stylebox_override("scroll_focus", StyleBoxEmpty.new())
	text_edit.text = FileAccess.get_file_as_string(path)
	text_edit.clear_undo_history()

var scroll_vertical: float

func page_left_callback() -> void:
	scroll_vertical = (current_page_index-1) * page_lines * 2
	text_edit.scroll_vertical = scroll_vertical
	swap_reference()

func page_right_end_callback() -> void:
	scroll_vertical = current_page_index * page_lines * 2
	text_edit.scroll_vertical = scroll_vertical
	swap_reference()


func _process(_delta: float) -> void:
	text_edit.scroll_vertical = scroll_vertical
