class_name StateMachine
extends Node

## StateMachine - MÃƒÂ¡quina de estados genÃƒÂ©rica
##
## Gestiona transiciones entre estados y propaga updates/inputs

# SeÃƒÂ±ales
signal state_changed(old_state: String, new_state: String)

# Estado actual
var current_state: BaseState = null
var previous_state: BaseState = null

# Referencia al player
var player: CharacterBody2D = null

# Estados disponibles
var states: Dictionary = {}

func _ready() -> void:
	player = get_parent() as CharacterBody2D
	
	if not player:
		push_error("[StateMachine] Parent must be a CharacterBody2D!")
		return
	
	await get_tree().process_frame
	
	for child in get_children():
		if child is BaseState:
			states[child.name.to_lower()] = child
			child.state_machine = self
			child.player = player
	
	print("[StateMachine] Registered %d states" % states.size())

func start(initial_state_name: String) -> void:
	var initial_state = states.get(initial_state_name.to_lower())  # Normalizar a minÃƒÂºsculas
	
	if not initial_state:
		push_error("[StateMachine] State '%s' not found!" % initial_state_name)
		return
	
	current_state = initial_state
	current_state.enter()
	print("[StateMachine] Started with state: %s" % initial_state_name)

func transition_to(new_state_name: String) -> void:
	var new_state = states.get(new_state_name.to_lower())
	
	if not new_state:
		push_error("[StateMachine] State '%s' not found!" % new_state_name)
		return
	
	if new_state == current_state:
		return
	
	# Salir del estado actual
	if current_state:
		current_state.exit()
		previous_state = current_state
	
	# Entrar al nuevo estado
	var old_state_name = current_state.name if current_state else "none"
	current_state = new_state
	current_state.enter()
	
	state_changed.emit(old_state_name, new_state_name)
	print("[StateMachine] %s -> %s" % [old_state_name, new_state_name])

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func get_current_state_name() -> String:
	return current_state.name if current_state else ""

func is_in_state(state_name: String) -> bool:
	if not current_state:
		return false
	return current_state.name.to_lower() == state_name.to_lower()
