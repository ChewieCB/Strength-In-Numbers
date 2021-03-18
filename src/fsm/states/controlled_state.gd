extends State

"""
"""


func enter(entity, _optional_args=null):
	# Clear the currently controlled character
	# (This group should only ever have one character in it)
	var controlled_characters = get_tree().get_nodes_in_group("controlled_characters")
	for character in controlled_characters:
		if character == entity:
			continue
		character.remove_from_group("controlled_characters")
	# Assign the new character as the controlled character
	entity.add_to_group("controlled_characters")
	# Deal with the moodle animation
	var moodle_anim = entity.get_node("Moodle/AnimationPlayer")
	if moodle_anim.current_animation == "recruitable_popup" or \
	moodle_anim.current_animation == "recruitable_idle":
		moodle_anim.play("recruitable_fadeout")
	# Set the selector sprite
	var selector = entity.get_node("Sprites/Selector")
	selector.texture = entity.selector_sprite_select
	selector.visible = true
	# Make the controlle character's camera to be the active camera
	entity.get_node("Camera2D").current = true


func handle_input(entity, _delta):
	var state_machine = entity.get_node("StateMachine")
	var states_node = state_machine.get_node("States")
	
	if entity.is_in_group("controlled_characters"):
		get_player_movement(entity)
		get_player_actions(entity)
	elif entity.is_in_group("recruited_characters"):
		return states_node.find_node("FollowState")
	else:
		return state_machine.default_state


func get_player_movement(entity):
	# Clear the current velocity
	entity.velocity = Vector2.ZERO
	entity.direction = Vector2.ZERO
	# Get user input
	if Input.is_action_pressed('right'):
		entity.direction.x += 1
	if Input.is_action_pressed('left'):
		entity.direction.x -= 1
	if Input.is_action_pressed('down'):
		entity.direction.y += 1
	if Input.is_action_pressed('up'):
		entity.direction.y -= 1
	# Apply the input velocity
	if entity.direction != Vector2.ZERO:
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


func get_player_actions(entity):
	if Input.is_action_just_pressed("recruit"):
		var humans = get_tree().get_nodes_in_group("humans")
		for human in humans:
			if human == entity:
				continue
			if not human.is_in_group("recruited_characters") and \
			human.global_position.distance_to(entity.global_position) <= entity.recruit_radius:
				human.add_to_group("recruited_characters")
				human.state_machine.set_state(human.state_machine.get_node("States/FollowState"), entity)
	elif Input.is_action_just_pressed("release"):
		var humans = get_tree().get_nodes_in_group("humans")
		for human in humans:
			if human == entity:
				continue
			if human.is_in_group("recruited_characters"):
				human.remove_from_group("recruited_characters")
				human.state_machine.set_state(human.state_machine.get_node("States/IdleState"), entity)


func exit(entity):
	if entity.is_in_group("controlled_character"):
		entity.remove_from_group("controlled_character")
	# TODO - add entity to recruited characters if they aren't already
	# and are close enough to the controlled character
	
	# Set the selector sprite
	var selector = entity.get_node("Sprites/Selector")
	selector.texture = entity.selector_sprite_hover
	selector.visible = false

