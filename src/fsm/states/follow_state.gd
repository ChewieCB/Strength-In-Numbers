extends State

"""
"""

var controlled_characters
var leader


func enter(entity, _optional_args=null):
	# Play the recruited popup
	entity.moodle.get_node("AnimationPlayer").play("recruited_popup")
	controlled_characters = get_tree().get_nodes_in_group("controlled_characters")
	# Set the selector sprite
	var selector = entity.get_node("Sprites/Selector")
	selector.texture = entity.selector_sprite_follow
	selector.visible = true
	#
	if len(controlled_characters) > 0:
		leader = _optional_args


func handle_input(entity, _delta):
	var states_node = entity.get_node("StateMachine/States")
	
	if len(controlled_characters) == 0:
		return states_node.get_node("IdleState")
	elif not leader:
		find_leader()
	else:
		# Clear the current velocity
		entity.velocity = Vector2.ZERO
		entity.direction = Vector2.ZERO
		var look = entity.get_node("RayCast2D")
		# If the character is too close to the leader, back up to give them space
		if leader.position.distance_to(entity.position) <= leader.nogo_radius:
			entity.direction = -(leader.position - entity.position)
			look.cast_to = -(leader.position - entity.position)
			print()
		else:
			# Raycast to find the leader or their scent trail
			look.cast_to = (leader.position - entity.position)
			look.force_raycast_update()
			# If we can see the leader, move towards them
			if not look.is_colliding():
				entity.direction = look.cast_to.normalized()
			# If we can see the leader's scent trail, follow that
			else:
				for scent in leader.scent_trail:
					look.cast_to = (scent.position - entity.position)
					look.force_raycast_update()
					
					if not look.is_colliding():
						entity.direction = look.cast_to.normalized()
						break
		# Apply the input velocity
		if entity.direction != Vector2.ZERO:
			if leader.position.distance_to(entity.position) <= leader.follow_radius and \
			leader.position.distance_to(entity.position) >= leader.nogo_radius:
				entity.velocity = lerp(
					entity.velocity, 
					Vector2.ZERO, 
					entity.friction
				)
			else:
				entity.velocity = lerp(
					entity.velocity, 
					entity.direction.normalized() * entity.movement_speed, 
					entity.acceleration
				)
		else:
			entity.velocity = lerp(
				entity.velocity, 
				Vector2.ZERO, 
				entity.friction
			)


func find_leader():
	leader = get_tree().get_nodes_in_group("controlled_characters")[0]


func exit(entity):
	# Set the selector sprite
	var selector = entity.get_node("Sprites/Selector")
	selector.texture = entity.selector_sprite_hover
	selector.visible = false
