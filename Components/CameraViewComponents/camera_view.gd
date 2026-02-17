@tool
class_name CameraView
extends Node2D

## CameraView - Define el área de límites de la cámara para un room.
##
## Se instancia como hijo de cada PlatformerRoom.
## En el editor se puede redimensionar arrastrando los handles de las esquinas.
## El CameraConfiner lee get_global_rect() para aplicar los límites a la Camera2D.

signal resized()

@export_group("Bounds")
@export var size: Vector2 = Vector2(1920, 1080):
	set(v):
		size = Vector2(max(v.x, 64.0), max(v.y, 64.0))
		queue_redraw()
		resized.emit()

@export_group("Debug")
@export var color: Color = Color(0.0, 0.8, 1.0, 0.25):
	set(v):
		color = v
		queue_redraw()

# Estado de drag en editor
var _drag_handle: int = -1  # -1 = ninguno, 0=BR, 1=BL, 2=TR, 3=TL
const HANDLE_RADIUS := 10.0

# ─────────────────────────────────────────────────────────────────────────────
# PÚBLICO
# ─────────────────────────────────────────────────────────────────────────────

## Devuelve el Rect2 en espacio global.
func get_global_rect() -> Rect2:
	return Rect2(global_position, size)

# ─────────────────────────────────────────────────────────────────────────────
# BUILT-IN
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return

	var rect := Rect2(Vector2.ZERO, size)

	# Relleno semitransparente
	draw_rect(rect, color, true)

	# Borde sólido
	var border_color := Color(color.r, color.g, color.b, 1.0)
	draw_rect(rect, border_color, false, 2.0)

	# Nombre
	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	draw_string(font, Vector2(8, 24), name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, border_color)

	# Dimensiones en esquina inferior derecha
	var size_text := "%d x %d" % [int(size.x), int(size.y)]
	draw_string(font, Vector2(size.x - 100, size.y - 8), size_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size - 2, border_color)

	# Handles en las 4 esquinas
	var handles := _get_handle_positions()
	for i in handles.size():
		var h_color := Color.YELLOW if _drag_handle == i else Color.WHITE
		draw_circle(handles[i], HANDLE_RADIUS, h_color)
		draw_arc(handles[i], HANDLE_RADIUS, 0, TAU, 16, border_color, 1.5)

# ─────────────────────────────────────────────────────────────────────────────
# INPUT DEL EDITOR (redimensionado con drag)
# ─────────────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if not Engine.is_editor_hint():
		return

	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				_drag_handle = _get_handle_at(to_local(get_viewport().get_mouse_position()))
			else:
				if _drag_handle != -1:
					_drag_handle = -1
					queue_redraw()

	elif event is InputEventMouseMotion and _drag_handle != -1:
		var local_mouse := to_local(get_viewport().get_mouse_position())
		_resize_from_handle(_drag_handle, local_mouse)

func _get_handle_positions() -> Array[Vector2]:
	return [
		Vector2(size.x, size.y),  # 0: Bottom-Right
		Vector2(0.0,    size.y),  # 1: Bottom-Left
		Vector2(size.x, 0.0),     # 2: Top-Right
		Vector2(0.0,    0.0),     # 3: Top-Left
	]

func _get_handle_at(local_pos: Vector2) -> int:
	var handles := _get_handle_positions()
	for i in handles.size():
		if local_pos.distance_to(handles[i]) <= HANDLE_RADIUS * 2.0:
			return i
	return -1

func _resize_from_handle(handle: int, local_mouse: Vector2) -> void:
	match handle:
		0:  # Bottom-Right: expande desde top-left
			size = Vector2(local_mouse.x, local_mouse.y)
		1:  # Bottom-Left: mueve origen X, expande borde inferior
			var delta_x := local_mouse.x
			position.x += delta_x
			size = Vector2(size.x - delta_x, local_mouse.y)
		2:  # Top-Right: expande borde derecho, mueve origen Y
			var delta_y := local_mouse.y
			position.y += delta_y
			size = Vector2(local_mouse.x, size.y - delta_y)
		3:  # Top-Left: mueve origen X e Y
			var delta := local_mouse
			position += delta
			size = Vector2(size.x - delta.x, size.y - delta.y)
	queue_redraw()
