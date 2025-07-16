extends ParallaxLayer

@export var scroll_speed: float = 50.0 

func _process(delta: float) -> void:
	# Ganti baris ini dari .x menjadi .y untuk pergerakan vertikal
	motion_offset.y += scroll_speed * delta
