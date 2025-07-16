# scrolling_background.gd
extends ParallaxBackground

@export var scroll_speed: float = 80.0

func _process(delta: float):
	# Setiap frame, gerakkan posisi scroll ke bawah
	scroll_offset.y += scroll_speed * delta
