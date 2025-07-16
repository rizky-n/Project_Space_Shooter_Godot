# boss.gd (Final)
extends CharacterBody2D

#==============================================================================
#  Variabel Export (Untuk diatur dari Inspector)
#==============================================================================
@export_group("Boss Stats")
@export var max_health: float = 1000.0

@export_group("Minion Spawning")
@export var normal_enemy_scene: PackedScene
@export var speed_enemy_scene: PackedScene
@export var spinning_enemy_scene: PackedScene
@export var spawn_minion_cooldown: float = 10.0

@export_group("Attacks")
@export var basic_bullet_scene: PackedScene
@export var rocket_scene: PackedScene
@export var laser_beam_scene: PackedScene
@export var basic_shot_cooldown: float = 2.5
@export var sweeping_shot_cooldown: float = 7.0
@export var rocket_cooldown: float = 8.0
@export var laser_beam_duration: float = 10.0

@export_group("Movement")
@export var reposition_cooldown: float = 5.0
@export var special_move_duration: float = 5.0

@export_group("Required Scenes")
@export var explosion_scene: PackedScene
@export var sustained_explosion_scene: PackedScene
@export var damage_text_scene: PackedScene

#==============================================================================
#  Variabel Path (Akan diisi oleh world_1.gd)
#==============================================================================
# Variabel ini tidak perlu di-export karena akan diisi lewat kode
var reposition_paths: Array[NodePath] = []
var center_spawn_point: NodePath
var left_move_point: NodePath
var right_move_point: NodePath

#==============================================================================
#  Referensi Node & Variabel Internal
#==============================================================================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var muzzles: Node2D = $Muzzles
@onready var basic_shot_timer: Timer = $AttackTimers/BasicShotTimer
@onready var sweeping_shot_timer: Timer = $AttackTimers/SweepingShotTimer
@onready var homing_rocket_timer: Timer = $AttackTimers/HomingRocketTimer
@onready var spawn_minion_timer: Timer = $AttackTimers/SpawnMinionTimer
@onready var reposition_timer: Timer = $AttackTimers/RepositionTimer
@onready var minion_spawn_left: Marker2D = $MinionSpawnLeft
@onready var minion_spawn_right: Marker2D = $MinionSpawnRight

var current_health: float
var is_in_special_attack: bool = false
var phase_triggers: Array[int] = [750, 500, 250]
var hit_flash_tween: Tween
var last_reposition_target: NodePath
var is_dying: bool = false

#==============================================================================
#  Fungsi Utama
#==============================================================================
func _ready():
	current_health = max_health
	# Hubungkan semua sinyal timer
	basic_shot_timer.timeout.connect(_on_BasicShotTimer_timeout)
	sweeping_shot_timer.timeout.connect(_on_SweepingShotTimer_timeout)
	homing_rocket_timer.timeout.connect(_on_HomingRocketTimer_timeout)
	spawn_minion_timer.timeout.connect(_on_SpawnMinionTimer_timeout)
	reposition_timer.timeout.connect(_on_RepositionTimer_timeout)

func take_damage(amount: float):
	if is_in_special_attack or current_health <= 0: return
	
	# Panggil scene teks damage
	if damage_text_scene:
		var damage_text = damage_text_scene.instantiate()
		# Taruh di scene utama agar tidak ikut hancur dengan musuh
		get_tree().root.add_child(damage_text)
		# Mulai animasinya
		damage_text.show_damage(amount, global_position)
	
	# Efek kelip saat kena hit
	if hit_flash_tween and hit_flash_tween.is_running():
		hit_flash_tween.kill()
	hit_flash_tween = create_tween()
	hit_flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.08)
	hit_flash_tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.08)

	var health_before = current_health
	current_health -= amount
	GameEvents.boss_health_updated.emit(current_health)
	print("Boss Health: ", current_health)
	
	if current_health <= 0:
		die()
		return
		
	for trigger_hp in phase_triggers:
		if health_before > trigger_hp and current_health <= trigger_hp:
			phase_triggers.erase(trigger_hp)
			execute_laser_beam_special()
			return

