class_name Charger
extends CharacterBody2D

## Charger - Enemigo que embiste agresivamente hacia los lados

@export var death_sound: AudioStream
@export var wall_hit_sound: AudioStream

@export_group("Movement")
@export var charge_speed: float = 300.0
@export var idle_duration: float = 1.0
@export var charge_duration_max: float = 3.0
@export var crash_knockback: float = 150.0

@export_group("Physics")
@export var gravity: float = 980.0

@export_group("Combat")
@export var contact_damage: int = 1
@export var death_bounce: float = -200.0

@export_group("Screenshake")
@export var shake_intensity: float = 10.0
@export var shake_duration: float = 0.3

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var attack_hitbox: HitboxComponent = $AttackHitbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_ray_right: RayCast2D = $WallRay
@onready var wall_ray_left: RayCast2D = $WallRay2

enum State { IDLE, CHARGING, CRASHED }

var current_state: State = State.IDLE
var direction: float = -1.0
var is_dead: bool = false
var charge_timer: float = 0.0

func _ready() -> void:
	sprite.play("charge")

	if health_component:
		health_component.died.connect(_on_died)

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

	_start_idle()
	print("[Charger] Spawned at %s" % global_position)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	apply_gravity(delta)

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.CHARGING:
			_process_charging(delta)
		State.CRASHED:
			_process_crashed(delta)

	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func _process_idle(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)

func _process_charging(delta: float) -> void:
	charge_timer += delta
	velocity.x = direction * charge_speed

	var hit_wall := false
	if direction > 0 and wall_ray_right and wall_ray_right.is_colliding():
		hit_wall = true
	elif direction < 0 and wall_ray_left and wall_ray_left.is_colliding():
		hit_wall = true

	if hit_wall or charge_timer > charge_duration_max:
		_hit_wall()

func _process_crashed(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)

func _start_idle() -> void:
	current_state = State.IDLE
	velocity.x = 0

	if sprite:
		sprite.play("charge")

	await get_tree().create_timer(idle_duration).timeout

	if not is_dead:
		_start_charge()

func _start_charge() -> void:
	current_state = State.CHARGING
	charge_timer = 0.0
	direction *= -1

	if sprite:
		sprite.play("charge")
		sprite.scale.x = -direction

	print("[Charger] CHARGING!")

func _hit_wall() -> void:
	print("[Charger] HIT WALL!")
	current_state = State.CRASHED

	if wall_hit_sound:
		AudioManager.play_sfx(wall_hit_sound)

	if sprite:
		sprite.play("crash")

	velocity.x = -direction * crash_knockback
	_trigger_screenshake()

	await get_tree().create_timer(0.5).timeout

	if not is_dead:
		_start_idle()

func _trigger_screenshake() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player or not player.has_node("Camera2D"):
		return

	var camera := player.get_node("Camera2D") as Camera2D
	var original_offset := camera.offset
	var shake_tween := create_tween()
	var shake_step_duration := shake_duration / 10.0

	for i in range(10):
		var random_offset := Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		shake_tween.tween_property(camera, "offset", original_offset + random_offset, shake_step_duration)

	shake_tween.tween_property(camera, "offset", original_offset, 0.1)

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

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_property(self, "rotation", PI, 0.5)

	var game_logic := get_tree().get_first_node_in_group("game_logic")
	if game_logic and game_logic.has_method("add_score"):
		game_logic.add_score(200)

	await tween.finished
	queue_free()
