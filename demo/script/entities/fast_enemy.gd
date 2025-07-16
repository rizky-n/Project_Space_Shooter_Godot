extends Area2D

## 1. ATRIBUT YANG BISA DIATUR
@export_group("Stats")
@export var health: float = 8.0
@export var damage: float = 4.0
@export var speed: float = 350.0
@export var score_value: int = 50

@export_group("Required Scenes")
@export var explosion_scene: PackedScene
@export var damage_text_scene: PackedScene


## 2. VARIABEL INTERNAL
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var sprite: Sprite2D = $Sprite2D # Ganti ke AnimatedSprite2D jika Anda pakai itu

var is_dying: bool = false

## 3. FUNGSI BAWAAN GODOT
func _ready():
	# Hubungkan sinyal tabrakan dari kode untuk memastikan selalu terhubung
	# Jika Anda punya VisibleNotifier, hubungkan juga di sini
	if has_node("VisibleOnScreenNotifier2D"):
		$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _physics_process(delta: float):
	# Perilaku utama: hanya bergerak lurus ke bawah dengan cepat
	global_position.y += speed * delta


## 4. FUNGSI KUSTOM (Sama seperti musuh lain untuk konsistensi)
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
		# Efek flash saat tertembak
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
		body.take_damage(damage)
		die()
