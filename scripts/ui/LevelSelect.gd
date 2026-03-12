extends Control

@onready var left_col := get_node_or_null("Panel/MainVBox/Cloumns/leftPanel/LeftColumns") as VBoxContainer
@onready var right_col := get_node_or_null("Panel/MainVBox/Cloumns/RightPanel/RightColumns") as VBoxContainer

func _ready() -> void:
	if left_col == null or right_col == null:
		push_error("LevelSelect: Columns not found. Check node names: Panel/MainVBox/Columns/LeftColumns & RightColumns.")
		return

	# Lock every button except Level 1-3
	var unlocked := ["Level1Button", "Level2Button", "Level3Button"]
	for child in left_col.get_children():
		if child is Button:
			if child.name in unlocked:
				child.disabled = false
				child.modulate.a = 1.0
			else:
				_lock(child)

	for child in right_col.get_children():
		if child is Button:
			_lock(child)

	# Connect level buttons
	var l2 = left_col.get_node_or_null("Level2Button")
	var l3 = left_col.get_node_or_null("Level3Button")
	if l2 and not l2.pressed.is_connected(_on_level_2_button_pressed):
		l2.pressed.connect(_on_level_2_button_pressed)
	if l3 and not l3.pressed.is_connected(_on_level_3_button_pressed):
		l3.pressed.connect(_on_level_3_button_pressed)

func _lock(btn: Button) -> void:
	btn.disabled = true
	btn.modulate.a = 0.4

func _on_level_1_button_pressed() -> void:
	GameConfig.set_level(1)
	SceneRouter.go_to("res://scenes/LaundryStore.tscn")

func _on_level_2_button_pressed() -> void:
	GameConfig.set_level(2)
	SceneRouter.go_to("res://scenes/LaundryStore.tscn")

func _on_level_3_button_pressed() -> void:
	GameConfig.set_level(3)
	SceneRouter.go_to("res://scenes/LaundryStore.tscn")

func _on_back_button_pressed() -> void:
	SceneRouter.go_to("res://scenes/MainMenu.tscn")
