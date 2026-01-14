extends Node3D
class_name NotificationPoster

var poster_mat_template = preload("res://page/page_material.tres")
var refresh_remain: int = 0

const POSTER_DEFAULT_SCALE = 1.0/512.0

func _ready() -> void:
	var mat = poster_mat_template.duplicate()
	mat.set_shader_parameter("overlay_tex", %SubViewport.get_texture())
	%Quad.material_override = mat
	%SubViewport.size_changed.connect(_on_sub_viewport_size_changed)
	_on_sub_viewport_size_changed()

func _adjust_size() -> void:
	if refresh_remain <= 0: return
	var h: int = 0
	for c in %VBoxContainer.get_children():
		if c is Control:
			h += c.size.y
	%SubViewport.size.y = h + 64
	%SubViewport.render_target_update_mode = SubViewport.UpdateMode.UPDATE_ONCE
	refresh_remain -= 1

func initialize(n: Notification) -> void:
	%Summary.text = n.summary
	%Body.text = n.body
	%AppName.text = n.app_name
	refresh_remain = 1

func _process(_delta: float) -> void:
	_adjust_size()

func _on_sub_viewport_size_changed() -> void:
	%Quad.scale = xy1(%SubViewport.size) * POSTER_DEFAULT_SCALE

static func xy1(v2i: Vector2i) -> Vector3:
	return Vector3(v2i.x, v2i.y, 1)
