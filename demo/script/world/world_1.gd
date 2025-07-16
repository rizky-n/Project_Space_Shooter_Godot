# world_1.gd (Versi Final dengan GameEvents)
extends Node2D

@export var player_scene: PackedScene
@export var boss_scene: PackedScene
@export var boss_music: AudioStream

# --- VARIABEL BARU & YANG DIUBAH ---
@onready var player_end_spawn: Marker2D = $PlayerEndSpawn
var player_instance: Player # Referensi ke instance player

@onready var player_spawn_location: Marker2D = $PlayerSpawn
@onready var spawner: Node = $EnemySpawner
@onready var scenery_spawner: Node2D = $ScenerySpawner
@onready var background_music: AudioStreamPlayer2D = $BackgroundMusic
@onready var boss_music_player: AudioStreamPlayer2D = $BossBackgroundMusic
@onready var boss_spawn_point: Marker2D = $BossSpawn
@onready var boss_path_container: Node2D = $BossPathPoints
@onready var main_hud: CanvasLayer = $MainHUD

func _ready() -> void:
	# Hubungkan semua sistem utama di sini
	spawner.all_waves_completed.connect(Callable(self, "_on_all_waves_completed"))
	spawner.wave_started.connect(Callable(scenery_spawner, "pause_spawning"))
	spawner.wave_ended.connect(Callable(scenery_spawner, "resume_spawning"))
	
	# --- KONEKSI BARU DI SINI ---
	# World akan selalu mendengarkan sinyal kemenangan dari GameEvents
	GameEvents.boss_defeated.connect(_on_boss_defeated)
	# ----------------------------
	
	GameEvents.player_died.connect(_on_player_died)
	
	# Mulai alur game
	background_music.play()
	spawn_player()
	scenery_spawner.resume_spawning()

func _on_player_died():
	background_music.stop()
	boss_music_player.stop()

func spawn_player() -> void:
	if not player_scene: return
	
	# Isi variabel member 'player_instance'
	player_instance = player_scene.instantiate()
	add_child(player_instance)
	
	player_instance.spawn_animation_finished.connect(Callable(spawner, "begin_spawning_process"))
	player_instance.spawn_animation_finished.connect(Callable(main_hud, "on_player_spawn_finished"))
	
	main_hud.player = player_instance
	player_instance.start_spawn_animation(player_spawn_location.global_position)

func _on_all_waves_completed():
	print("WAVES CLEARED! BOSS IS APPROACHING!")
	if scenery_spawner:
		scenery_spawner.pause_spawning()
	
	background_music.stop()
	boss_music_player.stream = boss_music
	boss_music_player.play()
	
	await get_tree().create_timer(5.0).timeout
	
	if not boss_scene: return
		
	var boss = boss_scene.instantiate()
	
	# !!! PENTING: KITA TIDAK PERLU KONEKSI DI SINI LAGI !!!
	# boss.boss_defeated.connect(_on_boss_defeated) # <-- HAPUS ATAU KOMENTARI BARIS INI
	
	var reposition_target_paths = [
		$BossSpawn.get_path(),
		$BossPathPoints/Path1.get_path(),
		$BossPathPoints/Path2.get_path(),
		$BossPathPoints/Path3.get_path(),
		$BossPathPoints/Path4.get_path()
	]
	
	boss.set("reposition_paths", reposition_target_paths)
	boss.set("center_spawn_point", $BossSpawn.get_path())
	boss.set("left_move_point", $BossPathPoints/LeftMovePoint.get_path())
	boss.set("right_move_point", $BossPathPoints/RightMovePoint.get_path())
	
	add_child(boss)
	boss.play_entrance_animation(boss_spawn_point.global_position)

# --- FUNGSI BARU UNTUK MENGHANDLE KEMENANGAN ---
func _on_boss_defeated():
	print("BOSS DEFEATED! World received signal. Starting victory sequence.")
	
	if not is_instance_valid(player_instance): return

	# Player bergerak ke titik kemenangan
	await player_instance.move_to_victory_point(player_end_spawn.global_position, 3.0)
	
	# Tunggu sebentar setelah player sampai
	await get_tree().create_timer(1.0).timeout

	# --- INI DIA BAGIAN BARUNYA ---
	# Panggil fungsi fade di HUD dan tunggu sampai selesai (layar gelap)
	print("Fading to black...")
	await main_hud.start_fade_out(1.5) # Durasi fade 1.5 detik
	# -----------------------------

	# Setelah layar benar-benar gelap, baru ganti scene
	get_tree().change_scene_to_file("res://ui/level_select_menu.tscn")
