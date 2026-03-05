extends Control

@onready var left_col := get_node_or_null("Panel/MainVBox/Cloumns/leftPanel/LeftColumns") as VBoxContainer
@onready var right_col := get_node_or_null("Panel/MainVBox/Cloumns/RightPanel/RightColumns") as VBoxContainer

func _ready() -> void:
	if left_col == null or right_col == null:
		push_error("LevelSelect: Columns not found. Check node names: Panel/MainVBox/Columns/LeftColumns & RightColumns.")
		return

	# Lock every button except Level 1 button
	for child in left_col.get_children():
		if child is Button and child.name != "Level1Button":
			_lock(child)

	for child in right_col.get_children():
		if child is Button:
			_lock(child)

func _lock(btn: Button) -> void:
	btn.disabled = true
	btn.modulate.a = 0.4

func _on_level_1_button_pressed() -> void:
	print("Level 1 pressed -> going to LaundryStore")
	SceneRouter.go_to("res://scenes/LaundryStore.tscn")

func _on_back_button_pressed() -> void:
	SceneRouter.go_to("res://scenes/MainMenu.tscn")
