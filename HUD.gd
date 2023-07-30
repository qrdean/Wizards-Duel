extends CanvasLayer

@onready var Current_Weapon_Label = $VBoxContainer/HBoxContainer/CurrentWeapon
@onready var Current_Ammo_Label = $VBoxContainer/HBoxContainer2/CurrentAmmo
@onready var Weapon_Stack_Label = $VBoxContainer/HBoxContainer3/WeaponStack


func _on_weapons_manager_update_ammo(ammo):
	Current_Ammo_Label.set_text(str(ammo[0])+" / "+ str(ammo[1]))

func _on_weapons_manager_update_weapon_stack(weapon_stack):
	Weapon_Stack_Label.set_text("")
	for weapon_name in weapon_stack:
		Weapon_Stack_Label.text += "\n" + weapon_name

func _on_weapons_manager_weapon_changed(weapon_name):
	Current_Weapon_Label.set_text(weapon_name)
