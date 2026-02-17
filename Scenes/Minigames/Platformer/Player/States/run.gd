extends BaseState

## Estado Run - Player corriendo en el suelo

func enter() -> void:
	print("[Run] Enter")
	if player.sprite:
		player.sprite.play("walk")

func exit() -> void:
	print("[Run] Exit")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	
	var input_dir = Input.get_axis("move_left", "move_right")
	
	if input_dir != 0:
		player.move_horizontal(input_dir, delta)
	else:
		player.apply_friction(delta)
	
	_check_transitions()
	
	player.move_and_slide()

func _check_transitions() -> void:
	var input_dir = Input.get_axis("move_left", "move_right")
	
	if input_dir == 0 and abs(player.velocity.x) < 10:
		state_machine.transition_to("idle")
		return
	
	if Input.is_action_just_pressed("jump"):
		player.input_buffer.add_input("jump")
		state_machine.transition_to("jump")
		return
	
	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return
