extends SubViewportContainer
func _ready():
	var mat := material as ShaderMaterial

	mat.set_shader_parameter("distortion", 1.0)
	mat.set_shader_parameter("saturation", 0.0)

	var tween := create_tween()
	tween.tween_property(mat, "shader_parameter/distortion", 0.0, 2)
	tween.tween_property(mat, "shader_parameter/saturation", 1.0, 0.66)
	tween.finished.connect(func():
		material = null
	)
