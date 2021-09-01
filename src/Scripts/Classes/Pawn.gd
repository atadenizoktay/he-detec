class_name Pawn
extends KinematicBody2D


"""
	This script (class) is a base class for entities such as the `Actor`, the
	`BasicBox`, and the `Enemy`.
"""

enum CELL_TYPES {
	EMPTY = -1,
	ACTOR = 0,
	WALL = 1,
	BOX = 2,
	ENEMY = 3,
	GRASS = 4
}

export(CELL_TYPES) var cell_type = CELL_TYPES.ACTOR

