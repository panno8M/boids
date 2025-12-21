extends PageBase

@onready var audio: AudioStreamPlayer = $Audio
@onready var directory: Label = $MarginContainer/VBoxContainer/Directory
@onready var file: Label = $MarginContainer/VBoxContainer/File

func set_contents_from_path(path: String) -> void:
	directory.text = path.get_base_dir() + "/"
	file.text = path.get_file()
	match path.get_extension():
		"ogg":
			audio.stream = AudioStreamOggVorbis.load_from_file(path)
		"wav":
			audio.stream = AudioStreamWAV.load_from_file(path)
		"mp3":
			audio.stream = AudioStreamMP3.load_from_file(path)
		_:
			return
	audio.bus = &"AudioPreview"

func _ready() -> void:
	$Audio.finished.connect(func(): $Audio.play())
