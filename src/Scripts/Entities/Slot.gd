extends Area2D


"""
	This script controls the `Slot` scene which is related to the slots the
	player pushes boxes into.
"""


export(Texture) var slot_texture: Texture

var level: Node2D


func _ready() -> void:
	initialize_slot()
	initialize_discoveries()
	initialize_signals()
	

func initialize_slot() -> void:
	# Initializes the `Slot` texture.
	$Sprite.set_texture(slot_texture)
	
	
func initialize_discoveries() -> void:
	# Initializes the node discoveries.
	level = get_tree().get_nodes_in_group("Level")[-1]
	

func initialize_signals() -> void:
	# Initializes the signals.
	var c_err_enter: int = connect(
		"body_entered", level, "update_slot_status_enter"
	)
	var c_err_exit: int = connect(
		"body_exited", level, "update_slot_status_exit"
	)
	if c_err_enter != OK or c_err_exit != OK:
		print("Failed to connect a signal for %s" % name)
