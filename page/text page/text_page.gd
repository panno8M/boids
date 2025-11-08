extends Control

var page_text: String:
	get:
		return get_node("Text").text
	set(value):
		get_node("Text").text = value + "\n".repeat(40)
