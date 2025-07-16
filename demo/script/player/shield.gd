extends Area2D

## ATRIBUT SHIELD - Bisa diatur dari Inspector scene Shield
@export var duration: float = 4.0 # Durasi aktif perisai dalam detik

## REFERENSI NODE
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var duration_timer: Timer = $DurationTimer
@onready var sfx_activate: AudioStreamPlayer2D = $SfxActivate
@onready var sfx_hit: AudioStreamPlayer2D = $SfxHit

# Fungsi ini akan dipanggil oleh Player untuk memulai semuanya
func activate():
	# Atur timer sesuai durasi dan mulai hitung mundur
	duration_timer.wait_time = duration
	duration_timer.start()
	
	# Jalankan animasi muncul
	appear_animation()

func appear_animation():
	scale = Vector2.ZERO
	sfx_activate.play()
	
	var tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.5)

func disappear_animation():
	# Matikan collision agar tidak bisa kena hit saat animasi hilang
	collision_shape.disabled = true
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	
	# Setelah animasi hilang selesai, hancurkan diri sendiri
	await tween.finished
	queue_free()

# Fungsi ini akan menangani semua yang masuk ke dalam perisai
# Baik itu Area2D (peluru musuh) maupun Body (musuh)
func _on_thing_entered(thing: Node2D):
	# Cek apakah yang masuk adalah dari grup "enemies" atau "enemy_projectiles"
	if thing.is_in_group("enemies") or thing.is_in_group("enemy_projectiles"):
		# Mainkan suara 'hit'
		sfx_hit.play()
		# Hancurkan musuh atau peluru yang menyentuh perisai
		thing.queue_free()
