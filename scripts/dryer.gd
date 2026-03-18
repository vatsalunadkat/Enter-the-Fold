extends Node2D

signal dry_complete

enum State { IDLE, RUNNING, DONE }

var current_state = State.IDLE
var _shake_tween: Tween

@onready var animated_sprite = $AnimatedSprite2D
@onready var running_effect = $RunningEffect
@onready var done_indicator = $DoneIndicator

func _ready() -> void:
	set_state(State.IDLE)

func start_dry(duration: float = 8.0) -> void:
	set_state(State.RUNNING)
	await get_tree().create_timer(duration).timeout
	set_state(State.DONE)

func collect_laundry() -> void:
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
			running_effect.state = "idle"
			done_indicator.visible = false
		State.RUNNING:
			animated_sprite.play("idle")
			running_effect.visible = true
			running_effect.state = "running"
			done_indicator.visible = false
			_shake_tween = create_tween().set_loops()
			_shake_tween.tween_property(animated_sprite, "position:x", 1.5, 0.04)
			_shake_tween.tween_property(animated_sprite, "position:x", -1.5, 0.04)
		State.DONE:
			if _shake_tween:
				_shake_tween.kill()
			animated_sprite.position.x = 0
			animated_sprite.play("idle")
			running_effect.visible = false
			running_effect.state = "idle"
			done_indicator.visible = true
			done_indicator.text = "✓ DONE"
			var tween = create_tween().set_loops(3)
			tween.tween_property(done_indicator, "modulate:a", 0.0, 0.3)
			tween.tween_property(done_indicator, "modulate:a", 1.0, 0.3)
			emit_signal("dry_complete")

# For testing — remove when integrating with LaundryStore
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		start_dry(8.0)
	if event.is_action_pressed("ui_cancel"):
		collect_laundry()
