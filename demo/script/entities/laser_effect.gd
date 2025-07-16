extends Node2D

func _ready():
	# Langsung mainkan animasi 'default' saat node ini dibuat
	$AnimatedSprite2D.play("default")
	# Hubungkan sinyal 'animation_finished' dari AnimatedSprite2D
	# ke fungsi queue_free() untuk menghancurkan node ini setelah animasi selesai.
	$AnimatedSprite2D.animation_finished.connect(queue_free)
