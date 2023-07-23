extends Area3D

var caster_id = null
var speed = 10
var velocity = Vector3()
var damage = 25

func _ready():
	set_as_top_level(true)

func _physics_process(delta):
	position -= transform.basis.z * speed * delta

func _on_area_entered(area):
	print_debug(area)
	print_debug(area.get_parent().name)
	var parent = area.get_parent()
	if parent != null && parent is Player && parent.name != caster_id:
		parent.take_damage()
	queue_free()
