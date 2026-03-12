extends CharacterBody2D

# Player doesn't move manually — all actions are driven by typing.
# The player character stays at a fixed position in the store.

func _ready() -> void:
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.frame = 0
