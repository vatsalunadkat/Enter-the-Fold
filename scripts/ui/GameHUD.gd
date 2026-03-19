extends CanvasLayer

@export var pause_menu: Control

@onready var money_label: Label = $TopBarPanel/TopBar/MoneyLabel
@onready var time_label: Label = $TopBarPanel/TopBar/TimeLabel
@onready var customers_label: Label = $TopBarPanel/TopBar/CustomersLabel
@onready var task_label: Label = $TaskPanel/TaskLabel
@onready var day_over_panel: Panel = $DayOverPanel
@onready var day_over_money: Label = $DayOverPanel/VBox/MoneyEarned
@onready var day_over_served: Label = $DayOverPanel/VBox/CustomersServed
@onready var menu_button: Button = $TopBarPanel/TopBar/MenuButton
@onready var shop_button := get_node_or_null("DayOverPanel/VBox/ShopButton") as Button
@onready var day_label: Label = $TopBarPanel/TopBar/DayLabel

func _ready() -> void:
	day_over_panel.visible = false
	menu_button.pressed.connect(_on_menu_button_pressed)

	if shop_button:
		shop_button.visible = false
		shop_button.pressed.connect(_on_shop_pressed)

	_update_day_label()

func _update_day_label() -> void:
	if GameConfig.endless_mode:
		day_label.text = "Day %d" % GameConfig.endless_day
		day_label.visible = true
	else:
		day_label.visible = false

func update_money(amount: int) -> void:
	money_label.text = "$ %d" % amount

func update_time(time_str: String) -> void:
	time_label.text = time_str

func update_task(text: String) -> void:
	task_label.text = text

func update_customers(served: int) -> void:
	customers_label.text = "Served: %d" % served

func show_day_over(money: int, served: int) -> void:
	day_over_panel.visible = true

	if GameConfig.endless_mode:
		day_over_money.text = "Earned today: $%d\nTotal balance: $%d" % [money, GameState.money]
		if shop_button:
			shop_button.visible = true
	else:
		day_over_money.text = "Money earned: $%d" % money
		if shop_button:
			shop_button.visible = false

	day_over_served.text = "Customers served: %d" % served

func _on_menu_button_pressed() -> void:
	print("menu clicked")
	var pm = get_node_or_null("../PauseMenu")
	if pm:
		print("pause menu found")
		pm.toggle_pause()
	else:
		print("pause menu not found")

func _on_shop_pressed() -> void:
	get_tree().paused = false
	SceneRouter.go_to("res://scenes/UpgradeShop.tscn")
