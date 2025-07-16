# SkillButton.gd
extends TextureButton

@onready var cooldown_overlay: TextureProgressBar = $CooldownOverlay
@onready var cooldown_label: Label = $CooldownLabel

# Variabel untuk menyimpan referensi ke timer yang relevan di Player
var cooldown_timer: Timer

func _ready():
	# Sembunyikan visual cooldown di awal
	cooldown_overlay.visible = false
	cooldown_label.visible = false

# Fungsi ini akan dipanggil oleh HUD setiap frame
func update_cooldown_visuals():
	# Jika timer belum di-set atau sudah berhenti, sembunyikan overlay & label
	if not cooldown_timer or cooldown_timer.is_stopped():
		cooldown_overlay.visible = false
		cooldown_label.visible = false
		disabled = false # Tombol bisa dipencet lagi
	else:
		# Jika timer berjalan, tampilkan visual cooldown
		cooldown_overlay.visible = true
		cooldown_label.visible = true
		disabled = true # Tombol tidak bisa dipencet saat cooldown
		
		# Update angka dan bar radial
		cooldown_label.text = "%.1f" % cooldown_timer.time_left
		cooldown_overlay.value = cooldown_timer.time_left / cooldown_timer.wait_time * 100
