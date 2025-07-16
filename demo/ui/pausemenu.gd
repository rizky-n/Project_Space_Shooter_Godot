# pausemenu.gd (Versi Final)
extends CanvasLayer

@onready var resume_button: Button = $menu_holder/resume
@onready var back_to_menu_button: Button = $menu_holder/quit

func _ready() -> void:
	hide()
	# Pastikan menu ini tidak ikut ter-pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Hubungkan tombol-tombol di dalam menu ini
	resume_button.pressed.connect(toggle_pause)

func _process(_delta: float):
	# Izinkan player untuk mem-pause dengan keyboard
	if Input.is_action_just_pressed("Pause"):
		toggle_pause()

# Fungsi utama untuk membuka/menutup menu
func toggle_pause():
	visible = not visible
	get_tree().paused = visible

func _on_back_to_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/mainmenu.tscn") 
