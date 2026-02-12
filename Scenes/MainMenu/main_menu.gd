extends Control

@onready var minigames_container: GridContainer = $MarginContainer/VBoxContainer/MinigamesContainer
@onready var settings_button: Button = $MarginContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	_populate_minigames()

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

	# TODO: Usar SceneTransition para cambiar de escena
	# Tipos disponibles: "instant", "fade", "wipe_left", "wipe_right", "pixelate", "circle_close", "circle_open"
	SceneTransition.change_scene(game_data.scene_path, "fade", false)
	
	# Temporal - solo imprimir
	print("Would load scene: %s" % game_data.scene_path)

## Callback del botón Settings
func _on_settings_button_pressed() -> void:
	print("Settings clicked - TODO")
	# Cambiar a escena settings cuando este creada
	# SceneTransition.change_scene("", "fade")

func _on_quit_button_pressed() -> void:
	SceneTransition.transition_midpoint.connect(func(): get_tree().quit())
	SceneTransition.change_scene("", "fade")  # Fade a negro y salir

## Opcional: Callback cuando inicia una transición
func _on_transition_started(transition_type: String) -> void:
	# Deshabilitar inputs mientras transiciona
	set_process_input(false)
	
	# Opcional: Feedback visual (ej: cursor de loading)
	print("Transition started: %s" % transition_type)

## Opcional: Callback cuando termina una transición
func _on_transition_finished() -> void:
	# Re-habilitar inputs
	set_process_input(true)
	
	print("Transition finished")
