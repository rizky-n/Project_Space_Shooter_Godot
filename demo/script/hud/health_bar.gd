extends ProgressBar

# Cukup referensi ke timer dan damage bar
@onready var timer = $Timer
@onready var damage_bar = $DamageBar

# Fungsi ini dipanggil dari HUD untuk memberitahu ada damage masuk
func on_damage_taken():
	# Mulai timer untuk menahan 'damage bar' di posisi lama
	timer.start()

# Saat timer selesai, samakan posisi damage bar dengan health bar
func _on_timer_timeout() -> void:
	damage_bar.value = value
