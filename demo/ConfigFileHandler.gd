extends Node

const SETTINGS_FILE_PATH = "res://settings.ini"

func _ready():

	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		var initial_config = ConfigFile.new()
		initial_config.set_value("video", "fullscreen", false)
		initial_config.set_value("audio", "Master", 1.0)
		initial_config.set_value("audio", "MUSIC", 1.0)
		initial_config.set_value("audio", "SFX", 1.0)
		initial_config.save(SETTINGS_FILE_PATH)

func save_video_setting(key: String, value):
	var config = ConfigFile.new()
	config.load(SETTINGS_FILE_PATH)
	config.set_value("video", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_video_settings() -> Dictionary:
	var config = ConfigFile.new()
	
	if not FileAccess.file_exists(SETTINGS_FILE_PATH) or config.load(SETTINGS_FILE_PATH) != OK:
		return {}

	var video_settings = {}
	for key in config.get_section_keys("video"):
		video_settings[key] = config.get_value("video", key)
	return video_settings

func save_audio_setting(key: String, value):
	var config = ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_FILE_PATH):
		config.load(SETTINGS_FILE_PATH)

	config.set_value("audio", key, value)
	config.save(SETTINGS_FILE_PATH)
	
func load_audio_settings() -> Dictionary:
	var config = ConfigFile.new()

	if not FileAccess.file_exists(SETTINGS_FILE_PATH) or config.load(SETTINGS_FILE_PATH) != OK:
		print("Gagal memuat settings.ini atau file tidak ada.")
		return {}

	var audio_settings = {}
	for key in config.get_section_keys("audio"):
		audio_settings[key] = config.get_value("audio", key)
	return audio_settings
