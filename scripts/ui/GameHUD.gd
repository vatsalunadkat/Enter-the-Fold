extends CanvasLayer

@onready var money_label: Label = $TopBar/MoneyLabel
@onready var time_label: Label = $TopBar/TimeLabel
@onready var customers_label: Label = $TopBar/CustomersLabel
@onready var task_label: Label = $TaskLabel
@onready var day_over_panel: Panel = $DayOverPanel
@onready var day_over_money: Label = $DayOverPanel/VBox/MoneyEarned
@onready var day_over_served: Label = $DayOverPanel/VBox/CustomersServed
@onready var menu_button: Button = $DayOverPanel/VBox/MenuButton
@onready var shop_button: Button = $DayOverPanel/VBox/ShopButton
@onready var day_label: Label = $TopBar/DayLabel

func _ready() -> void:
	day_over_panel.visible = false
	menu_button.pressed.connect(_on_menu_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	shop_button.visible = false
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
	
	# Show shop button only in endless mode
	if GameConfig.endless_mode:
		day_over_money.text = "Earned today: $%d\nTotal balance: $%d" % [money, GameState.money]
		shop_button.visible = true
		menu_button.text = "Quit to Menu"
	else:
		day_over_money.text = "Money earned: $%d" % money
		shop_button.visible = false
		menu_button.text = "Back to Menu"
	
	day_over_served.text = "Customers served: %d" % served

func _on_menu_pressed() -> void:
	get_tree().paused = false
	GameConfig.reset_endless()
	SceneRouter.go_to("res://scenes/MainMenu.tscn")

func _on_shop_pressed() -> void:
	get_tree().paused = false
	SceneRouter.go_to("res://scenes/UpgradeShop.tscn")

