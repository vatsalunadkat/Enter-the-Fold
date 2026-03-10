extends CharacterBody2D

signal visit_done

enum State { WALK_IN, IDLE, WALK_OUT, DONE }
var current_state = State.DONE

var speed = 100.0
var path_points: Array = []   # Baked world-space points extracted from the assigned Path2D
var current_point_index = 0   # Tracks which point along the path we're currently moving toward

# Called externally to kick off a visit along a given Path2D (drop-off or pickup)
func start_visit(path: Path2D):
	path_points = Array(path.curve.get_baked_points())
	current_point_index = 0
	set_state(State.WALK_IN)

func set_state(new_state):
	current_state = new_state
	match new_state:
		State.WALK_IN:
			# face forward and play the walk-in animation
			$AnimatedSprite2D.flip_h = false
			$AnimatedSprite2D.play("walk_in")

		State.IDLE:
			$AnimatedSprite2D.play("idle")
			# wait at the destination before leaving
			await get_tree().create_timer(2.0).timeout
			# reverse the path so the customer walks back the way they came
			path_points.reverse()
			current_point_index = 0
			set_state(State.WALK_OUT)

		State.WALK_OUT:
			# flip sprite to face the exit direction
			$AnimatedSprite2D.flip_h = true
			$AnimatedSprite2D.play("walk_out")

		State.DONE:
			# hide the customer and notify the manager script that this visit is complete
			hide()
			emit_signal("visit_done")

func _process(delta):
	# skip movement processing while the customer is idle or finished
	if current_state == State.IDLE or current_state == State.DONE:
		return

	if current_point_index < path_points.size():
		var target = path_points[current_point_index]
		position = position.move_toward(target, speed * delta)
		# snap to the next point once we're close enough to avoid overshooting
		if position.distance_to(target) < 2.0:
			current_point_index += 1
	else:
		# all path points reached, transition to the next state
		if current_state == State.WALK_IN:
			set_state(State.IDLE)
		elif current_state == State.WALK_OUT:
			set_state(State.DONE)
