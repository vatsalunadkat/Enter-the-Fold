extends Control

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		print("pause pressed")
		toggle_pause()

func toggle_pause() -> void:
	visible = !visible
	get_tree().paused = visible

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	visible = false
	SceneRouter.go_to("res://scenes/LaundryStore.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	visible = false
	SceneRouter.go_to("res://scenes/MainMenu.tscn")
