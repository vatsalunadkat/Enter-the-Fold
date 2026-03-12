extends Node2D

@onready var prompt_manager = $PromptManager

func _ready():

	prompt_manager.show_prompt("wash", $FakeObject1, "machine1")
	prompt_manager.show_prompt("soap", $FakeObject2, "machine2")
	prompt_manager.show_prompt("dry", $FakeObject3, "machine3")

	prompt_manager.prompt_completed.connect(_on_prompt_done)


func _on_prompt_done(state_id):
	print("Prompt finished:", state_id)
