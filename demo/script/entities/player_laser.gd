# player_laser.gd (Versi Final Sederhana)
class_name Projectile
extends Area2D

## Variabel yang bisa diatur
@export var speed: float = 900.0
@export var damage: float = 1.0
@export var hit_effect_scene: PackedScene # Efek untuk tembakan biasa
@export var power_shot_explosion: PackedScene # Efek untuk tembakan power-up

## Variabel status internal
var is_power_shot: bool = false

func _ready():
	area_entered.connect(_on_target_entered)
	body_entered.connect(_on_target_entered)
	if has_node("VisibleOnScreenNotifier2D"):
		$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _process(delta: float):
	global_position += -transform.y * speed * delta

# Fungsi ini dipanggil oleh Player untuk mengubah laser ini menjadi power shot
func set_as_power_shot():
	is_power_shot = true
	# Mainkan animasi terbang power-up yang looping
	if $AnimatedSprite2D.sprite_frames.has_animation("power_shoot_fly"):
		$AnimatedSprite2D.play("power_shoot_fly")
	
	if has_node("SfxPowerUp"):
		$SfxPowerUp.play()

# Fungsi ini berjalan saat laser mengenai sesuatu
func _on_target_entered(target: Node):
	# Cek jika target bisa menerima damage
	if target.has_method("take_damage"):
		target.take_damage(damage)
		
		# Logika simpel: Cek apakah ini power shot atau bukan
		if is_power_shot:
			# Jika power shot, munculkan ledakan besar
			spawn_effect(power_shot_explosion)
		else:
			# Jika tembakan biasa, munculkan hitspark biasa
			spawn_effect(hit_effect_scene)
		
		# Hancurkan laser setelah memunculkan efek
		queue_free()

# Satu fungsi untuk memunculkan semua jenis efek
func spawn_effect(effect_scene: PackedScene):
	if not effect_scene: return
	
	var effect = effect_scene.instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position
