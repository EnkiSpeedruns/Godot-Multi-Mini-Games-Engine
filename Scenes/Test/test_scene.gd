extends Control

## TEST SCENE - Para probar transiciones del SceneTransition
## Solo incluye las transiciones que funcionan: instant, fade, wipe_left, wipe_right

@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton
@onready var transition_type_label: Label = $MarginContainer/VBoxContainer/TransitionTypeLabel

var transition_types: Array[String] = [
	"instant",
	"fade",
	"wipe_left",
	"wipe_right"
]

var current_type_index: int = 1  # Empezar con "fade"

func _ready() -> void:
	_update_label()
	
	# Escuchar señales de SceneTransition para debug
	SceneTransition.transition_started.connect(_on_transition_started)
	SceneTransition.transition_midpoint.connect(_on_transition_midpoint)
	SceneTransition.transition_finished.connect(_on_transition_finished)

func _update_label() -> void:
	if transition_type_label:
		transition_type_label.text = "Current Transition: %s" % transition_types[current_type_index]

## Volver al Main Menu
func _on_back_button_pressed() -> void:
	print("Returning to main menu with '%s' transition" % transition_types[current_type_index])
	SceneTransition.change_scene("res://Scenes/MainMenu/MainMenu.tscn", transition_types[current_type_index])

## Recargar esta escena con transición
func _on_reload_button_pressed() -> void:
	print("Reloading test scene with '%s' transition" % transition_types[current_type_index])
	SceneTransition.reload_current_scene(transition_types[current_type_index])

## Cambiar al siguiente tipo de transición
func _on_next_type_button_pressed() -> void:
	current_type_index = (current_type_index + 1) % transition_types.size()
	_update_label()
	print("Changed to transition type: %s" % transition_types[current_type_index])

## Cambiar al tipo anterior de transición
func _on_prev_type_button_pressed() -> void:
	current_type_index = (current_type_index - 1 + transition_types.size()) % transition_types.size()
	_update_label()
	print("Changed to transition type: %s" % transition_types[current_type_index])

## Test con loading label
func _on_test_with_loading_button_pressed() -> void:
	print("Testing with loading label")
	SceneTransition.change_scene(
		"res://Scenes/Test/TestScene.tscn",
		transition_types[current_type_index],
		true  # Show loading label
	)

# === Callbacks de debug ===

func _on_transition_started(transition_type: String) -> void:
	print("🎬 TRANSITION STARTED: %s" % transition_type)

func _on_transition_midpoint() -> void:
	print("⚡ TRANSITION MIDPOINT - Scene is changing now")

func _on_transition_finished() -> void:
	print("✅ TRANSITION FINISHED")

# === Input alternativo para testear ===

func _input(event: InputEvent) -> void:
	# Presionar SPACE para reload rápido
	if event.is_action_pressed("ui_accept"):
		_on_reload_button_pressed()
	
	# Presionar ESC para volver al menú
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
	
	# Flechas para cambiar tipo
	if event.is_action_pressed("ui_right"):
		_on_next_type_button_pressed()
	
	if event.is_action_pressed("ui_left"):
		_on_prev_type_button_pressed()
