extends Control

@onready var left_col := get_node_or_null("Panel/MainVBox/Cloumns/leftPanel/LeftColumns") as VBoxContainer
@onready var right_panel := get_node_or_null("Panel/MainVBox/Cloumns/RightPanel") as PanelContainer

func _ready() -> void:
	if left_col == null:
		push_error("LevelSelect: LeftColumns not found.")
		return

	# Setup level buttons (1-3 only)
	var l2 = left_col.get_node_or_null("Level2Button")
	var l3 = left_col.get_node_or_null("Level3Button")
	if l2 and not l2.pressed.is_connected(_on_level_2_button_pressed):
		l2.pressed.connect(_on_level_2_button_pressed)
	if l3 and not l3.pressed.is_connected(_on_level_3_button_pressed):
		l3.pressed.connect(_on_level_3_button_pressed)

	# Setup endless mode button
	var endless_btn = right_panel.get_node_or_null("VBox/EndlessButton") if right_panel else null
	if endless_btn and not endless_btn.pressed.is_connected(_on_endless_button_pressed):
		endless_btn.pressed.connect(_on_endless_button_pressed)

func _on_level_1_button_pressed() -> void:
	GameConfig.reset_endless()
	GameConfig.set_level(1)
	SceneRouter.go_to("res://scenes/LaundryStore.tscn")

func _on_level_2_button_pressed() -> void:
	GameConfig.reset_endless()
	GameConfig.set_level(2)
	SceneRouter.go_to("res://scenes/LaundryStore.tscn")

func _on_level_3_button_pressed() -> void:
	GameConfig.reset_endless()
	GameConfig.set_level(3)
	SceneRouter.go_to("res://scenes/LaundryStore.tscn")

func _on_endless_button_pressed() -> void:
	GameConfig.start_endless_mode()
	UpgradeManager.reset_all()  # Fresh start for endless
	SceneRouter.go_to("res://scenes/LaundryStore.tscn")

func _on_back_button_pressed() -> void:
	SceneRouter.go_to("res://scenes/MainMenu.tscn")

