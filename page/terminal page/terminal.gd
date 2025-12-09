extends Terminal

func _custom_process(pwd: String, cmd: String, args: PackedStringArray) -> bool:
	match cmd:
		"spawn":
			for arg in args:
				if BookSpawner2.singleton.spawn(pwd + "/" + arg).size() == 0:
					error("spawn => error: \"", arg, "\" is not exists in ", pwd, ".")
			return true
		_:
			return false
