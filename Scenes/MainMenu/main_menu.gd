extends Control

## MainMenu - Menú principal con audio integrado

@onready var minigames_container: GridContainer = $MarginContainer/VBoxContainer/MinigamesContainer
@onready var settings_button: Button = $MarginContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton

# Recursos de audio
var menu_music: AudioStream
var hover_sound: AudioStream
var click_sound: AudioStream

func _ready() -> void:
	_load_audio_resources()
	_setup_button_sounds()
	_start_menu_music()
	_populate_minigames()

## Carga los recursos de audio
func _load_audio_resources() -> void:
	menu_music = load("res://Resources/Audio/Music/the-old-master.wav")
	hover_sound = load("res://Resources/Audio/SFX/tap-a.ogg")
	click_sound = load("res://Resources/Audio/SFX/click-a.ogg")

## Inicia la música del menú
func _start_menu_music() -> void:
	# Solo iniciar música si no está sonando ya
	# Esto permite que la música continúe entre Main Menu <-> Settings
	if not AudioManager.is_music_playing():
		AudioManager.play_music(menu_music, 1.5, true)  # Fade in de 1.5s, loop
		print("Started menu music")
	else:
		print("Menu music already playing, continuing...")

## Configura sonidos para los botones principales
func _setup_button_sounds() -> void:
	# Settings button
	settings_button.mouse_entered.connect(_on_button_hover)
	settings_button.pressed.connect(func(): _on_button_click())
	
	# Quit button
	quit_button.mouse_entered.connect(_on_button_hover)
	quit_button.pressed.connect(func(): _on_button_click())

## Crea un GameButton por cada minijuego registrado en GameManager
func _populate_minigames() -> void:
	# Limpiar cualquier hijo existente
	for child in minigames_container.get_children():
		child.queue_free()
	
	# Obtener minijuegos desde GameManager
	var games = GameManager.get_minigames()
	
	# Precargar la escena de GameButton
	var game_button_scene = preload("res://Scenes/MainMenu/UI/GameButton.tscn")
	
	# Crear un GameButton por cada juego
	for game_data in games:
		var button = game_button_scene.instantiate()
		
		# Configurar propiedades
		button.game_id = game_data.id
		button.game_name = game_data.name
		button.description = game_data.description
		button.high_score = game_data.high_score
		button.is_locked = !game_data.unlocked
		# button.thumbnail = load(game_data.thumbnail) cuando tengamos imágenes
		
		# Conectar señal
		button.game_selected.connect(_on_game_selected)
		
		# Agregar al container
		minigames_container.add_child(button)
	
	print("Populated %d minigames" % games.size())

## Callback cuando seleccionan un minijuego
func _on_game_selected(game_id: String) -> void:
	print("Main Menu: Selected game '%s'" % game_id)
	
	var game_data = GameManager.get_minigame_by_id(game_id)
	
	if game_data.is_empty():
		push_error("Game data not found for id: %s" % game_id)
		return
	
	# Reproducir sonido de selección
	AudioManager.play_sfx(click_sound)
	
	# Detener música del menú con fade out
	AudioManager.stop_music(1.0)
	
	# Cambiar a escena del minijuego
	SceneTransition.change_scene(game_data.scene_path, "fade", false)

## Callback del botón Settings
func _on_settings_button_pressed() -> void:
	print("Opening settings...")
	# NO detenemos la música - continuará en Settings
	SceneTransition.change_scene("res://Scenes/MainMenu/SettingsMenu.tscn", "wipe_left")

## Callback del botón Quit
func _on_quit_button_pressed() -> void:
	# Fade out de música antes de salir
	AudioManager.stop_music(1.5)
	
	# Conectar al midpoint de transición para cerrar en el momento justo
	if not SceneTransition.transition_midpoint.is_connected(_quit_game):
		SceneTransition.transition_midpoint.connect(_quit_game, CONNECT_ONE_SHOT)
	
	# Iniciar transición a negro (sin escena destino)
	SceneTransition.change_scene("", "fade")

func _quit_game() -> void:
	print("Quitting game...")
	get_tree().quit()

## Sonido de hover sobre botón
func _on_button_hover() -> void:
	AudioManager.play_sfx(hover_sound, -8.0)  # Más bajo que clicks

## Sonido de click en botón
func _on_button_click() -> void:
	AudioManager.play_sfx(click_sound)
