extends Node

signal customer_arrived

@onready var console = $CanvasLayer/ConsoleLabel

enum State {
	IDLE,
	CUSTOMER_ARRIVES,
	AWAITING_PICKUP, #prompt appear
	AWAITING_MACHINE_DROP,#prompt appear
	MACHINE_WASHING,
	AWAITING_MACHINE_PICKUP, #prompt appear
	AWAITING_SHELF_PLACE, #prompt appear
	AWAITING_CUSTOMER_RETURN,
	AWAITING_SERVE, #prompt appear
	MONEY_COLLECTED
}

var current_state = State.IDLE

func _ready():
	customer_arrived.connect(_on_customer_arrived)
	enter_current_state()

func _on_customer_arrived() -> void:
	if current_state == State.IDLE:
		change_state(State.CUSTOMER_ARRIVES)
	else: 
		return # ignore if already busy

func change_state(new_state):
	print_to_text_label("\n")
	current_state = new_state
	print("[Current state is now: ", State.keys()[current_state] + "]")
	print_to_text_label("[Current state is now: "+ State.keys()[current_state] + "] \n")
	enter_current_state()

func enter_current_state():
	match current_state:
		State.IDLE:
			print("Game is idle.")
			print_to_text_label("Game is idle." + "\n")

		State.CUSTOMER_ARRIVES:
			print("Customer walks in.")
			print_to_text_label("Customer walks in." + "\n")
			change_state(State.AWAITING_PICKUP)

		State.AWAITING_PICKUP:
			print("Waiting for player to pick up laundry.")
			print_to_text_label("Waiting for player to pick up laundry." + "\n")

		State.AWAITING_MACHINE_DROP:
			print("Waiting for player to put laundry in machine.")
			print_to_text_label("Waiting for player to put laundry in machine." + "\n")

		State.MACHINE_WASHING:
			
			print("Machine is washing for 10 seconds.")
			print_to_text_label("Machine is washing for 10 seconds." + "\n")
			$Timer.start(10)

		State.AWAITING_MACHINE_PICKUP:
			print("Waiting to take out laundry from machine.")
			print_to_text_label("Waiting to take out laundry from machine." + "\n")

		State.AWAITING_SHELF_PLACE:
			print("Waiting to place laundry on shelf.")
			print_to_text_label("Waiting to place laundry on shelf." + "\n")

		State.AWAITING_CUSTOMER_RETURN:
			print("Waiting for 10 seconds for customer to return.")
			print_to_text_label("Waiting for 10 seconds for customer to return." + "\n")
			$Timer.start(10)

		State.AWAITING_SERVE:
			print("Waiting to give laundry to customer.")
			print_to_text_label("Waiting to give laundry to customer." + "\n")

		State.MONEY_COLLECTED:
			print("Customer paid.")
			print_to_text_label("Customer paid.\n")
			GameState.add_money(10)
			print_to_text_label("\n \n")
			change_state(State.IDLE)

func complete_current_step():
	match current_state: 
		State.AWAITING_PICKUP:
			change_state(State.AWAITING_MACHINE_DROP)
			
		State.AWAITING_MACHINE_DROP:
			change_state(State.MACHINE_WASHING)
			
		State.AWAITING_MACHINE_PICKUP:
			change_state(State.AWAITING_SHELF_PLACE)

		State.AWAITING_SHELF_PLACE:
			change_state(State.AWAITING_CUSTOMER_RETURN)
			
		State.AWAITING_SERVE:
			change_state(State.MONEY_COLLECTED)

#TEMPORARY FUNC 
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_released():
	#	var typed_event = event as InputEventKey 
	#	var key_typed = PackedByteArray([typed_event.unicode]).get_string_from_utf8()
		print_to_text_label("\n" + "Nu har jag tryckt en knapp" + "\n")
		complete_current_step()

func _on_timer_timeout() -> void:
	if current_state == State.MACHINE_WASHING:
		print("Wash finished")
		print_to_text_label("Wash finished" + "\n")
		change_state(State.AWAITING_MACHINE_PICKUP)
	else: if current_state == State.AWAITING_CUSTOMER_RETURN:
		change_state(State.AWAITING_SERVE)

func print_to_text_label(str : String) -> void:
	console.append_text(str)
	scroll_down()

func scroll_down() -> void:
	console.scroll_to_line(console.get_line_count()-1)
