extends Node

# Game Manager
# Gestiona la lista de minijuegos, high scores y configuracion

#Señales
signal high_score_updated(game_id: String, new_score: int)
signal minigame_unlocked(game_id: String) 

# Ruta del archivo de guardado
const SAVE_FILE_PATH = "user://save_data.cfg"

# Lista de minijuegos disponibles
var minigames: Array [Dictionary] = []

#Archivo de configuracion para persistencia
var save_file: ConfigFile

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_initialize_minigames()
	_load_save_data()
	print("GameManager initialized with %d minigames" % minigames.size())  

# Inicializa la lista de minijuegos
# Acá registramos todos los juegos disponibles
func _initialize_minigames() -> void:
	minigames = [
		{
			"id": "platformer",
			"name": "Platformer",
			"description": "classic jump and run action!",
			"scene_path": "res://Scenes/Minigames/Platformer/Main.tscn",
			"Thumbnail": "res://Resources/Sprites/Thumbnails/Platformer.png",
			"high_score": 0,
			"unlocked": true,
			"category": "action"
		},
		{
			"id": "snake",
			"name": "Snake",
			"description": "Eat and grow, don't bite yourself!",
			"scene_path": "res://scenes/minigames/snake/main.tscn",
			"thumbnail": "res://resources/sprites/thumbnails/snake.png",
			"high_score": 0,
			"unlocked": true,
			"category": "arcade"
		},
		{
			"id": "breakout",
			"name": "Breakout",
			"description": "Break all the blocks with your ball!",
			"scene_path": "res://scenes/minigames/breakout/main.tscn",
			"thumbnail": "res://resources/sprites/thumbnails/breakout.png",
			"high_score": 0,
			"unlocked": true,
			"category": "arcade"
		},
		{
			"id": "shoot_em_up",
			"name": "Space Shooter",
			"description": "Shoot down enemy waves!",
			"scene_path": "res://scenes/minigames/shoot_em_up/main.tscn",
			"thumbnail": "res://resources/sprites/thumbnails/shoot_em_up.png",
			"high_score": 0,
			"unlocked": false,  # Bloqueado inicialmente
			"category": "action"
		},
		{
			"id": "beat_em_up",
			"name": "Beat Em Up",
			"description": "Fight through enemy hordes!",
			"scene_path": "res://scenes/minigames/beat_em_up/main.tscn",
			"thumbnail": "res://resources/sprites/thumbnails/beat_em_up.png",
			"high_score": 0,
			"unlocked": false,
			"category": "action"
		},
		{
			"id": "asteroids",
			"name": "Asteroids",
			"description": "Destroy asteroids in space!",
			"scene_path": "res://scenes/minigames/asteroids/main.tscn",
			"thumbnail": "res://resources/sprites/thumbnails/asteroids.png",
			"high_score": 0,
			"unlocked": false,
			"category": "arcade"
		}
	]

func _load_save_data() -> void:
	save_file = ConfigFile.new()
	var err = save_file.load(SAVE_FILE_PATH)
	
	if err != OK:
		print("No save file found, creating new one")
		_create_default_save()
		return
		
	# Cargar high score y estado de unlocked para cada juego
	for game in minigames:
		var game_id = game.id
		
		# Cargar high score
		if save_file.has_section_key("scores", game_id):
			game.high_score = save_file.get_value("scores", game_id, 0)
		
		# Cargar estado de unlock
		if save_file.has_section_key("unlocked", game_id):
			game.unlocked = save_file.get_value("unlocked", game_id, false)
		
		print("Save data loaded successfully")

# Crear archivo de guardado por defecto
func _create_default_save() -> void:
	# Guardar valores iniciales
	for game in minigames:
		save_file.set_value("scores", game.id, game.high_score)
		save_file.set_value("unlocked", game.id, game.unlocked)

	# Configuracion por defecto
	save_file.set_value("settings", "master_volume", 1.0)
	save_file.set_value("settings", "music_volume", 0.8)
	save_file.set_value("settings", "sfx_volume", 1.0)

	save_file.save(SAVE_FILE_PATH)
	print("Default save file creted")

func _save_data() -> void:
	save_file.save(SAVE_FILE_PATH)
	print("Data saved to disk")

# Retorna todos los minijuegos disponibles
func get_minigames() -> Array[Dictionary]:
	return minigames

# Retorna un minijuego especifico por ID
func get_minigame_by_id(game_id: String) -> Dictionary:
	for game in minigames:
		if game.id == game_id:
			return game
	push_warning("Minigame with id '%s' not found" % game_id)
	return{}

# Guarda un nuevo high score si es mayor al actual
func save_high_score(game_id: String, score: int) -> bool:
	var game = get_minigame_by_id(game_id)
	
	if game.is_empty():
		return false
	
	#Solo guardar si es un nuevo record
	if score > game.high_score:
		game.high_score = score
		save_file.set_value("scores", game_id, score)
		_save_data()
		high_score_updated.emit(game_id, score)
		print("New high score for %s: %d" % [game_id, score])
		return true
	
	return false

# Retorna el high score de un minijuego
func get_high_score(game_id: String) -> int:
	var game = get_minigame_by_id(game_id)
	if game.is_empty():
		return 0
	return game.high_score

# Desbloquea un minijuego
func unlock_minigame(game_id: String) -> void:
	var game = get_minigame_by_id(game_id)
	
	if game.is_empty():

		if not game.unlocked:
			game.unlocked = true
			save_file.set_value("unlocked", game_id, true)
			_save_data()
			minigame_unlocked.emit(game_id)
			print("Minigame unlocked: %s" % game_id)
			
		return
# Guarda una configuración
func save_setting(key: String, value: Variant) -> void:
	save_file.set_value("settings", key, value)
	_save_data()

# Carga una configuracion
func load_setting(key: String, default_value: Variant = null) -> Variant:
	return save_file.get_value("settings", key, default_value)

# Resetea todos los datos (útil para testing)
func reset_all_data() -> void:
	# Resetear high scores
	for game in minigames:
		game.high_score = 0
		#mantener los primeros 3 desbloqueados
		game.unlocked = game.id in ["platformer", "snake", "breakout"]
	
	_create_default_save()
	print("All date reset to defaults")
