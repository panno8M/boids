extends PageBase

@export var description: Label
var packed_scene: PackedScene
var array_mesh: ArrayMesh
var scene: Node

func set_contents_from_3d_model_path(path: String) -> void:
	var resource = ResourceLoader.load(path)
	if resource is PackedScene:
		packed_scene = resource
		scene = packed_scene.instantiate()
		add_child(scene)
		description.text = path
	elif resource is ArrayMesh:
		array_mesh = resource
		scene = MeshInstance3D.new()
		scene.mesh = array_mesh
		add_child(scene)
		description.text = path
