extends Area3D

@export var Weapon_Name: String
@export var Current_Ammo: int
@export var Reserve_Ammo: int

const TYPE = "Weapon"

var Pick_Up_Ready: bool = false

func _ready():
	await get_tree().create_timer(2.0).timeout
	Pick_Up_Ready = true
	
func Set_Ammo(w_name: String, c_ammo: int, r_ammo: int):
	if w_name == Weapon_Name:
		Current_Ammo = c_ammo
		Reserve_Ammo = r_ammo
