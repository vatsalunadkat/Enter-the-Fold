extends Node

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 8

var sfx_library: Dictionary = {}

var music_volume: float = 0.8
var sfx_volume: float = 1.0
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
		music_player.stream = stream
		music_player.volume_db = linear_to_db(music_volume)
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
			player.volume_db = linear_to_db(sfx_volume)
			player.play()
			print("AudioManager: Playing SFX -> ", sfx_name)
			return

	sfx_players[0].stream = sfx_library[sfx_name]
	sfx_players[0].volume_db = linear_to_db(sfx_volume)
	sfx_players[0].play()
	print("AudioManager: Reused SFX player for -> ", sfx_name)


func set_music_volume(vol: float) -> void:
	music_volume = clamp(vol, 0.0, 1.0)
	music_player.volume_db = linear_to_db(music_volume)


func set_sfx_volume(vol: float) -> void:
	sfx_volume = clamp(vol, 0.0, 1.0)


func toggle_music(enabled: bool) -> void:
	music_enabled = enabled
	if not enabled:
		stop_music()


func toggle_sfx(enabled: bool) -> void:
	sfx_enabled = enabled
