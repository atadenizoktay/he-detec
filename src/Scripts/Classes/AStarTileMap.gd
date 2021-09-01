class_name AStarTileMap
extends TileMap


"""
	This script (class) is a base class for the `Floor`.
"""


var occupied_cells: Array

onready var astar: AStar2D = AStar2D.new()

	
func initialize_points() -> void:
	# Initializes `astar` points.
	occupied_cells = get_used_cells()
	for cell in occupied_cells:
		var cell_id: int = generate_cell_id(cell)
		astar.add_point(cell_id, cell, 1)
	
	
func unite_points() -> void:
	# Connects the points of `astar` later to create paths with.
	var neighbors: Array = [
		Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN
	]
	for cell in occupied_cells:
		for n in neighbors:
			# Checking if the cell that is trying to be united is inside the
			# borders.
			var next_cell: Vector2 = cell + n
			var x_in_range: bool = Helpers.in_range(-1, 8, next_cell.x)
			var y_in_range: bool = Helpers.in_range(-1, 8, next_cell.y)
			
			if x_in_range and y_in_range:
				if occupied_cells.has(next_cell):
					var cell_id_1: int = generate_cell_id(cell)
					var cell_id_2: int = generate_cell_id(next_cell)
					astar.connect_points(cell_id_1, cell_id_2, false)
	

func get_path_points(start: Vector2, end: Vector2) -> PoolVector2Array:
	# Gets `path_points` which will be used to check path blockage.
	var start_cell_id: int = generate_cell_id(start)
	var end_cell_id: int = generate_cell_id(end)
	var path_points: PoolVector2Array = astar.get_point_path(
		start_cell_id, end_cell_id
	)
	path_points.remove(0)
	return path_points
	
	
func generate_cell_id(cell: Vector2) -> int:
	# Generates an id for the input cell by utilizing the Cantor pairing
	# function.
	var x: float = cell.x
	var y: float = cell.y
	return int((x + y) * (x + y + 1) / 2 + y)

