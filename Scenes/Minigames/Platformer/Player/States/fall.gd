extends BaseState

## Estado Fall - Player cayendo

@export var coyote_time: float = 0.15
var time_off_floor: float = 0.0

func enter() -> void:
	print("[Fall] Enter")
	time_off_floor = 0.0
	
	if player.sprite:
		player.sprite.play("fall")

func exit() -> void:
	print("[Fall] Exit")

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		time_off_floor += delta
	
	player.apply_gravity(delta)
	
	var input_dir = Input.get_axis("move_left", "move_right")
	if input_dir != 0:
		player.move_horizontal(input_dir, delta, player.air_control)
	
	_check_transitions()
	
	player.move_and_slide()

func _check_transitions() -> void:
	if Input.is_action_just_pressed("jump"):
		player.input_buffer.add_input("jump")
		
		if time_off_floor <= coyote_time:
			state_machine.transition_to("jump")
			return
	
	if player.is_on_floor():
		if player.input_buffer.has_input("jump"):
			state_machine.transition_to("jump")
			return
		
		var input_dir = Input.get_axis("move_left", "move_right")
		if input_dir != 0:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
		return
