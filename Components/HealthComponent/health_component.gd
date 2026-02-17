class_name HealthComponent
extends Node

## HealthComponent - Gestiona puntos de vida de cualquier entidad
##
## Componente reutilizable que maneja HP, daño, curación, invencibilidad temporal
## Se comunica mediante señales para mantener desacoplamiento

# Señales
signal health_changed(new_health: int, max_health: int)
signal damaged(damage_amount: int)
signal healed(heal_amount: int)
signal died()

# Propiedades exportadas
@export var max_health: int = 100:
	set(value):
		max_health = max(1, value)
		current_health = min(current_health, max_health)
		health_changed.emit(current_health, max_health)

@export var current_health: int = max_health:
	set(value):
		var old_health = current_health
		current_health = clamp(value, 0, max_health)
		
		if current_health != old_health:
			health_changed.emit(current_health, max_health)
			
			if current_health < old_health:
				damaged.emit(old_health - current_health)
			elif current_health > old_health:
				healed.emit(current_health - old_health)
			
			if current_health == 0 and old_health > 0:
				died.emit()

@export var invincibility_duration: float = 0.0

# Estado interno
var is_invincible: bool = false
var invincibility_timer: Timer

func _ready() -> void:
	invincibility_timer = Timer.new()
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(invincibility_timer)
	
	current_health = max_health
	print("[HealthComponent] Initialized - Max HP: %d" % max_health)

func take_damage(amount: int, ignore_invincibility: bool = false) -> bool:
	if amount <= 0:
		return false
	
	if is_invincible and not ignore_invincibility:
		return false
	
	current_health -= amount
	
	if invincibility_duration > 0 and not ignore_invincibility:
		set_invincible(invincibility_duration)
	
	return true

func heal(amount: int) -> int:
	if amount <= 0:
		return 0
	
	var old_health = current_health
	current_health += amount
	return current_health - old_health

func set_invincible(duration: float) -> void:
	is_invincible = true
	invincibility_timer.start(duration)

func _on_invincibility_timeout() -> void:
	is_invincible = false

func is_alive() -> bool:
	return current_health > 0

func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

func kill() -> void:
	current_health = 0

func restore_full_health() -> void:
	current_health = max_health

func get_is_invincible() -> bool:
	return is_invincible
