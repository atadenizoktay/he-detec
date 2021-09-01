extends Area2D


"""
	This script controls the `Skip` scene which is related to the areas which
	the player moves into and clears the stealth levels.
"""


var level: Node2D


func _ready() -> void:
	initialize_discoveries()
	initialize_signals()
	

func initialize_discoveries() -> void:
	# Initializes the node discoveries.
	level = get_tree().get_nodes_in_group("Level")[-1]
	

func initialize_signals() -> void:
	# Initializes the signals.
	var c_err: int = connect("body_entered", level, "update_skip_status_enter")
	if c_err != OK:
		print("Failed to connect signal for %s" % name)
