extends Resource
class_name Weapon_Resource

@export_group("Weapon Animations")
@export var Weapon_Name: String
@export var Ready_Anim: String
@export var Unready_Anim: String
@export var Reload_Anim: String
@export var Shoot_Anim: String
@export var Out_Of_Ammo_Anim: String

@export_group("Weapon Stats")
@export var Current_Ammo: int
@export var Reserve_Ammo: int
@export var Magazine: int
@export var Max_Ammo: int
@export var Auto_Fire: bool
@export var Damage: int
@export var Weapon_Range: int

@export_flags("HitScan", "Projectile") var Type = 1
@export var Projectile_To_Load: PackedScene
@export var Projectile_Velocity: int
