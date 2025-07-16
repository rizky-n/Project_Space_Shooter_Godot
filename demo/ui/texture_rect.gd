# scrolling_texture_rect.gd
extends TextureRect

@export var scroll_speed: float = 40.0 # Kecepatan scroll dalam piksel per detik

func _process(delta: float):
	# Animasikan offset dari material untuk menciptakan ilusi scroll
	# Pastikan node ini memiliki CanvasItemMaterial
	if material:
		material.scroll_offset.y -= scroll_speed * delta
