class_name Fish
extends Area2D

## Fish - Pez que salta del agua periódicamente

@export var death_sound: AudioStream

@export_group("Jump")
@export var jump_height: float = 200.0
@export var jump_duration: float = 0.8
@export var jump_interval_min: float = 2.0
@export var jump_interval_max: float = 4.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var attack_hitbox: HitboxComponent = $AttackHitbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_dead: bool = false
var is_jumping: bool = false
var spawn_position: Vector2

func _ready() -> void:
	spawn_position = global_position

	if health_component:
		health_component.died.connect(_on_died)

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)

	_hide_underwater()
	_schedule_next_jump()
	print("[Fish] Spawned at %s" % global_position)

func _hide_underwater() -> void:
	if sprite:
		sprite.play("down")
		sprite.visible = false

	if attack_hitbox:
		attack_hitbox.deactivate()

	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	collision_shape.set_deferred("disabled", true)

func _schedule_next_jump() -> void:
	if is_dead:
		return

	var wait_time := randf_range(jump_interval_min, jump_interval_max)
	await get_tree().create_timer(wait_time).timeout

	if not is_dead and not is_jumping:
		_jump()

func _jump() -> void:
	if is_dead or is_jumping:
		return

	is_jumping = true

	if sprite:
		sprite.visible = true
		sprite.play("up")

	# Subiendo: solo el attack_hitbox activo
	if attack_hitbox:
		attack_hitbox.activate()

	collision_shape.set_deferred("disabled", false)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	tween.tween_property(self, "position:y", spawn_position.y - jump_height, jump_duration / 2.0)

	# A mitad del salto: desactivar ataque, activar hurtbox
	tween.tween_callback(func():
		if sprite:
			sprite.play("down")
		if attack_hitbox:
			attack_hitbox.deactivate()
		if hurtbox:
			hurtbox.set_deferred("monitoring", true)
			hurtbox.set_deferred("monitorable", true)
	)

	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:y", spawn_position.y, jump_duration / 2.0)
	tween.tween_callback(_on_jump_finished)

	print("[Fish] Jumping!")

func _on_jump_finished() -> void:
	is_jumping = false
	_hide_underwater()
	_schedule_next_jump()

func _on_hit_received(hit_data: Dictionary) -> void:
	if is_dead or not is_jumping:
		return

	if hit_data.has("source") and hit_data.source is Player:
		var player := hit_data.source as Player
		if hit_data.position.y < global_position.y - 10:
			player.velocity.y = -200

func _on_died() -> void:
	if is_dead:
		return
	if death_sound:
		AudioManager.play_sfx(death_sound)
	is_dead = true
	is_jumping = false

	if attack_hitbox:
		attack_hitbox.deactivate()

	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	collision_shape.set_deferred("disabled", true)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)

	var game_logic := get_tree().get_first_node_in_group("game_logic")
	if game_logic and game_logic.has_method("add_score"):
		game_logic.add_score(150)

	await tween.finished
	queue_free()
