extends Bookfly
class_name BookBase

var loaded: bool
var current_page: int
@export var max_page: int = -1
var current_right_page: PageBase
var swap_right_page: PageBase
var current_left_page: PageBase
var swap_left_page: PageBase

func open_callback() -> void:
	pass
func close_callback() -> void:
	pass
func navigate_callback(_new_index: int) -> void:
	pass

func open() -> void:
	if not loaded:
		open_callback()
		loaded = true
	play_open(current_right_page.material, current_left_page.material)
	call_deferred("navigate", current_page)

func close() -> void:
	if loaded:
		close_callback()
		play_close()

func release() -> void:
	if loaded:
		close_callback()
	play_release()

func navigate(new_index: int) -> void:
	if loaded:
		current_left_page.page_index = new_index * 2
		current_right_page.page_index = new_index * 2 + 1
		navigate_callback(new_index)

func page_right() -> void:
	if max_page != -1 and max_page <= current_page:
		return
	if play_page_right(swap_right_page.material, swap_left_page.material):
		swap_pages()
		current_page += 1
		navigate(current_page)
		
func page_left() -> void:
	if current_page <= 0:
		return
	if play_page_left(swap_right_page.material, swap_left_page.material):
		swap_pages()
		current_page -= 1
		navigate(current_page)

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
