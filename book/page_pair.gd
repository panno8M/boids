extends Resource
class_name PagePair

var left: PageBase
var right: PageBase

func _init(left_page, right_page: PageBase) -> void:
	left = left_page
	right = right_page
