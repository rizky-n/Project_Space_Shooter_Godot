extends Label

# Fungsi utama untuk memulai efek
func show_damage(amount: int, spawn_position: Vector2):
	# Atur teks dan posisi awal
	text = str(amount)
	global_position = spawn_position + Vector2(randf_range(-20, 20), 0) # Beri sedikit offset acak
	
	# Buat animasi mengambang dan menghilang
	var tween = create_tween().set_parallel(true) # a.set_parallel() membuat animasi berjalan bersamaan
	
	# Animasikan posisi Y ke atas
	tween.tween_property(self, "global_position:y", global_position.y - 60, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Animasikan transparansi (alpha) dari penuh menjadi hilang
	tween.tween_property(self, "modulate:a", 0.0, 1.0).set_delay(0.2)
	
	# Hancurkan diri sendiri setelah animasi selesai
	await tween.finished
	queue_free()
