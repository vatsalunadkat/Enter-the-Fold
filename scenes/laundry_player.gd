extends CharacterBody2D

# Player doesn't move manually — all actions are driven by typing.
# The player character stays at a fixed position in the store.

func _ready() -> void:
	# Play idle animation if available
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("default")
