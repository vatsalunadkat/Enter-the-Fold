extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

func set_empty() -> void:
	animated_sprite.play("empty")

func set_full() -> void:
	animated_sprite.play("full")

func _ready() -> void:
	set_empty()
