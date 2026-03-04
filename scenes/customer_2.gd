extends CharacterBody2D

signal visit_done

enum State { WALK_IN, IDLE, WALK_OUT, DONE }

var current_state = State.DONE
var speed = 100.0
var path_points: Array = []
var current_point_index = 0

func start_visit(path: Path2D):
	path_points = Array(path.curve.get_baked_points())
	current_point_index = 0
	set_state(State.WALK_IN)

func set_state(new_state):
	current_state = new_state
	match new_state:
		State.WALK_IN:
			$AnimatedSprite2D.flip_h = false
			$AnimatedSprite2D.play("walk_in")
		State.IDLE:
			$AnimatedSprite2D.play("idle")
			await get_tree().create_timer(2.0).timeout
			path_points.reverse()
			current_point_index = 0
			set_state(State.WALK_OUT)
		State.WALK_OUT:
			$AnimatedSprite2D.flip_h = true
			$AnimatedSprite2D.play("walk_out")
		State.DONE:
			hide()
			emit_signal("visit_done")

func _process(delta):
	if current_state == State.IDLE or current_state == State.DONE:
		return

	if current_point_index < path_points.size():
		var target = path_points[current_point_index]
		position = position.move_toward(target, speed * delta)
		if position.distance_to(target) < 2.0:
			current_point_index += 1
	else:
		if current_state == State.WALK_IN:
			set_state(State.IDLE)
		elif current_state == State.WALK_OUT:
			set_state(State.DONE)
