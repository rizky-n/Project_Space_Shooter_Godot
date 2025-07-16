# EnemySpawner.gd (Versi Final dengan Perbaikan Sinyal)
extends Node

#==============================================================================
#  Sinyal
#==============================================================================
# PERBAIKAN: Kita hapus argumen dari sinyal karena tidak diperlukan oleh ScenerySpawner
signal wave_started
signal wave_ended
signal all_waves_completed

#==============================================================================
#  Variabel Export
#==============================================================================
@export_group("Enemy Scenes")
@export var normal_enemy_scene: PackedScene
@export var spinning_enemy_scene: PackedScene
@export var speed_enemy_scene: PackedScene
@export var tanker_enemy_scene: PackedScene
@export var meteor_scene: PackedScene

@export_group("Wave Settings")
@export var time_between_waves: float = 5.0

#==============================================================================
#  Referensi Node & Variabel Internal
#==============================================================================
@onready var spawn_timer: Timer = $Timer
@onready var spawn_points: Dictionary = {
	"kiri": $LeftSpawn,
	"tengah": $MiddleSpawn,
	"kanan": $RightSpawn,
	"ujung_kanan": $RightEndSpawn,
	"ujung_kiri": $LeftEndSpawn
}

var enemy_scenes: Dictionary
var all_waves: Array[Array]
var current_wave_number: int = -1
var current_wave_data: Array
var current_wave_index: int = 0

#==============================================================================
#  DATA GELOMBANG MUSUH (Harus Anda isi sendiri)
#==============================================================================
var wave_1: Array[Dictionary] = [
	{ "delay": 0.8, "enemy_type": "normal", "spawn_point": "tengah" },
	{ "delay": 1.2, "enemy_type": "spinning", "spawn_point": "ujung_kanan" },
	{ "delay": 2.0, "enemy_type": "tanker", "spawn_point": "ujung_kiri" },
	{ "delay": 1.0, "enemy_type": "speed", "spawn_point": "tengah" },
	{ "delay": 0.6, "enemy_type": "meteor", "spawn_point": "ujung_kiri" },
	{ "delay": 1.5, "enemy_type": "normal", "spawn_point": "ujung_kanan" },
	{ "delay": 1.3, "enemy_type": "speed", "spawn_point": "ujung_kiri" },
	{ "delay": 2.5, "enemy_type": "tanker", "spawn_point": "tengah" },
	{ "delay": 1.1, "enemy_type": "spinning", "spawn_point": "ujung_kanan" },
	{ "delay": 0.9, "enemy_type": "meteor", "spawn_point": "tengah" },
]

var wave_2: Array[Dictionary] = [
	{ "delay": 0.7, "enemy_type": "spinning", "spawn_point": "ujung_kiri" },
	{ "delay": 1.8, "enemy_type": "normal", "spawn_point": "tengah" },
	{ "delay": 0.9, "enemy_type": "speed", "spawn_point": "ujung_kanan" },
	{ "delay": 1.4, "enemy_type": "meteor", "spawn_point": "ujung_kiri" },
	{ "delay": 2.1, "enemy_type": "tanker", "spawn_point": "tengah" },
	{ "delay": 0.5, "enemy_type": "spinning", "spawn_point": "ujung_kanan" },
	{ "delay": 1.7, "enemy_type": "speed", "spawn_point": "tengah" },
	{ "delay": 2.2, "enemy_type": "normal", "spawn_point": "ujung_kiri" },
	{ "delay": 1.0, "enemy_type": "meteor", "spawn_point": "ujung_kanan" },
	{ "delay": 0.6, "enemy_type": "tanker", "spawn_point": "tengah" },
]

var wave_3: Array[Dictionary] = [
	{ "delay": 1.1, "enemy_type": "tanker", "spawn_point": "tengah" },
	{ "delay": 0.7, "enemy_type": "normal", "spawn_point": "ujung_kanan" },
	{ "delay": 1.6, "enemy_type": "meteor", "spawn_point": "ujung_kiri" },
	{ "delay": 2.0, "enemy_type": "spinning", "spawn_point": "tengah" },
	{ "delay": 0.9, "enemy_type": "speed", "spawn_point": "ujung_kanan" },
	{ "delay": 1.3, "enemy_type": "normal", "spawn_point": "tengah" },
	{ "delay": 2.4, "enemy_type": "tanker", "spawn_point": "ujung_kiri" },
	{ "delay": 0.8, "enemy_type": "spinning", "spawn_point": "ujung_kanan" },
	{ "delay": 1.9, "enemy_type": "speed", "spawn_point": "tengah" },
	{ "delay": 1.2, "enemy_type": "meteor", "spawn_point": "ujung_kiri" },
]

#==============================================================================
#  FUNGSI UTAMA & ALUR LOGIKA
#==============================================================================
func _ready():
	enemy_scenes = {
		"normal": normal_enemy_scene, "spinning": spinning_enemy_scene,
		"speed": speed_enemy_scene, "tanker": tanker_enemy_scene, "meteor": meteor_scene
	}
	all_waves = [wave_1, wave_2, wave_3]

func begin_spawning_process():
	await get_tree().create_timer(3.0).timeout
	_start_next_wave()

func _start_next_wave():
	current_wave_number += 1
	if current_wave_number >= all_waves.size():
		print("SELURUH GELOMBANG SELESAI! Mempersiapkan bos...")
		all_waves_completed.emit()
		queue_free()
		return
	
	var next_wave_data = all_waves[current_wave_number]
	start_wave(next_wave_data)

func start_wave(wave_data: Array):
	print("Memulai gelombang ke-%d!" % (current_wave_number + 1))
	# PERBAIKAN: Pancarkan sinyal tanpa argumen
	wave_started.emit()
	
	current_wave_data = wave_data
	current_wave_index = 0
	_spawn_next_in_wave()

func _spawn_next_in_wave():
	if current_wave_index >= current_wave_data.size():
		print("Gelombang ke-%d selesai!" % (current_wave_number + 1))
		# PERBAIKAN: Pancarkan sinyal tanpa argumen
		wave_ended.emit()
		
		await get_tree().create_timer(time_between_waves).timeout
		_start_next_wave()
		return
	
	var event = current_wave_data[current_wave_index]
	spawn_timer.start(event["delay"])

func _on_spawn_timer_timeout():
	if current_wave_index >= current_wave_data.size(): return
		
	var event = current_wave_data[current_wave_index]
	var enemy_scene = enemy_scenes.get(event["enemy_type"])
	var spawn_marker = spawn_points.get(event["spawn_point"])
	
	if enemy_scene and spawn_marker:
		var enemy = enemy_scene.instantiate()
		get_parent().add_child(enemy)
		enemy.global_position = spawn_marker.global_position
	else:
		print("Error: Tipe musuh atau titik spawn tidak ditemukan: ", event)
	
	current_wave_index += 1
	_spawn_next_in_wave()
