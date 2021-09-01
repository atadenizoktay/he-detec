extends Pawn


"""
	This script controls the `BasicBox` actions which are the boxes in Sokoban
	levels that are pushable by the `Actor`.
"""


export(Texture) var box_texture: Texture

onready var Floor: TileMap = get_parent()


func _ready() -> void:
	initialize_box()
	

func initialize_box() -> void:
	# Initializes the `BasicBox` texture.
	$Sprite.set_texture(box_texture)
	

func box_movement(push_direction: Vector2) -> bool:
	# Controls the movement of the box depending on the feedback from the
	# `Floor`.
	var target_position: Vector2 = Floor.request_move(self, push_direction)
	if target_position:
		move_to(target_position)
		return true
	return false


func move_to(target_position: Vector2) -> void:
	# Moves to the `target_position` by interpolation.
	$MovementTween.interpolate_property(
		self, "position", position, target_position,
		GlobalStash.box_movement_duration, 
		Tween.TRANS_SINE, Tween.EASE_OUT, 0
		)
	$MovementTween.start()
