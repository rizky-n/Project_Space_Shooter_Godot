
extends Area2D

## 1. ATRIBUT DASAR & PENGATURAN
@export_group("Base Stats")
@export_range(10.0, 50.0) var base_health: float = 15.0
@export_range(50.0, 250.0) var base_speed: float = 100.0
@export_range(3.0, 15.0) var base_collision_damage: float = 5.0

@export_group("Randomization")
@export_range(0.5, 1.0) var min_scale: float = 0.8
@export_range(1.0, 2.5) var max_scale: float = 1.7
@export_range(0.0, 3.0) var rotation_speed_range: float = 1.5
@export_range(0, 90) var trajectory_spread_degrees: float = 45.0

@export_group("Required Scenes & Nodes")
@export var explosion_scene: PackedScene
@export var damage_text_scene: PackedScene

## 2. VARIABEL INTERNAL
var health: float
var max_health: float # Kita butuh ini lagi untuk menghitung persentase
var move_direction: Vector2
var rotation_speed: float
var is_dying: bool = false


## 3. FUNGSI BAWAAN GODOT
func _ready():
	randomize_attributes()
	# Pastikan animasi dimulai dari frame utuh
	$AnimatedSprite2D.animation = "default"
	$AnimatedSprite2D.frame = 0

func _physics_process(delta: float):
	global_position += move_direction * (base_speed / scale.x) * delta
	rotation += rotation_speed * delta
	check_screen_bounces()

## 4. FUNGSI KUSTOM
func randomize_attributes():
	var random_scale = randf_range(min_scale, max_scale)
	scale = Vector2.ONE * random_scale
	# Hitung dan simpan HP maksimal
	health = base_health * random_scale
	max_health = health
	
	rotation_speed = randf_range(-rotation_speed_range, rotation_speed_range)
	var angle_offset = deg_to_rad(randf_range(-trajectory_spread_degrees, trajectory_spread_degrees))
	move_direction = Vector2.DOWN.rotated(angle_offset)

func take_damage(amount: float):
	if is_dying: return
	
	if damage_text_scene:
		var damage_text = damage_text_scene.instantiate()
		# Taruh di scene utama agar tidak ikut hancur dengan musuh
		get_tree().root.add_child(damage_text)
		# Mulai animasinya
		damage_text.show_damage(amount, global_position)
		
	health -= amount
	
	if health <= 0:
		die()
	else:
		# Update tampilan visual HANYA JIKA belum mati
		update_visual_state()
		# Efek flash juga hanya berjalan jika belum mati
		var tween = create_tween()
		tween.tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.05)
		tween.tween_property($AnimatedSprite2D, "modulate", Color(1,1,1,1), 0.05)

func check_screen_bounces():
	var screen_size = get_viewport_rect().size
	
	# Cek batas kanan layar
	if global_position.x > screen_size.x:
		# 1. Koreksi posisi agar tidak terjebak di luar layar
		global_position.x = screen_size.x
		# 2. Pantulkan arah horizontalnya
		# Vector2.LEFT adalah 'normal' dari dinding kanan
		move_direction = move_direction.bounce(Vector2.LEFT)

	# Cek batas kiri layar
	elif global_position.x < 0:
		# 1. Koreksi posisi
		global_position.x = 0
		# 2. Pantulkan arah horizontalnya
		# Vector2.RIGHT adalah 'normal' dari dinding kiri
		move_direction = move_direction.bounce(Vector2.RIGHT)

# Fungsi baru untuk mengatur frame berdasarkan persentase HP
func update_visual_state():
	var health_percentage = health / max_health
	
	if health_percentage <= 0.2: # Di bawah 20% HP
		$AnimatedSprite2D.frame = 2 # Tampilan retak parah
	elif health_percentage <= 0.5: # Di bawah 50% HP
		$AnimatedSprite2D.frame = 1 # Tampilan retak sedikit
	else:
		$AnimatedSprite2D.frame = 0 # Tampilan utuh

# Fungsi die() 
func die():
	# Penjaga agar fungsi tidak berjalan ganda
	if is_dying: return
	is_dying = true
	
	# 1. Hentikan semua gerakan dan matikan collision
	set_physics_process(false)
	$CollisionPolygon2D.set_deferred("disabled", true)
	
	# 2. SEKARANG JUGA, munculkan scene ledakan eksternal
	#    (untuk suara, asap, dan efek utama)
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		# Pastikan explosion muncul di parent yang sama dengan meteor
		get_parent().add_child(explosion)
		explosion.global_position = global_position
	
	# 3. DI SAAT YANG SAMA, mainkan animasi hancurnya meteor itu sendiri
	$AnimatedSprite2D.play("destroy")
	
	# 4. TUNGGU sampai animasi hancur internal ini selesai
	await $AnimatedSprite2D.animation_finished
	
	# 5. Setelah animasi serpihan selesai, baru hancurkan node meteor
	queue_free()

func _on_body_entered(body: Node):
	if is_dying: return
	
	if body is Player:
		body.take_damage(base_collision_damage * scale.x)
		die()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
