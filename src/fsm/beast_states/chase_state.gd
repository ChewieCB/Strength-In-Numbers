extends State

""" 
"""

var target

func enter(entity, _optional_args=null):
	# Play the idle animation
	entity.anim_playback.travel("Chase")
	target = entity.target


func handle_input(entity, _delta):
	if not target:
		# TODO - exit state
		return
	else:
		# Clear the current velocity
		entity.velocity = Vector2.ZERO
		entity.direction = Vector2.ZERO
		# Path to the target
		var nav_path = entity.tilemap_nav.get_simple_path(entity.position, target.position)
		# Convert the path points from local space to global space for the draw func
		var path_line_points = []
		for _point in nav_path:
			var _global_point = _point - entity.global_position
			path_line_points.append(_global_point)
		var path_line = entity.get_node("Line2D")
		path_line.points = path_line_points
		
		# Move towards the target
		# Point the viewcone towards the next point
		entity.raycast.cast_to = nav_path[1] - entity.global_position
		
		# Calculate the movement distance for this frame
		var distance_to_walk = entity.movement_speed * _delta
		
		# Move the player along the path until he has run out of movement or the path ends.
		while distance_to_walk > 0 and nav_path.size() > 0:
			var distance_to_next_point = entity.position.distance_to(nav_path[0])
			if distance_to_walk <= distance_to_next_point:
				# The player does not have enough movement left to get to the next point.
				entity.position += entity.position.direction_to(nav_path[0]) * distance_to_walk
			else:
				# The player get to the next point
				position = nav_path[0]
				nav_path.remove(0)
			# Update the distance to walk
			distance_to_walk -= distance_to_next_point


func exit(_entity):
	pass

