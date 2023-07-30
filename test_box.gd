extends RigidBody3D

var health = 5

func Hit_Successful(damage):
	health -= damage
	print("target health: "+str(health))
	if health <= 0:
		queue_free()
