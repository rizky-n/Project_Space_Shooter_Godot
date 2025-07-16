extends CharacterBody2D
class_name Player

#==============================================================================
#  Sinyal
#==============================================================================
signal spawn_animation_finished

#==============================================================================
#  Variabel Export (Dikelompokkan agar rapi di Inspector)
#==============================================================================
@export_group("Core Stats")
@export var health: float = 100.0
@export var speed: float = 400.0

@export_group("Shooting")
@export var laser_scene: PackedScene
@export var fire_rate: float = 0.4

@export_group("Skill: Shield")
@export var shield_scene: PackedScene
@export var shield_cooldown_time: float = 10.0

@export_group("Skill: Power Up")
@export var powerup_activation_effect: PackedScene
@export var powerup_duration: float = 4.0
@export var powerup_cooldown_time: float = 12.0
@export var powerup_fire_rate_multiplier: float = 1.8
@export var powerup_speed_multiplier: float = 1.3
@export var powerup_damage_multiplier: float = 2.0

@export_group("Skill: Laser Beam")
@export var laser_beam_scene: PackedScene
@export var beam_cooldown_time: float = 15.0

@export_group("Required Scenes")
@export var explosion_scene: PackedScene
@export var damage_text_scene: PackedScene

#==============================================================================
#  Referensi Node (@onready)
#==============================================================================
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_laser: AudioStreamPlayer2D = $SfxLaser
@onready var left_gun: Marker2D = $LaserPosition/LeftGun
@onready var right_gun: Marker2D = $LaserPosition/RightGun
@onready var muzzle_laser: Marker2D = $MuzzleLaser 

# Timers untuk skill
@onready var shield_cooldown_timer: Timer = $ShieldCooldownTimer
@onready var powerup_duration_timer: Timer = $PowerUpDurationTimer
@onready var powerup_cooldown_timer: Timer = $PowerUpCooldownTimer
@onready var beam_cooldown_timer: Timer = $BeamCooldownTimer


#==============================================================================
#  Variabel Status Internal
#==============================================================================
var max_health: float
var current_health: float
var is_spawning: bool = true
var fire_cooldown: float = 0.0
var is_powered_up: bool = false
var original_speed: float
var original_fire_rate: float
var active_beam = null
var is_movement_locked: bool = false

#==============================================================================
#  Fungsi Bawaan Godot
#==============================================================================
func _ready() -> void:
	hide()
	# Simpan nilai atribut asli saat game dimulai
	original_speed = speed
	original_fire_rate = fire_rate
	max_health = health
	current_health = health

func _physics_process(_delta: float) -> void:
	# Jika sedang animasi masuk ATAU pergerakan dikunci, hentikan semua proses di bawahnya
	if is_spawning or is_movement_locked:
		return
	# Logika untuk membuat beam 'menempel' pada player
	if is_instance_valid(active_beam):
		# Update posisi beam agar selalu sama dengan posisi meriam laser
		active_beam.global_position = muzzle_laser.global_position
		# Rotasinya cukup di-set sekali saat dibuat, tapi posisinya harus update terus
	# Proses input skill dan tembakan
	handle_input()
	# Proses pergerakan player
	handle_movement()

#==============================================================================
#  Fungsi Logika Utama
#==============================================================================
func handle_input():
	# Cek input untuk skill
	if Input.is_action_just_pressed("skill_1"):
		try_activate_shield()
	if Input.is_action_just_pressed("skill_2"):
		try_activate_power_up()
	if Input.is_action_just_pressed("skill_3"):
		try_activate_laser_beam()
		
	# Cek input untuk menembak
	if fire_cooldown > 0:
		fire_cooldown -= get_physics_process_delta_time()
	elif Input.is_action_pressed("shoot"):
		shoot()
		fire_cooldown = fire_rate

func handle_movement():
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	handle_screen_wrap()
	update_animation()

func shoot():
	if not laser_scene: return
	
	sfx_laser.play()

	var laser_left = laser_scene.instantiate()
	get_parent().add_child(laser_left)
	laser_left.global_position = left_gun.global_position
	
	var laser_right = laser_scene.instantiate()
	get_parent().add_child(laser_right)
	laser_right.global_position = right_gun.global_position
	
	# Jika sedang power-up, ubah tampilan laser
	if is_powered_up:
		laser_left.set_as_power_shot()
		laser_right.set_as_power_shot()
		
