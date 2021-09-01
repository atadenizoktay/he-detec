extends Control


"""
	This script controls the main menu.
"""


var can_start: bool = false


func _ready() -> void:
	GlobalStash.initialize_clues()
	initialize_bgm()
	control_transition()
	

func initialize_bgm() -> void:
	# Initializes the background music when the scene is loaded.
	GlobalSound.change_game_state("Menu")


func control_transition() -> void:
	# Controls the initial transition when the scene is loaded.
	$DelayTimer.start()
	yield($DelayTimer, "timeout")
	GlobalTransition.fade_in()
	yield(GlobalTransition, "faded_in")
	can_start = true
	

func _on_Start_gui_input(event: InputEvent) -> void:
	# Starts the game after the start button is pressed.
	if event.is_action_pressed("LMB"):
		if can_start:
			GlobalSound.play_sound("Navigation")
			can_start = false
			
			# Controls the transition.
			GlobalTransition.change_notice("There's been a murder!")
			GlobalTransition.change_icon(null)
			GlobalTransition.fade_out()
			yield(GlobalTransition, "faded_out")
			
			# Changes the scene after the timeout.
			$StartTimer.start()
			yield($StartTimer, "timeout")
			var first_scene: PackedScene = load("res://src/Scenes/Stages/Stealth1.tscn")
			var fs: Node2D = first_scene.instance()
			get_parent().call_deferred("add_child", fs)
			queue_free()


func _on_Start_mouse_entered() -> void:
	# Controls modulation.
	$M/V/H2/Start.self_modulate = GlobalStash.mouse_enter_modulate


func _on_Start_mouse_exited() -> void:
	# Controls modulation.
	$M/V/H2/Start.self_modulate = GlobalStash.mouse_exit_modulate
