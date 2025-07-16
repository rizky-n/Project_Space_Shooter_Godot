# scenery_object.gd
extends Sprite2D # Menggunakan Sprite2D sebagai root karena ini murni visual

# Properti ini bisa diatur dari Inspector untuk setiap objek
@export var move_speed: float = 60.0
@export_range(-2.0, 2.0) var rotation_speed: float = 0.3 # radian per detik

func _ready():
	# Beri rotasi awal yang acak agar tidak semua objek menghadap arah yang sama
	rotation = randf_range(0, TAU) # TAU sama dengan 2 * PI atau 360 derajat
	# Acak kecepatan putaran agar ada yang searah/berlawanan jarum jam
	rotation_speed = randf_range(-rotation_speed, rotation_speed)

func _process(delta: float):
	# Gerakkan objek ke bawah
	position.y += move_speed * delta
	# Putar objek secara terus-menerus
	rotation += rotation_speed * delta

# Fungsi ini akan dihubungkan ke sinyal dari VisibleOnScreenNotifier2D
func _on_screen_exited():
	queue_free() # Hancurkan diri sendiri
