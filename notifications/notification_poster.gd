extends Node3D
class_name NotificationPoster

var poster_mat_template = preload("res://page/page_material.tres")

const POSTER_DEFAULT_SCALE = 1.0/512.0

func _ready() -> void:
	var mat = poster_mat_template.duplicate()
	mat.set_shader_parameter("overlay_tex", %SubViewport.get_texture())
	%Quad.material_override = mat
	%SubViewport.size_changed.connect(_on_sub_viewport_size_changed)
	_on_sub_viewport_size_changed()

var i: int
func _process(delta: float) -> void:
	%SubViewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
	%SubViewport.get_node("Label").text = str(i)
	i += 1

func _on_sub_viewport_size_changed() -> void:
	%Quad.scale = xy1(%SubViewport.size) * POSTER_DEFAULT_SCALE

static func xy1(v2i: Vector2i) -> Vector3:
	return Vector3(v2i.x, v2i.y, 1)
