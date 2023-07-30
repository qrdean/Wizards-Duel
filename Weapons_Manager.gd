extends Node3D

signal Weapon_Changed
signal Update_Ammo
signal Update_Weapon_Stack

@onready var Animation_Player = get_node("%AnimationPlayer")
@onready var Bullet_Point = get_node("%Bullet_Point")

var Debug_Bullet: PackedScene = preload("res://objects/bullet_debug.tscn")

var Current_Weapon: Weapon_Resource = null
var Weapon_Stack: Array[String] = []
var Weapon_Indicator: int = 0
var Next_Weapon: String
var Weapon_List: Dictionary = {}

@export var _weapon_resources: Array[Weapon_Resource]
@export var Start_Weapons: Array[String]

enum {NULL, HITSCAN, PROJECTILE}

var Collision_Exclusion = []

func _ready():
	initialize(Start_Weapons)
	
func _input(event):
	if event.is_action_pressed("weapon_up"):
		Weapon_Indicator = min(Weapon_Indicator+1, Weapon_Stack.size()-1)
		exit(Weapon_Stack[Weapon_Indicator])
	
	if event.is_action_pressed("weapon_down"):
		Weapon_Indicator = max(Weapon_Indicator-1, 0)
		exit(Weapon_Stack[Weapon_Indicator])
	
	if event.is_action_pressed("reload"):
		reload()
	
	if event.is_action_pressed("fire"):
		shoot()

func initialize(start_weapons):
	for weapon in _weapon_resources:
		Weapon_List[weapon.Weapon_Name] = weapon
		
	for weapon in start_weapons:
		Weapon_Stack.push_back(weapon)
		
	Current_Weapon = Weapon_List[Weapon_Stack[0]]
	emit_signal("Update_Weapon_Stack", Weapon_Stack)
	enter()
	
func enter():
	Animation_Player.queue(Current_Weapon.Ready_Anim)
	emit_signal("Weapon_Changed", Current_Weapon.Weapon_Name)
	emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])

func exit(next_weapon: String):
	if next_weapon != Current_Weapon.Weapon_Name:
		if Animation_Player.get_current_animation() != Current_Weapon.Unready_Anim:
			Animation_Player.queue(Current_Weapon.Unready_Anim)
			Next_Weapon = next_weapon

func change_weapon(weapon_name: String):
	Current_Weapon = Weapon_List[weapon_name]
	Next_Weapon = ""
	enter()

func shoot():
	if Current_Weapon.Current_Ammo != 0:
		if !Animation_Player.is_playing():
			Animation_Player.play(Current_Weapon.Shoot_Anim)
			Current_Weapon.Current_Ammo -= 1
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
			var camera_collision = get_camera_collision()
			match Current_Weapon.Type:
				NULL:
					print("no type selected")
				HITSCAN:
					hit_scan_collision(camera_collision)
				PROJECTILE:
					launch_projectile(camera_collision)
	else:
		reload()

func reload():
	if Current_Weapon.Current_Ammo == Current_Weapon.Magazine:
		return
	elif !Animation_Player.is_playing():
		if Current_Weapon.Reserve_Ammo != 0:
			Animation_Player.queue(Current_Weapon.Reload_Anim)
			var reload_amount = min(Current_Weapon.Magazine-Current_Weapon.Current_Ammo, Current_Weapon.Magazine, Current_Weapon.Reserve_Ammo)
			
			Current_Weapon.Current_Ammo = Current_Weapon.Current_Ammo + reload_amount
			Current_Weapon.Reserve_Ammo = Current_Weapon.Reserve_Ammo - reload_amount
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
		
		else:
			Animation_Player.play(Current_Weapon.Out_Of_Ammo_Anim)
			
func get_camera_collision() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	
	var ray_origin = camera.project_ray_origin(viewport/2)
	var ray_end = ray_origin + camera.project_ray_normal(viewport/2)*Current_Weapon.Weapon_Range
	
	var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	new_intersection.set_exclude(Collision_Exclusion)
	var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	
	if not intersection.is_empty():
		return intersection.position
	else:
		return ray_end

func hit_scan_collision(collision_point: Vector3):
	var bullet_point_origin = Bullet_Point.global_transform.origin
	var bullet_direction = (collision_point - bullet_point_origin).normalized()
	var new_intersection = PhysicsRayQueryParameters3D.create(bullet_point_origin, collision_point + bullet_direction*2)
	var bullet_collision = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	
	if bullet_collision:
		var hit_indicator = Debug_Bullet.instantiate()
		var world = get_tree().get_root()
		world.add_child(hit_indicator)
		hit_indicator.global_translate(bullet_collision.position)

		hit_scan_damage(bullet_collision.collider, Current_Weapon.Damage)

func hit_scan_damage(collider, damage):
	if collider.is_in_group("target") && collider.has_method("Hit_Successful"):
		collider.Hit_Successful(damage)
	else:
		print("not damageable")

func launch_projectile(collision_point: Vector3):
	var direction = (collision_point - Bullet_Point.global_transform.origin).normalized()
	var projectile = Current_Weapon.Projectile_To_Load.instantiate()
	
	var projectile_rid = projectile.get_rid()
	Collision_Exclusion.push_back(projectile_rid)
	projectile.tree_exited.connect(remove_exclusion.bind(projectile_rid))
	
	Bullet_Point.add_child(projectile)
	projectile.Damage = Current_Weapon.Damage
	projectile.set_linear_velocity(direction*Current_Weapon.Projectile_Velocity)
	
func remove_exclusion(_RID):
	Collision_Exclusion.erase(_RID)

func pickup(area):
	var weapon_in_stack = Weapon_Stack.find(area.Weapon_Name, 0)

	if weapon_in_stack != -1:
		var remaining = add_ammo(area.Weapon_Name, area.Current_Ammo+area.Reserve_Ammo)
		area.Current_Ammo = min(remaining, Weapon_List[area.Weapon_Name].Magazine)
		area.Reserve_Ammo = max(remaining - area.Current_Ammo, 0)

		if remaining == 0:
			area.queue_free()

	elif area.TYPE == "Weapon":
		if area.Pick_Up_Ready == true:
			var get_ref = Weapon_Stack.find(Current_Weapon.Weapon_Name)
			Weapon_Stack.insert(get_ref,area.Weapon_Name)

			Weapon_List[area.Weapon_Name].Current_Ammo = area.Current_Ammo
			Weapon_List[area.Weapon_Name].Reserve_Ammo = area.Reserve_Ammo

			emit_signal("Update_Weapon_Stack", Weapon_Stack)
			exit(area.Weapon_Name)

			area.queue_free()

func add_ammo(weapon_name: String, ammo: int) -> int:
	var weapon = Weapon_List[weapon_name]

	var required = weapon.Max_Ammo - weapon.Reserve_Ammo
	var remaining = max(ammo - required, 0)

	weapon.Reserve_Ammo += min(ammo, required)

	emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
	return remaining

func _on_animation_player_animation_finished(anim_name):
	if anim_name == Current_Weapon.Unready_Anim:
		change_weapon(Next_Weapon)
	
	if anim_name == Current_Weapon.Shoot_Anim && Current_Weapon.Auto_Fire:
		if Input.is_action_pressed("fire"):
			shoot()


func _on_pickup_detection_area_entered(area):
	print(area.name)
	pickup(area)
