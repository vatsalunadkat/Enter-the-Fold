extends CanvasLayer

@onready var money_label = $MoneyLabel
var bb_code_format = "[font_size=28] [color=green] %s[/color]"

func _ready() -> void:
	var str = bb_code_format % ("Money: $" + str(GameState.money))
	money_label.text = str
	GameState.money_updated.connect(_on_money_updated)

func _on_money_updated(new_total):
	money_label.text = bb_code_format % ("Money: $" + str(new_total))
