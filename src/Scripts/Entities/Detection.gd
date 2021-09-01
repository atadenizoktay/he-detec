extends Area2D


"""
	This script controls the `Detection` scenes which are created and instanced
	by the `Enemy` scenes, that will try to detect the `Actor`.
"""


var level: Node2D
var actor: KinematicBody2D


func _ready() -> void:
	initialize_discoveries()
	initialize_signals()


func initialize_discoveries() -> void:
	# Initializes the node discoveries.
	level = get_tree().get_nodes_in_group("Level")[-1]
	actor = get_tree().get_nodes_in_group("Actor")[-1]


func initialize_signals() -> void:
	# Initializes the signals.
	var c_err: int = actor.connect("turn_skipped", self, "try_to_detect")
	if c_err != OK:
		print("Failed to connect signal for %s" % name)


func try_to_detect() -> void:
	# Checks the overlapping bodies of the detection area, and tries to detect
	# the `Actor`.
	var bodies: Array = get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("Actor"):
			if level.can_restart:
				level.restart_level("Detect")
			return
	queue_free()
