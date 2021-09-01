extends Node


"""
	This script (singleton) controls all audio-related activities in the game.
"""


const UUID_UTIL: GDScript = preload("res://src/Scripts/Addons/uuid.gd")

export(int, -80, 24, 1) var bgm_db: int
export(int, -80, 24, 1) var sfx_db: int
export(int, 1000, 2000, 100) var low_chz: int = 2000
export(int, 2000, 20000, 100) var high_chz: int = 5000
export(int, -80, 24, 1) var attack_db: int
export(int, -80, 24, 1) var detect_db: int
export(int, -80, 24, 1) var walk_db: int
export(int, -80, 24, 1) var block_db: int
export(int, -80, 24, 1) var push_db: int
export(int, -80, 24, 1) var socket_db: int
export(int, -80, 24, 1) var navigation_db: int
export(int, -80, 24, 1) var warp_db: int
export(int, -80, 24, 1) var win_db: int
export(int, -80, 24, 1) var lose_db: int


onready var BGMP: AudioStreamPlayer = $BGMP
onready var MenuBGM: AudioStreamOGGVorbis = preload("res://assets/audio/" + \
		"music/Menu.ogg")
onready var StealthBGM: AudioStreamOGGVorbis = preload("res://assets/audio/" + \
		"music/Stealth.ogg")
onready var SokobanBGM: AudioStreamOGGVorbis = preload("res://assets/audio/" + \
		"music/Sokoban.ogg")
onready var CluesBGM: AudioStreamOGGVorbis = preload("res://assets/audio/" + \
		"music/Clues.ogg")
onready var AttackT: AudioStreamSample = preload("res://assets/audio/" + \
		"sound/attack.wav")
onready var DetectT: AudioStreamSample = preload("res://assets/audio/" + \
		"sound/detect.wav")
onready var WalkT: AudioStreamSample = preload("res://assets/audio/" + \
		"sound/walk.wav")
onready var BlockT: AudioStreamSample = preload("res://assets/audio/" + \
		"sound/block.wav")
onready var PushT: AudioStreamSample = preload("res://assets/audio/" + \
		"sound/push.wav")
onready var SocketT: AudioStreamSample = preload("res://assets/audio/" + \
		"sound/socket.wav")
onready var NavigationT: AudioStreamSample = preload("res://assets/audio/" + \
		"sound/navigation.wav")
onready var WarpT: AudioStreamSample = preload("res://assets/audio/" + \
		"sound/warp.wav")
onready var WinT: AudioStreamSample = preload("res://assets/audio/" + \
		"sound/win.wav")
onready var LoseT: AudioStreamSample = preload("res://assets/audio/" + \
		"sound/lose.wav")
onready var original_tracks: Array = [WarpT, WinT, LoseT]


func _ready() -> void:
	initialize_players()
	
	
func _input(_event) -> void:
	if Input.is_action_just_pressed("MuteMusic"):
		# Mutes the `Music` audio bus.
		var bus_i: int = AudioServer.get_bus_index("Music")
		var mute_status: bool = AudioServer.is_bus_mute(bus_i)
		AudioServer.set_bus_mute(bus_i, not mute_status)
	elif Input.is_action_just_pressed("MuteSound"):
		# Mutes the `Sound` audio bus.
		var bus_i: int = AudioServer.get_bus_index("Sound")
		var mute_status: bool = AudioServer.is_bus_mute(bus_i)
		AudioServer.set_bus_mute(bus_i, not mute_status)
		
		
func initialize_players() -> void:
	# Initializes child `AudioStreamPlayer` nodes depending on their audio bus.
	for asp in get_children():
		if asp.bus == "Music":
			asp.volume_db = bgm_db
		else:
			asp.volume_db = sfx_db
	
	
func change_game_state(to: String) -> void:
	# Changes the game state and the track related to that game state.
	var track: String = "%sBGM" % to
	if BGMP.stream != get(track):
		BGMP.stream = get(track)
		BGMP.play()


func play_sound(s: String) -> void:
	# Plays the sound corresponding to the `s` parameter. For example,
	# `play_sound("Attack")` plays the `AttackT` sound.
	var track: AudioStreamSample = get("%sT" % s)
	var p_bus: String = "Sound"
	var uuid: String
	var bus_i: int

	# the If track is not in `original_tracks`, its frequency will be randomized
	# between `low_chz` and `high_chz` variables to create various sound
	# effects.
	if not track in original_tracks:
		uuid = UUID_UTIL.v4()
		p_bus = uuid
		
		# Adding an audio bus to the `AudioServer` after creating a unique id
		# (`uuid`) for it.
		AudioServer.add_bus(-1)
		bus_i = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_i, uuid)
		AudioServer.set_bus_send(bus_i, "Sound")
		
		# Creating a low pass filter effect for the audio.
		var lp_effect: AudioEffect = AudioEffectLowPassFilter.new()
		var r: int = int(stepify(rand_range(low_chz, high_chz), 5))
		lp_effect.cutoff_hz = r
		AudioServer.add_bus_effect(bus_i, lp_effect, -1)
	
	# A new `AudioStreamPlayer` is created and added as a child to the scene.
	var asp: AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(asp)
	asp.stream = track
	asp.volume_db = get("%s_db" % s.to_lower())
	asp.bus = p_bus
	asp.play()
	print("Playing sound: %s" % s)
	
	yield(asp, "finished")
	asp.queue_free()
	if uuid:
		# The newly-created audio bus is removed in the end, after the audio is
		# played.
		AudioServer.remove_bus(AudioServer.get_bus_index(uuid))
