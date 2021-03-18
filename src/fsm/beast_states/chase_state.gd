extends State

""" 
"""


func enter(entity, _optional_args=null):
	# Play the idle animation
	entity.anim_tree.travel("Chase")


func handle_input(entity, _delta):
	pass


func exit(_entity):
	pass

