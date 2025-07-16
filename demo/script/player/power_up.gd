# power_up_effect.gd
extends Node2D # Sesuai dengan root node Anda

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var SfxActivate: AudioStreamPlayer2D = $SfxActivate

func _ready():
	# Mainkan animasi 'default'
	animated_sprite.play("default")
	SfxActivate.play()
	# Tunggu sampai sinyal animation_finished terpancar
	await animated_sprite.animation_finished
	# Setelah animasi selesai, hancurkan node ini
	queue_free()
