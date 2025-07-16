class_name Enemy
extends Area2D

@export_group("Shooting")

## Variabel yang bisa diatur dari editor
@export var health: float = 10.0
@export var damage: float = 3.0  
@export var speed: float = 100.0
@export var explosion_scene: PackedScene
@export var bullet_scene: PackedScene
@export var damage_text_scene: PackedScene
@export var fire_cooldown: float = 3.0

## Referensi ke node-node di dalam scene
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var muzzle: Marker2D = $Muzzle

# Variabel 
@export var score_value: int = 100

var is_dying: bool = false
var fire_timer: float = 0.0

func _physics_process(delta: float):
	# Gerakkan musuh lurus ke bawah
	global_position.y += speed * delta
	
	# LOGIKA MENEMBAK
	# Hanya berjalan jika musuh tidak sedang dalam proses mati
	if not is_dying:
		# Hitung mundur cooldown
		if fire_timer > 0:
			fire_timer -= delta
		else:
			# Jika cooldown selesai, tembak!
			shoot()
			# Reset cooldown (tambahkan sedikit acak agar tidak monoton)
			fire_timer = fire_cooldown + randf_range(-0.5, 0.5)

# Fungsi untuk menerima kerusakan
func take_damage(amount: float):
	# Panggil scene teks damage
	if damage_text_scene:
		var damage_text = damage_text_scene.instantiate()
		# Taruh di scene utama agar tidak ikut hancur dengan musuh
		get_tree().root.add_child(damage_text)
		# Mulai animasinya
		damage_text.show_damage(amount, global_position)
	
	health -= amount
	if health <= 0 and not is_dying:
		die()

# Proses kematian musuh
func die():
	is_dying = true
	# Nonaktifkan collision agar tidak memicu interaksi lain
	collision_shape.set_deferred("disabled", true)

	# Panggil fungsi untuk memunculkan ledakan
	spawn_explosion()

	# Sembunyikan sprite dan mainkan suara ledakan
	sprite.hide()
	GameEvents.score_updated.emit(score_value)
	queue_free()

# Fungsi baru untuk membuat ledakan
func spawn_explosion():
	# Pastikan scene ledakan sudah dimasukkan di inspector
	if not explosion_scene: return
	
	# Buat instance dari scene ledakan
	var explosion = explosion_scene.instantiate()
	# Tambahkan ledakan ke scene utama
	get_parent().add_child(explosion)
	# Atur posisi ledakan sama dengan posisi musuh
	explosion.global_position = global_position

func _on_area_entered(area: Area2D):
	# Cek apakah yang masuk adalah laser dari grup 'player_lasers'
	if area.is_in_group("player_lasers"):
		# Beri kerusakan pada diri sendiri sebesar 1 (sesuai spesifikasi)
		take_damage(1)
		# Hancurkan laser yang menabrak
		area.queue_free()

# Terpicu saat Area2D ini memasuki PhysicsBody2D (misal: player)
func _on_body_entered(body: Node):
	# Cek apakah body yang ditabrak adalah Player
	if body is Player:
		# Beri kerusakan pada player
		body.take_damage(damage)
		# Hancurkan diri sendiri setelah menabrak player
		die()

func shoot():
	# Pastikan bullet scene sudah diatur di Inspector
	if not bullet_scene: return

	# Buat instance peluru
	var bullet = bullet_scene.instantiate()
	
	# Tambahkan peluru ke scene utama
	get_parent().add_child(bullet)
	# Atur posisi awal peluru di Muzzle
	bullet.global_position = muzzle.global_position
	# Putar 180 derajat agar bergerak ke bawah
	bullet.rotation_degrees = 180

# Fungsi ini akan dipanggil oleh Player saat menembak dalam mode power-up
func set_as_power_shot():
	# Cek dulu apakah animasi "power_up" ada di dalam AnimatedSprite2D
	if $AnimatedSprite2D.sprite_frames.has_animation("power_up"):
		$AnimatedSprite2D.play("power_up")
	
	# Cek apakah node suara power-up ada sebelum memainkannya
	if has_node("SfxPowerUp"):
		$SfxPowerUp.play()

# Terpicu saat musuh keluar dari layar
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
