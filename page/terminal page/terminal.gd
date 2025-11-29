extends Terminal

func _custom_process(pwd: String, cmd: String, _args: PackedStringArray) -> bool:
	match cmd:
		"spawn":
			BookSpawner2.singleton.spawn("test/Book_Albedo.png")
			return true
		_:
			return false
