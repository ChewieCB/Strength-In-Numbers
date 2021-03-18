extends Node2D
class_name StateMachine

signal state_changed(new_state)

onready var actor = get_parent()
onready var states = $States.get_children()
onready var default_state = states[0]

var current_state setget set_state


func _physics_process(delta):
	# Check if the state needs changing
	var update_state = current_state.handle_input(actor, delta)
	if update_state != null:
		set_state(update_state)


func set_state(new_state, _optional_args=null):
	if current_state != null:
		current_state.exit(actor)
	current_state = new_state
	new_state.enter(actor, _optional_args)
	# Update the debug state label
	actor.get_node("StateLabel").text = str(current_state.name)
#	emit_signal("state_changed", new_state.name)


func get_class(): 
	return "StateMachine"
