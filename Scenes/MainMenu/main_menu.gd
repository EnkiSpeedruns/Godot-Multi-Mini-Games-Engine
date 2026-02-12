extends Control

@onready var minigames_container: GridContainer = $MarginContainer/VBoxContainer/MinigamesContainer
@onready var settings_button: Button = $MarginContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	_populate_minigames()
	
	# FIX: Conectar señales de transición en _ready para evitar duplicados
	# Solo conectar si no están ya conectadas
	if not SceneTransition.transition_started.is_connected(_on_transition_started):
		SceneTransition.transition_started.connect(_on_transition_started)
	if not SceneTransition.transition_finished.is_connected(_on_transition_finished):
		SceneTransition.transition_finished.connect(_on_transition_finished)

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
		# button.thumbnail = load(game_data.thumbnail) # cuando tengamos imágenes
		
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

	# Usar SceneTransition para cambiar de escena
	# Tipos disponibles: "instant", "fade", "wipe_left", "wipe_right"
	SceneTransition.change_scene(game_data.scene_path, "fade", false)

## Callback del botón Settings
func _on_settings_button_pressed() -> void:
	print("Opening Settings...")
	SceneTransition.change_scene("res://Scenes/MainMenu/SettingsMenu.tscn", "wipe_left")

## Callback del botón Quit
func _on_quit_button_pressed() -> void:
	print("Quitting game...")
	# FIX: Usar una función lambda inline que se desconecta a sí misma
	var quit_callback = func():
		get_tree().quit()
	
	# Conectar, esperar a que se ejecute, y desconectar
	SceneTransition.transition_midpoint.connect(quit_callback, CONNECT_ONE_SHOT)
	SceneTransition.change_scene("", "fade")

## Callback cuando inicia una transición
func _on_transition_started(transition_type: String) -> void:
	# Deshabilitar inputs mientras transiciona
	set_process_input(false)
	print("🎬 Transition started: %s" % transition_type)

## Callback cuando termina una transición
func _on_transition_finished() -> void:
	# Re-habilitar inputs
	set_process_input(true)
	print("✅ Transition finished")
