class_name Walker
extends CharacterBody2D

## Walker - Enemigo básico que patrulla

@export_group("Movement")
@export var move_speed: float = 50.0
@export var patrol_distance: float = 200.0
@export var detect_edges: bool = true

@export_group("Physics")
@export var gravity: float = 980.0

@export_group("Combat")
@export var contact_damage: int = 10
@export var death_bounce: float = -200.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var attack_hitbox: HitboxComponent = $AttackHitbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_ray_right: RayCast2D = $WallRay
@onready var wall_ray_left: RayCast2D = $WallRay2
@onready var edge_ray: RayCast2D = $EdgeRay

var direction: float = 1.0
var start_position: Vector2
var is_dead: bool = false
var _turned_this_frame: bool = false

func _ready() -> void:
	start_position = global_position
	sprite.play("default")
	if health_component:
		health_component.died.connect(_on_died)
		health_component.damaged.connect(_on_damaged)

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

	if attack_hitbox:
		attack_hitbox.hit_landed.connect(_on_attack_landed)

	print("[Walker] Spawned at %s" % global_position)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_turned_this_frame = false
	apply_gravity(delta)
	patrol(delta)
	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func patrol(delta: float) -> void:
	# Límite de patrulla
	var distance_from_start := global_position.x - start_position.x
	if abs(distance_from_start) > patrol_distance / 2.0:
		if (direction > 0 and distance_from_start > 0) or (direction < 0 and distance_from_start < 0):
			_turn_around()

	# Pared según dirección
	if not _turned_this_frame and direction > 0 and wall_ray_right and wall_ray_right.is_colliding():
		_turn_around()
	elif not _turned_this_frame and direction < 0 and wall_ray_left and wall_ray_left.is_colliding():
		_turn_around()

	# Borde (sin suelo adelante)
	if not _turned_this_frame and detect_edges and edge_ray and not edge_ray.is_colliding():
		_turn_around()

	velocity.x = direction * move_speed

	if sprite:
		sprite.flip_h = direction < 0

func _turn_around() -> void:
	if _turned_this_frame:
		return
	direction *= -1
	_turned_this_frame = true

func _on_hit_received(hit_data: Dictionary) -> void:
	if is_dead:
		return

	if hit_data.has("source") and hit_data.source is Player:
		var player := hit_data.source as Player
		if hit_data.position.y < global_position.y - 10:
			player.velocity.y = death_bounce

func _on_damaged(damage_amount: int) -> void:
	pass

func _on_attack_landed(_hurtbox: HurtboxComponent) -> void:
	pass

func _on_died() -> void:
	if is_dead:
		return

	is_dead = true
	set_physics_process(false)

	if attack_hitbox:
		attack_hitbox.deactivate()

	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	_play_death_animation()

	var game_logic := get_tree().get_first_node_in_group("game_logic")
	if game_logic and game_logic.has_method("add_score"):
		game_logic.add_score(100)

	await get_tree().create_timer(1.0).timeout
	queue_free()

func _play_death_animation() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "rotation", PI, 0.5)
	velocity.y = -150
