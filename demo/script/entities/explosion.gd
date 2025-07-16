extends Node2D

@onready var sfx_destroy: AudioStreamPlayer2D = $SfxDestroy

func _ready():
	# Langsung mainkan animasi 'default' saat node ini dibuat
	$AnimatedSprite2D.play("default")
	sfx_destroy.play()
	# Hubungkan sinyal 'animation_finished' dari AnimatedSprite2D
	# ke fungsi queue_free() untuk menghancurkan node ini setelah animasi selesai.
	$AnimatedSprite2D.animation_finished.connect(queue_free)
