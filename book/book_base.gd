extends Bookfly
class_name BookBase

var loaded: bool
var current_page_index: int
var pages: Array[PagePair]

func initialize_callback() -> void:
	pass
func open_callback() -> void:
	pass
func close_callback() -> void:
	pass
func page_left_callback() -> void:
	pass
func page_right_callback() -> void:
	pass
func page_left_end_callback() -> void:
	pass
func page_right_end_callback() -> void:
	pass

func prev_page() -> PagePair:
	if not pages or current_page_index == 0:
		return null
	else:
		return pages[current_page_index-1]

func next_page() -> PagePair:
	if not pages or current_page_index == pages.size()-1:
		return null
	else:
		return pages[current_page_index+1]

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)

func curr_page() -> PagePair:
	return pages[current_page_index]

func open() -> void:
	if not loaded:
		initialize_callback()
		loaded = true
	open_callback()
	var current = curr_page()
	play_open(current.right.material, current.left.material)
	call_deferred("navigate", current, current_page_index)

func close() -> void:
	if loaded:
		close_callback()
		play_close()

func release() -> void:
	if loaded:
		close_callback()
	play_release()

func navigate(dst: PagePair, new_index: int) -> void:
	if loaded:
		dst.left.page_index = new_index * 2
		dst.right.page_index = new_index * 2 + 1
		current_page_index = new_index

func page_right() -> void:
	if not animation_player.is_playing():
		# swap_pages()
		var next: PagePair = next_page()
		if next:
			page_right_callback()
			navigate(next, current_page_index + 1)
			play_page_right(next.right.material, next.left.material)

func page_left() -> void:
	if not animation_player.is_playing():
		# swap_pages()
		var prev: PagePair = prev_page()
		if prev:
			page_left_callback()
			navigate(prev, current_page_index - 1)
			play_page_left(prev.right.material, prev.left.material)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		page_right_name:
			call_deferred("page_right_end_callback")
		page_left_name:
			call_deferred("page_left_end_callback")
