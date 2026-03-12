extends CanvasLayer

@onready var money_label: Label = $TopBar/MoneyLabel
@onready var time_label: Label = $TopBar/TimeLabel
@onready var customers_label: Label = $TopBar/CustomersLabel
@onready var task_label: Label = $TaskLabel
@onready var day_over_panel: Panel = $DayOverPanel
@onready var day_over_money: Label = $DayOverPanel/VBox/MoneyEarned
@onready var day_over_served: Label = $DayOverPanel/VBox/CustomersServed
@onready var menu_button: Button = $DayOverPanel/VBox/MenuButton

func _ready() -> void:
	day_over_panel.visible = false
	menu_button.pressed.connect(_on_menu_pressed)

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
	day_over_money.text = "Money earned: $%d" % money
	day_over_served.text = "Customers served: %d" % served

func _on_menu_pressed() -> void:
	get_tree().paused = false
	SceneRouter.go_to("res://scenes/MainMenu.tscn")
