extends Camera2D

## Camera Controller - CÃ¡mara inteligente para platformer

@export_group("Smoothing")
@export var smooth_speed: float = 5.0
@export var vertical_smoothing_multiplier: float = 0.5

@export_group("Look Ahead")
@export var look_ahead_enabled: bool = true
@export var look_ahead_distance: float = 100.0
@export var look_ahead_speed: float = 2.0

@export_group("Dead Zone")
@export var dead_zone_width: float = 100.0
@export var dead_zone_height: float = 60.0

var player: CharacterBody2D
var look_ahead_offset: float = 0.0
var target_look_ahead: float = 0.0

func _ready() -> void:
	player = get_parent() as CharacterBody2D
	
	if not player:
		push_error("[CameraController] Parent must be CharacterBody2D (Player)")
		return
	
	# ConfiguraciÃ³n inicial
	position_smoothing_enabled = true
	position_smoothing_speed = smooth_speed
	
	print("[CameraController] Ready")

func _process(delta: float) -> void:
	if not player:
		return
	
	_update_look_ahead(delta)

func _update_look_ahead(delta: float) -> void:
	if not look_ahead_enabled:
		return

	var player_direction := 0.0
	if abs(player.velocity.x) > 10.0:
		player_direction = sign(player.velocity.x)

	target_look_ahead = player_direction * look_ahead_distance
	look_ahead_offset = lerp(look_ahead_offset, target_look_ahead, look_ahead_speed * delta)

	# Clampear usando posición del player vs límites (no get_screen_center_position)
	var viewport_half_width := get_viewport_rect().size.x / (2.0 * zoom.x)
	var player_x := player.global_position.x

	var max_offset_right := look_ahead_distance
	var max_offset_left := look_ahead_distance

	if limit_right != 10000000:
		max_offset_right = max(0.0, limit_right - player_x - viewport_half_width)

	if limit_left != -10000000:
		max_offset_left = max(0.0, player_x - limit_left - viewport_half_width)

	offset.x = clamp(look_ahead_offset, -max_offset_left, max_offset_right)
