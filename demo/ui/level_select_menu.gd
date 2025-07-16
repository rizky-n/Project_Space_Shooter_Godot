extends Control

@onready var button: Button = $Button
@onready var button_2: Button = $Button2
@onready var button_3: Button = $Button3
@onready var lvl_1_locked: TextureRect = $lvl1_locked
@onready var lvl_2_locked: ColorRect = $lvl2_locked
@onready var lvl_3_locked: ColorRect = $lvl3_locked
@onready var lock_1: Sprite2D = $lock1
@onready var lock_2: Sprite2D = $lock2

func _ready() -> void:
	button.grab_focus()

	# Jika level 1 selesai, gemboknya tidak terlihat. Jika belum, gemboknya terlihat.
	lvl_1_locked.visible = not LevelCore.lvl1_completed
	lock_1.visible = not LevelCore.lvl1_completed	

#Level Icon Unlock
	#if LevelCore.lvl2_completed == true:
		#lvl_2_locked.visible = false
		#lock_2.visible = false
	#if LevelCore.lvl2_completed == false:
		#lvl_2_locked.visible = true

	#if LevelCore.lvl3_completed == true:
		#lvl_3_locked.visible = false
	#if LevelCore.lvl3_completed == false:
		#lvl_3_locked.visible = true

#Enter Level
func _on_button_pressed() -> void:
	# Hentikan musik menu sebelum pindah ke scene level
	MusicController.stop_music()

	# Logika if/else Anda bisa disederhanakan karena hasilnya sama
	get_tree().change_scene_to_file("res://world/world_1.tscn")

#func _on_button_2_pressed() -> void:
	#if LevelCore.lvl1_completed == false:
		#null
	#if LevelCore.lvl1_completed == true:
		#get_tree().change_scene_to_file("res://scenes/gameplay/gameplay2.tscn")

#func _on_button_3_pressed() -> void:
	#if LevelCore.lvl2_completed == false:
		#null
	#if LevelCore.lvl2_completed == true:
		#get_tree().change_scene_to_file("res://scenes/gameplay/gameplay3.tscn")