#==============================================================================
#  Kontrol Serangan & Gerakan
#==============================================================================
func play_entrance_animation(target_pos: Vector2):
	global_position = Vector2(target_pos.x, -200)
	is_in_special_attack = true 
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target_pos, 5.0)
	GameEvents.boss_appeared.emit("GARGANTUA", max_health)
	await tween.finished
	is_in_special_attack = false
	start_all_attack_timers()

func start_all_attack_timers():
	basic_shot_timer.start(basic_shot_cooldown)
	sweeping_shot_timer.start(sweeping_shot_cooldown)
	homing_rocket_timer.start(rocket_cooldown)
	spawn_minion_timer.start(spawn_minion_cooldown)
	reposition_timer.start(reposition_cooldown)

func stop_all_attack_timers():
	basic_shot_timer.stop()
	sweeping_shot_timer.stop()
	homing_rocket_timer.stop()
	spawn_minion_timer.stop()
	reposition_timer.stop()

#==============================================================================
#  Implementasi Serangan & Gerakan (Dipanggil oleh Timer)
#==============================================================================
func _on_BasicShotTimer_timeout():
	if is_in_special_attack: return
	# Tembak lurus dari muzzle 5 - 10
	for i in range(5, 11):
		var muzzle = muzzles.get_node_or_null("Muzzle" + str(i))
		if muzzle and basic_bullet_scene:
			var bullet = basic_bullet_scene.instantiate()
			get_parent().add_child(bullet)
			bullet.global_position = muzzle.global_position
			bullet.rotation_degrees = 180
	basic_shot_timer.start(basic_shot_cooldown)

func _on_SweepingShotTimer_timeout():
	if is_in_special_attack: return
	execute_sweeping_attack()
	sweeping_shot_timer.start(sweeping_shot_cooldown)

func execute_sweeping_attack():
	# PERBAIKAN: Menggunakan Muzzle 6 dan 9
	var muzzle_left = muzzles.get_node_or_null("Muzzle6")
	var muzzle_right = muzzles.get_node_or_null("Muzzle9")
	if not muzzle_left or not muzzle_right: return
	
	var sweep_shots = 5
	var sweep_duration = 1.5
	for i in sweep_shots:
		if is_in_special_attack: return
		var progress = float(i) / (sweep_shots - 1)
		var angle_deg_right = lerp(180, 90, progress)
		var angle_deg_left = lerp(180, 270, progress)
		
		var bullet_r = basic_bullet_scene.instantiate()
		get_parent().add_child(bullet_r)
		bullet_r.global_position = muzzle_right.global_position
		bullet_r.rotation_degrees = angle_deg_right
		
		var bullet_l = basic_bullet_scene.instantiate()
		get_parent().add_child(bullet_l)
		bullet_l.global_position = muzzle_left.global_position
		bullet_l.rotation_degrees = angle_deg_left
		
		await get_tree().create_timer(sweep_duration / sweep_shots).timeout

func _on_HomingRocketTimer_timeout():
	if is_in_special_attack: return
	for muzzle in muzzles.get_children():
		if muzzle.name in ["Muzzle3", "Muzzle4", "Muzzle11", "Muzzle12"]:
			if rocket_scene:
				var rocket = rocket_scene.instantiate()
				get_parent().add_child(rocket)
				rocket.global_position = muzzle.global_position
	homing_rocket_timer.start(rocket_cooldown)

func _on_SpawnMinionTimer_timeout():
	if is_in_special_attack: return
	var spawnable_minions = [normal_enemy_scene, speed_enemy_scene, spinning_enemy_scene]
	var spawn_points_sides = [minion_spawn_left, minion_spawn_right]
	for i in 5:
		var random_minion_scene = spawnable_minions.pick_random()
		var spawn_point = spawn_points_sides.pick_random()
		if random_minion_scene and spawn_point:
			var minion = random_minion_scene.instantiate()
			get_parent().add_child(minion)
			minion.global_position = spawn_point.global_position
	spawn_minion_timer.start(spawn_minion_cooldown)

