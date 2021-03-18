extends State

"""
In the Idle state a character will wait a set amount of time before either switching
to a new state as it's critera are met, or ending their turn.

This state is effectively an intermediary/observer state that a character should
default to until a more appropriate state can be switched to. 
"""


func enter(entity, _optional_args=null):
	# Stop any player movement
	entity.velocity = Vector2.ZERO
	# Set the selector sprite
	var selector = entity.get_node("Sprites/Selector")
	selector.texture = entity.selector_sprite_hover
	selector.visible = false


func handle_input(entity, _delta):
	var states_node = entity.get_node("StateMachine/States")
	# TODO
	# Character selected by player: IdleState -> ControlledState
	#
	# Character recruited by player: IdleState -> FollowState
	#


func exit(_entity):
	pass

