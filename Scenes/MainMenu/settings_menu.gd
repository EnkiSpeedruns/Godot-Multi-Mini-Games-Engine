extends Control

## SettingsMenu - Menú de configuración con audio integrado
##
## Permite cambiar display mode, resolución, y audio
## La música continúa desde el Main Menu

# Referencias a nodos UI - Display
@onready var display_mode_option: OptionButton = $Panel/MarginContainer/VBoxContainer/DisplaySection/DisplayModeOption
@onready var resolution_option: OptionButton = $Panel/MarginContainer/VBoxContainer/DisplaySection/ResolutionOption
@onready var vsync_check: CheckButton = $Panel/MarginContainer/VBoxContainer/DisplaySection/VSyncCheck

# Referencias a nodos UI - Audio
@onready var master_slider: HSlider = $Panel/MarginContainer/VBoxContainer/AudioSection/MasterVolumeContainer/MasterSlider
@onready var music_slider: HSlider = $Panel/MarginContainer/VBoxContainer/AudioSection/MusicVolumeContainer/MusicSlider
@onready var sfx_slider: HSlider = $Panel/MarginContainer/VBoxContainer/AudioSection/SFXVolumeContainer/SFXSlider

@onready var master_value_label: Label = $Panel/MarginContainer/VBoxContainer/AudioSection/MasterVolumeContainer/MasterValueLabel
@onready var music_value_label: Label = $Panel/MarginContainer/VBoxContainer/AudioSection/MusicVolumeContainer/MusicValueLabel
@onready var sfx_value_label: Label = $Panel/MarginContainer/VBoxContainer/AudioSection/SFXVolumeContainer/SFXValueLabel

# Referencias a botones
@onready var apply_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonsSection/ApplyButton
@onready var reset_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonsSection/ResetButton
@onready var back_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonsSection/BackButton

# Settings temporales (se aplican al presionar Apply)
var temp_display_mode: DisplayServer.WindowMode
var temp_resolution: Vector2i
var temp_vsync: bool

# Recursos de audio
var hover_sound: AudioStream
var click_sound: AudioStream
var switch_sound: AudioStream
var apply_sound: AudioStream

func _ready() -> void:
	_load_audio_resources()
	_populate_display_options()
	_populate_resolution_options()
	_load_current_settings()
	_connect_signals()
	_setup_button_sounds()
	
	print("SettingsMenu ready")
	print("Music continues from Main Menu")

## Carga los recursos de audio
func _load_audio_resources() -> void:
	hover_sound = load("res://Resources/Audio/SFX/tap-a.ogg")
	click_sound = load("res://Resources/Audio/SFX/click-a.ogg")
	switch_sound = load("res://Resources/Audio/SFX/switch-a.ogg")
	apply_sound = load("res://Resources/Audio/SFX/click-b.ogg")

## Configura sonidos para botones y controles
func _setup_button_sounds() -> void:
	# Botones principales
	apply_button.mouse_entered.connect(_on_button_hover)
	reset_button.mouse_entered.connect(_on_button_hover)
	back_button.mouse_entered.connect(_on_button_hover)
	
	# OptionButtons
	display_mode_option.mouse_entered.connect(_on_button_hover)
	resolution_option.mouse_entered.connect(_on_button_hover)

