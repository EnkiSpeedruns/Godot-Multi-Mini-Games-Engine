extends Node

## SettingsManager - Sistema global de configuración
##
## Maneja settings de display, audio, y controles
## Se integra con GameManager para persistencia

# Señales
signal setting_changed(setting_name: String, value: Variant)
signal display_mode_changed(mode: DisplayServer.WindowMode)
signal resolution_changed(resolution: Vector2i)

# Configuración actual
var current_settings: Dictionary = {
	"display": {
		"mode": DisplayServer.WINDOW_MODE_WINDOWED,
		"resolution": Vector2i(1920, 1080),
		"vsync": true
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0
	}
}

# Resoluciones disponibles (comunes)
const AVAILABLE_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(800, 600),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

func _ready() -> void:
	_load_settings()
	_apply_all_settings()
	
	print("SettingsManager initialized")
	print("Current mode: %s" % _get_mode_name(current_settings.display.mode))
	print("Current resolution: %s" % current_settings.display.resolution)

func _load_settings() -> void:
	var saved_mode = GameManager.load_setting("display_mode", DisplayServer.WINDOW_MODE_WINDOWED)
	var saved_resolution = GameManager.load_setting("display_resolution", Vector2i(1920, 1080))
	var saved_vsync = GameManager.load_setting("display_vsync", true)
	
	var saved_master = GameManager.load_setting("master_volume", 1.0)
	var saved_music = GameManager.load_setting("music_volume", 0.8)
	var saved_sfx = GameManager.load_setting("sfx_volume", 1.0)
	
	current_settings.display.mode = saved_mode
	current_settings.display.resolution = saved_resolution
	current_settings.display.vsync = saved_vsync
	
	current_settings.audio.master_volume = saved_master
	current_settings.audio.music_volume = saved_music
	current_settings.audio.sfx_volume = saved_sfx

func _apply_all_settings() -> void:
	# Aplicar en orden correcto: primero modo, luego resolución
	set_display_mode(current_settings.display.mode, true)  # true = no guardar
	set_resolution(current_settings.display.resolution, true)  # true = no guardar
	set_vsync(current_settings.display.vsync, true)  # true = no guardar

## Versión corregida de set_display_mode
func set_display_mode(mode: DisplayServer.WindowMode, skip_save: bool = false) -> void:
	# Guardar resolución actual antes de cambiar modo
	var current_resolution = current_settings.display.resolution
	
	# Cambiar modo
	DisplayServer.window_set_mode(mode)
	current_settings.display.mode = mode
	
	# Si estamos en modo ventana, asegurar que la resolución sea correcta
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		# Aplicar la resolución guardada
		DisplayServer.window_set_size(current_resolution)
		_center_window(current_resolution)
	
	if not skip_save:
		GameManager.save_setting("display_mode", mode)
	
	display_mode_changed.emit(mode)
	setting_changed.emit("display_mode", mode)
	print("Display mode changed to: %s" % _get_mode_name(mode))

## Versión corregida de set_resolution
func set_resolution(resolution: Vector2i, skip_save: bool = false) -> void:
	# Obtener el modo actual
	var current_mode = DisplayServer.window_get_mode()
	
	# Solo aplicar tamaño si estamos en modo ventana
	if current_mode == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(resolution)
		_center_window(resolution)
	else:
		# Si estamos en fullscreen, solo guardamos la resolución
		# Se aplicará cuando cambiemos a modo ventana
		print("Resolution change deferred - currently in fullscreen mode")
	
	current_settings.display.resolution = resolution
	
	if not skip_save:
		GameManager.save_setting("display_resolution", resolution)
	
	resolution_changed.emit(resolution)
	setting_changed.emit("resolution", resolution)
	print("Resolution set to: %dx%d" % [resolution.x, resolution.y])

## Función auxiliar para centrar ventana
func _center_window(resolution: Vector2i) -> void:
	var screen_size = DisplayServer.screen_get_size()
	var window_pos = (screen_size - resolution) / 2
	DisplayServer.window_set_position(window_pos)

## Versión corregida de set_vsync
func set_vsync(enabled: bool, skip_save: bool = false) -> void:
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	current_settings.display.vsync = enabled
	
	if not skip_save:
		GameManager.save_setting("display_vsync", enabled)
	
	setting_changed.emit("vsync", enabled)
	print("VSync: %s" % ("enabled" if enabled else "disabled"))

## Versión mejorada de toggle_fullscreen
func toggle_fullscreen() -> void:
	if current_settings.display.mode == DisplayServer.WINDOW_MODE_WINDOWED:
		# Cambiar a fullscreen
		set_display_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Cambiar a ventana - restaurar resolución guardada
		set_display_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# Asegurar que la resolución se aplique al volver a ventana
		DisplayServer.window_set_size(current_settings.display.resolution)
		_center_window(current_settings.display.resolution)

func set_master_volume(volume: float) -> void:
	volume = clamp(volume, 0.0, 1.0)
	current_settings.audio.master_volume = volume
	GameManager.save_setting("master_volume", volume)
	setting_changed.emit("master_volume", volume)

func set_music_volume(volume: float) -> void:
	volume = clamp(volume, 0.0, 1.0)
	current_settings.audio.music_volume = volume
	GameManager.save_setting("music_volume", volume)
	setting_changed.emit("music_volume", volume)

func set_sfx_volume(volume: float) -> void:
	volume = clamp(volume, 0.0, 1.0)
	current_settings.audio.sfx_volume = volume
	GameManager.save_setting("sfx_volume", volume)
	setting_changed.emit("sfx_volume", volume)

func get_display_mode() -> DisplayServer.WindowMode:
	return current_settings.display.mode

func get_resolution() -> Vector2i:
	return current_settings.display.resolution

func get_vsync() -> bool:
	return current_settings.display.vsync

func get_master_volume() -> float:
	return current_settings.audio.master_volume

func get_music_volume() -> float:
	return current_settings.audio.music_volume

func get_sfx_volume() -> float:
	return current_settings.audio.sfx_volume

func get_available_resolutions() -> Array[Vector2i]:
	return AVAILABLE_RESOLUTIONS

func reset_to_defaults() -> void:
	set_display_mode(DisplayServer.WINDOW_MODE_WINDOWED, false)
	set_resolution(Vector2i(1920, 1080), false)
	set_vsync(true, false)
	set_master_volume(1.0)
	set_music_volume(0.8)
	set_sfx_volume(1.0)
	print("Settings reset to defaults")

func _get_mode_name(mode: DisplayServer.WindowMode) -> String:
	match mode:
		DisplayServer.WINDOW_MODE_WINDOWED:
			return "Windowed"
		DisplayServer.WINDOW_MODE_FULLSCREEN:
			return "Fullscreen"
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			return "Exclusive Fullscreen"
		DisplayServer.WINDOW_MODE_MINIMIZED:
			return "Minimized"
		DisplayServer.WINDOW_MODE_MAXIMIZED:
			return "Maximized"
		_:
			return "Unknown"

func get_resolution_index(resolution: Vector2i) -> int:
	for i in range(AVAILABLE_RESOLUTIONS.size()):
		if AVAILABLE_RESOLUTIONS[i] == resolution:
			return i
	return 0
