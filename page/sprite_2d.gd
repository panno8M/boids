extends Sprite2D

var velocity: Vector2
@export var region: Rect2
@export var speed: float = 100

func _ready() -> void:
	velocity = Vector2.UP.rotated(randf_range(0, TAU))

func _process(delta: float) -> void:
	position += velocity * speed * delta

	if position.x < region.position.x:
		velocity = Vector2(abs(velocity.x), velocity.y)
	if region.position.x + region.size.x < position.x + get_rect().size.x:
		velocity = Vector2(-abs(velocity.x), velocity.y)
	if position.y < region.position.y:
		velocity = Vector2(velocity.x, abs(velocity.y))
	if region.position.y + region.size.y < position.y + get_rect().size.y:
		velocity = Vector2(velocity.x, -abs(velocity.y))
