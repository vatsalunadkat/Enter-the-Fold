extends CharacterBody2D

signal arrived

var speed := 120.0
var _target: Vector2
var _walking: bool = false

@onready var sprite := $AnimatedSprite2D

func _ready() -> void:
	sprite.stop()
	sprite.frame = 0

func walk_to(target_pos: Vector2) -> void:
	_target = target_pos
	_walking = true
	sprite.flip_h = (target_pos.x < global_position.x)
	sprite.play("default")

func stop_walking() -> void:
	_walking = false
	sprite.stop()
	sprite.frame = 0

func _process(delta: float) -> void:
	if not _walking:
		return
	position = position.move_toward(_target, speed * delta)
	if position.distance_to(_target) < 2.0:
		_walking = false
		sprite.stop()
		sprite.frame = 0
		arrived.emit()
