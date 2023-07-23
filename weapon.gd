extends Node3D
class_name Staff

@export var bullet: PackedScene

var can_fire = true

@onready var sphere = $CSGSphere3D
@onready var timer = $Timer

func fire_staff_bolt():
	if can_fire:
		can_fire = false
		timer.start()
		var newbullet = bullet.instantiate()
		add_child(newbullet)
		newbullet.transform = sphere.global_transform


func _on_timer_timeout():
	can_fire = true
