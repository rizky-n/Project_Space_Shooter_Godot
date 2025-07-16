# MainHUD.gd (Versi Final dengan Semua Perbaikan)
extends CanvasLayer

#==============================================================================
#  Referensi Node
#==============================================================================
@onready var score_label: Label = $TopUI/HBoxContainer/ScoreLabel
@onready var high_score_label: Label = $TopUI/HBoxContainer/HighScoreLabel
@onready var player_health_bar: ProgressBar = $BottomLeftUI/VBoxContainer/PlayerHealthBar
@onready var boss_ui: MarginContainer = $BossUI
@onready var boss_health_bar: ProgressBar = $BossUI/VBoxContainer/BossHealthBar
@onready var boss_name_label: Label = $BossUI/VBoxContainer/BossNameLabel

# Referensi untuk UI Overlay
@onready var game_over_overlay: TextureRect = $GameOverOverlay
@onready var victory_overlay: TextureRect = $VictoryOverlay
@onready var pause_menu = $TopRightUI/PauseButton/Pausemenu
@onready var sfx_victory: AudioStreamPlayer2D = $VictoryOverlay/SfxVictory

# Referensi untuk Tombol Skill (Ganti nama node jika perlu)
@onready var skill_1_button: TextureButton = $BottomLeftUI/VBoxContainer/SkillsContainer/Skill1Button
@onready var skill_2_button: TextureButton = $BottomLeftUI/VBoxContainer/SkillsContainer/Skill2Button
@onready var skill_3_button: TextureButton = $BottomLeftUI/VBoxContainer/SkillsContainer/Skill3Button

# Referensi untuk Tombol Pause & Game Over
@onready var pause_button: TextureButton = $TopRightUI/PauseButton
@onready var retry_button: Button = $GameOverOverlay/VBoxContainer/RetryButton
@onready var main_menu_button: Button = $GameOverOverlay/VBoxContainer/MainMenuButton
@onready var fade_overlay: ColorRect = $FadeOverlay

#==============================================================================
#  Variabel Internal
#==============================================================================
var score: int = 0
var high_score: int = 0
const HIGHSCORE_FILE_PATH = "user://highscore.dat"
var player = null
var boss = null

#==============================================================================
#  Fungsi Utama
#==============================================================================
func _ready() -> void:
	# Sembunyikan elemen yang tidak diperlukan di awal
	boss_ui.hide()
	game_over_overlay.hide()
	pause_menu.hide()
	victory_overlay.hide()
	# Sembunyikan juga UI utama di awal
	$TopUI.hide()
	$TopRightUI.hide()
	$BottomLeftUI.hide()
	
	load_high_score()
	
	# Hubungkan semua sinyal dari "Papan Pengumuman"
	GameEvents.score_updated.connect(_on_score_updated)
	GameEvents.boss_appeared.connect(_on_boss_appeared)
	GameEvents.boss_defeated.connect(_on_boss_defeated)
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.player_health_updated.connect(_on_player_health_updated)
	GameEvents.boss_health_updated.connect(_on_boss_health_updated)
	
	# Hubungkan tombol-tombol UI ke fungsinya
	pause_button.pressed.connect(_on_pause_button_pressed)
	retry_button.pressed.connect(_on_RetryButton_pressed)
	main_menu_button.pressed.connect(_on_MainMenuButton_pressed)
	
	# Hubungkan tombol skill ke fungsi barunya
	skill_1_button.pressed.connect(on_skill_1_button_pressed)
	skill_2_button.pressed.connect(on_skill_2_button_pressed)
	skill_3_button.pressed.connect(on_skill_3_button_pressed)

func _process(delta: float):
	## Periksa dan update health bar Boss setiap frame
	if is_instance_valid(boss):
		if boss_health_bar.max_value != boss.max_health:
			boss_health_bar.max_value = boss.max_health
		boss_health_bar.value = boss.current_health
	
	# Update Cooldown Skill
	if is_instance_valid(player):
		update_skill_cooldown(skill_1_button, player.shield_cooldown_timer)
		update_skill_cooldown(skill_2_button, player.powerup_cooldown_timer)
		update_skill_cooldown(skill_3_button, player.beam_cooldown_timer)

#==============================================================================
#  Fungsi-Fungsi Merespon Sinyal & Event
#==============================================================================
# Fungsi ini dipanggil saat Player selesai animasi masuk
# Fungsi ini dipanggil oleh sinyal dari Player (via World)
func on_player_spawn_finished():
	$TopUI.show()
	$TopRightUI.show()
	$BottomLeftUI.show()
	# Inisialisasi health bar player setelah HUD muncul
	if is_instance_valid(player):
		player_health_bar.max_value = player.max_health
		player_health_bar.value = player.current_health
		if player_health_bar.has_method("on_damage_taken"):
			player_health_bar.on_damage_taken()

