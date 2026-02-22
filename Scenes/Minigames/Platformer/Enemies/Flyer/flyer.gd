class_name Flyer
extends CharacterBody2D

## Flyer - Enemigo volador que patrulla con movimiento ondulante

@export var death_sound: AudioStream

@export_group("Movement")
@export var move_speed: float = 60.0
@export var patrol_distance: float = 200.0
@export var wave_amplitude: float = 30.0
@export var wave_frequency: float = 2.0

@export_group("Combat")
@export var contact_damage: int = 1
@export var death_bounce: float = -200.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var attack_hitbox: HitboxComponent = $AttackHitbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_ray_right: RayCast2D = $WallRay
@onready var wall_ray_left: RayCast2D = $WallRay2

var direction: float = 1.0
var start_position: Vector2
var is_dead: bool = false
var time: float = 0.0
var _turned_this_frame: bool = false

func _ready() -> void:
	start_position = global_position
	sprite.play("default")

	if health_component:
		health_component.died.connect(_on_died)

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

	print("[Flyer] Spawned at %s" % global_position)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_turned_this_frame = false
	time += delta
	patrol(delta)
	move_and_slide()

func patrol(delta: float) -> void:
	var distance_from_start := global_position.x - start_position.x

	if abs(distance_from_start) > patrol_distance / 2.0:
		if (direction > 0 and distance_from_start > 0) or (direction < 0 and distance_from_start < 0):
			_turn_around()

	if not _turned_this_frame and direction > 0 and wall_ray_right and wall_ray_right.is_colliding():
		_turn_around()
	elif not _turned_this_frame and direction < 0 and wall_ray_left and wall_ray_left.is_colliding():
		_turn_around()

	velocity.x = direction * move_speed

	var wave_offset := sin(time * wave_frequency) * wave_amplitude
	var target_y := start_position.y + wave_offset
	velocity.y = (target_y - global_position.y) * 5.0

	if sprite:
		sprite.scale.x = direction

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

func _on_died() -> void:
	if is_dead:
		return
	if death_sound:
		AudioManager.play_sfx(death_sound)
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
	velocity.y = 200
