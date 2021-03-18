extends Node2D
class_name State

"""
This is a base class from which all states extend from, all of it's functions
should be virtual.
"""


func enter(_entity, _optional_args=null):
	pass


func handle_input(_entity, _delta):
	pass


func play_turn(_entity):
	pass


func exit(_entity):
	pass

func get_class(): 
	return "State"
