extends Node

# console.append_text( + "\n")

@onready var console = $CanvasLayer/RichTextLabel

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
	customer_arrived()

func customer_arrived() -> void:
	if current_state == State.IDLE:
		enter_current_state()
		change_state(State.CUSTOMER_ARRIVES)
	else: 
		return # ignore if already busy

func change_state(new_state):
	$CanvasLayer/RichTextLabel.append_text("\n")
	current_state = new_state
	print("[Current state is now: ", State.keys()[current_state] + "]")
	console.append_text("[Current state is now: "+ State.keys()[current_state] + "] \n")
	enter_current_state()

func enter_current_state():
	match current_state:
		State.IDLE:
			print("Game is idle.")
			console.append_text("Game is idle." + "\n")

		State.CUSTOMER_ARRIVES:
			print("Customer walks in.")
			console.append_text("Customer walks in." + "\n")
			change_state(State.AWAITING_PICKUP)

		State.AWAITING_PICKUP:
			print("Waiting for player to pick up laundry.")
			console.append_text("Waiting for player to pick up laundry." + "\n")

		State.AWAITING_MACHINE_DROP:
			print("Waiting for player to put laundry in machine.")
			console.append_text("Waiting for player to put laundry in machine." + "\n")

		State.MACHINE_WASHING:
			print("Machine is washing for 10 seconds.")
			console.append_text("Machine is washing for 2 seconds." + "\n")
			$Timer.start(2)

		State.AWAITING_MACHINE_PICKUP:
			print("Waiting to take out laundry from machine.")
			console.append_text("Waiting to take out laundry from machine." + "\n")

		State.AWAITING_SHELF_PLACE:
			print("Waiting to place laundry on shelf.")
			console.append_text("Waiting to place laundry on shelf." + "\n")

		State.AWAITING_CUSTOMER_RETURN:
			print("Waiting for 2 seconds for customer to return.")
			console.append_text("Waiting for 2 seconds for customer to return." + "\n")
			$Timer.start(2)

		State.AWAITING_SERVE:
			print("Waiting to give laundry to customer.")
			console.append_text("Waiting to give laundry to customer." + "\n")

		State.MONEY_COLLECTED:
			print("Customer paid.")
			console.append_text("Customer paid." + "\n")
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
		console.append_text("Nu har jag tryckt en knapp" + "\n")
		complete_current_step()


func _on_timer_timeout() -> void:
	if current_state == State.MACHINE_WASHING:
		print("Wash finished")
		console.append_text("Wash finished" + "\n")
		change_state(State.AWAITING_MACHINE_PICKUP)
	else: if current_state == State.AWAITING_CUSTOMER_RETURN:
		change_state(State.AWAITING_SERVE)
