class_name HurtboxComponent
extends Area2D

## HurtboxComponent - Área que RECIBE daño
##
## Se coloca en el player, enemigos, objetos destructibles.
## Detecta cuando un HitboxComponent lo toca y notifica al HealthComponent.

# Señales
signal hit_received(hit_data: Dictionary)
signal invincibility_started()
signal invincibility_ended()

# Configuración
@export_group("Health")
@export var health_component_path: NodePath
@export var auto_find_health: bool = true

@export_group("Entity Type")
@export_flags("Player", "Enemy", "Neutral") var entity_category: int = 0b001

@export_group("Invincibility")
@export var invincibility_on_hit: bool = true
@export var invincibility_duration: float = 1.0

@export_group("Visual Feedback")
@export var blink_on_hit: bool = true
@export var blink_duration: float = 0.1
@export var blink_count: int = 3

# Referencias
var health_component: HealthComponent = null

# Estado
var is_invincible: bool = false
var invincibility_timer: Timer
var blink_timer: Timer

var sprite: Node2D = null

func _ready() -> void:
	_find_health_component()
	_find_sprite()
	_setup_timers()
	
	print("[HurtboxComponent] Ready - Category: %d" % entity_category)

func _find_health_component() -> void:
	if health_component_path:
		health_component = get_node(health_component_path)
	elif auto_find_health:
		var parent = get_parent()
		if parent:
			for child in parent.get_children():
				if child is HealthComponent:
					health_component = child
					break
	
	if not health_component:
		push_warning("[HurtboxComponent] No HealthComponent found!")

func _find_sprite() -> void:
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is Sprite2D or child is AnimatedSprite2D:
				sprite = child
				break

func _setup_timers() -> void:
	invincibility_timer = Timer.new()
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(invincibility_timer)
	
	blink_timer = Timer.new()
	blink_timer.timeout.connect(_on_blink_timeout)
	add_child(blink_timer)

func take_hit(hit_data: Dictionary) -> void:
	if is_invincible:
		print("[HurtboxComponent] Hit blocked by invincibility")
		return
	
	print("[HurtboxComponent] Taking hit - Damage: %d" % hit_data.get("damage", 0))
	
	if health_component:
		health_component.take_damage(hit_data.get("damage", 0))
	
	if hit_data.has("knockback"):
		_apply_knockback(hit_data.knockback)
	
	if invincibility_on_hit:
		set_invincible(invincibility_duration)
	
	if blink_on_hit and sprite:
		_start_blink()
	
	hit_received.emit(hit_data)

func _apply_knockback(knockback: Vector2) -> void:
	var parent = get_parent()
	
	if parent is CharacterBody2D:
		parent.velocity += knockback
	elif parent is RigidBody2D:
		parent.apply_impulse(knockback)

func set_invincible(duration: float) -> void:
	is_invincible = true
	invincibility_timer.start(duration)
	invincibility_started.emit()
	print("[HurtboxComponent] Invincibility activated for %.1fs" % duration)

func _on_invincibility_timeout() -> void:
	is_invincible = false
	invincibility_ended.emit()
	print("[HurtboxComponent] Invincibility ended")

func _start_blink() -> void:
	if not sprite:
		return
	
	var blink_interval = blink_duration / float(blink_count)
	blink_timer.start(blink_interval)
	_blink_count_remaining = blink_count * 2

var _blink_count_remaining: int = 0

func _on_blink_timeout() -> void:
	if _blink_count_remaining <= 0:
		blink_timer.stop()
		sprite.visible = true
		return
	
	sprite.visible = not sprite.visible
	_blink_count_remaining -= 1
	
	if _blink_count_remaining > 0:
		var blink_interval = blink_duration / float(blink_count)
		blink_timer.start(blink_interval)
	else:
		sprite.visible = true

func get_is_invincible() -> bool:
	return is_invincible
