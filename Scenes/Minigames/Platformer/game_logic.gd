extends Node

## GameLogic - Controlador principal del minijuego Platformer

@onready var player: Player = $Level/Player
@onready var level: Node2D = $Level
@onready var hud: CanvasLayer = $HUD
@onready var room_manager: RoomManager = $RoomManager
@onready var camera_confiner: CameraConfiner = $Level/CameraConfiner

var game_started: bool = false
var current_score: int = 0

func _ready() -> void:
	add_to_group("game_logic")
	start_game()

func start_game() -> void:
	if game_started:
		return

	game_started = true
	current_score = 0

	if camera_confiner and player.has_node("Camera2D"):
		camera_confiner.set_camera(player.get_node("Camera2D") as Camera2D)

	if room_manager:
		room_manager.room_spawned.connect(_on_room_spawned)
		room_manager.room_completed.connect(_on_room_completed)
		room_manager.difficulty_increased.connect(_on_difficulty_increased)
		room_manager.initialize(level, player)

	if player and player.health_component:
		player.health_component.died.connect(_on_player_died)
		player.health_component.health_changed.connect(_on_player_health_changed)

	if hud:
		hud.update_health(player.health_component.current_health, player.health_component.max_health)
		hud.update_score(current_score)

func _on_room_spawned(room: PlatformerRoom) -> void:
	if camera_confiner:
		camera_confiner.apply_room(room)

func _on_room_completed(room_id: String, total_cleared: int) -> void:
	print("[GameLogic] Room completed: %s | Total: %d" % [room_id, total_cleared])

func _on_difficulty_increased(new_difficulty: String) -> void:
	print("[GameLogic] DIFFICULTY INCREASED: %s" % new_difficulty)

func _on_player_health_changed(new_health: int, max_health: int) -> void:
	if hud:
		hud.update_health(new_health, max_health)

func pause_game() -> void:
	get_tree().paused = true

func resume_game() -> void:
	get_tree().paused = false

func restart_game() -> void:
	get_tree().reload_current_scene()

func end_game(score: int) -> void:
	game_started = false
	GameManager.save_high_score("platformer", score)

func return_to_menu() -> void:
	SceneTransition.change_scene("res://Scenes/MainMenu/MainMenu.tscn", "fade")

func _on_player_died() -> void:
	end_game(current_score)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not get_tree().paused:
			pause_game()
		else:
			resume_game()

func add_score(points: int) -> void:
	current_score += points
	if hud:
		hud.update_score(current_score)
