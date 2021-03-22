extends State

"""
In the Wander state a character will pick a random location within it's home radius
and move to it, before waiting a few seconds, and repeating the process.
"""

var min_distance = 16
var floormap
var valid_cells


func enter(entity, _optional_args=null):
	randomize()
	# Generate the home area from the initial position and the home radius
	floormap = entity.tilemap.get_node("Floor")
	var floormap_cells = floormap.get_used_cells()
	# Remove any cells outside of the home radius
	for _cell in floormap_cells:
		if _cell.distance_to(entity.init_position) > entity.HOME_RADIUS:
			continue
		elif _cell.distance_to(entity.init_position) < min_distance:
			continue
		else:
			valid_cells.append(_cell)


func get_new_wander_cell():
	randomize()
	var random_index = int(rand_range(0.0, valid_cells.size()))
	
	return valid_cells[random_index]


func handle_input(entity, _delta):
	var states_node = entity.get_node("StateMachine/States")
	# TODO
	# Character selected by player: IdleState -> ControlledState
	#
	# Character recruited by player: IdleState -> FollowState
	#
	
	# 


func exit(_entity):
	pass

