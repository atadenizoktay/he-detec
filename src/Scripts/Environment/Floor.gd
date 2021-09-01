extends AStarTileMap


"""
	This script controls all the tile-based actions the entities take during
	each playable level.
"""


enum CELL_TYPES {
	EMPTY = -1,
	ACTOR = 0,
	WALL = 1,
	BOX = 2,
	ENEMY= 3,
	GRASS = 4
}


func _ready() -> void:
	make_layout_transparent()
	recognize_children()
	initialize_points()
	unite_points()


func make_layout_transparent() -> void:
	# Makes the tilemap layout transparent since the levels have their own
	# sprites for layouts instead of utilizing a tilemap of individual sprite
	# cells.
	var tile_ids: Array = tile_set.get_tiles_ids()
	for id in tile_ids:
		tile_set.tile_set_modulate(id, Color.transparent)
#		tile_set.tile_set_modulate(id, Color(1, 1, 1, 1))
		# Remove the comment above to make the default tiles non-transparent
		# if you'd like to test new levels.
	
	
func recognize_children() -> void:
	# Recognizes all tilemap cells and maps them.
	for child in get_children():
		set_cellv(world_to_map(child.position), child.cell_type)


func request_move(pawn: Object, direction: Vector2) -> Vector2:
	# This function is utilized when an entity requests to move to a cell.
	var cell_start: Vector2 = world_to_map(pawn.position)
	var cell_target: Vector2 = cell_start + direction
	
	var cell_target_type = get_cellv(cell_target)
	var cell_target_to_str: String = \
			GlobalStash.CELL_TYPE_TO_STR[cell_target_type]
	
	# Each request may result in different outcomes depending on the entity
	# that requests the move, and the type of cell that movement is requested 
	# to.
	var movement_status: String
	match cell_target_type:
		CELL_TYPES.EMPTY:
			pass
		CELL_TYPES.GRASS:
			if pawn.cell_type == CELL_TYPES.ACTOR:
				GlobalSound.play_sound("Walk")
			
			# Checking if the cell that the movement is requested to is inside
			# borders.
			var x_in_range: bool = Helpers.in_range(-1, 8, cell_target.x)
			var y_in_range: bool = Helpers.in_range(-1, 8, cell_target.y)
			
			if x_in_range and y_in_range:
				movement_status = "Moving ..."
				print_movement_report(
					pawn.name,
					cell_target_to_str,
					str(cell_target),
					movement_status
				)
				return update_pawn_position(pawn, cell_start, cell_target)
		CELL_TYPES.ACTOR:
			pass
		CELL_TYPES.WALL:
			pass
		CELL_TYPES.BOX:
			if pawn.cell_type == CELL_TYPES.ACTOR:
				# Checks if the box is pushable, if so, pushes it.
				var colliding_box: KinematicBody2D = pawn.Face.get_collider()
				var can_push: bool = colliding_box.box_movement(direction)
				
				if can_push:
					GlobalSound.play_sound("Push")
					movement_status = "Pushing ..."
					print_movement_report(
						pawn.name,
						cell_target_to_str,
						str(cell_target),
						movement_status
					)
					return update_pawn_position(pawn, cell_start, cell_target)
		CELL_TYPES.ENEMY:
			if pawn.cell_type == CELL_TYPES.ACTOR:
				var colliding_enemy: KinematicBody2D = pawn.Face.get_collider()
				if not colliding_enemy:
					# This prevents a bug that occurs when too many inputs are
					# given successively.
					return Vector2(0, 0)
				
				GlobalSound.play_sound("Attack")
				colliding_enemy.queue_free()
				
				movement_status = "Eliminating ..."
				print_movement_report(
					pawn.name,
					cell_target_to_str,
					str(cell_target),
					movement_status
				)
				return update_pawn_position(pawn, cell_start, cell_target)
		
	# If blocked and the movement requester is the actor, plays a sound that
	# indicates that the movement was not possible.
	if pawn.cell_type == CELL_TYPES.ACTOR:
		GlobalSound.play_sound("Block")
		
	movement_status = "Blocked ..."
	print_movement_report(
		pawn.name,
		cell_target_to_str,
		str(cell_target),
		movement_status
	)
	return Vector2(0, 0)


func print_movement_report(name: String, target: String, target_c: String, \
		status: String) -> void:
	# Prints the movement report. This is for debugging purposes.
	print("{0} -> {1} @ {2} ... {3}".format({
		0: name,
		1: target,
		2: target_c,
		3: status
	}))


func update_pawn_position(pawn: Object, start: Vector2, \
		target: Vector2) -> Vector2:
	# Updates the pawn position on the world map, and returns that position's
	# global coordinates.
	set_cellv(target, pawn.cell_type)
	set_cellv(start, CELL_TYPES.GRASS)
	return map_to_world(target) + cell_size / 2


func check_path_blockage(t_pawn: Object, c_pawn: Object, \
		cleave: bool) -> Dictionary:
	# Checks if the requested path is blocked.
	var t_pos: Vector2 = world_to_map(t_pawn.position)
	var c_pos: Vector2 = world_to_map(c_pawn.position)
	var path_points: PoolVector2Array = get_path_points(t_pos, c_pos)
	
	var control_1: bool = check_for_obstacles(path_points)
	var control_2: bool = true
	if cleave:
		# If the attack pattern of the `Enemy` is `CLEAVE`, checks an
		# alternative path to see if the path is blocked.
		var p_1: Vector2 = t_pos + path_points[1] - path_points[0]
		var p_2: Vector2 = p_1 + path_points[0] - t_pos
		var alt_path: PoolVector2Array = [p_1, p_2]
		control_2 = check_for_obstacles(alt_path)
	
	# Returns the blockage status.
	if control_1 and control_2:
		return {"is_blocked": true, "points": path_points}
	return {"is_blocked": false, "points": path_points}


func check_for_obstacles(points: PoolVector2Array) -> bool:
	# Checks if there are any obstacles in the path.
	points.remove(points.size() - 1)
	for p in points:
		var cell_i: int = get_cellv(p)
		if cell_i != CELL_TYPES.GRASS:
			return true
	return false
