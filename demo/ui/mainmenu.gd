extends Node2D

var level: int = 1

@onready var mainvolslider = $CenterContainer/SettingsMenu/mainvolslider
@onready var musicvolslider = $CenterContainer/SettingsMenu/musicvolslider
@onready var sfxvolslider = $CenterContainer/SettingsMenu/sfxvolslider
@onready var fullscreen_checkbutton = $CenterContainer/SettingsMenu/fullscreen

func _ready() -> void:
	MusicController.play_music()
	$CenterContainer/SettingsMenu/fullscreen.button_pressed = true if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN else false
	$CenterContainer/SettingsMenu/mainvolslider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	$CenterContainer/SettingsMenu/musicvolslider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("MUSIC")))
	$CenterContainer/SettingsMenu/sfxvolslider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	
	var video_settings = ConfigFileHandler.load_video_settings()
	fullscreen_checkbutton.button_pressed = video_settings.fullscreen
	
	var audio_settings = ConfigFileHandler.load_audio_settings()
	mainvolslider.value = min(audio_settings["Master"], 1.0) * 100
	musicvolslider.value = min(audio_settings["MUSIC"], 1.0) * 100
	sfxvolslider.value = min(audio_settings["SFX"], 1.0) * 100

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(str("res://ui/level_select_menu.tscn"))


func _on_settings_pressed() -> void:
	$CenterContainer/MainButtons.visible = false
	$CenterContainer/SettingsMenu.visible = true


func _on_credits_pressed() -> void:
	$CenterContainer/MainButtons.visible = false
	$CenterContainer/CreditsMenu.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	$CenterContainer/MainButtons.visible = true
	if $CenterContainer/SettingsMenu.visible:
		$CenterContainer/SettingsMenu.visible = false
		$CenterContainer/MainButtons/settings.grab_focus()
	if $CenterContainer/CreditsMenu.visible:
		$CenterContainer/CreditsMenu.visible = false
		$CenterContainer/MainButtons/credits.grab_focus()


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	ConfigFileHandler.save_video_setting("fullscreen", toggled_on)


func _on_mainvolslider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)

func _on_musicvolslider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("MUSIC"), value)

func _on_sfxvolslider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), value)

func _on_mainvolslider_drag_ended(value_changed):
	if value_changed:
		ConfigFileHandler.save_audio_setting("Master", mainvolslider.value / 100)

func _on_musicvolslider_drag_ended(value_changed):
	if value_changed:
		ConfigFileHandler.save_audio_setting("MUSIC", musicvolslider.value / 100)

func _on_sfxvolslider_drag_ended(value_changed):
	if value_changed:
		ConfigFileHandler.save_audio_setting("SFX", sfxvolslider.value / 100)
