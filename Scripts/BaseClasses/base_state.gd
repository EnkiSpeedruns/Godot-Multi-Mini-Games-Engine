class_name BaseState
extends Node

## BaseState - Clase base para todos los estados

# Referencia a la state machine
var state_machine: Node = null

# Referencia al player
var player: CharacterBody2D = null

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	pass

func handle_input(event: InputEvent) -> void:
	pass
