extends State

"""
In the Idle state a character will wait a set amount of time before either switching
to a new state as it's critera are met, or ending their turn.

This state is effectively an intermediary/observer state that a character should
default to until a more appropriate state can be switched to. 
"""


func enter(entity, _optional_args=null):
	# Stop any movement
	entity.velocity = Vector2.ZERO
	# Play the idle animation
	entity.anim_tree["parameters/playback"].travel("Idle")

func handle_input(entity, _delta):
	var states_node = entity.get_node("StateMachine/States")
	# TODO
	# Character selected by player: IdleState -> ControlledState
	#
	# Character recruited by player: IdleState -> FollowState
	#


func exit(_entity):
	pass

