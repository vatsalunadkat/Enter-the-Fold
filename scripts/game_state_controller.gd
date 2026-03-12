extends Node

signal customer_arrived

@onready var console = $CanvasLayer/ConsoleLabel
@onready var prompt_manager = $PromptManager
@onready var pickup_anchor = $PickupAnchor
@onready var machine_anchor = $MachineAnchor
@onready var shelf_anchor = $ShelfAnchor
@onready var serve_anchor = $ServeAnchor

enum State {
	IDLE,
	CUSTOMER_ARRIVES,
	AWAITING_PICKUP,
	AWAITING_MACHINE_DROP,
	MACHINE_WASHING,
	AWAITING_MACHINE_PICKUP,
	AWAITING_SHELF_PLACE,
	AWAITING_CUSTOMER_RETURN,
	AWAITING_SERVE,
	MONEY_COLLECTED
}

var current_state = State.IDLE

func _ready():
	customer_arrived.connect(_on_customer_arrived)
	prompt_manager.prompt_completed.connect(_on_prompt_completed)
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
			prompt_manager.show_prompt(
				prompt_manager.get_random_word("easy"),
				pickup_anchor,
				"awaiting_pickup"
			)

		State.AWAITING_MACHINE_DROP:
			print("Waiting for player to put laundry in machine.")
			print_to_text_label("Waiting for player to put laundry in machine." + "\n")
			prompt_manager.show_prompt(
				prompt_manager.get_random_word("easy"),
				machine_anchor,
				"awaiting_machine_drop"
			)

		State.MACHINE_WASHING:
			print("Machine is washing for 3 seconds.")
			print_to_text_label("Machine is washing for 3 seconds." + "\n")
			$Timer.start(3)

		State.AWAITING_MACHINE_PICKUP:
			print("Waiting to take out laundry from machine.")
			print_to_text_label("Waiting to take out laundry from machine." + "\n")
			prompt_manager.show_prompt(
				prompt_manager.get_random_word("easy"),
				machine_anchor,
				"awaiting_machine_pickup"
			)

		State.AWAITING_SHELF_PLACE:
			print("Waiting to place laundry on shelf.")
			print_to_text_label("Waiting to place laundry on shelf." + "\n")
			prompt_manager.show_prompt(
				prompt_manager.get_random_word("easy"),
				shelf_anchor,
				"awaiting_shelf_place"
			)

		State.AWAITING_CUSTOMER_RETURN:
			print("Waiting for 10 seconds for customer to return.")
			print_to_text_label("Waiting for 10 seconds for customer to return." + "\n")
			$Timer.start(3)

		State.AWAITING_SERVE:
			print("Waiting to give laundry to customer.")
			print_to_text_label("Waiting to give laundry to customer." + "\n")
			prompt_manager.show_prompt(
				prompt_manager.get_random_word("easy"),
				serve_anchor,
				"awaiting_serve"
			)

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
	
func _on_prompt_completed(state_id: String) -> void:
	match state_id:
		"awaiting_pickup":
			change_state(State.AWAITING_MACHINE_DROP)
		"awaiting_machine_drop":
			change_state(State.MACHINE_WASHING)
		"awaiting_machine_pickup":
			change_state(State.AWAITING_SHELF_PLACE)
		"awaiting_shelf_place":
			change_state(State.AWAITING_CUSTOMER_RETURN)
		"awaiting_serve":
			change_state(State.MONEY_COLLECTED)