func _on_player_health_updated(current_health: float, max_health: float):
	# Saat menerima sinyal, LANGSUNG update bar
	if player_health_bar.max_value != max_health:
		player_health_bar.max_value = max_health
		
	player_health_bar.value = current_health
	
	if player_health_bar.has_method("on_damage_taken"):
		player_health_bar.on_damage_taken()

func _on_score_updated(score_value: int):
	score += score_value
	score_label.text = "SCORE: %s" % score
	if score > high_score:
		high_score = score
		high_score_label.text = "HIGH: %s" % high_score

func _on_boss_appeared(boss_name: String, _max_health: float):
	# Kita hanya perlu menampilkan UI dan mengatur nama
	boss_name_label.text = boss_name
	# Cari referensi ke bos yang baru muncul
	boss = get_tree().get_first_node_in_group("boss")
	boss_ui.show()

func _on_boss_health_updated(current_health: float):
	if boss_health_bar.has_method("update_health"):
		boss_health_bar.update_health(current_health)

func _on_boss_defeated():
	boss_ui.hide()
	sfx_victory.play()    
	victory_overlay.show()

func _on_player_died():
	MusicController.play_defeatMusic()
	
	save_high_score()
	game_over_overlay.show()
	if game_over_overlay.has_node("VBoxContainer/ScoreLabel"):
		game_over_overlay.get_node("VBoxContainer/ScoreLabel").text = "SCORE: %s" % score
	if game_over_overlay.has_node("VBoxContainer/HighscoreLabel"):
		game_over_overlay.get_node("VBoxContainer/HighscoreLabel").text = "HIGH: %s" % high_score

#==============================================================================
#  Fungsi-Fungsi Tombol
#==============================================================================
func _on_pause_button_pressed():
	if pause_menu.has_method("toggle_pause"):
		pause_menu.toggle_pause()

func _on_RetryButton_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_MainMenuButton_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/mainmenu.tscn") 

# --- FUNGSI UNTUK TOMBOL SKILL ---
func on_skill_1_button_pressed():
	if is_instance_valid(player):
		player.try_activate_shield()

func on_skill_2_button_pressed():
	if is_instance_valid(player):
		player.try_activate_power_up()

func on_skill_3_button_pressed():
	if is_instance_valid(player):
		player.try_activate_laser_beam()

#==============================================================================
#  Fungsi Helper (Cooldown & High Score)
#==============================================================================
func update_skill_button(timer: Timer, button: TextureButton):
	var cooldown_label = button.get_node_or_null("CooldownLabel")
	if not cooldown_label: return
	
	if timer and not timer.is_stopped():
		button.disabled = true
		cooldown_label.visible = true
		cooldown_label.text = "%.1f" % timer.time_left
	else:
		button.disabled = false
		cooldown_label.visible = false

func save_high_score():
	var file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(high_score)

func load_high_score():
	if FileAccess.file_exists(HIGHSCORE_FILE_PATH):
		var file = FileAccess.open(HIGHSCORE_FILE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_var(true)
	high_score_label.text = "HIGH: %s" % high_score

func update_skill_cooldown(button: TextureButton, timer: Timer):
	var overlay: TextureProgressBar = button.get_node_or_null("CooldownOverlay")
	var label: Label = button.get_node_or_null("CooldownLabel")
	if not overlay or not label: return
	
	if timer and not timer.is_stopped():
		button.disabled = true
		overlay.visible = true
		label.visible = true
		label.text = "%.1f" % timer.time_left
		# Update bar radial berdasarkan sisa waktu
		overlay.value = timer.time_left / timer.wait_time * 100
	else:
		button.disabled = false
		overlay.visible = false
		label.visible = false

# Fungsi ini bisa dipanggil dari mana saja (dalam kasus ini, dari World)
func start_fade_out(duration: float = 1.0):
	"""
	Membuat layar menjadi gelap secara perlahan.
	Mengembalikan sinyal 'finished' agar script lain bisa menunggu.
	"""
	# Pastikan overlay terlihat sebelum dianimasikan
	fade_overlay.visible = true
	
	var tween = create_tween()
	
	# Kita akan menganimasikan properti 'color' dari transparan ke solid.
	# Warna awal sudah transparan, jadi kita hanya perlu tween ke warna tujuan.
	var target_color = Color.BLACK # Warna hitam pekat (alpha = 1.0)
	
	tween.tween_property(fade_overlay, "color", target_color, duration)
	
	# Kembalikan sinyal 'finished' agar World bisa 'await'
	return tween.finished
