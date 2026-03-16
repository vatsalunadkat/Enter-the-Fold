extends Control

@onready var status_label: Label = $CenterContainer/VBoxContainer/Label

var music_on: bool = true
var sfx_on: bool = true

const TEST_MUSIC_PATH: String = "res://assets/audio/music/carefree.ogg"
const TEST_SFX_NAME: String = "typing_correct"


func _ready() -> void:
	status_label.text = "Audio test ready."


func _on_play_music_button_pressed() -> void:
	AudioManager.play_music(TEST_MUSIC_PATH)
	status_label.text = "Playing music..."


func _on_play_sfx_button_pressed() -> void:
	AudioManager.play_sfx(TEST_SFX_NAME)
	status_label.text = "Playing SFX: " + TEST_SFX_NAME


func _on_stop_music_button_pressed() -> void:
	AudioManager.stop_music()
	status_label.text = "Music stopped."


func _on_toggle_music_button_pressed() -> void:
	music_on = not music_on
	AudioManager.toggle_music(music_on)

	if music_on:
		status_label.text = "Music enabled."
	else:
		status_label.text = "Music disabled."


func _on_toggle_sfx_button_pressed() -> void:
	sfx_on = not sfx_on
	AudioManager.toggle_sfx(sfx_on)

	if sfx_on:
		status_label.text = "SFX enabled."
	else:
		status_label.text = "SFX disabled."
