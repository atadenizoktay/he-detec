extends Node2D


"""
	This script includes properties and functions related to each playable game
	level.
"""


enum LEVEL_TYPES {
	SOKOBAN,
	STEALTH
}

export(LEVEL_TYPES) var level_type: int
export(String) var level_name: String
export(int) var slot_count: int
export(PackedScene) var next_level: PackedScene

var slots: Dictionary = {}
var win_status: bool = false
var can_restart: bool = false

onready var clues_level: PackedScene = preload("res://src/Scenes/Main/" + \
		"Clues.tscn")


func _ready() -> void:
	initialize_bgm()
	control_transition()
	
	# This code block was used to fix a bug before but is no longer used. It
	# still is here in case the bug where multiple instances of playable levels
	# become present appears again.
#	for l in get_tree().get_nodes_in_group("Level"):
#		if l != self:
#			l.call_deferred("queue_free")
	

func _input(_event) -> void:
	if Input.is_action_just_pressed("Restart"):
		if can_restart:
			can_restart = false
			restart_level("Warp")


func initialize_bgm() -> void:
	# Initializes the background music when the scene is loaded.
	match level_type:
		LEVEL_TYPES.STEALTH:
			GlobalSound.change_game_state("Stealth")
		LEVEL_TYPES.SOKOBAN:
			GlobalSound.change_game_state("Sokoban")
			
			
func control_transition() -> void:
	# Controls the initial transition when the scene is loaded.
	GlobalTransition.fade_in()
	yield(GlobalTransition, "faded_in")
	can_restart = true
	GlobalTransition.is_transitioning = false
	
	
func update_slot_status_enter(body: Node) -> void:
	# Updates the box slot status when a body is entered a `Slot` area. See
	# `Slot.gd` for the connection.
	if not win_status:
		if body.is_in_group("Box"):
			GlobalSound.play_sound("Socket")
			slots[body] = true
			var s: int = update_slot_success()
			if s == slot_count:
				check_win_status()


func update_slot_status_exit(body: Node) -> void:
	# Updates the box slot status when a body is exited a `Slot` area. See
	# `Slot.gd` for the connection.
	if not win_status:
		if body.is_in_group("Box"):
			GlobalSound.play_sound("Socket")
			slots[body] = false


func update_skip_status_enter(body: Node) -> void:
	# Updates the skip status when a body is entered a `Skip` area. See
	# `Skip.gd` for the connection.
	if not win_status:
		if body.is_in_group("Actor"):
			check_win_status()


func check_win_status() -> void:
	# Checks the win status depending on the level type.
	match level_type:
		LEVEL_TYPES.SOKOBAN:
			if Helpers.all_true_dict(slots):
				win_status = true
				clear_level()
		LEVEL_TYPES.STEALTH:
			clear_level()


func clear_level() -> void:
	# Clears the current level and continues to the next level.
	var nl: Node
	if next_level != null:
		nl = next_level.instance()
	else:
		nl = clues_level.instance()
	
	var notice: String
	var clue_icon: Texture = null
	match level_type:
		LEVEL_TYPES.SOKOBAN:
			# Gathers clue depending on the Sokoban level success and resets
			# the success count for Sokoban levels.
			var c_s: int = update_slot_success()
			var g_s: int = GlobalStash.sokoban_level_s_count
			var success: int = int(max(c_s, g_s))
			GlobalStash.gather_clue(level_name, success)
			GlobalStash.sokoban_level_s_count = 0
			
			var clue: Array = GlobalStash.gathered_clues[-1]
			if clue != []:
				var is_not: String = "not " if not clue[0] else ""
				var desc: String = GlobalStash.letter_to_clue[clue[1]]
				notice = "The killer is {0}{1}!".format([is_not, desc])
				clue_icon = GlobalStash.get_clue_icon(level_name, success)
			else:
				notice = "You could not get any clues!"
		LEVEL_TYPES.STEALTH:
			# Determines the restart count for the next Sokoban level and
			# resets the try count for stealth levels.
			var t: int = GlobalStash.stealth_level_t_count
			GlobalStash.sokoban_level_r_count = int(max(1, 4 - t))
			GlobalStash.stealth_level_t_count = 0
			notice = "You are ahead! You have %d restarts!" % \
					GlobalStash.sokoban_level_r_count
	
	# Controls the audio and the transition.
	GlobalSound.play_sound("Warp")
	GlobalTransition.change_notice(notice)
	GlobalTransition.change_icon(clue_icon)
	GlobalTransition.fade_out()
	GlobalTransition.is_transitioning = true
	yield(GlobalTransition, "faded_out")
	
	# Changes the scene after the timeout.
	$ClearTimer.start()
	yield($ClearTimer, "timeout")
	get_parent().call_deferred("add_child", nl)
	queue_free()


func update_slot_success() -> int:
	# Updates the slot success depending on the bodies that enter `Slot` areas.
	# Slot success affects the quality of the clue that is got after clearing
	# a Sokoban level.
	var success: int = 0
	var g_s: int = GlobalStash.sokoban_level_s_count
	for v in slots.values():
		if v:
			success += 1
	GlobalStash.sokoban_level_s_count = int(max(success, g_s))
	return success
	
	
func restart_level(sound: String) -> void:
	# Restarts the current level.
	can_restart = false
	var notice: String
	match level_type:
		LEVEL_TYPES.SOKOBAN:
			if GlobalStash.sokoban_level_r_count > 0:
				GlobalStash.sokoban_level_r_count -= 1
				notice = "You have %d restarts left!" % \
						GlobalStash.sokoban_level_r_count
			else:
				clear_level()
				return
		LEVEL_TYPES.STEALTH:
			GlobalStash.stealth_level_t_count += 1
			notice = "Stealth attempt #%d!" % \
					(GlobalStash.stealth_level_t_count + 1)
	
	# Controls the audio and the transition.
	GlobalSound.play_sound(sound)
	GlobalTransition.change_notice(notice)
	GlobalTransition.change_icon(null)
	GlobalTransition.fade_out()
	GlobalTransition.is_transitioning = true
	yield(GlobalTransition, "faded_out")
	
	# Changes the scene after the timeout.
	$RestartTimer.start()
	yield($RestartTimer, "timeout")
	var nl_ps: PackedScene = GlobalStash.get(level_name)
	var nl: Node2D = nl_ps.instance()
	get_parent().call_deferred("add_child", nl)
	queue_free()
