extends Node2D

signal register_complete

enum State { IDLE, RUNNING, DONE }

var current_state = State.IDLE
var _shake_tween: Tween

@onready var animated_sprite = $AnimatedSprite2D
@onready var running_effect = $RunningEffect

func _ready() -> void:
	set_state(State.IDLE)

func start_transaction(duration: float = 3.0) -> void:
	set_state(State.RUNNING)
	await get_tree().create_timer(duration).timeout
	set_state(State.DONE)

func reset() -> void:
	set_state(State.IDLE)

func set_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.IDLE:
			if _shake_tween:
				_shake_tween.kill()
			animated_sprite.position.x = 0
			animated_sprite.play("idle")
			running_effect.visible = false
			running_effect.stop_register()
		State.RUNNING:
			animated_sprite.play("idle")
			running_effect.visible = true
			running_effect.start_register()
			_shake_tween = create_tween().set_loops()
			_shake_tween.tween_property(animated_sprite, "position:x", 1.5, 0.06)
			_shake_tween.tween_property(animated_sprite, "position:x", -1.5, 0.06)
		State.DONE:
			if _shake_tween:
				_shake_tween.kill()
			animated_sprite.position.x = 0
			animated_sprite.play("idle")
			running_effect.visible = false
			running_effect.stop_register()
			emit_signal("register_complete")

# For testing — remove when integrating
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		start_transaction(3.0)
	if event.is_action_pressed("ui_cancel"):
		reset()
