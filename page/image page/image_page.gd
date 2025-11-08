extends PageBase

@onready var image: TextureRect = $MarginContainer/VBoxContainer/Image
@onready var description: Label = $MarginContainer/VBoxContainer/Description

func set_contents_from_image_path(path: String) -> void:
	var img = Image.load_from_file(path)
	image.texture = ImageTexture.create_from_image(img)
	description.text = path
