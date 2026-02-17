class_name PlatformerRoom
extends Node2D

## PlatformerRoom - VersiÃ³n Simple que Funcionaba + Scaling Discreto

# SeÃ±ales
signal room_completed()
signal player_entered()
signal all_spawns_completed()
signal layout_selected(variant_index: int)

# ConfiguraciÃ³n
@export_group("Room Info")
@export_enum("Easy", "Medium", "Hard") var difficulty: String = "Easy"
@export var room_width: float = 1024.0
@export var room_id: String = ""

@export_group("Scoring")
@export var completion_bonus: int = 50

# Referencias a nodos hijos
@onready var entry_point: Marker2D = $EntryPoint
@onready var exit_point: Marker2D = $ExitPoint
@onready var exit_trigger: Area2D = $ExitTrigger

# Soporte para variantes de TileMap
@onready var tilemap_variants: TileMapVariant = $TileMapVariants
@onready var tilemap: TileMapLayer = null

# Contenedores
@onready var spawn_points_container: Node2D = $SpawnPoints
@onready var entities_container: Node2D = $Entities

# Estado
var is_active: bool = false
var player_has_entered: bool = false
var rooms_cleared: int = 0

# Valores discretos de HP/DaÃ±o (se setean desde RoomManager)
var target_enemy_hp: int = 1
var target_enemy_damage: int = 1

func _ready() -> void:
	if exit_trigger:
		exit_trigger.body_entered.connect(_on_exit_trigger_entered)
	
	if entry_point:
		entry_point.visible = false
	if exit_point:
		exit_point.visible = false
	
	print("[Room %s] Ready - Difficulty: %s" % [room_id, difficulty])

func initialize(total_rooms_cleared: int, current_difficulty: String, hp: int = 1, damage: int = 1) -> void:
	"""Inicializa el room con contexto de dificultad"""
	rooms_cleared = total_rooms_cleared
	
	if not current_difficulty.is_empty():
		difficulty = current_difficulty
	
	# Guardar valores discretos
	target_enemy_hp = hp
	target_enemy_damage = damage
	
	# Seleccionar variante de TileMap
	_select_tilemap_variant()
	
	# Procesar spawn points
	call_deferred("_process_spawn_points")
	
	print("[Room %s] Initialized - Rooms: %d, Difficulty: %s, HP: %d, Damage: %d" % 
		  [room_id, rooms_cleared, difficulty, target_enemy_hp, target_enemy_damage])

func _select_tilemap_variant() -> void:
	"""Selecciona una variante de TileMap aleatoriamente"""
	if tilemap_variants:
		tilemap = tilemap_variants.select_variant()
		
		if tilemap:
			var variant_index = tilemap_variants.get_active_variant_index()
			layout_selected.emit(variant_index)
			print("[Room %s] TileMap variant %d/%d selected" % 
				  [room_id, variant_index + 1, tilemap_variants.get_variant_count()])
	
	elif has_node("TileMapLayer"):
		tilemap = get_node("TileMapLayer")
		print("[Room %s] Using single TileMapLayer (no variants)" % room_id)
	else:
		push_warning("[Room %s] No TileMapLayer found!" % room_id)

func _process_spawn_points() -> void:
	"""Procesa todos los SpawnPoints con valores discretos"""
	if not spawn_points_container:
		push_warning("[Room %s] No SpawnPoints container found!" % room_id)
		return
	
	var spawn_points = spawn_points_container.get_children()
	
	if spawn_points.is_empty():
		print("[Room %s] No spawn points configured" % room_id)
		all_spawns_completed.emit()
		return
	
	print("[Room %s] Processing %d spawn points..." % [room_id, spawn_points.size()])
	
	var spawned_count = 0
	
	for spawn_point in spawn_points:
		if not spawn_point is SpawnPoint:
			continue
		
		if spawn_point.can_spawn(difficulty, rooms_cleared):
			# Pasar valores discretos
			var entity = spawn_point.spawn_entity_discrete(target_enemy_hp, target_enemy_damage)
			
			if entity:
				entities_container.add_child(entity)
				spawned_count += 1
	
	print("[Room %s] Spawned %d entities (HP: %d, Damage: %d)" % 
		  [room_id, spawned_count, target_enemy_hp, target_enemy_damage])
	
	all_spawns_completed.emit()

func activate() -> void:
	if is_active:
		return
	
	is_active = true
	print("[Room %s] Activated" % room_id)

func deactivate() -> void:
	is_active = false
	print("[Room %s] Deactivated" % room_id)

func _on_exit_trigger_entered(body: Node2D) -> void:
	if body is Player and is_active:
		call_deferred("_complete_room")

func _complete_room() -> void:
	room_completed.emit()
	
	var game_logic = get_tree().get_first_node_in_group("game_logic")
	if game_logic and game_logic.has_method("add_score"):
		game_logic.add_score(completion_bonus)
	
	print("[Room %s] COMPLETED! Bonus: %d" % [room_id, completion_bonus])

# ============================================================================
# GETTERS
# ============================================================================

func get_entry_position() -> Vector2:
	if entry_point:
		return entry_point.global_position
	return global_position

func get_exit_position() -> Vector2:
	if exit_point:
		return exit_point.global_position
	return global_position + Vector2(room_width, 0)

func get_enemy_count() -> int:
	if not entities_container:
		return 0
	
	var count = 0
	for entity in entities_container.get_children():
		if entity.has_node("HealthComponent"):
			var health = entity.get_node("HealthComponent") as HealthComponent
			if health.is_alive():
				count += 1
	
	return count

func get_spawn_points() -> Array[SpawnPoint]:
	var points: Array[SpawnPoint] = []
	
	if not spawn_points_container:
		return points
	
	for child in spawn_points_container.get_children():
		if child is SpawnPoint:
			points.append(child)
	
	return points

func get_active_tilemap_variant() -> int:
	if tilemap_variants:
		return tilemap_variants.get_active_variant_index()
	return 0
