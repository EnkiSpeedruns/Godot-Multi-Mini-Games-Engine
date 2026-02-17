class_name RoomManager
extends Node

## RoomManager - Sistema ULTRA SIMPLE: 1 room a la vez

signal room_spawned(room: PlatformerRoom)
signal room_completed(room_id: String, rooms_cleared: int)
signal difficulty_increased(new_difficulty: String)

# Pool de rooms
var easy_rooms: Array[PackedScene] = []
var medium_rooms: Array[PackedScene] = []
var hard_rooms: Array[PackedScene] = []

# Estado - SOLO current_room
var current_room: PlatformerRoom = null
var rooms_cleared: int = 0
var current_difficulty: String = "Easy"

# Configuración
@export_group("Difficulty Progression")
@export var easy_tier_rooms: int = 5
@export var medium_tier_rooms: int = 5

@export_group("Discrete Scaling")
@export var easy_enemy_hp: int = 1
@export var medium_enemy_hp: int = 2
@export var hard_enemy_hp: int = 3

@export var easy_enemy_damage: int = 1
@export var medium_enemy_damage: int = 2
@export var hard_enemy_damage: int = 3

# Referencias
var level_container: Node2D
var player: Player

func _ready() -> void:
	_load_room_scenes()

func _load_room_scenes() -> void:
	"""AGREGAR TUS ROOMS AQUÍ"""
	# Ejemplo:
	easy_rooms = [preload("res://Scenes/Minigames/Platformer/Rooms/Room1.tscn")]
	medium_rooms = easy_rooms
	hard_rooms = easy_rooms


func initialize(container: Node2D, game_player: Player) -> void:
	level_container = container
	player = game_player
	rooms_cleared = 0
	current_difficulty = "Easy"
	
	_spawn_room(0, "Easy")

func _spawn_room(room_number: int, difficulty: String) -> void:
	"""
	Spawnea UN room y SOLO un room.
	Destruye el anterior completamente.
	"""
	print("\n[RoomManager] ═══════════════════════════════════")
	print("[RoomManager] SPAWNING NEW ROOM")
	print("  Room number: %d" % room_number)
	print("  Difficulty: %s" % difficulty)
	
	# 1. DESTRUIR room anterior si existe
	if current_room:
		print("  Destroying previous room: %s" % current_room.room_id)
		current_room.queue_free()
		current_room = null
		
		# Esperar un frame para que se destruya
		await get_tree().process_frame
	
	# 2. CREAR nuevo room
	var new_room = _instantiate_room(difficulty, room_number)
	if not new_room:
		push_error("[RoomManager] Failed to create room!")
		return
	
	# 3. AGREGAR a la escena
	level_container.add_child(new_room)
	new_room.global_position = Vector2.ZERO  # Siempre en (0, 0)
	
	print("  New room created: %s at %s" % [new_room.room_id, new_room.global_position])
	
	# 4. INICIALIZAR
	var hp = _get_hp_for_difficulty(difficulty)
	var damage = _get_damage_for_difficulty(difficulty)
	new_room.initialize(room_number, difficulty, hp, damage)
	
	# 5. ACTIVAR
	current_room = new_room
	current_room.activate()
	current_room.room_completed.connect(_on_room_completed)
	
	# 6. TELETRANSPORTAR PLAYER
	_teleport_player_to_room(current_room)
	
	# 7. NOTIFICAR
	room_spawned.emit(current_room)
	
	print("[RoomManager] Room ready!")
	print("[RoomManager] ═══════════════════════════════════\n")

func _on_room_completed() -> void:
	"""Callback cuando se completa un room"""
	rooms_cleared += 1
	
	print("\n[RoomManager] ═══ ROOM COMPLETED ═══")
	print("  Rooms cleared: %d" % rooms_cleared)
	
	room_completed.emit(current_room.room_id, rooms_cleared)
	
	# Actualizar dificultad
	_update_difficulty()
	
	# Spawn siguiente room
	var next_difficulty = _calculate_difficulty_for_rooms(rooms_cleared + 1)
	_spawn_room(rooms_cleared + 1, next_difficulty)

func _instantiate_room(difficulty: String, room_number: int) -> PlatformerRoom:
	"""Instancia un room de la dificultad especificada"""
	var pool: Array[PackedScene] = []
	
	match difficulty:
		"Easy": pool = easy_rooms
		"Medium": pool = medium_rooms
		"Hard": pool = hard_rooms
	
	if pool.is_empty():
		push_error("[RoomManager] No rooms for difficulty: %s" % difficulty)
		return null
	
	var random_index = randi() % pool.size()
	var room = pool[random_index].instantiate() as PlatformerRoom
	
	if room:
		room.room_id = "%s_%d" % [difficulty.to_lower(), room_number]
	
	return room

func _teleport_player_to_room(room: PlatformerRoom) -> void:
	"""TELETRANSPORTA al player al EntryPoint del room"""
	if not player:
		push_error("[RoomManager] No player reference!")
		return
	
	var entry_pos = room.get_entry_position()
	
	print("[RoomManager] Teleporting player to: %s" % entry_pos)
	
	player.global_position = entry_pos
	player.velocity = Vector2.ZERO

func _update_difficulty() -> void:
	var previous = current_difficulty
	current_difficulty = _calculate_difficulty_for_rooms(rooms_cleared + 1)
	
	if current_difficulty != previous:
		difficulty_increased.emit(current_difficulty)
		print("[RoomManager] ⚠️ DIFFICULTY: %s → %s" % [previous, current_difficulty])
		print("  HP: %d, Damage: %d" % [_get_hp_for_difficulty(current_difficulty), 
										_get_damage_for_difficulty(current_difficulty)])

func _calculate_difficulty_for_rooms(rooms_count: int) -> String:
	if rooms_count >= (easy_tier_rooms + medium_tier_rooms):
		return "Hard"
	elif rooms_count >= easy_tier_rooms:
		return "Medium"
	else:
		return "Easy"

func _get_hp_for_difficulty(difficulty: String) -> int:
	match difficulty:
		"Easy": return easy_enemy_hp
		"Medium": return medium_enemy_hp
		"Hard": return hard_enemy_hp
		_: return 1

func _get_damage_for_difficulty(difficulty: String) -> int:
	match difficulty:
		"Easy": return easy_enemy_damage
		"Medium": return medium_enemy_damage
		"Hard": return hard_enemy_damage
		_: return 1

func get_current_difficulty() -> String:
	return current_difficulty

func get_rooms_cleared() -> int:
	return rooms_cleared

func get_current_room() -> PlatformerRoom:
	return current_room
