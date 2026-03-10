extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
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
