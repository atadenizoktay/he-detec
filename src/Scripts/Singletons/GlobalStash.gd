extends Node


"""
	This script is a singleton that keeps certain data in order to maintain
	other scripts' cleanness.
"""


const TILE_SIZE_VECTOR: Vector2 = Vector2(8, 8)
const TILE_SIZE: int = 8
const CELL_TYPE_TO_STR: Dictionary = {
	-1: "EMPTY",
	0: "ACTOR",
	1: "WALL",
	2: "BOX",
	3: "ENEMY",
	4: "GRASS"
}

var skip_duration: float = 0.04
var actor_movement_duration: float = 0.12
var box_movement_duration: float = 0.12
var mouse_enter_modulate: Color = Color(0.8, 0.8, 0.8, 1)
var mouse_exit_modulate: Color = Color(0.5, 0.5, 0.5, 1)
var enemy_cooldown_modulate: Color = Color(0.4, 0.5, 1, 1)
var stealth_level_t_count: int = 0 setget set_stealth_level_t_count
var sokoban_level_r_count: int = 0 setget set_sokoban_level_r_count
var sokoban_level_s_count: int = 0 setget set_sokoban_level_s_count
var suspect_names: Array = [
	"Timbermann", "Butcher", "Mademoiselle", "Librarian"
]
var clue_names: Array = [
	"near-sighted", "broken-hearted", "in-love", "left-handed",
	"greedy", "well-read", "a smoker", "large-footed",
	"classy", "scarred" , "alcoholic", "an ex-convict"
]
var letter_to_clue: Dictionary = {}
var suspects: Dictionary = {
	# Murderers and their clues. This dictionary, later, will be shuffled to
	# make the game seem random.
	0: {
		"is_murderer": true,
		"clues": ["A", "C", "E", "G", "I"]
	},
	1: {
		"is_murderer": false,
		"clues": ["A", "D", "E", "H", "J"]	
	},
	2: {
		"is_murderer": false,
		"clues": ["A", "D", "F", "H", "K"]	
	},
	3: {
		"is_murderer": false,
		"clues": ["B", "D", "F", "G", "L"]	
	}
}
var clues_by_box: Dictionary = {
	# Clues to get depending on the Sokoban level success.
	"Sokoban1": {
		1: [true, "A"],
		2: [false, "H"],
		3: [true, "E"]
	},
	"Sokoban2": {
		1: [false, "J"],
		2: [false, "K"],
		3: [true, "G"]
	},
	"Sokoban3": {
		1: [false, "B"],
		2: [false, "F"],
		3: [false, "D"]
	}
}
var gathered_clues: Array

onready var Stealth1: PackedScene = preload("res://src/Scenes/Stages/" + \
		"Stealth1.tscn")
onready var Stealth2: PackedScene = preload("res://src/Scenes/Stages/" + \
		"Stealth2.tscn")
onready var Stealth3: PackedScene = preload("res://src/Scenes/Stages/" + \
		"Stealth3.tscn")
onready var Sokoban1: PackedScene = preload("res://src/Scenes/Stages/" + \
		"Sokoban1.tscn")
onready var Sokoban2: PackedScene = preload("res://src/Scenes/Stages/" + \
		"Sokoban2.tscn")
onready var Sokoban3: PackedScene = preload("res://src/Scenes/Stages/" + \
		"Sokoban3.tscn")
onready var TimbermannFrame: Texture = preload("res://assets/art/ui/" + \
		"portraits/timbermann.png")
onready var ButcherFrame: Texture = preload("res://assets/art/ui/" + \
		"portraits/butcher.png")
onready var MademoiselleFrame: Texture = preload("res://assets/art/ui/" + \
		"portraits/mademoiselle.png")
onready var LibrarianFrame: Texture = preload("res://assets/art/ui/" + \
		"portraits/librarian.png")
onready var AClue: Texture
onready var BClue: Texture
onready var CClue: Texture
onready var DClue: Texture
onready var EClue: Texture
onready var FClue: Texture
onready var GClue: Texture
onready var HClue: Texture
onready var IClue: Texture
onready var JClue: Texture
onready var KClue: Texture
onready var LClue: Texture
onready var Positive: Texture = preload("res://assets/art/ui/clues/" + \
		"positive.png")
onready var Negative: Texture = preload("res://assets/art/ui/clues/" + \
		"negative.png")
onready var m3x6: DynamicFontData = preload("res://assets/fonts/m3x6.ttf")
onready var m5x7: DynamicFontData = preload("res://assets/fonts/m5x7.ttf")


func _ready() -> void:
	randomize()
	initialize_clues()


func initialize_clues() -> void:
	# Loads clue textures depending on the clue name.
	clue_names.shuffle()
	var ls: String = "ABCDEFGHIJKL"
	for l in ls:
		var i: int = ls.find(l)
		var c: String = clue_names[i]
		letter_to_clue[l] = c
		
		c = c.replace("-", "_")
		c = c.replace(" ", "_")
		var p: String = "%sClue" % l
		var t_path: String = "res://assets/art/ui/clues/%s.png" % c
		set(p, load(t_path))
	
	
func gather_clue(l_name: String, b_count: int) -> void:
	# Gathers clue depending on the level name (`l_name`) and box count 
	# (`b_count`).
	var clue: Array = clues_by_box[l_name][b_count] if b_count else []
	gathered_clues.append(clue)


func get_clue_icon(l_name: String, b_count: int) -> Texture:
	# Gathers a clue texture depending on the level name (`l_name`) and box
	# count (`b_count`).
	return get("%sClue" % clues_by_box[l_name][b_count][-1])


func set_stealth_level_t_count(val: int) -> void:
	# Sets try count for the current stealth level.
	stealth_level_t_count = val
	print("Tries: %d" % stealth_level_t_count)
	

func set_sokoban_level_r_count(val: int) -> void:
	# Sets the restart count for the current Sokoban level.
	sokoban_level_r_count = val
	print("Restarts: %d" % sokoban_level_r_count)


func set_sokoban_level_s_count(val: int) -> void:
	# Sets the success count for the current Sokoban level.
	sokoban_level_s_count = val
	print("Success: %d" % sokoban_level_s_count)
