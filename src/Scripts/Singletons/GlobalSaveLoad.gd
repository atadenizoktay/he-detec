extends Node


"""
	This script was used to save the game state, but it is no longer utilized.
"""


const UNDO_PATH: String = "user://undo.sav"


func save_level_layout(level_id: int) -> void:
	# Saves the level layout.
	var save_data: Dictionary = {level_id: {}}

	var entities: Array = get_tree().get_nodes_in_group("Entity")
	for entity in entities:
		save_data[level_id][get_path_to(entity)] = {
			"cell_position": entity.position,
		}
	
	var save_data_as_string: String = var2str(save_data)
	var save_file: File = File.new()
	var err: int = save_file.open(UNDO_PATH, File.WRITE)
	if err != OK:
		print("Could not save file at %s" % UNDO_PATH)

	save_file.store_string(save_data_as_string)
	save_file.close()


func load_level_layout(level_id: int) -> void:
	# Loads the level layout.
	var save_file: File =  File.new()
	var err: int = save_file.open(UNDO_PATH, File.READ)
	if err != OK:
		print("Could not load file at %s" % UNDO_PATH)
		return
	
	var load_data: Dictionary = str2var(save_file.get_as_text())
	save_file.close()
	
	if level_id in load_data.keys():
		var entities: Array = get_tree().get_nodes_in_group("Entity")
		for entity in entities:
			var path: NodePath = get_path_to(entity)
			if load_data[level_id].has(path):
				var Floor: TileMap = entity.get_parent()
				var loaded_entity_position: Vector2 = load_data[level_id] \
						[path]["cell_position"]
				Floor.set_cellv(Floor.world_to_map(entity.position), -1)
				Floor.set_cellv(Floor.world_to_map(
					loaded_entity_position), entity.cell_type
				)
				entity.position = loaded_entity_position
