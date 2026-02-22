extends BaseState

## Estado Hit - Player recibiendo daÃ±o

@export var hitstun_duration: float = 0.3
@export var apply_friction: bool = false  # No aplicar fricciÃ³n durante knockback
@export var knockback_strength: Vector2 = Vector2(200, -150)  # Fuerza del knockback (x, y)

var hitstun_timer: float = 0.0
var knockback_applied: bool = false

func enter() -> void:
	print("[Hit] Enter")
	hitstun_timer = hitstun_duration
	knockback_applied = false
	
	# Reproducir animaciÃ³n de hit
	if player.sprite:
		player.sprite.play("hit")

func exit() -> void:
	print("[Hit] Exit")

func physics_update(delta: float) -> void:
	# Aplicar knockback solo una vez al entrar
	if not knockback_applied:
		# Determinar direcciÃ³n del knockback segÃºn de dÃ³nde vino el golpe
		# Si no hay info, usar la direcciÃ³n contraria a donde mira el sprite
		var knockback_dir = -1 if player.sprite.flip_h else 1
		
		player.velocity.x = knockback_strength.x * knockback_dir
		player.velocity.y = knockback_strength.y
		knockback_applied = true
	
	# Aplicar gravedad
	player.apply_gravity(delta)
	
	# Opcional: aplicar fricciÃ³n ligera en el aire
	if apply_friction and not player.is_on_floor():
		player.velocity.x = lerp(player.velocity.x, 0.0, 0.1)
	
	# Decrementar timer
	hitstun_timer -= delta
	
	# Cuando termina el hitstun, volver al estado apropiado
	if hitstun_timer <= 0:
		_check_exit_state()
	
	player.move_and_slide()

func _check_exit_state() -> void:
	# Determinar a quÃ© estado volver segÃºn la situaciÃ³n
	if player.is_on_floor():
		var input_dir = Input.get_axis("move_left", "move_right")
		if input_dir != 0:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
	else:
		# En el aire
		if player.velocity.y < 0:
			state_machine.transition_to("jump")
		else:
			state_machine.transition_to("fall")
