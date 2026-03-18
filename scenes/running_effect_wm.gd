extends Sprite2D

var state = "idle"

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if state == "running":
		rotation += delta * 3.0
