class_name CameraConfiner
extends Node2D

## CameraConfiner - Aplica los límites de la Camera2D según el room activo.
##
## Vive una sola vez en Level (hijo directo).
## Cada PlatformerRoom tiene un CameraView hijo que define su área.
## Cuando el RoomManager spawna un room, llama a apply_room(room).
##
## Estructura en escena:
##   Main
##   └── Level
##       ├── Player
##       │   └── Camera2D
##       └── CameraConfiner   ← esta escena

signal view_applied(room_name: String)

var _camera: Camera2D = null

# ─────────────────────────────────────────────────────────────────────────────
# BUILT-IN
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	pass

# ─────────────────────────────────────────────────────────────────────────────
# PÚBLICO
# ─────────────────────────────────────────────────────────────────────────────

## Aplica los límites del CameraView que vive dentro del room dado.
func apply_room(room: Node2D) -> void:
	if room == null:
		push_error("[CameraConfiner] apply_room: room es null.")
		return

	var view := _find_view_in(room)

	if view == null:
		push_error("[CameraConfiner] El room '%s' no tiene un CameraView hijo." % room.name)
		return

	_apply_view(view, room.name)

## Inyección manual de cámara si la búsqueda automática falla.
func set_camera(camera: Camera2D) -> void:
	_camera = camera

# ─────────────────────────────────────────────────────────────────────────────
# PRIVADO
# ─────────────────────────────────────────────────────────────────────────────

func _find_view_in(room: Node2D) -> CameraView:
	for child in room.get_children():
		if child is CameraView:
			return child
	return null

func _apply_view(view: CameraView, source_name: String) -> void:
	if _camera == null:
		push_error("[CameraConfiner] Sin cámara asignada. Llamá set_camera() antes de apply_room().")
		return

	var rect := view.get_global_rect()

	_camera.limit_left   = int(rect.position.x)
	_camera.limit_top    = int(rect.position.y)
	_camera.limit_right  = int(rect.end.x)
	_camera.limit_bottom = int(rect.end.y)

	_camera.reset_smoothing()

	view_applied.emit(source_name)
	print("[CameraConfiner] Límites aplicados desde '%s': L%d T%d R%d B%d" % [
		source_name,
		_camera.limit_left, _camera.limit_top,
		_camera.limit_right, _camera.limit_bottom
	])
