class_name Player
extends CharacterBody2D

## Player - Controlador principal del jugador del platformer

# ============================================================================
# CONFIGURACIÓN DE MOVIMIENTO
# ============================================================================
@export_group("Movement")
@export var max_speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0
@export var air_control: float = 0.8

@export_group("Jump")
@export var jump_velocity: float = -400.0
@export var variable_jump_height: bool = true
@export var min_jump_velocity: float = -200.0

@export_group("Physics")
@export var gravity: float = 980.0
@export var terminal_velocity: float = 500.0

# ============================================================================
# COMPONENTES
# ============================================================================
@onready var health_component: HealthComponent = $HealthComponent
@onready var input_buffer: InputBufferComponent = $InputBufferComponent
@onready var state_machine: StateMachine = $StateMachine
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var stomp_hitbox: HitboxComponent = $StompHitbox

# Referencias visuales
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if state_machine:
		await get_tree().process_frame
		state_machine.start("idle")
	
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.died.connect(_on_died)
	
	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)
	
	if stomp_hitbox:
		stomp_hitbox.hit_landed.connect(_on_stomp_landed)
	
	# Asegurar que empiece con idle
	if sprite:
		sprite.play("idle")
	
	print("[Player] Ready!")
	
func _physics_process(delta: float) -> void:
# Acivar/desactivar stomp hitbox según si está cayendo
	if stomp_hitbox:
		if velocity.y > 0:  # Cayendo
			stomp_hitbox.activate()
		else:
			stomp_hitbox.deactivate()

# ============================================================================
# FUNCIONES DE MOVIMIENTO
# ============================================================================

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, terminal_velocity)

func move_horizontal(direction: float, delta: float, control_multiplier: float = 1.0) -> void:
	if direction != 0:
		velocity.x += direction * acceleration * control_multiplier * delta
		velocity.x = clamp(velocity.x, -max_speed, max_speed)
		
		if sprite:
			sprite.flip_h = direction < 0

func apply_friction(delta: float) -> void:
	if abs(velocity.x) > friction * delta:
		velocity.x -= sign(velocity.x) * friction * delta
	else:
		velocity.x = 0

func jump() -> void:
	velocity.y = jump_velocity
	
	if input_buffer:
		input_buffer.consume_input("jump")

func cut_jump() -> void:
	if variable_jump_height and velocity.y < min_jump_velocity:
		velocity.y = min_jump_velocity

# ============================================================================
# CALLBACKS
# ============================================================================

func _on_health_changed(new_health: int, max_health: int) -> void:
	print("[Player] Health: %d/%d" % [new_health, max_health])

func _on_died() -> void:
	print("[Player] DIED!")
	set_physics_process(false)
	# Aquí game over

func _on_hit_received(hit_data: Dictionary) -> void:
	print("[Player] Got hit! Damage: %d" % hit_data.damage)
	
	# Solo transicionar al estado Hit
	# El estado se encarga del knockback
	if state_machine:
		state_machine.transition_to("hit")

func _on_stomp_landed(hurtbox: HurtboxComponent) -> void:
	print("[Player] Stomped enemy!")
	# Bounce al player
	velocity.y = jump_velocity * 0.6  # Bounce menor que salto normal

func take_damage(amount: int) -> void:
	if health_component:
		health_component.take_damage(amount)

func heal(amount: int) -> void:
	if health_component:
		health_component.heal(amount)

func get_current_state() -> String:
	if state_machine:
		return state_machine.get_current_state_name()
	return "Unknown"
