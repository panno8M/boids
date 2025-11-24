extends Label

@export var player: Player

func _ready() -> void:
	if player:
		player.state_changed.connect(_on_player_state_changed)

func _on_player_state_changed(_old_state: Player.State, new_state: Player.State) -> void:
	match new_state:
		Player.State.HOLD:
			text = player.holding.path.get_file()
			visible = true
		_:
			visible = false
