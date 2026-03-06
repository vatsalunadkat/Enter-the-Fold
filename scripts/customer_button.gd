extends Button

@onready var game_state_controller = $"/root/GameStateController"

func _on_pressed():
	game_state_controller.customer_arrived.emit() 
