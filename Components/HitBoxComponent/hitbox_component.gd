class_name HitboxComponent
extends Area2D

## HitboxComponent - Área que CAUSA daño
##
## Se coloca en ataques, proyectiles, trampas.
## Detecta cuando entra en contacto con un HurtboxComponent y le pasa la info.

# Señales
signal hit_landed(hurtbox: HurtboxComponent)

# Configuración
@export_group("Damage")
@export var damage: int = 10
@export var knockback_force: Vector2 = Vector2.ZERO
@export var knockback_direction: Vector2 = Vector2.ZERO

@export_group("Behavior")
@export var hit_once: bool = false
@export var auto_activate: bool = true
@export var destroy_on_hit: bool = false

@export_group("Filtering")
@export_flags("Player", "Enemy", "Neutral") var can_hit: int = 0b010

# Estado
var is_active: bool = false
var has_hit: bool = false

var hit_cooldowns: Dictionary = {}
@export var hit_cooldown_duration: float = 0.5

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	
	if auto_activate:
		activate()
	
	print("[HitboxComponent] Ready - Damage: %d" % damage)

func activate() -> void:
	is_active = true
	monitoring = true

func deactivate() -> void:
	is_active = false
	monitoring = false

func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return
	
	if not area is HurtboxComponent:
		return
	
	var hurtbox = area as HurtboxComponent
	
	if not _can_hit_entity(hurtbox):
		return
	
	if _is_in_cooldown(hurtbox):
		return
	
	_apply_hit(hurtbox)

func _can_hit_entity(hurtbox: HurtboxComponent) -> bool:
	if hurtbox.entity_category == 0:
		return true
	
	return (can_hit & hurtbox.entity_category) != 0

func _is_in_cooldown(hurtbox: HurtboxComponent) -> bool:
	var hurtbox_id = hurtbox.get_instance_id()
	
	if hurtbox_id in hit_cooldowns:
		var time_since_hit = Time.get_ticks_msec() / 1000.0 - hit_cooldowns[hurtbox_id]
		return time_since_hit < hit_cooldown_duration
	
	return false

func _apply_hit(hurtbox: HurtboxComponent) -> void:
	var final_knockback = knockback_force
	
	if knockback_direction == Vector2.ZERO:
		var direction = (hurtbox.global_position - global_position).normalized()
		final_knockback = direction * knockback_force.length()
	else:
		final_knockback = knockback_direction.normalized() * knockback_force.length()
	
	var hit_data = {
		"damage": damage,
		"knockback": final_knockback,
		"source": get_parent(),
		"position": global_position
	}
	
	hurtbox.take_hit(hit_data)
	
	hit_cooldowns[hurtbox.get_instance_id()] = Time.get_ticks_msec() / 1000.0
	
	hit_landed.emit(hurtbox)
	
	print("[HitboxComponent] Hit landed! Damage: %d" % damage)
	
	if hit_once:
		has_hit = true
		deactivate()
	
	if destroy_on_hit:
		if get_parent():
			get_parent().queue_free()

func set_damage(new_damage: int) -> void:
	damage = new_damage

func set_knockback(new_knockback: Vector2) -> void:
	knockback_force = new_knockback

func clear_cooldowns() -> void:
	hit_cooldowns.clear()
