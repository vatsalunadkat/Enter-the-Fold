extends Node2D

signal iron_complete

enum State { IDLE, RUNNING, DONE }

var current_state = State.IDLE

@onready var animated_sprite = $AnimatedSprite2D
@onready var running_effect = $RunningEffect
@onready var done_indicator = $DoneIndicator

func _ready() -> void:
	set_state(State.IDLE)

func start_iron(duration: float = 6.0) -> void:
	set_state(State.RUNNING)
	await get_tree().create_timer(duration).timeout
	set_state(State.DONE)

func collect_laundry() -> void:
	set_state(State.IDLE)

func set_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.IDLE:
			animated_sprite.play("idle")
			running_effect.visible = false
			running_effect.stop_iron()
			done_indicator.visible = false
		State.RUNNING:
			animated_sprite.play("idle")
			running_effect.visible = true
			running_effect.start_iron()
			done_indicator.visible = false
		State.DONE:
			animated_sprite.play("idle")
			running_effect.visible = false
			running_effect.stop_iron()
			done_indicator.visible = true
			done_indicator.text = "✓ DONE"
			var tween = create_tween().set_loops(3)
			tween.tween_property(done_indicator, "modulate:a", 0.0, 0.3)
			tween.tween_property(done_indicator, "modulate:a", 1.0, 0.3)
			emit_signal("iron_complete")

# For testing — remove when integrating with LaundryStore
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		start_iron(6.0)
	if event.is_action_pressed("ui_cancel"):
		collect_laundry()
