extends Control


"""
	This scripts controls the `Clues` scene where murderers' information is
	displayed to the player for guessing.
"""


var suspects: Dictionary = {}
var suspects_name_list: Array
var can_detect: bool = false

onready var c_name_label: Label = $M/V/H1/Name
onready var c_frame: TextureRect = $M/V/H2/Frame/Person
onready var c_clue_1: TextureRect = $M/V/H2/V1/Clue1
onready var c_clue_2: TextureRect = $M/V/H2/V1/Clue2
onready var c_clue_3: TextureRect = $M/V/H2/V1/Clue3
onready var c_clue_4: TextureRect = $M/V/H2/V2/Clue4
onready var c_clue_5: TextureRect = $M/V/H2/V2/Clue5
onready var c_clues: Array = [c_clue_1, c_clue_2, c_clue_3, c_clue_4, c_clue_5]
onready var d_clue_1: TextureRect = $M/V/H3/Slot1/Clue
onready var d_clue_2: TextureRect = $M/V/H3/Slot2/Clue
onready var d_clue_3: TextureRect = $M/V/H3/Slot3/Clue
onready var d_clues: Array = [d_clue_1, d_clue_2, d_clue_3]
onready var d_clue_1_p: TextureRect = $M/V/H3/Slot1/Positivity
onready var d_clue_2_p: TextureRect = $M/V/H3/Slot2/Positivity
onready var d_clue_3_p: TextureRect = $M/V/H3/Slot3/Positivity
onready var d_clue_ps: Array = [d_clue_1_p, d_clue_2_p, d_clue_3_p]
onready var menu_scene: PackedScene = preload("res://src/Scenes/Main/Menu.tscn")


func _ready() -> void:
	randomize()
	initialize_bgm()
	initialize_suspects()
	initialize_clues()
	control_transition()


func control_transition() -> void:
	# Controls the initial transition when the scene is loaded.
	GlobalTransition.fade_in()
	yield(GlobalTransition, "faded_in")
	can_detect = true
	
	
func initialize_bgm() -> void:
	# Initializes the background music when the scene is loaded.
	GlobalSound.change_game_state("Clues")
	
	
func initialize_suspects() -> void:
	# Initializes the suspects by shuffling certain data. This creates the
	# immersion of randomness in each gameplay.
	var names: Array = GlobalStash.suspect_names.duplicate()
	var values: Array = GlobalStash.suspects.values().duplicate()
	names.shuffle()
	values.shuffle()
	for i in range(names.size()):
		suspects[names[i]] = values[i]
	
	suspects_name_list = suspects.keys()
	var s_name: String = suspects_name_list[0]
	c_name_label.set_text(s_name)
	change_suspect_frame(s_name)
	change_suspect_clues(suspects[s_name]["clues"])


func change_suspect_frame(s_name: String) -> void:
	# Changes the texture in the suspect's frame.
	var n: String = s_name.replace(" ", "")
	c_frame.set_texture(GlobalStash.get("%sFrame" % n))
	c_name_label.set_text(s_name)
	
	
func change_suspect_clues(clues: Array) -> void:
	# Changes the textures around the suspect's frame.
	for c in c_clues:
		var i: int = c_clues.find(c)
		c.set_texture(GlobalStash.get("%sClue" % clues[i]))
	

func initialize_clues() -> void:
	# Initializes clue slots for the player to guess according to.
	var clues: Array = GlobalStash.gathered_clues
	while clues.size() != 3:
		clues.append([])
	
	for p in d_clue_ps:
		var i: int = d_clue_ps.find(p)
		var c: Array = clues[i]
		var d_c: TextureRect = d_clues[i]
		
		if c != []:
			var positivity: bool = c[0]
			if positivity:
				p.set_texture(GlobalStash.Positive)
			else:
				p.set_texture(GlobalStash.Negative)
			
			var clue_id: String = c[1]
			d_c.set_texture(GlobalStash.get("%sClue" % clue_id))
			
			
func _on_Finger_gui_input(event: InputEvent) -> void:
	# When the question mark is pressed, makes the player guess the murderer as
	# the current suspect that is in the frame.
	if event.is_action_pressed("LMB"):
		if can_detect:
			GlobalSound.play_sound("Navigation")
			can_detect = false
			
			var s_name: String = suspects_name_list[0]
			var is_murderer: bool = suspects[s_name]["is_murderer"]
			if is_murderer:
				GlobalTransition.change_notice("U detec right!")
				GlobalSound.play_sound("Win")
			else:
				GlobalTransition.change_notice("U detec wrong!")
				GlobalSound.play_sound("Lose")
			
			# Controls the transition.
			GlobalTransition.change_icon(null)
			GlobalTransition.fade_out()
			yield(GlobalTransition, "faded_out")
			
			# Changes the scene after the timeout.
			$MenuTimer.start()
			yield($MenuTimer, "timeout")
			var ms: Control = menu_scene.instance()
			get_parent().call_deferred("add_child", ms)
			queue_free()
			

func _on_Finger_mouse_entered() -> void:
	# Controls modulation.
	$M/V/H2/V2/Finger.self_modulate = GlobalStash.mouse_enter_modulate


func _on_Finger_mouse_exited() -> void:
	# Controls modulation.
	$M/V/H2/V2/Finger.self_modulate = GlobalStash.mouse_exit_modulate
	
	
func _on_LeftArrow_gui_input(event: InputEvent) -> void:
	# Changes the current suspect with the one before the current one.
	if event.is_action_pressed("LMB"):
		if can_detect:
			GlobalSound.play_sound("Navigation")
			suspects_name_list.append(suspects_name_list.pop_front())
			
			var s_name: String = suspects_name_list[0]
			change_suspect_frame(s_name)
			change_suspect_clues(suspects[s_name]["clues"])


func _on_RightArrow_gui_input(event: InputEvent) -> void:
	# Changes the current suspect with the one after the current one.
	if event.is_action_pressed("LMB"):
		if can_detect:
			GlobalSound.play_sound("Navigation")
			suspects_name_list.insert(0, suspects_name_list.pop_back())
			
			var s_name: String = suspects_name_list[0]
			change_suspect_frame(s_name)
			change_suspect_clues(suspects[s_name]["clues"])


func _on_LeftArrow_mouse_entered() -> void:
	# Controls modulation.
	$M/V/H3/LeftArrow.self_modulate = GlobalStash.mouse_enter_modulate


func _on_LeftArrow_mouse_exited() -> void:
	# Controls modulation.
	$M/V/H3/LeftArrow.self_modulate = GlobalStash.mouse_exit_modulate


func _on_RightArrow_mouse_entered() -> void:
	# Controls modulation.
	$M/V/H3/RightArrow.self_modulate = GlobalStash.mouse_enter_modulate


func _on_RightArrow_mouse_exited() -> void:
	# Controls modulation.
	$M/V/H3/RightArrow.self_modulate = GlobalStash.mouse_exit_modulate
