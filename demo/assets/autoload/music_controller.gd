extends Node

@onready var Music: AudioStreamPlayer2D = $Music
@onready var Defeat: AudioStreamPlayer2D = $DefeatMusic

func _ready():
	pass

func play_music():
	Music.play()
	
func play_defeatMusic():
	Defeat.play()
	
func stop_music():
	Music.stop()