func take_damage(amount: float):
	if damage_text_scene:
		var damage_text = damage_text_scene.instantiate()
		# Taruh di scene utama agar tidak ikut hancur dengan musuh
		get_tree().root.add_child(damage_text)
		# Mulai animasinya
		damage_text.show_damage(amount, global_position)
	# Untuk sementara, buat Player kebal saat Shield aktif
	if get_node_or_null("Shield") != null: return
		
	current_health -= amount
	print("Player health: ", current_health)
	GameEvents.player_health_updated.emit(current_health, max_health)
		
	if damage_text_scene:
		var damage_text = damage_text_scene.instantiate()
		get_tree().root.add_child(damage_text)
		damage_text.show_damage(amount, global_position)
		
	if current_health <= 0:
		GameEvents.player_died.emit()
		queue_free()

func spawn_explosion():
	if not explosion_scene: return
	var explosion = explosion_scene.instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = global_position

func on_rocket_hit(damage_amount: float):
	take_damage(damage_amount)

#==============================================================================
#  Fungsi Skill & Power-up
#==============================================================================

# --- SHIELD ---
func try_activate_shield():
	if shield_cooldown_timer.is_stopped():
		_execute_shield_skill()

func _execute_shield_skill():
	if not shield_scene: return
	print("Shield Activated!")
	shield_cooldown_timer.start(shield_cooldown_time)
	var shield = shield_scene.instantiate()
	add_child(shield)
	shield.activate()

# --- POWER UP ---
func try_activate_power_up():
	if powerup_cooldown_timer.is_stopped():
		_execute_power_up_skill()
	else:
		print("Power Up is on cooldown!")

func _execute_power_up_skill():
	if is_powered_up:
		powerup_duration_timer.start(powerup_duration)
		return
	print("Power Up Activated!")
	is_powered_up = true
	powerup_duration_timer.start(powerup_duration)
	powerup_cooldown_timer.start(powerup_cooldown_time)
	if powerup_activation_effect:
		var effect = powerup_activation_effect.instantiate()
		add_child(effect)
	speed = original_speed * powerup_speed_multiplier
	fire_rate = original_fire_rate / powerup_fire_rate_multiplier

# --- LASER BEAM ---
func try_activate_laser_beam():
	if beam_cooldown_timer.is_stopped():
		_execute_laser_beam_skill()
	else:
		print("Laser Beam is on cooldown!")

func _execute_laser_beam_skill():
	if is_instance_valid(active_beam) or not laser_beam_scene: return
	print("LASEEEER BEEEAM!")
	beam_cooldown_timer.start(beam_cooldown_time)
	var beam = laser_beam_scene.instantiate()
	active_beam = beam
	get_parent().add_child(beam)
	beam.global_position = muzzle_laser.global_position
	beam.rotation_degrees = -90
	beam.add_exception(self)
	beam.fire_full_sequence()

#==============================================================================
#  Fungsi Timeout dari Timer
#==============================================================================
func _on_powerup_duration_timer_timeout():
	print("Power Up expired.")
	is_powered_up = false
	speed = original_speed
	fire_rate = original_fire_rate

#==============================================================================
#  Fungsi Helper (Animasi & Batas Layar)
#==============================================================================
func start_spawn_animation(target_position: Vector2):
	var screen_size = get_viewport_rect().size
	global_position = Vector2(target_position.x, screen_size.y + 50)
	show()
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target_position, 1.5)
	await tween.finished
	is_spawning = false
	spawn_animation_finished.emit()

func handle_screen_wrap():
	var screen_size = get_viewport_rect().size
	if position.x > screen_size.x: position.x = 0
	elif position.x < 0: position.x = screen_size.x
	position.y = clamp(position.y, 0, screen_size.y)

func update_animation():
	if velocity.x < 0: animated_sprite.play("left")
	elif velocity.x > 0: animated_sprite.play("right")
	else: animated_sprite.play("default")
	
	# FUNGSI UNTUK SEKUENS KEMENANGAN
func move_to_victory_point(target_pos: Vector2, duration: float = 2.0):
	"""
	Mengunci input player dan menggerakkan player ke posisi target.
	Mengembalikan sinyal 'finished' dari Tween agar script lain bisa menunggu.
	"""
	is_movement_locked = true # Kunci input dan pergerakan manual
	
	var tween = create_tween()
	tween.set_parallel(false)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(self, "global_position", target_pos, duration)
	
	# Penting: kembalikan sinyal 'finished' agar World bisa 'await'
	return tween.finished
