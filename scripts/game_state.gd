extends Node

signal money_updated(new_total)

var money: int = 0

func add_money(amount: int) -> void:
	money += amount
	emit_signal("money_updated", money)
