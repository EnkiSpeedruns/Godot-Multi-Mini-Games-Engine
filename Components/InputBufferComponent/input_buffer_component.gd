class_name InputBufferComponent
extends Node

## InputBufferComponent - Almacena inputs recientes para combos y mecánicas permisivas
##
## Esencial para jump buffering (presionar salto antes de tocar suelo)
## y coyote time (gracia al salir de plataforma)

# Propiedades exportadas
@export var buffer_window: float = 0.2  # segundos

# Estructura de input almacenado
class BufferedInput:
	var action: String
	var timestamp: float
	
	func _init(p_action: String, p_timestamp: float):
		action = p_action
		timestamp = p_timestamp

# Buffer de inputs
var input_buffer: Array[BufferedInput] = []

func _ready() -> void:
	print("[InputBufferComponent] Initialized - Buffer window: %.2fs" % buffer_window)

func _process(delta: float) -> void:
	_clean_old_inputs()

func add_input(action: String) -> void:
	var buffered = BufferedInput.new(action, Time.get_ticks_msec() / 1000.0)
	input_buffer.append(buffered)
	print("[InputBufferComponent] Buffered: %s" % action)

func has_input(action: String, max_age: float = -1.0) -> bool:
	if max_age < 0:
		max_age = buffer_window
	
	var current_time = Time.get_ticks_msec() / 1000.0
	
	for buffered in input_buffer:
		if buffered.action == action:
			var age = current_time - buffered.timestamp
			if age <= max_age:
				return true
	
	return false

func consume_input(action: String) -> bool:
	for i in range(input_buffer.size()):
		if input_buffer[i].action == action:
			input_buffer.remove_at(i)
			print("[InputBufferComponent] Consumed: %s" % action)
			return true
	return false

func clear_buffer() -> void:
	input_buffer.clear()

func get_recent_inputs(count: int = 3) -> Array[String]:
	var result: Array[String] = []
	var limit = min(count, input_buffer.size())
	
	for i in range(limit):
		var index = input_buffer.size() - 1 - i
		result.append(input_buffer[index].action)
	
	return result

func _clean_old_inputs() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	var i = 0
	while i < input_buffer.size():
		var age = current_time - input_buffer[i].timestamp
		if age > buffer_window:
			input_buffer.remove_at(i)
		else:
			i += 1
