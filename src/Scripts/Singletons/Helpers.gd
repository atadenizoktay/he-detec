extends Node


static func arr_suc(arr: Array) -> Array:
	# Successor function for arrays.
	var new_arr: Array = []
	for i in arr:
		var val: float = i / abs(i) if i != 0 else 0
		new_arr.append(i + val)
	return new_arr


static func rand_color(alpha: float) -> Color:
	# Returns a random color with the given `alpha` value as the color alpha
	# value between 0 and 1.
	randomize()
	return Color(randf(), randf(), randf(), fmod(alpha, 1))


static func in_range(start: float, end: float, num: float) -> bool:
	# Checks whether the given number `num` is in the given range that starts
	# with `start`, and ends with `end`.
	if start < num and num < end:
		return true
	return false
	

static func vec_sim_x_y(vec1: Vector2, vec2: Vector2) -> bool:
	# Checks whether the x or y property of the two given vectors (`vec1` and
	# `vec2`) are the same but the vectors are different. This function is used
	# to determine if the line that connects the two vectors is straight.
	if vec1.x == vec2.x or \
			vec1.y == vec2.y and \
			vec1 != vec2:
		return true
	return false


static func all_true_dict(dict: Dictionary) -> bool:
	# Checks whether all the values of keys in a dictionary are true or not.
	var values: Array = Array(dict.values())
	for v in values:
		if v != true:
			return false
	return true
