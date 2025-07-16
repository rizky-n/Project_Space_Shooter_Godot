# spinning_ship.gd
extends Area2D

## 1. ATRIBUT YANG BISA DIATUR
@export_group("Stats")
@export var health: float = 26.0
@export var damage: float = 15.0
@export var speed: float = 100.0 # Kecepatan gerak maju
@export var rotation_speed: float = 1.2 # Kecepatan berputar (radian per detik)
@export var score_value: int = 200

@export_group("Shooting")
@export var bullet_scene: PackedScene # Gunakan scene enemy_bullet.tscn
@export var fire_cooldown: float = 4.0

@export_group("Required Scenes")
@export var explosion_scene: PackedScene
@export var damage_text_scene: PackedScene


## 2. VARIABEL INTERNAL
@onready var muzzles: Marker2D = $Muzzle # Referensi ke wadah meriam
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var sprite: Sprite2D = $Sprite2D

var fire_timer: float = 0.0
var is_dying: bool = false


## 3. FUNGSI BAWAAN GODOT
func _ready():
	if has_node("VisibleOnScreenNotifier2D"):
		$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _physics_process(delta: float):
	# Perilaku utama: bergerak maju DAN berputar
	global_position.y += speed * delta
	rotation += rotation_speed * delta # Ini yang membuatnya berputar
	
	# Logika menembak
	if not is_dying:
		if fire_timer > 0:
			fire_timer -= delta
		else:
			shoot()
			fire_timer = fire_cooldown

## 4. FUNGSI KUSTOM
# FUNGSI SHOOT() VERSI BARU YANG LEBIH BAIK
func shoot():
	if not bullet_scene: return
	
	# Loop melalui setiap meriam yang ada di dalam node 'Muzzles'
	for muzzle in muzzles.get_children():
		# Pastikan yang kita ambil adalah Marker2D
		if muzzle is Marker2D:
			var bullet = bullet_scene.instantiate()
			get_parent().add_child(bullet)
			
			# Atur posisi awal peluru di Muzzle (tetap sama)
			bullet.global_position = muzzle.global_position
			
			# --- LOGIKA ROTASI BARU YANG LEBIH KUAT ---
			# 1. Hitung vektor arah dari pusat kapal ke posisi meriam.
			#    Ini akan selalu memberikan arah yang benar "menjauh dari pusat".
			var fire_direction = (muzzle.global_position - global_position).normalized()
			
			# 2. Atur rotasi peluru agar "atas"-nya menghadap ke arah tersebut.
			#    Kita perlu menambahkan PI/2 (90 derajat) karena 'atas' pada sprite
			#    dianggap sebagai (0, -1), bukan (1, 0) yang menjadi dasar .angle().
			bullet.rotation = fire_direction.angle() + PI / 2.0
			
			# Atur damage peluru seperti biasa
			if bullet.has_method("set"):
				bullet.set("damage", 3.0)


# Bagian ini sama persis dengan musuh lain, menunjukkan pola desain yang baik!
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
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)
		tween.tween_property(sprite, "modulate", Color(1,1,1,1), 0.05)

func die():
	if is_dying: return
	is_dying = true
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	sprite.hide()
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_parent().add_child(explosion)
		explosion.global_position = global_position
		
	GameEvents.score_updated.emit(score_value)
	queue_free()

func _on_body_entered(body: Node):
	if is_dying: return
	if body is Player:
		# Musuh ini tidak memberikan damage tabrakan, hanya menembak
		body.take_damage(damage)
		pass
