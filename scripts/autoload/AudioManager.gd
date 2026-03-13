extends Node

# --- Music ---
var music_player: AudioStreamPlayer

# --- SFX ---
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 8

# Preloaded sound effects dictionary
var sfx_library: Dictionary = {}

# Volume settings
var music_volume: float = 0.8
var sfx_volume: float = 1.0

# Enable/disable settings
var music_enabled: bool = true
var sfx_enabled: bool = true

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
