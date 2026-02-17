extends BaseState

## Estado Jump - Player saltando

var has_released_jump: bool = false

func enter() -> void:
	print("[Jump] Enter")
	player.jump()
	has_released_jump = false
	
	if player.sprite:
		player.sprite.play("jump")

func exit() -> void:
	print("[Jump] Exit")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	
	if not has_released_jump and Input.is_action_just_released("jump"):
		player.cut_jump()
		has_released_jump = true
	
	var input_dir = Input.get_axis("move_left", "move_right")
	if input_dir != 0:
		player.move_horizontal(input_dir, delta, player.air_control)
	
	_check_transitions()
	
	player.move_and_slide()

func _check_transitions() -> void:
	if player.velocity.y > 0:
		state_machine.transition_to("fall")
		return
	
	if player.is_on_floor():
		state_machine.transition_to("idle")
		return
