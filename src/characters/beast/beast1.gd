extends Character
class_name Beast

const scent_scene = preload("res://src/characters/human/Scent.tscn")

# STATE MACHINE
var state_machine
var anim_tree
var anim_playback
# MOODLE UI
var moodle
# INIT FLAG
var initialized = false
# SCENT TRAIL PATHFINDING VARS
var scent_trail = []
var target
# AUDIO FILES
# TODO - abstract these wav files to a resource so we can batch assign/import them
#
# Alert
var alert_sounds = [
	preload("res://assets/characters/beast/sounds/alerted/beast_alert_0.wav"),
	preload("res://assets/characters/beast/sounds/alerted/beast_alert_1.wav"),
	preload("res://assets/characters/beast/sounds/alerted/beast_alert_2.wav")
]
# Lost Target
var lost_target_sounds = [
	preload("res://assets/characters/beast/sounds/lost_target/beast_lost_target_0.wav"),
	preload("res://assets/characters/beast/sounds/lost_target/beast_lost_target_1.wav")
]

# VIEWCONE/RAYCASTING
export (int) var DETECT_RADIUS = 96
export (int) var NEAR_RADIUS = 32
export (int) var VERY_NEAR_RADIUS = 16
export (int) var FOV = 90
export (int) var view_angle # setget set_view_angle
var view_cone_points setget set_view_cone_points
var view_cone_points_colors
var space_state

onready var raycast = $RayCast2D

# TILEMAP
var tilemap_nav
var walls
# WANDER VARS
onready var init_position = global_position
export (int) var HOME_RADIUS = 8


func _ready():
	randomize()
	
	# Animation Tree
	anim_tree = $AnimationTree
	anim_tree.active = true
	anim_playback = anim_tree["parameters/playback"]
	anim_playback.start("Idle")
	#
	
	moodle = $Moodle
	$Moodle/AnimationPlayer.play("blank")
	#
	
	# Set peripheral detection collider
	$PeripheralDetectionArea/CollisionShape.shape.radius = VERY_NEAR_RADIUS
	
	self.add_to_group("beasts")
	
	# Finite State Machine
	state_machine = $StateMachine
	
	# Tilemaps
	tilemap_nav = get_node("../../TileMap")
	if tilemap_nav:
		walls = tilemap_nav.get_node("Walls")
	
	# Make sure everything is loaded before setting the initial state
	initialized = true
	assert(initialized)
	#
	state_machine.set_state(state_machine.default_state)


func _process(_delta):
	# Set animations
	var anim_direction = direction.normalized()
	# Invert the y direction since the axis are different between the anim tree
	# and the physics engine
	anim_direction.y *= -1
	
	# Raycast
	var raycast_angle = rad2deg(raycast.cast_to.angle())
	view_angle = 90 - raycast_angle
	
	# State Machine
	if velocity == Vector2.ZERO:
		anim_tree["parameters/Idle/blend_position"] = anim_tree["parameters/Move/blend_position"]
		anim_playback.travel("Idle")
	else:
		# Move the viewcone to the new movement direction
#		var _angle_to_new_direction = velocity.angle_to(Vector2.ZERO)
#		view_angle = rad2deg(_angle_to_new_direction)
		# Set the anim parameters
		anim_tree["parameters/Move/blend_position"] = anim_direction
		anim_playback.travel("Move")
	
	update()


func _physics_process(_delta):
	space_state = get_world_2d().direct_space_state
	var view_cone = gen_circle_arc_poly(Vector2.ZERO, DETECT_RADIUS, view_angle - FOV/2, view_angle + FOV/2)
	view_cone_points = view_cone[0]
	view_cone_points_colors = view_cone[1]


# Drawing the FOV
const RED = Color(1.0, 0, 0, 0.4)
const GREEN = Color(0, 1.0, 0, 0.4)
var draw_color = GREEN

func _draw():
	# DEBUG - draw home area
	draw_rect(Rect2(Vector2(-HOME_RADIUS/2, -HOME_RADIUS/2), Vector2(HOME_RADIUS, HOME_RADIUS)), Color(0.5, 0.2, 0.2, 0.4))
	# DEBUG - draw the near/very near radius that the beast can rotate to face a human in
	draw_circle(Vector2.ZERO, NEAR_RADIUS, Color(0.6, 0, 0.7, 0.4))
	draw_circle(Vector2.ZERO, VERY_NEAR_RADIUS, Color(1, 1, 1, 0.4))
	if view_cone_points:
		draw_polygon(view_cone_points, PoolColorArray([draw_color]))


# HELPER FUNCS


func gen_circle_arc_poly(center, radius, angle_from, angle_to):
	var nb_points = 32
	var points_arc = PoolVector2Array()
	var colors = PoolColorArray()
	points_arc.push_back(center)
	colors.push_back(GREEN)
	
	for i in range(nb_points + 1):
		var angle_point = angle_from + i * (angle_to - angle_from) / nb_points
		var _point = center + Vector2(cos(deg2rad(90 - angle_point)), sin(deg2rad(90 - angle_point))) * radius
		# Check if the point collides with anything
		var result = space_state.intersect_ray(to_global(center), to_global(_point), [self], 1)
		if result:
			# Add the point where the ray collides
			points_arc.push_back(to_local(result.position))
			colors.push_back(RED)
		else:
			# Add the point as normal
			points_arc.push_back(_point)
			colors.push_back(GREEN)
	set_view_cone_points(points_arc)
	return [points_arc, colors]


# SETTERS/GETTERS

#func set_view_angle(value):
#	view_angle = rad2deg(value)
#	var new_cast = raycast.cast_to.rotated(value)
#	raycast.cast_to = new_cast
#	raycast.force_raycast_update()


func set_view_cone_points(value):
	view_cone_points = value
	var new_view_shape = ConvexPolygonShape2D.new()
	new_view_shape.points = (view_cone_points)
	$DetectionArea/CollisionShape.shape = new_view_shape


# SIGNAL FUNCS


func _on_DetectionArea_body_entered(body):
	if body is Human:
		draw_color = RED
		if not target:
			target = body
			state_machine.set_state(state_machine.get_node("States/BeastChaseState"))


func _on_DetectionArea_body_exited(body):
	if body is Human:
		if global_position.distance_to(body.global_position) > NEAR_RADIUS:
			if body == target:
				target = null
				# Check if any other humans are in the view cone
				var new_targets = []
				for _human in get_tree().get_nodes_in_group("humans"):
					if _human == body:
						continue
					elif $DetectionArea.overlaps_body(_human):
						new_targets.append(_human)
				# Set the closest human within view as new target
				if new_targets:
					var closest_target = new_targets.sort_custom(self, "sort_closest")
					target = closest_target
				else:
					draw_color = GREEN
					state_machine.set_state(state_machine.get_node("States/BeastIdleState"))
				
	#	player_last_seen_position = body.global_position.snapped(tilemap.cell_size)
	#	$PlayerSFX.play_lost()
	#	yield($PlayerSFX, "finished")
	#	ai.state_machine.set_state($Controller/StateMachine/States/SearchState)


func sort_closest(a, b):
	if global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position):
		return true
	return false

