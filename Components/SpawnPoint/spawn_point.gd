class_name SpawnPoint
extends Marker2D

## SpawnPoint - VERSIÓN con Scaling Discreto
##
## Soporta valores discretos de HP/Daño en vez de multiplicadores

# Señales
signal entity_spawned(entity: Node2D)

# Tipo de spawn point
enum SpawnType {
	ENEMY,      # Spawns enemigos
	COLLECTIBLE # Spawns items (coins, hearts)
}

@export_group("Spawn Configuration")
@export var spawn_type: SpawnType = SpawnType.ENEMY
@export var spawn_id: String = ""

@export_group("Spawn Options")
@export var spawn_options: Array[PackedScene] = []

@export_group("Spawn Chance")
@export_range(0.0, 1.0) var spawn_chance: float = 1.0

@export_group("Difficulty Scaling")
@export_enum("Easy", "Medium", "Hard") var min_difficulty: String = "Easy"
@export var always_spawn_on_hard: bool = false

# Estado
var has_spawned: bool = false
var spawned_entity: Node2D = null

func _ready() -> void:
	# Ocultar el marker en runtime
	visible = false

func can_spawn(current_difficulty: String, rooms_cleared: int) -> bool:
	"""Determina si este spawn point puede activarse"""
	
	print("      [SpawnPoint %s] can_spawn check:" % spawn_id)
	print("        has_spawned: %s" % has_spawned)
	
	if has_spawned:
		print("        → Already spawned, returning false")
		return false
	
	# Verificar dificultad mínima
	var difficulty_order = ["Easy", "Medium", "Hard"]
	var current_index = difficulty_order.find(current_difficulty)
	var min_index = difficulty_order.find(min_difficulty)
	
	print("        current_difficulty: %s (index: %d)" % [current_difficulty, current_index])
	print("        min_difficulty: %s (index: %d)" % [min_difficulty, min_index])
	
	if current_index < min_index:
		print("        → Difficulty too low, returning false")
		return false
	
	# En hard, si always_spawn_on_hard, forzar spawn
	if always_spawn_on_hard and current_difficulty == "Hard":
		print("        → always_spawn_on_hard + Hard, returning true")
		return true
	
	# Random según spawn_chance
	var roll = randf()
	var will_spawn = roll <= spawn_chance
	
	print("        spawn_chance: %.2f" % spawn_chance)
	print("        random roll: %.2f" % roll)
	print("        → returning %s" % will_spawn)
	
	return will_spawn

func spawn_entity_discrete(target_hp: int, target_damage: int) -> Node2D:
	"""
	NUEVO: Spawnea entidad con valores discretos de HP/Daño.
	Reemplaza spawn_entity() que usaba multiplicador.
	"""
	if spawn_options.is_empty():
		push_warning("[SpawnPoint %s] No spawn options configured!" % spawn_id)
		return null
	
	# Seleccionar random
	var random_index = randi() % spawn_options.size()
	var selected_scene = spawn_options[random_index]
	
	# Instanciar
	spawned_entity = selected_scene.instantiate()
	
	# Aplicar scaling discreto si es enemigo
	if spawn_type == SpawnType.ENEMY:
		_apply_discrete_scaling(spawned_entity, target_hp, target_damage)
	
	# Posicionar
	spawned_entity.global_position = global_position
	
	# Marcar como spawneado
	has_spawned = true
	
	entity_spawned.emit(spawned_entity)
	
	print("[SpawnPoint %s] Spawned: %s" % [spawn_id, spawned_entity.name])
	
	return spawned_entity

func _apply_discrete_scaling(enemy: Node2D, target_hp: int, target_damage: int) -> void:
	"""
	Aplica valores discretos de HP/Daño al enemigo.
	Mucho más simple y predecible que multiplicadores.
	"""
	
	# Setear HP
	if enemy.has_node("HealthComponent"):
		var health = enemy.get_node("HealthComponent") as HealthComponent
		
		# Usar set_deferred para evitar problemas durante physics
		health.set_deferred("max_health", target_hp)
		health.set_deferred("current_health", target_hp)
		
		print("  [Scaling] HP set to: %d" % target_hp)
	
	# Setear Daño
	if enemy.has_node("AttackHitbox"):
		var hitbox = enemy.get_node("AttackHitbox") as HitboxComponent
		
		# Usar set_deferred
		hitbox.set_deferred("damage", target_damage)
		
		print("  [Scaling] Damage set to: %d" % target_damage)

func clear() -> void:
	"""Resetea el spawn point"""
	has_spawned = false
	
	if is_instance_valid(spawned_entity):
		spawned_entity.queue_free()
		spawned_entity = null

# ============================================================================
# RETROCOMPATIBILIDAD (opcional)
# ============================================================================

func spawn_entity(difficulty_multiplier: float = 1.0) -> Node2D:
	"""
	Método legacy con multiplicador.
	Convertir a valores discretos.
	"""
	push_warning("[SpawnPoint] spawn_entity() is deprecated, use spawn_entity_discrete()")
	
	# Convertir multiplier a valores discretos aproximados
	var approx_hp = max(1, int(1.0 * difficulty_multiplier))
	var approx_damage = max(1, int(1.0 * difficulty_multiplier))
	
	return spawn_entity_discrete(approx_hp, approx_damage)