func _on_RepositionTimer_timeout():
	if is_in_special_attack: return
	if reposition_paths.is_empty(): return
	
	var next_target_path = reposition_paths.pick_random()
	while reposition_paths.size() > 1 and next_target_path == last_reposition_target:
		next_target_path = reposition_paths.pick_random()
	
	last_reposition_target = next_target_path
	var target_node = get_node(next_target_path)
	
	if target_node:
		var move_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		move_tween.tween_property(self, "global_position", target_node.global_position, 2.0)
	
	reposition_timer.start(reposition_cooldown)

#==============================================================================
#  Serangan Spesial & Kematian
#==============================================================================
func execute_laser_beam_special():
	# --- TAHAP 1: PERSIAPAN & KEMBALI KE TENGAH ---
	is_in_special_attack = true
	stop_all_attack_timers()
	print("BOSS: Returning to center for special attack!")
	
	var center_target = get_node_or_null(center_spawn_point)
	if center_target:
		var return_tween = create_tween().set_ease(Tween.EASE_OUT)
		return_tween.tween_property(self, "global_position", center_target.global_position, 1.5)
		await return_tween.finished
	
	# --- TAHAP 2: CHARGING / PERINGATAN ---
	# (Bagian ini tidak berubah)
	if sustained_explosion_scene:
		var charge_effect = sustained_explosion_scene.instantiate()
		add_child(charge_effect)
		charge_effect.start(3.0)
	var warning_tween = create_tween().set_loops(4)
	warning_tween.tween_property(animated_sprite, "modulate", Color.RED, 0.25)
	warning_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.25)
	await get_tree().create_timer(2.0).timeout
	
	# --- TAHAP 3: SERANGAN UTAMA (LASER & GERAKAN) ---
	get_tree().get_first_node_in_group("camera_shaker").shake(15.0, 10.0)
	var left_target = get_node_or_null(left_move_point)
	var right_target = get_node_or_null(right_move_point)
	
	# Memunculkan 2 laser beam
	var beam1 = laser_beam_scene.instantiate(); var beam2 = laser_beam_scene.instantiate()
	muzzles.get_node("Muzzle1").add_child(beam1); muzzles.get_node("Muzzle2").add_child(beam2)
	beam1.set("firing_duration", 10.0); beam2.set("firing_duration", 10.0)
	beam1.fire_full_sequence(); beam2.fire_full_sequence()
	
	# Gerakan bolak-balik selama serangan
	if left_target and right_target:
		var move_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_loops(2)
		move_tween.tween_property(self, "global_position", right_target.global_position, special_move_duration / 2.0)
		move_tween.tween_property(self, "global_position", left_target.global_position, special_move_duration / 2.0)
	
	# Tunggu selama durasi laser (10 detik)
	await get_tree().create_timer(laser_beam_duration).timeout
	
	# --- TAHAP 4: KEMBALI KE POSISI AWAL SETELAH SELESAI ---
	print("BOSS: Special attack finished. Returning to position...")
	if center_target:
		var final_return_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		final_return_tween.tween_property(self, "global_position", center_target.global_position, 1.5)
		await final_return_tween.finished
		
	# --- TAHAP 5: KEMBALI NORMAL ---
	is_in_special_attack = false
	start_all_attack_timers()

func die():
	if current_health > 0 and not is_queued_for_deletion(): return
	if is_dying: return
	is_dying = true
	
	print("BOSS DEFEATED! Final sequence...")
	stop_all_attack_timers()
	set_physics_process(false)
	$CollisionPolygon2D.set_deferred("disabled", true)
	
	# Kembali ke tengah sebelum meledak
	var center_target = get_node(center_spawn_point)
	if center_target:
		var move_tween = create_tween().set_ease(Tween.EASE_IN)
		move_tween.tween_property(self, "global_position", center_target.global_position, 2.0)
		await move_tween.finished
		
	# Mulai sekuens ledakan
	get_tree().get_first_node_in_group("camera_shaker").shake(25.0, 5.0)
	if sustained_explosion_scene:
		var death_explosion = sustained_explosion_scene.instantiate()
		get_parent().add_child(death_explosion)
		death_explosion.global_position = global_position
		death_explosion.start(5.0)
		
	animated_sprite.hide()
	GameEvents.boss_defeated.emit()
	GameEvents.score_updated.emit(5000)
	await get_tree().create_timer(5.0).timeout
	queue_free()
