extends Control

@onready var save_button := get_node_or_null("CenterContainer/Panel/VBoxContainer/SaveButton") as Button 

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	if !GameConfig.endless_mode:
		SaveManager.save_game()
		save_button.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		print("pause pressed")
		toggle_pause()

func toggle_pause() -> void:
	visible = !visible
	get_tree().paused = visible
	save_button.text = "Save Game"

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
	
func _on_save_button_pressed() -> void:
	SaveManager.save_game()
	save_button.text = "Game Saved!"
