# CameraShaker.gd
extends Node

# Ambil referensi ke parent (Camera2D) dan timer
@onready var camera: Camera2D = get_parent()
@onready var shake_timer: Timer = $ShakeTimer

var shake_strength: float = 0.0

func _ready():
	# Hubungkan sinyal timeout dari timer ke fungsi untuk menghentikan getaran
	shake_timer.timeout.connect(_on_shake_timer_timeout)
	# Matikan proses fisika di awal, hanya aktif saat ada getaran
	set_process(false)

func _process(_delta):
	# Setiap frame selama getaran, beri offset acak pada kamera
	var offset = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	) * shake_strength
	camera.offset = offset

# Ini adalah FUNGSI UTAMA yang akan kita panggil dari Player atau Boss
func shake(strength: float, duration: float):
	# Jika sudah bergetar, jangan tumpuk efeknya
	if not shake_timer.is_stopped():
		return
		
	print("Camera Shake! Strength: ", strength, " Duration: ", duration)
	self.shake_strength = strength
	shake_timer.wait_time = duration
	shake_timer.start()
	# Aktifkan _process agar kamera mulai bergetar
	set_process(true)

# Fungsi ini berjalan saat ShakeTimer selesai
func _on_shake_timer_timeout():
	print("Shake finished.")
	# Matikan _process agar getaran berhenti
	set_process(false)
	# PENTING: Kembalikan posisi kamera ke tengah
	camera.offset = Vector2.ZERO
