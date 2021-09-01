extends Pawn


"""
	This script controls the `Actor` actions which is the entity that the player
	controls and clears the level with.
"""


signal turn_skipped

var can_move: bool = true

onready var Floor: TileMap = get_parent()
onready var Face: RayCast2D = $Face
onready var Tw: Tween = $MovementTween
	

func _ready() -> void:
	initialize_timers()


func _process(_delta) -> void:
	actor_movement()


func initialize_timers() -> void:
	# Initializes the timers.
	var s_dur: float = GlobalStash.skip_duration
	var m_dur: float = GlobalStash.actor_movement_duration
	$ActionTimer.set_wait_time(s_dur)
	$SkipTimer.set_wait_time(s_dur + m_dur)


func actor_movement() -> void:
	# Controls the actor movement.
	if can_move and not GlobalTransition.is_transitioning:
		# Checks if the turn was frozen by the player input.
		var turn_freeze: bool = check_turn_skip()
		if turn_freeze:
			skip_turn(false)
			return
		
		# Gets the input direction.
		var input_direction: Vector2 = get_input_direction()
		if not input_direction:
			return
		
		# Updates look direction and tries to move to the `target_position`.
		update_look_direction(input_direction)
		var target_position: Vector2 = Floor.request_move(self, input_direction)
		if target_position:
			move_to(target_position)		
		return


func check_turn_skip() -> bool:
	# Checks if the input for the turn freeze is pressed.
	if Input.is_action_just_pressed("Skip"):
		return true
	return false


func skip_turn(movement: bool) -> void:
	# Skips the turn depending on the movement type which either can be true,
	# indicating that this is a normal turn skip, or false, indicating that
	# the turn is skipped by freeze input.
	if movement:
		emit_signal("turn_skipped")
	else:
		can_move = false
		emit_signal("turn_skipped")
		$SkipTimer.start()
		yield($SkipTimer, "timeout")
		finish_turn()

	
func get_input_direction() -> Vector2:
	# Gets the player's input direction.
	if Input.is_action_just_pressed("Right") or \
			Input.is_action_just_pressed("Left"):
		return Vector2(
			int(Input.is_action_just_pressed("Right")) - \
			int(Input.is_action_just_pressed("Left")),
			0
		)
	elif Input.is_action_just_pressed("Down") or \
			Input.is_action_just_pressed("Up"):
		return Vector2(
			0,
			int(Input.is_action_just_pressed("Down")) - \
			int(Input.is_action_just_pressed("Up"))
		)
	else:
		return Vector2(0, 0)


func update_look_direction(direction: Vector2) -> void:
	# Updates `Face` direction depending on the input direction. `Face` controls
	# certain actions such as eliminating an enemy or pushing a box.
	$Face.cast_to = direction * GlobalStash.TILE_SIZE
	$Face.force_raycast_update()


func move_to(target_position: Vector2) -> void:
	# Moves to the `target_position` by interpolation.
	Tw.interpolate_property(
		self, "position", position, target_position,
		GlobalStash.actor_movement_duration, 
		Tween.TRANS_SINE, Tween.EASE_OUT, 0
		)
	Tw.start()


func finish_turn() -> void:
	# Makes the player eligible to move after a turn is finished.
	print("Turn finished ...")
	can_move = true


func _on_MovementTween_tween_started(object: Object, key: NodePath) -> void:
	# Triggered when `move_to` is called.
	if object == self:
		match key:
			NodePath(":position"):
				can_move = false


func _on_MovementTween_tween_completed(object: Object, key: NodePath) -> void:
	# Triggered when movement by interpolation has ended.
	if object == self:
		match key:
			NodePath(":position"):
				skip_turn(true)
				$ActionTimer.start()
				yield($ActionTimer, "timeout")
				finish_turn()
