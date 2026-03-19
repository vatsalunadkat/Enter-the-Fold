extends Control

@onready var levels_box := get_node_or_null("MenuCard/CardPadding/MainVBox/LevelsBox/") as VBoxContainer

func _ready() -> void:
	# Setup level buttons (1-3 only)
	var l2 = levels_box.get_node_or_null("Level2Button")
	var l3 = levels_box.get_node_or_null("Level3Button")
	if l2 and not l2.pressed.is_connected(_on_level_2_button_pressed):
		l2.pressed.connect(_on_level_2_button_pressed)
	if l3 and not l3.pressed.is_connected(_on_level_3_button_pressed):
		l3.pressed.connect(_on_level_3_button_pressed)

	# Setup endless mode button
	var endless_btn = get_node_or_null("MenuCard/CardPadding/MainVBox/EndlessBox/EndlessButton")
	if endless_btn and not endless_btn.pressed.is_connected(_on_endless_button_pressed):
		endless_btn.pressed.connect(_on_endless_button_pressed)
	
	# ⭐ NEW: Continue Endless Button Logic
	var continue_btn = levels_box.get_node_or_null("ContinueEndlessButton")

	if continue_btn:

		# Show only if save exists
		if SaveManager.save_exists():
			continue_btn.visible = true

			if not continue_btn.pressed.is_connected(_on_continue_endless_button_pressed):
				continue_btn.pressed.connect(_on_continue_endless_button_pressed)

		else:
			continue_btn.visible = false

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
	SaveManager.delete_save()
	UpgradeManager.reset_all()  # Fresh start for endless
	SceneRouter.go_to("res://scenes/LaundryStore.tscn")

func _on_back_button_pressed() -> void:
	SceneRouter.go_to("res://scenes/MainMenu.tscn")

func _on_continue_endless_button_pressed() -> void:
	SaveManager.load_game()
	SceneRouter.go_to("res://scenes/UpgradeShop.tscn")
