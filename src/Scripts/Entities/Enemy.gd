extends Pawn


"""
	This script controls the `Enemy` actions which are entities that have
	different movement and detection properties they utilize to try to detect
	the `Actor`.
"""


enum ENEMY_ATTACK_TYPES {
	STRAIGHT,
	CLEAVE
}
enum ENEMY_TRIGGER_TYPES {
	STEP,
	STEP_HEAD
}
enum ENEMY_ROAM_TYPES {
	STATIC,
	STRAIGHT
}
enum ENEMY_ROAM_START_DIRECTIONS {
	LEFT,
	RIGHT,
	UP,
	DOWN
}
enum ENEMY_COOLDOWN_TYPES {
	COOLDOWN,
	NO_COOLDOWN
}

export(ENEMY_ATTACK_TYPES) var enemy_attack_type: int
export(ENEMY_TRIGGER_TYPES) var enemy_trigger_type: int
export(int, 1, 10) var enemy_attack_range: int
export(ENEMY_ROAM_TYPES) var enemy_roam_type: int
export(ENEMY_ROAM_START_DIRECTIONS) var enemy_roam_start_direction: int
export(ENEMY_COOLDOWN_TYPES) var enemy_cooldown_type: int
export(Texture) var enemy_texture: Texture

var actor: KinematicBody2D
var enemy_look_direction: Vector2
var just_detected: bool = false

onready var trigger_scn: PackedScene = preload("res://src/Scenes/" + \
		"Entities/Trigger.tscn")
onready var detection_scn: PackedScene = preload("res://src/Scenes/" + \
		"Entities/Detection.tscn")
onready var Floor: TileMap = get_parent()


func _ready() -> void:
	initialize_enemy()
	initialize_discoveries()
	initialize_triggers(enemy_attack_type, enemy_trigger_type)
	initialize_roaming(enemy_roam_start_direction)


func initialize_enemy() -> void:
	# Initializes the `Enemy` texture.
	if enemy_texture != null:
		$Sprite.set_texture(enemy_texture)
	
	
func initialize_discoveries() -> void:
	# Initializes the node discoveries.
	actor = get_tree().get_nodes_in_group("Actor")[-1]
	var c_err: int = actor.connect("turn_skipped", self, "control_action")
	if c_err != OK:
		print("Failed to connect signal for %s" % name)

			
func initialize_triggers(a_type: int, t_type: int) -> void:
	# Each `Enemy` has a trigger area that consists of `Trigger` scenes. The
	# `Enemy` is triggered when the `Actor` moves into a `Trigger` scene of the
	# `Enemy` and tries to detect the player. This function initializes the
	# `Trigger` areas each enemy has depending on its detection properties.
	var r_col: Color = Helpers.rand_color(0.2)
	var a_range: int = enemy_attack_range
	
	# Checks the attack type of the `Enemy`, and initializes `Trigger` scenes 
	# according to it.
	match a_type:
		ENEMY_ATTACK_TYPES.STRAIGHT:
			var a_arr: Array = [0, 1, 0, -1]
			create_triggers(a_arr, a_range, r_col, "")
		ENEMY_ATTACK_TYPES.CLEAVE:
			var a_arr_1: Array = [0, 1, 0, -1]
			var a_arr_2: Array = [1, -1, -1, 1]
			create_triggers(a_arr_1, 1, r_col, "")
			create_triggers(a_arr_2, 1, r_col, "Cleave")
	
	# Checks the trigger type of the `Enemy`, and initializes additional
	# `Trigger` scenes according to it.
	match t_type:
		ENEMY_TRIGGER_TYPES.STEP:
			pass
		ENEMY_TRIGGER_TYPES.STEP_HEAD:
			var t_arr: Array = [0, a_range + 1, 0, -a_range - 1]
			create_triggers(t_arr, 1, r_col, "Head")


func create_triggers(arr: Array, length: int, color: Color, id: String) -> void:
	# Creates the `Trigger` areas that were initialized in the
	# `initialize_triggers` function before
	for _i in range(length):
		for _j in range(4):
			var t_vec: Vector2 = Vector2(arr[0], arr[1])
			t_vec *= GlobalStash.TILE_SIZE_VECTOR
			var t: Area2D = trigger_scn.instance()
			$Triggers.add_child(t)
			t.global_position = global_position + t_vec
			t.get_node("Sprite").self_modulate = color
			t.name = t.name + id if id else t.name
			arr.append(arr.pop_front())
		arr = Helpers.arr_suc(arr)


func initialize_roaming(r_s_dir: int) -> void:
	# Initializes roaming.
	match r_s_dir:
		ENEMY_ROAM_START_DIRECTIONS.LEFT:
			enemy_look_direction = Vector2(-1, 0)
		ENEMY_ROAM_START_DIRECTIONS.RIGHT:
			enemy_look_direction = Vector2(1, 0)
		ENEMY_ROAM_START_DIRECTIONS.UP:
			enemy_look_direction = Vector2(0, -1)
		ENEMY_ROAM_START_DIRECTIONS.DOWN:
			enemy_look_direction = Vector2(0, 1)
	
			
