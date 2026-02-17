extends BaseState

## Estado Idle - Player parado en el suelo

func enter() -> void:
	print("[Idle] Enter")
	if player.sprite:
		player.sprite.play("idle")

func exit() -> void:
	print("[Idle] Exit")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_friction(delta)
	
	_check_transitions()
	
	player.move_and_slide()

func _check_transitions() -> void:
	var input_dir = Input.get_axis("move_left", "move_right")
	
	if input_dir != 0:
		state_machine.transition_to("run")
		return
	
	if Input.is_action_just_pressed("jump"):
		player.input_buffer.add_input("jump")
		state_machine.transition_to("jump")
		return
	
	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return
