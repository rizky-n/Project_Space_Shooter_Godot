# boss_rocket.gd (Versi Homing - Mengikuti Player)
extends Area2D

@export_group("Rocket Stats")
@export var health: float = 6.0
@export var speed: float = 250.0 # Kecepatan sedikit dikurangi untuk homing
@export var damage: float = 8.0

@export_group("Homing Behavior")
@export var lifetime: float = 12.0 # Waktu mengikuti player dalam detik
@export var turn_speed: float = 3.0 # Seberapa cepat roket bisa berputar (radian per detik)
@export var homing_strength: float = 1.0 # Kekuatan homing (0-1)

@export_group("Required Scenes")
@export var explosion_scene: PackedScene

var direction: Vector2 = Vector2.DOWN
var is_dying: bool = false
var player_target: Node2D
var homing_active: bool = true

func _ready():
	# Ambil referensi player
	player_target = get_tree().get_first_node_in_group("player")
	
	# Inisialisasi arah awal
	if is_instance_valid(player_target):
		direction = (player_target.global_position - global_position).normalized()
	else:
		direction = Vector2.DOWN
	
	# Atur rotasi awal
	rotation = direction.angle() + PI / 2.0
	
	# Hubungkan sinyal
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Timer untuk menghentikan homing setelah 12 detik
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		die()

func _physics_process(delta: float):
	if is_dying:
		return
	
	# LOGIKA HOMING: Cari target dan putar ke arahnya
	if homing_active and is_instance_valid(player_target):
		# Hitung arah ke target
		var target_direction = (player_target.global_position - global_position).normalized()
		
		# Hitung sudut yang dibutuhkan untuk mencapai target
		var target_angle = target_direction.angle()
		var current_angle = direction.angle()
		
		# Hitung perbedaan sudut (dengan normalisasi -PI hingga PI)
		var angle_diff = fmod(target_angle - current_angle + PI, TAU) - PI
		
		# Batasi kecepatan berputar
		var max_turn = turn_speed * delta
		angle_diff = clamp(angle_diff, -max_turn, max_turn)
		
		# Update arah berdasarkan rotasi
		var new_angle = current_angle + angle_diff
		direction = Vector2.from_angle(new_angle)
		
		# Update rotasi visual roket
		rotation = direction.angle() + PI / 2.0
	
	# Gerakkan roket ke arah yang sudah dihitung
	global_position += direction * speed * delta

func take_damage(amount: float):
	if is_dying:
		return
	
	health -= amount
	if health <= 0:
		die()

func die():
	if is_dying:
		return
	
	is_dying = true
	homing_active = false
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Spawn explosion jika ada
	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_parent().add_child(explosion)
		explosion.global_position = global_position
	
	queue_free()

func _on_area_entered(area):
	if area.is_in_group("player_projectile"):
		take_damage(area.damage if area.has_method("get_damage") else 1.0)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Berikan damage ke player
		if body.has_method("take_damage"):
			body.take_damage(damage)
		die()
