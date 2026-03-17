extends Node

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 8

var sfx_library: Dictionary = {}

var music_enabled: bool = true
var sfx_enabled: bool = true


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	for i in range(MAX_SFX_PLAYERS):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	var music_bus_index = AudioServer.get_bus_index("Music")
	if music_bus_index != -1:
		AudioServer.set_bus_mute(music_bus_index, false)
		AudioServer.set_bus_volume_db(music_bus_index, 0.0)

	var sfx_bus_index = AudioServer.get_bus_index("SFX")
	if sfx_bus_index != -1:
		AudioServer.set_bus_mute(sfx_bus_index, false)
		AudioServer.set_bus_volume_db(sfx_bus_index, 0.0)

	print("AudioManager: Music bus index = ", music_bus_index)
	print("AudioManager: SFX bus index = ", sfx_bus_index)

	_load_sfx_library()
	print("AudioManager: Loaded SFX count = ", sfx_library.size())


func _load_sfx_library() -> void:
	var sfx_files = {
		"typing_correct": "res://assets/audio/sfx/tap.wav",
		"typing_wrong": "res://assets/audio/sfx/hurt.wav",
		"word_complete": "res://assets/audio/sfx/power_up.wav",
		"washing_machine": "res://assets/audio/sfx/washing_machine.wav",
		"wash_done": "res://assets/audio/sfx/power_up.wav",
		"customer_arrive": "res://assets/audio/sfx/jump.wav",
		"money_collect": "res://assets/audio/sfx/coin.wav",
		"day_end": "res://assets/audio/sfx/explosion.wav",
	}

	for key in sfx_files:
		if ResourceLoader.exists(sfx_files[key]):
			sfx_library[key] = load(sfx_files[key])
			print("AudioManager: Loaded SFX -> ", key, " from ", sfx_files[key])
		else:
			print("AudioManager: SFX file not found (skipping): ", sfx_files[key])


func play_music(track_path: String) -> void:
	if not music_enabled:
		print("AudioManager: Music is disabled.")
		return

	if not ResourceLoader.exists(track_path):
		print("AudioManager: Music file not found: ", track_path)
		return

	var stream = load(track_path) as AudioStream
	if stream:
		if music_player.playing:
			music_player.stop()

		music_player.stream = stream
		music_player.play()


func stop_music() -> void:
	music_player.stop()


func play_sfx(sfx_name: String) -> void:
	if not sfx_enabled:
		print("AudioManager: SFX is disabled.")
		return

	if sfx_name not in sfx_library:
		print("AudioManager: Unknown SFX: ", sfx_name)
		return

	for player in sfx_players:
		if not player.playing:
			player.stream = sfx_library[sfx_name]
			player.play()
			print("AudioManager: Playing SFX -> ", sfx_name)
			return

	sfx_players[0].stream = sfx_library[sfx_name]
	sfx_players[0].play()
	print("AudioManager: Reused SFX player for -> ", sfx_name)


func toggle_music(enabled: bool) -> void:
	music_enabled = enabled
	var bus_index = AudioServer.get_bus_index("Music")
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, not enabled)

	if not enabled:
		stop_music()


func toggle_sfx(enabled: bool) -> void:
	sfx_enabled = enabled
	var bus_index = AudioServer.get_bus_index("SFX")
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, not enabled)