func control_action() -> void:
	# Controls the `Enemy` action depending on if the `Enemy` is detecting or
	# just detected.
	if $Detections.get_child_count() != 0:
		return
	
	# Checks the cooldown property of the `Enemy` and controls it.
	match enemy_cooldown_type:
		ENEMY_COOLDOWN_TYPES.COOLDOWN:
			if just_detected:
				just_detected = false
				$Sprite.self_modulate = Color.white
				return
		ENEMY_COOLDOWN_TYPES.NO_COOLDOWN:
			just_detected = false
			$Sprite.self_modulate = Color.white

	# Checking if the `Trigger` scenes are colliding with the `Actor`.
	var trigger: bool
	var cleave: bool
	for t in $Triggers.get_children():
		if actor in t.get_overlapping_bodies():
			trigger = true
			cleave = "Cleave" in t.name
			break
	
	if trigger:
		# Checking if there are any obstacles between the `Actor` and the
		# `Enemy`.
		var path_blockage_info: Dictionary = Floor.check_path_blockage(
			self, actor, cleave
		)
		var path_is_blocked: bool = path_blockage_info["is_blocked"]
		var path_points: PoolVector2Array = path_blockage_info["points"]

		if not path_is_blocked:
			# Will create detection areas if the path is not blocked.
			create_detections(enemy_attack_type, path_points)
			return
	
	# If triggers are not colliding with the `Actor`, `Enemy` roams.
	var r_type: int = enemy_roam_type
	match r_type:
		ENEMY_ROAM_TYPES.STATIC:
			pass
		ENEMY_ROAM_TYPES.STRAIGHT:
			enemy_straight_movement()


func create_detections(a_type: int, path_points: PoolVector2Array) -> void:
	# Creates `Detection` depending on the attack type (`a_type`) of the `Enemy`
	# and the detection path (`path_points`).
	just_detected = true
	$Sprite.self_modulate = GlobalStash.enemy_cooldown_modulate

	var d_points: Array = []
	match a_type:
		ENEMY_ATTACK_TYPES.STRAIGHT:
			var d_dir: Vector2 = (path_points[-1] - \
					Floor.world_to_map(self.position)).normalized()
			for t in $Triggers.get_children():
				var t_dir: Vector2 = (t.global_position - global_position) \
						.normalized()
				if not "Head" in t.name and \
						d_dir == t_dir:
					# Checks if the `Trigger` is a head-trigger or not. Head
					# triggers are only for triggering purposes and are not
					# bases for `Detection` scenes.
					d_points.append(t.global_position)
		ENEMY_ATTACK_TYPES.CLEAVE:
			var straight: bool = Helpers.vec_sim_x_y(
				path_points[-1], Floor.world_to_map(self.position)
			)
			if straight:
				# If the path from the `Enemy` to the `Actor` is straight.
				var d_dir: Vector2 = (path_points[0] - \
						Floor.world_to_map(self.position)).normalized()
				for t in $Triggers.get_children():
					var t_dir: Vector2 = (t.global_position - global_position) \
							.normalized()
					if not "Head" in t.name and \
							d_dir == t_dir:
						# Checks if the `Trigger` is a head-trigger or not. Head
						# triggers are only for triggering purposes and are not
						# bases for `Detection` scenes.
						d_points.append(t.global_position)
						
						var ts: int = GlobalStash.TILE_SIZE
						if t_dir.y == 0:
							d_points.append(t.global_position + \
									Vector2.UP * ts)
							d_points.append(t.global_position + \
									Vector2.DOWN * ts)
						elif t_dir.x == 0:
							d_points.append(t.global_position + \
									Vector2.RIGHT * ts)
							d_points.append(t.global_position + \
									Vector2.LEFT * ts)
			else:
				# If the path from the `Enemy` to the `Actor` is not straight.
				var p_pos: Vector2 = Floor.map_to_world(path_points[-1]) + \
						Floor.cell_size / 2
				d_points = [
					Vector2(global_position.x, p_pos.y),
					Vector2(p_pos.x, global_position.y),
					p_pos
				]
	
	# Instances and adds detection points (`d_points`).
	for p in d_points:
		var d: Area2D = detection_scn.instance()
		$Detections.add_child(d)
		d.global_position = p


func enemy_straight_movement() -> void:
	# Makes the `Enemy` roam on a straight line if the target cell is not
	# blocked.
	var target_position: Vector2 = Floor.request_move(
		self, enemy_look_direction
	)
	if target_position:
		move_to(target_position)
	else:
		enemy_look_direction *= -1
		target_position = Floor.request_move(self, enemy_look_direction)
		if target_position:
			move_to(target_position)
	return


func move_to(target_position: Vector2) -> void:
	# Moves to the `target_position` by interpolation.
	$MovementTween.interpolate_property(
		self, "position", position, target_position,
		GlobalStash.box_movement_duration, 
		Tween.TRANS_SINE, Tween.EASE_OUT, 0
		)
	$MovementTween.start()
