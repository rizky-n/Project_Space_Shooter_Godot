extends Node2D

## Variabel yang bisa diatur dari Inspector
@export var scenery_scenes: Array[PackedScene]
@export_range(1.0, 10.0) var min_spawn_delay: float = 3.0
@export_range(5.0, 20.0) var max_spawn_delay: float = 8.0

## Referensi ke node anak
@onready var timer: Timer = $Timer
@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D

# Fungsi untuk memulai timer dengan durasi acak
func start_next_spawn_timer():
	var wait_time = randf_range(min_spawn_delay, max_spawn_delay)
	timer.wait_time = wait_time
	timer.start()
	print("Scenery spawner: waiting for ", wait_time, " seconds.")

# Fungsi ini berjalan saat timer selesai
func _on_timer_timeout():
	if scenery_scenes.is_empty():
		print("Scenery spawner: No scenes to spawn.")
		return
		
	var random_scene = scenery_scenes.pick_random()
	var scenery_instance = random_scene.instantiate()
	
	path_follow.progress_ratio = randf()
	scenery_instance.global_position = path_follow.global_position
	
	get_parent().add_child(scenery_instance)
	print("Spawning scenery: ", random_scene.resource_path.get_file())
	
	# Mulai lagi timer untuk spawn berikutnya
	start_next_spawn_timer()


#==============================================================================
#  FUNGSI KONTROL BARU (Untuk dipanggil oleh World)
#==============================================================================

# Fungsi untuk menghentikan spawn pemandangan
func pause_spawning():
	timer.stop()
	print("Scenery Spawner: PAUSED")

# Fungsi untuk melanjutkan spawn pemandangan
func resume_spawning():
	print("Scenery Spawner: RESUMED")
	# Panggil fungsi ini untuk memulai timer lagi
	start_next_spawn_timer()
