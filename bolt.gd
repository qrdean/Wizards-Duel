extends Area3D

var speed = 10
var velocity = Vector3()
var damage = 25

func _ready():
	set_as_top_level(true)

func _physics_process(delta):
	position -= transform.basis.z * speed * delta


func _on_body_entered(body):
	if body.is_in_group("Enemy"):
		body.take_damage(damage)
		
	queue_free()
