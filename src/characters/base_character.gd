extends KinematicBody2D
class_name Character

export (int) var movement_speed = 200
export (float) var acceleration = 0.7
export (float) var friction = 0.05

var direction = Vector2()
var velocity = Vector2()


func _physics_process(_delta):
	velocity = move_and_slide(velocity)