## Puebla las opciones de display mode
func _populate_display_options() -> void:
	display_mode_option.clear()
	display_mode_option.add_item("Windowed", DisplayServer.WINDOW_MODE_WINDOWED)
	display_mode_option.add_item("Fullscreen", DisplayServer.WINDOW_MODE_FULLSCREEN)
	display_mode_option.add_item("Borderless Fullscreen", DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

## Puebla las opciones de resolución
func _populate_resolution_options() -> void:
	resolution_option.clear()
	
	var resolutions = SettingsManager.get_available_resolutions()
	for i in range(resolutions.size()):
		var res = resolutions[i]
		var aspect_ratio = _get_aspect_ratio(res)
		var label = "%dx%d (%s)" % [res.x, res.y, aspect_ratio]
		resolution_option.add_item(label, i)

## Carga los settings actuales desde SettingsManager
func _load_current_settings() -> void:
	# Display
	var current_mode = SettingsManager.get_display_mode()
	var current_res = SettingsManager.get_resolution()
	var current_vsync = SettingsManager.get_vsync()
	
	# Setear valores temporales
	temp_display_mode = current_mode
	temp_resolution = current_res
	temp_vsync = current_vsync
	
	# Actualizar UI - Display
	_select_display_mode(current_mode)
	_select_resolution(current_res)
	vsync_check.button_pressed = current_vsync
	
	# Audio
	master_slider.value = SettingsManager.get_master_volume() * 100
	music_slider.value = SettingsManager.get_music_volume() * 100
	sfx_slider.value = SettingsManager.get_sfx_volume() * 100
	
	_update_volume_labels()

## Selecciona el display mode en el OptionButton
func _select_display_mode(mode: DisplayServer.WindowMode) -> void:
	for i in range(display_mode_option.item_count):
		if display_mode_option.get_item_id(i) == mode:
			display_mode_option.selected = i
			return

## Selecciona la resolución en el OptionButton
func _select_resolution(resolution: Vector2i) -> void:
	var index = SettingsManager.get_resolution_index(resolution)
	resolution_option.selected = index

## Conecta señales de UI
func _connect_signals() -> void:
	# Display
	display_mode_option.item_selected.connect(_on_display_mode_selected)
	resolution_option.item_selected.connect(_on_resolution_selected)
	vsync_check.toggled.connect(_on_vsync_toggled)
	
	# Audio
	master_slider.value_changed.connect(_on_master_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	
	# Botones
	apply_button.pressed.connect(_on_apply_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	back_button.pressed.connect(_on_back_pressed)

## Callback cuando cambia display mode
func _on_display_mode_selected(index: int) -> void:
	temp_display_mode = display_mode_option.get_item_id(index)
	AudioManager.play_sfx(switch_sound, -6.0)
	print("Display mode selected: %s" % temp_display_mode)

## Callback cuando cambia resolución
func _on_resolution_selected(index: int) -> void:
	var resolutions = SettingsManager.get_available_resolutions()
	temp_resolution = resolutions[index]
	AudioManager.play_sfx(switch_sound, -6.0)
	print("Resolution selected: %dx%d" % [temp_resolution.x, temp_resolution.y])

## Callback cuando cambia VSync
func _on_vsync_toggled(toggled_on: bool) -> void:
	temp_vsync = toggled_on
	AudioManager.play_sfx(switch_sound, -6.0)
	print("VSync: %s" % toggled_on)

## Callback cuando cambia master volume
func _on_master_slider_changed(value: float) -> void:
	var volume = value / 100.0
	SettingsManager.set_master_volume(volume)
	_update_volume_labels()
	
	# Reproducir sonido de prueba al cambiar volumen
	_play_volume_test_sound()

## Callback cuando cambia music volume
func _on_music_slider_changed(value: float) -> void:
	var volume = value / 100.0
	SettingsManager.set_music_volume(volume)
	_update_volume_labels()
	# La música que está sonando reflejará el cambio inmediatamente

## Callback cuando cambia SFX volume
func _on_sfx_slider_changed(value: float) -> void:
	var volume = value / 100.0
	SettingsManager.set_sfx_volume(volume)
	_update_volume_labels()
	
	# Reproducir sonido de prueba al cambiar volumen
	_play_volume_test_sound()

## Reproduce un sonido de prueba para testear volumen
func _play_volume_test_sound() -> void:
	AudioManager.play_sfx(click_sound, -3.0)

## Actualiza los labels de volumen
func _update_volume_labels() -> void:
	if master_value_label:
		master_value_label.text = "%d%%" % int(master_slider.value)
	if music_value_label:
		music_value_label.text = "%d%%" % int(music_slider.value)
	if sfx_value_label:
		sfx_value_label.text = "%d%%" % int(sfx_slider.value)

## Aplica los cambios de display
func _on_apply_pressed() -> void:
	print("Applying settings...")
	
	# Sonido de confirmación
	AudioManager.play_sfx(apply_sound)
	
	# Aplicar display settings
	SettingsManager.set_display_mode(temp_display_mode)
	SettingsManager.set_resolution(temp_resolution)
	SettingsManager.set_vsync(temp_vsync)
	
	# Audio ya se aplica en tiempo real con los sliders
	
	print("Settings applied!")
	
	# Opcional: Mostrar feedback visual
	apply_button.text = "Applied!"
	await get_tree().create_timer(1.0).timeout
	apply_button.text = "Apply"

## Resetea a valores por defecto
func _on_reset_pressed() -> void:
	print("Resetting to defaults...")
	
	AudioManager.play_sfx(click_sound)
	
	SettingsManager.reset_to_defaults()
	_load_current_settings()
	
	print("Settings reset!")

## Vuelve al main menu
func _on_back_pressed() -> void:
	AudioManager.play_sfx(click_sound)
	# La música continúa al volver al Main Menu
	SceneTransition.change_scene("res://Scenes/MainMenu/MainMenu.tscn", "wipe_right")

## Sonido de hover sobre botón
func _on_button_hover() -> void:
	AudioManager.play_sfx(hover_sound, -8.0)

## Calcula aspect ratio
func _get_aspect_ratio(resolution: Vector2i) -> String:
	var gcd_val = _gcd(resolution.x, resolution.y)
	var ratio_x = resolution.x / gcd_val
	var ratio_y = resolution.y / gcd_val
	
	# Casos especiales comunes
	if ratio_x == 16 and ratio_y == 9:
		return "16:9"
	elif ratio_x == 4 and ratio_y == 3:
		return "4:3"
	elif ratio_x == 16 and ratio_y == 10:
		return "16:10"
	elif ratio_x == 21 and ratio_y == 9:
		return "21:9"
	else:
		return "%d:%d" % [ratio_x, ratio_y]

## Calcula GCD (Greatest Common Divisor)
func _gcd(a: int, b: int) -> int:
	while b != 0:
		var temp = b
		b = a % b
		a = temp
	return a

## Input para cerrar con ESC
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
