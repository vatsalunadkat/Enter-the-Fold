extends CharacterBody2D

signal arrived
signal left_store

enum State { IDLE, WALKING, DONE }
var current_state = State.DONE

var speed = 100.0
var _walk_targets: Array = []
var _walk_index: int = 0
var _leave_after_walk: bool = false

func walk_to(target_pos: Vector2) -> void:
	_walk_targets = [target_pos]
	_walk_index = 0
	_leave_after_walk = false
	show()
	current_state = State.WALKING
	$AnimatedSprite2D.flip_h = (target_pos.x < global_position.x)
	$AnimatedSprite2D.play("walk_in")

func walk_path(path: Path2D) -> void:
	_walk_targets = Array(path.curve.get_baked_points())
	_walk_index = 0
	_leave_after_walk = false
	show()
	current_state = State.WALKING
	$AnimatedSprite2D.flip_h = false
	$AnimatedSprite2D.play("walk_in")

func start_idle() -> void:
	current_state = State.IDLE
	$AnimatedSprite2D.play("idle")

func leave_to(target_pos: Vector2) -> void:
	_walk_targets = [target_pos]
	_walk_index = 0
	_leave_after_walk = true
	current_state = State.WALKING
	$AnimatedSprite2D.flip_h = (target_pos.x < global_position.x)
	$AnimatedSprite2D.play("walk_out")

func _process(delta):
	if current_state != State.WALKING:
		return

	if _walk_index < _walk_targets.size():
		var target = _walk_targets[_walk_index]
		position = position.move_toward(target, speed * delta)
		if position.distance_to(target) < 2.0:
			_walk_index += 1
	else:
		if _leave_after_walk:
			current_state = State.DONE
			hide()
			left_store.emit()
		else:
			start_idle()
			arrived.emit()
