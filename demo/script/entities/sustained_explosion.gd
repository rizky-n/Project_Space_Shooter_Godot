# sustained_explosion.gd
extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var timer: Timer = $Timer

func _ready():
	# Hubungkan sinyal timeout dari timer ke fungsi untuk menghancurkan diri
	timer.timeout.connect(queue_free)

# Fungsi utama untuk memulai efek ini dari luar
func start(duration: float):
	animated_sprite.play()
	if audio_player.stream: # Hanya mainkan jika ada suara
		audio_player.play()
	
	# Mulai timer durasi, setelah selesai, node ini akan hancur
	timer.start(duration)
