extends Character
class_name Human

const scent_scene = preload("res://src/characters/human/Scent.tscn")

export (bool) var is_starter_character = false

var state_machine
var anim_tree
var anim_state_machine
#
var selector
var selector_sprite_hover
var selector_sprite_select
var selector_sprite_follow
#
var moodle
#
var initialized = false
var is_mouseover = false setget set_is_mouseover
export (int) var recruit_radius = 30
export (int) var follow_radius = 20
export (int) var nogo_radius = 10
#
var shirt_color
#
var scent_trail = []
#
var death_sound1 = preload("res://assets/characters/human/sounds/death/human_death_1.wav")
var death_sound2 = preload("res://assets/characters/human/sounds/death/human_death_2.wav")
var death_sound3 = preload("res://assets/characters/human/sounds/death/human_death_3.wav")
var death_sounds = [
	death_sound1,
	death_sound2,
	death_sound3,
]


func _ready():
	randomize()
	#
	$ScentTimer.connect("timeout", self, "add_scent")
	# Animation Tree
	anim_tree = $AnimationTree
	anim_tree.active = true
	var anim_playback = anim_tree["parameters/playback"]
	anim_playback.start("Idle")
	# Selector
	selector = $Sprites/Selector
	selector_sprite_hover = load("res://assets/ui/selector/selector0.png")
	selector_sprite_select = load("res://assets/ui/selector/selector1.png")
	selector_sprite_follow = load("res://assets/ui/selector/selector3.png")
	moodle = $Moodle
	$Moodle/AnimationPlayer.play("blank")
	#
	self.add_to_group("humans")
	$RecruitRadius/CollisionShape2D.shape.radius = recruit_radius
	# Misc Details
	shirt_color = Color(randf(), randf(), randf(), 1)
	$Sprites/Shirt.modulate = shirt_color
	# TODO - add names
	#
	# Finite State Machine
	state_machine = $StateMachine
	# Make sure everything is loaded before setting the initial state
	initialized = true
	assert(initialized)
	#
	if is_starter_character:
		state_machine.set_state($StateMachine/States/ControlledState)
	else:
		state_machine.set_state(state_machine.default_state)


func _process(_delta):
	# Highlight/select characters
	check_selector()
	# Set animations
	anim_state_machine = anim_tree["parameters/playback"]
	var anim_direction = direction.normalized()
	# Invert the y direction since the axis are different between the anim tree
	# and the physics engine
	anim_direction.y *= -1
	
	if velocity == Vector2.ZERO:
		anim_tree["parameters/Idle/blend_position"] = anim_tree["parameters/Move/blend_position"]
		anim_state_machine.travel("Idle")
	else:
		anim_tree["parameters/Move/blend_position"] = anim_direction
		anim_state_machine.travel("Move")


func _input(event):
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()


func check_selector():
	if is_mouseover:
		if Input.is_action_just_pressed("click"):
			var idle_state = $StateMachine/States/IdleState
			var controlled_state = $StateMachine/States/ControlledState
			var follow_state = $StateMachine/States/FollowState
			var death_state = $StateMachine/States/DeathState
			var controlled_characters = get_tree().get_nodes_in_group("controlled_characters")
			var recruited_characters = get_tree().get_nodes_in_group("recruited_characters")
				
			if state_machine.current_state == controlled_state:
				self.remove_from_group("controlled_characters")
				if len(controlled_characters) > 0:
					state_machine.set_state(follow_state, controlled_characters)
					# Cleanup any leftover dead characters, we don't remove them
					# inside the death state so we can keep their camera active
					# if we need to.
					var dead_characters = get_tree().get_nodes_in_group("dead_characters")
					if len(dead_characters) > 0:
						for character in dead_characters:
							character.queue_free()
				else:
					# Set character to idle
					state_machine.set_state(idle_state)
			elif state_machine.current_state == death_state:
				return
			else:
				# Set character to controlled
				state_machine.set_state(controlled_state)
				# Make the controlled character a follower and change the leader
				# of the followers to the new controlled character
				if len(controlled_characters) > 0:
					for character in controlled_characters:
						character.add_to_group("recruited_characters")
					for follower in recruited_characters:
						# Refresh the recruited characters array now we've updated it
						recruited_characters = get_tree().get_nodes_in_group("recruited_characters")
						var follower_state = follower.get_node("StateMachine/States/FollowState")
						follower_state.leader = self
		elif Input.is_mouse_button_pressed(2) and \
		state_machine.current_state != $StateMachine/States/DeathState:
			state_machine.set_state($StateMachine/States/DeathState)


func add_scent():
	if is_in_group("controlled_characters"):
		var scent = scent_scene.instance()
		var scent_color = shirt_color
		scent_color.a = 0.5
		scent.get_node("ColorRect").color = scent_color
		scent.human = self
		scent.position = self.position
		get_parent().get_parent().get_node("Scents").add_child(scent)
		scent_trail.push_front(scent)


func set_is_mouseover(value):
	is_mouseover = value
	# Only one character should be selected at once so iterate over all the nearby
	# characters and set their is_mouseover to false if it isn't already
	var humans = get_tree().get_nodes_in_group("humans")
	for human in humans:
		if human == self:
			continue
		if human.is_mouseover:
			human.is_mouseover = false
	# Don't toggle the selector if the character is controlled
	if state_machine.current_state == $StateMachine/States/ControlledState or \
	state_machine.current_state == $StateMachine/States/DeathState:
		return
	# Show/hide selector sprite
	if is_mouseover:
		selector.texture = selector_sprite_hover
		selector.visible = true
	else:
		if state_machine.current_state == $StateMachine/States/FollowState:
			selector.texture = selector_sprite_follow
		else:
			selector.visible = false


func _on_SelectorArea_mouse_entered():
	if state_machine.current_state != $StateMachine/States/DeathState:
		$StateLabel.visible = true
		set_is_mouseover(true)


func _on_SelectorArea_mouse_exited():
	$StateLabel.visible = false
	set_is_mouseover(false)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "recruitable_popup":
		$Moodle/AnimationPlayer.play("recruitable_idle")
	elif anim_name == "recruited_popup":
		$Moodle/AnimationPlayer.play("recruited_fadeout")


func _on_RecruitRadius_body_entered(body):
	if is_in_group("controlled_characters") and body.has_node("Moodle"):
		if body.is_in_group("humans") and \
		not body.is_in_group("recruited_characters") and \
		not body.is_in_group("controlled_characters"):
			body.get_node("Moodle/AnimationPlayer").play("recruitable_popup")


func _on_RecruitRadius_body_exited(body):
	if is_in_group("controlled_characters") and body.has_node("Moodle"):
		if body.is_in_group("humans") and \
		not body.is_in_group("recruited_characters") and \
		not body.is_in_group("controlled_characters"):
			body.get_node("Moodle/AnimationPlayer").play("recruitable_fadeout")

