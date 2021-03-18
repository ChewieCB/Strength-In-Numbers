extends Node2D

var human

func _ready():
	var scent_timer = Timer.new()
	scent_timer.wait_time = 1.5
	scent_timer.connect("timeout", self, "remove_scent")
	add_child(scent_timer)
	scent_timer.start()


func remove_scent():
	human.scent_trail.erase(self)
	queue_free()
