@tool
extends Marker3D
class_name SunLight

@onready var pivot: Node3D = $Pivot
@onready var sun_light: DirectionalLight3D = $Pivot/DirectionalLight3D

@export var time_source: TimeSource
@export var axial_tilt_deg: float = 23.4
@export var azimuth_offset_deg: float = 0.0
@export var show_timeinfo: bool = true:
	get():
		return %TimeInfo.visible
	set(value):
		%TimeInfo.visible = value

@export_group("Environment")
@export var world_environment: WorldEnvironment

@export_subgroup("Sky", "sky")
@export var sky_energy_curve: Curve

@export_subgroup("Ambient", "ambient")
@export var ambient_gradient: Gradient
@export var ambient_energy_curve: Curve
@export var ambient_max_energy: float = 1.0

@export_group("Sun", "sun")
@export var sun_gradient: Gradient
@export var sun_energy_curve: Curve
@export var sun_max_energy: float = 1.0

func _ready():
	# デフォルト注入（未設定時）
	if time_source == null:
		time_source = SystemTimeSource.new()
	update_sun()

func _process(_delta):
	update_sun()
	
func get_day_factor(time: float) -> float:
	# 0.5 を中心にした山型
	var x: float = abs(time - 0.5) * 2.0   # 0.0（正午）〜1.0（深夜）
	return clamp(1.0 - x, 0.0, 1.0)
	
func update_sun():
	var time := time_source.get_time()
	%TimeInfo.text = "Time: " + str(time)

	# 正午 = 0°
	var hour_angle_deg := (time - 0.5) * 360.0
	rotation.z = deg_to_rad(axial_tilt_deg)
	rotation.y = deg_to_rad(azimuth_offset_deg)
	pivot.rotation.x = -deg_to_rad(hour_angle_deg)

	# 昼夜係数
	var day_factor := get_day_factor(time)

	update_sun_light(day_factor)
	update_environment(day_factor)

func update_sun_light(day_factor: float):
	if sun_gradient:
		var c := sun_gradient.sample(day_factor)
		sun_light.light_color = c

	if sun_energy_curve:
		var energy_factor := sun_energy_curve.sample(day_factor)
		var energy := energy_factor * sun_max_energy
		sun_light.light_energy = energy
		sun_light.visible = energy > 0.0

func update_environment(day_factor: float):
	if not world_environment:
		return
	var env := world_environment.environment
	if not env:
		return

	# Ambient Light
	if ambient_energy_curve:
		env.ambient_light_energy = ambient_energy_curve.sample(day_factor) * ambient_max_energy
	if ambient_gradient:
		env.ambient_light_color = ambient_gradient.sample(day_factor)

	if env.sky is Sky and env.sky.sky_material is ProceduralSkyMaterial:
		if sky_energy_curve:
			env.sky.sky_material.sky_energy_multiplier = sky_energy_curve.sample(day_factor)
