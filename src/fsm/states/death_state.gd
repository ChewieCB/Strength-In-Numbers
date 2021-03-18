extends State

"""
"""


func enter(entity, _optional_args=null):
	randomize()
	# Stop any player movement
	entity.velocity = Vector2.ZERO
	#
#	death(entity)
	death(entity)
	entity.add_to_group("dead_characters")


func death(entity):
	# Play a death sound
	var death_sound = entity.death_sounds.pop_front()
	var audio_player = entity.get_node("SFX")
	audio_player.stream = death_sound
	audio_player.pitch_scale = rand_range(0.7, 1.2)
	audio_player.play()
	entity.death_sounds.push_back(death_sound)
	# Emit blood and gore particles
	entity.get_node("GibEmitter").emitting = true
	entity.get_node("BloodEmitter").emitting = true
	
	yield(get_tree(), "idle_frame")
	
	# Remove all nodes except the camera and state logic
	var exempt_node_types = [
		"Camera2D",
		"AnimationPlayer", "AnimationTree",
		"StateMachine", "State",
		"Particles2D",
		"AudioStreamPlayer2D",
	]
	for node in entity.get_children():
		if node.get_class() in exempt_node_types:
			continue
		else:
			node.queue_free()
	


