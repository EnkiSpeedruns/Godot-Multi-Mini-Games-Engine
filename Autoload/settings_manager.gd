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
		"mode": DisplayServer.WINDOW_MODE_WINDOWED,  # Windowed por defecto
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
	Vector2i(1920, 1080),  # 16:9 Full HD
	Vector2i(1600, 900),   # 16:9 HD+
	Vector2i(1366, 768),   # 16:9 HD
	Vector2i(1280, 720),   # 16:9 HD
	Vector2i(1024, 768),   # 4:3 XGA
	Vector2i(800, 600),    # 4:3 SVGA
	Vector2i(2560, 1440),  # 16:9 2K
	Vector2i(3840, 2160),  # 16:9 4K
]

func _ready() -> void:
	# Cargar settings guardados
	_load_settings()
	
	# Aplicar settings cargados
	_apply_all_settings()
	
	print("SettingsManager initialized")
	print("Current mode: %s" % _get_mode_name(current_settings.display.mode))
	print("Current resolution: %s" % current_settings.display.resolution)

## Carga settings desde GameManager
func _load_settings() -> void:
	# Cargar cada setting individual
	var saved_mode = GameManager.load_setting("display_mode", DisplayServer.WINDOW_MODE_WINDOWED)
	var saved_resolution = GameManager.load_setting("display_resolution", Vector2i(1920, 1080))
	var saved_vsync = GameManager.load_setting("display_vsync", true)
	
	var saved_master = GameManager.load_setting("master_volume", 1.0)
	var saved_music = GameManager.load_setting("music_volume", 0.8)
	var saved_sfx = GameManager.load_setting("sfx_volume", 1.0)
	
	# Actualizar diccionario
	current_settings.display.mode = saved_mode
	current_settings.display.resolution = saved_resolution
	current_settings.display.vsync = saved_vsync
	
	current_settings.audio.master_volume = saved_master
	current_settings.audio.music_volume = saved_music
	current_settings.audio.sfx_volume = saved_sfx

## Aplica todos los settings al iniciar
func _apply_all_settings() -> void:
	set_display_mode(current_settings.display.mode)
	set_resolution(current_settings.display.resolution)
	set_vsync(current_settings.display.vsync)
	
	# Audio se aplicará cuando tengamos AudioManager
	# Por ahora solo guardamos los valores

## Cambia el modo de display (Fullscreen, Windowed, etc.)
func set_display_mode(mode: DisplayServer.WindowMode) -> void:
	DisplayServer.window_set_mode(mode)
	current_settings.display.mode = mode
	GameManager.save_setting("display_mode", mode)
	display_mode_changed.emit(mode)
	setting_changed.emit("display_mode", mode)
	print("Display mode changed to: %s" % _get_mode_name(mode))

## Cambia la resolución de la ventana
func set_resolution(resolution: Vector2i) -> void:
	# Guardar el modo actual ANTES de obtenerlo
	var current_mode = DisplayServer.window_get_mode()
	
	# Solo aplicar tamaño si no estamos en fullscreen exclusivo
	if current_mode != DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		# FIX: Primero cambiar a windowed si estamos en fullscreen normal
		if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			# Esperar un frame para que el cambio se aplique
			await get_tree().process_frame
		
		DisplayServer.window_set_size(resolution)
		
		# Centrar ventana
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - resolution) / 2
		DisplayServer.window_set_position(window_pos)
		
		# Si estábamos en fullscreen, volver a ese modo
		if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			await get_tree().process_frame
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	current_settings.display.resolution = resolution
	GameManager.save_setting("display_resolution", resolution)
	resolution_changed.emit(resolution)
	setting_changed.emit("resolution", resolution)
	print("Resolution changed to: %dx%d" % [resolution.x, resolution.y])

## Activa/desactiva VSync
func set_vsync(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	current_settings.display.vsync = enabled
	GameManager.save_setting("display_vsync", enabled)
	setting_changed.emit("vsync", enabled)
	print("VSync: %s" % ("enabled" if enabled else "disabled"))

## Toggle entre fullscreen y windowed
func toggle_fullscreen() -> void:
	if current_settings.display.mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		set_display_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		set_display_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

## Setea volumen master (0.0 a 1.0)
func set_master_volume(volume: float) -> void:
	volume = clamp(volume, 0.0, 1.0)
	current_settings.audio.master_volume = volume
	GameManager.save_setting("master_volume", volume)
	setting_changed.emit("master_volume", volume)
	
	# Aplicar a AudioManager en tiempo real
	if AudioManager:
		AudioManager.set_master_volume(volume)

## Setea volumen de música (0.0 a 1.0)
func set_music_volume(volume: float) -> void:
	volume = clamp(volume, 0.0, 1.0)
	current_settings.audio.music_volume = volume
	GameManager.save_setting("music_volume", volume)
	setting_changed.emit("music_volume", volume)
	
# Aplicar a AudioManager en tiempo real
	if AudioManager:
		AudioManager.set_music_volume(volume)

## Setea volumen de SFX (0.0 a 1.0)
func set_sfx_volume(volume: float) -> void:
	volume = clamp(volume, 0.0, 1.0)
	current_settings.audio.sfx_volume = volume
	GameManager.save_setting("sfx_volume", volume)
	setting_changed.emit("sfx_volume", volume)

# Aplicar a AudioManager en tiempo real
	if AudioManager:
		AudioManager.set_sfx_volume(volume)

## Obtiene el modo de display actual
func get_display_mode() -> DisplayServer.WindowMode:
	return current_settings.display.mode

## Obtiene la resolución actual
func get_resolution() -> Vector2i:
	return current_settings.display.resolution

## Obtiene el estado de VSync
func get_vsync() -> bool:
	return current_settings.display.vsync

## Obtiene volumen master
func get_master_volume() -> float:
	return current_settings.audio.master_volume

## Obtiene volumen de música
func get_music_volume() -> float:
	return current_settings.audio.music_volume

## Obtiene volumen de SFX
func get_sfx_volume() -> float:
	return current_settings.audio.sfx_volume

## Retorna array de resoluciones disponibles
func get_available_resolutions() -> Array[Vector2i]:
	return AVAILABLE_RESOLUTIONS

## Resetea settings a valores por defecto
func reset_to_defaults() -> void:
	set_display_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	set_resolution(Vector2i(1920, 1080))
	set_vsync(true)
	set_master_volume(1.0)
	set_music_volume(0.8)
	set_sfx_volume(1.0)
	print("Settings reset to defaults")

## Convierte WindowMode a string legible
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

## Obtiene el índice de una resolución en el array de disponibles
func get_resolution_index(resolution: Vector2i) -> int:
	for i in range(AVAILABLE_RESOLUTIONS.size()):
		if AVAILABLE_RESOLUTIONS[i] == resolution:
			return i
	return 0  # Default a primera resolución si no se encuentra
