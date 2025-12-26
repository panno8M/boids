@tool
extends TimeSource
class_name CyclingTimeSource

## 1秒あたりに進む time の量（1.0 = 1秒で1日）
@export var speed: float = 0.1

@export var pausing: bool

@export_range(0.0, 1.0) var time: float
@export_range(0, 23) var hour: int:
	get(): return int(floor(time * 24.0))
	set(value): time = (float(value) / 24.0)

var _last_ticks_msec: int = 0

func get_time() -> float:
	var now := Time.get_ticks_msec()

	if pausing or _last_ticks_msec == 0:
		_last_ticks_msec = now
		return time

	var delta_sec := float(now - _last_ticks_msec) / 1000.0
	_last_ticks_msec = now

	time = fmod(time + delta_sec * speed, 1.0)
	return time
