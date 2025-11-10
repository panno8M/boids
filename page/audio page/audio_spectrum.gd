extends Control
class_name AudioSpectrum

enum Direction { HORIZONTAL, VERTICAL }

const NUM_BARS = 128
const LOG_10 = log(10.0)

@export var direction: Direction = Direction.VERTICAL
@export var flip_x: bool
@export var flip_y: bool
@export var min_freq: float = 20.0:
	get: return _min_freq
	set(value):
		_min_freq = value
		setup_freq_table(_min_freq, _max_freq)
@export var max_freq: float = 20000.0:
	get: return _max_freq
	set(value):
		_max_freq = value
		setup_freq_table(_min_freq, _max_freq)
@onready var analyzer: AudioEffectSpectrumAnalyzerInstance = AudioServer.get_bus_effect_instance(AudioServer.get_bus_index(&"AudioPreview"), 0)
var _min_freq: float = 20.0
var _max_freq: float = 20000.0
var bar_lengths: PackedFloat32Array
var peekholds: PackedFloat32Array
var freq_table: PackedFloat32Array
var min_freq_log: float
var max_freq_log: float
var max_length: int

func _ready() -> void:
	bar_lengths.resize(NUM_BARS)
	peekholds.resize(NUM_BARS)
	setup_freq_table(_min_freq, _max_freq)

func _process(delta):
	calc_bar_lengths(delta)
	queue_redraw()

func _draw():
	var bar_step = (size.x if direction == Direction.HORIZONTAL else size.y) / NUM_BARS
	for i in range(NUM_BARS):
		var value = clamp(pow(bar_lengths[i], 0.5), 0, 1)
		var color = Color.from_hsv(float(i) / NUM_BARS, 0.8, value)
		var thickness = bar_step - 2
		var margin = 2
		var circle_pos = Vector2(max(5, peekholds[i] * max_length), i * bar_step + thickness/2)
		if direction == Direction.HORIZONTAL:
			circle_pos = Vector2(circle_pos.y, circle_pos.x)
		draw_circle(circle_pos, thickness/2, color, true)
		draw_rect(get_bar_rect(i, thickness, margin, max(5, bar_lengths[i] * max_length)), color)

func setup_freq_table(min_freq, max_freq) -> void:
	freq_table.resize(NUM_BARS + 1)
	min_freq_log = log(min_freq) / LOG_10
	max_freq_log = log(max_freq) / LOG_10
	for i in range(freq_table.size()):
		freq_table[i] = pow(10, lerp(min_freq_log, max_freq_log, float(i) / NUM_BARS))

func calc_bar_lengths(delta: float) -> void:
	if analyzer == null:
		return

	max_length = int(size.y if direction == Direction.HORIZONTAL else size.x)
	for i in range(NUM_BARS):
		var mag = analyzer.get_magnitude_for_frequency_range(freq_table[i], freq_table[i+1])
		var amp = (mag.x + mag.y) * 0.5
		var db = linear_to_db(amp)
		const DB_MIN = -80.0
		const DB_MAX = 0.0
		var l = clamp((db - DB_MIN) / (DB_MAX - DB_MIN), 0.0, 1.0)
		var fall_speed = 2.5
		peekholds[i] = max(l, lerp(peekholds[i], l, delta * fall_speed))
		bar_lengths[i] = l

func get_bar_rect(i: int, thickness: float, margin: float, length: float) -> Rect2:
	var step = thickness + margin
	var ri = NUM_BARS - i - 1
	var inv_len = max_length - length

	match direction:
		Direction.HORIZONTAL:
			if flip_x:
				if flip_y:
					return Rect2(Vector2(ri * step, inv_len), Vector2(thickness, length))
				else:
					return Rect2(Vector2(ri * step, 0), Vector2(thickness, length))
			else:
				if flip_y:
					return Rect2(Vector2(i * step, inv_len), Vector2(thickness, length))
				else:
					return Rect2(Vector2(i * step, 0), Vector2(thickness, length))
		Direction.VERTICAL:
			if flip_x:
				if flip_y:
					return Rect2(Vector2(inv_len, ri * step), Vector2(length, thickness))
				else:
					return Rect2(Vector2(inv_len, i * step), Vector2(length, thickness))
			else:
				if flip_y:
					return Rect2(Vector2(0, ri * step), Vector2(length, thickness))
				else:
					return Rect2(Vector2(0, i * step), Vector2(length, thickness))
		_:
			return Rect2()
