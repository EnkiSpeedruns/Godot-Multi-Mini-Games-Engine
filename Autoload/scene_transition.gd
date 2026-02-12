extends CanvasLayer

## SceneTransition - Sistema global de transiciones entre escenas
##
## Maneja transiciones visuales y carga asíncrona de escenas.
## Uso: SceneTransition.change_scene(scene_path, "fade")

# Señales
signal transition_started(transition_type: String)
signal transition_midpoint()  # Momento en que cambia la escena
signal transition_finished()

# Tipos de transición disponibles
enum TransitionType {
	INSTANT,
	FADE,
	WIPE_LEFT,
	WIPE_RIGHT,
	PIXELATE,
	CIRCLE_CLOSE,
	CIRCLE_OPEN
}

# Configuración
@export var default_transition: TransitionType = TransitionType.FADE
@export var transition_duration: float = 0.5
@export var use_async_loading: bool = true

# Estado interno
var _is_transitioning: bool = false
var _target_scene_path: String = ""
var _transition_type: TransitionType = TransitionType.FADE

# Nodos de UI para transiciones
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var color_rect: ColorRect = $ColorRect
@onready var loading_label: Label = $LoadingLabel

func _ready() -> void:
	# Asegurarse de que este CanvasLayer está por encima de todo
	layer = 100
	
	# Inicialmente invisible
	color_rect.visible = false
	loading_label.visible = false
	
	# Crear animaciones proceduralmente
	_create_animations()
	
	print("SceneTransition initialized")

## Cambia a una nueva escena con transición
##
## @param scene_path: Ruta a la escena a cargar
## @param transition_type_name: Nombre del tipo de transición ("fade", "wipe", etc.)
## @param show_loading: Si mostrar el texto "Loading..."
func change_scene(
	scene_path: String, 
	transition_type_name: String = "fade",
	show_loading: bool = false
) -> void:
	if _is_transitioning:
		push_warning("SceneTransition: Already transitioning, ignoring request")
		return
	
	_target_scene_path = scene_path
	_transition_type = _parse_transition_type(transition_type_name)
	_is_transitioning = true
	
	loading_label.visible = show_loading
	
	transition_started.emit(transition_type_name)
	
	# Ejecutar transición de salida
	_play_transition_out()

## Recarga la escena actual con transición
func reload_current_scene(transition_type_name: String = "fade") -> void:
	var current_scene = get_tree().current_scene
	if current_scene:
		change_scene(current_scene.scene_file_path, transition_type_name)

## Convierte string a enum TransitionType
func _parse_transition_type(type_name: String) -> TransitionType:
	match type_name.to_lower():
		"instant":
			return TransitionType.INSTANT
		"fade":
			return TransitionType.FADE
		"wipe_left", "wipe-left":
			return TransitionType.WIPE_LEFT
		"wipe_right", "wipe-right":
			return TransitionType.WIPE_RIGHT
		"pixelate":
			return TransitionType.PIXELATE
		"circle_close", "circle-close":
			return TransitionType.CIRCLE_CLOSE
		"circle_open", "circle-open":
			return TransitionType.CIRCLE_OPEN
		_:
			push_warning("Unknown transition type '%s', using default" % type_name)
			return default_transition

## Reproduce la animación de salida (oscurecer pantalla)
func _play_transition_out() -> void:
	color_rect.visible = true
	
	match _transition_type:
		TransitionType.INSTANT:
			_on_transition_out_complete()
		TransitionType.FADE:
			animation_player.play("fade_out")
		TransitionType.WIPE_LEFT:
			animation_player.play("wipe_left_out")
		TransitionType.WIPE_RIGHT:
			animation_player.play("wipe_right_out")
		TransitionType.PIXELATE:
			animation_player.play("pixelate_out")
		TransitionType.CIRCLE_CLOSE:
			animation_player.play("circle_close")
		TransitionType.CIRCLE_OPEN:
			animation_player.play("circle_close")  # Primero cerrar
		_:
			animation_player.play("fade_out")

## Reproduce la animación de entrada (aclarar pantalla)
func _play_transition_in() -> void:
	match _transition_type:
		TransitionType.INSTANT:
			_on_transition_in_complete()
		TransitionType.FADE:
			animation_player.play("fade_in")
		TransitionType.WIPE_LEFT:
			animation_player.play("wipe_left_in")
		TransitionType.WIPE_RIGHT:
			animation_player.play("wipe_right_in")
		TransitionType.PIXELATE:
			animation_player.play("pixelate_in")
		TransitionType.CIRCLE_CLOSE:
			animation_player.play("circle_open")  # Luego abrir
		TransitionType.CIRCLE_OPEN:
			animation_player.play("circle_open")
		_:
			animation_player.play("fade_in")

## Callback cuando termina la animación de salida
func _on_transition_out_complete() -> void:
	transition_midpoint.emit()
	
	if use_async_loading:
		_load_scene_async()
	else:
		_load_scene_sync()

## Carga síncrona de escena (simple pero puede causar lag)
func _load_scene_sync() -> void:
	var err = get_tree().change_scene_to_file(_target_scene_path)
	
	if err != OK:
		push_error("Failed to load scene: %s" % _target_scene_path)
		_is_transitioning = false
		color_rect.visible = false
		loading_label.visible = false
		return
	
	# Pequeña pausa para que la nueva escena se inicialice
	await get_tree().process_frame
	
	_play_transition_in()

## Carga asíncrona de escena (recomendado para escenas grandes)
func _load_scene_async() -> void:
	var loader = ResourceLoader.load_threaded_request(_target_scene_path)
	
	if loader == OK:
		_poll_async_loading()
	else:
		push_error("Failed to start async loading: %s" % _target_scene_path)
		# Fallback a carga síncrona
		_load_scene_sync()

## Polling del estado de carga asíncrona
func _poll_async_loading() -> void:
	var progress = []
	
	while true:
		var status = ResourceLoader.load_threaded_get_status(_target_scene_path, progress)
		
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				# Actualizar indicador de carga si lo tenemos
				if loading_label.visible and progress.size() > 0:
					loading_label.text = "Loading... %d%%" % int(progress[0] * 100)
				await get_tree().process_frame
			
			ResourceLoader.THREAD_LOAD_LOADED:
				var scene = ResourceLoader.load_threaded_get(_target_scene_path)
				if scene:
					get_tree().change_scene_to_packed(scene)
					await get_tree().process_frame
					_play_transition_in()
				else:
					push_error("Failed to get loaded scene")
					_is_transitioning = false
					color_rect.visible = false
					loading_label.visible = false
				return
			
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Async loading failed: %s" % _target_scene_path)
				_is_transitioning = false
				color_rect.visible = false
				loading_label.visible = false
				return
			
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error("Invalid resource: %s" % _target_scene_path)
				_is_transitioning = false
				color_rect.visible = false
				loading_label.visible = false
				return

## Callback cuando termina la animación de entrada
func _on_transition_in_complete() -> void:
	color_rect.visible = false
	loading_label.visible = false
	_is_transitioning = false
	transition_finished.emit()

## Crea las animaciones proceduralmente
func _create_animations() -> void:
	var anim_lib = AnimationLibrary.new()
	
	# Fade Out
	var fade_out = _create_fade_animation(0.0, 1.0)
	fade_out.set_length(transition_duration)
	anim_lib.add_animation("fade_out", fade_out)
	
	# Fade In
	var fade_in = _create_fade_animation(1.0, 0.0)
	fade_in.set_length(transition_duration)
	anim_lib.add_animation("fade_in", fade_in)
	
	# Wipe Left Out
	var wipe_left_out = _create_wipe_animation(Vector2(-1, 0), Vector2(0, 0))
	wipe_left_out.set_length(transition_duration)
	anim_lib.add_animation("wipe_left_out", wipe_left_out)
	
	# Wipe Left In
	var wipe_left_in = _create_wipe_animation(Vector2(0, 0), Vector2(1, 0))
	wipe_left_in.set_length(transition_duration)
	anim_lib.add_animation("wipe_left_in", wipe_left_in)
	
	# Wipe Right Out
	var wipe_right_out = _create_wipe_animation(Vector2(1, 0), Vector2(0, 0))
	wipe_right_out.set_length(transition_duration)
	anim_lib.add_animation("wipe_right_out", wipe_right_out)
	
	# Wipe Right In
	var wipe_right_in = _create_wipe_animation(Vector2(0, 0), Vector2(-1, 0))
	wipe_right_in.set_length(transition_duration)
	anim_lib.add_animation("wipe_right_in", wipe_right_in)
	
	# Pixelate Out (simulado con alpha)
	var pixelate_out = _create_fade_animation(0.0, 1.0)
	pixelate_out.set_length(transition_duration * 0.7)
	anim_lib.add_animation("pixelate_out", pixelate_out)
	
	# Pixelate In
	var pixelate_in = _create_fade_animation(1.0, 0.0)
	pixelate_in.set_length(transition_duration * 0.7)
	anim_lib.add_animation("pixelate_in", pixelate_in)
	
	# Circle Close (simulado con scale)
	var circle_close = _create_scale_animation(Vector2(10, 10), Vector2(0, 0))
	circle_close.set_length(transition_duration)
	anim_lib.add_animation("circle_close", circle_close)
	
	# Circle Open
	var circle_open = _create_scale_animation(Vector2(0, 0), Vector2(10, 10))
	circle_open.set_length(transition_duration)
	anim_lib.add_animation("circle_open", circle_open)
	
	animation_player.add_animation_library("", anim_lib)
	
	# Conectar señales
	animation_player.animation_finished.connect(_on_animation_finished)

## Crea una animación de fade
func _create_fade_animation(from_alpha: float, to_alpha: float) -> Animation:
	var anim = Animation.new()
	
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "ColorRect:color:a")
	anim.track_insert_key(track_idx, 0.0, from_alpha)
	anim.track_insert_key(track_idx, transition_duration, to_alpha)
	
	return anim

## Crea una animación de wipe (desplazamiento)
func _create_wipe_animation(from_offset: Vector2, to_offset: Vector2) -> Animation:
	var anim = Animation.new()
	
	# Track para material shader (si lo implementamos)
	# Por ahora usamos position
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "ColorRect:position:x")
	
	var viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width", 1920)
	
	anim.track_insert_key(track_idx, 0.0, from_offset.x * viewport_width)
	anim.track_insert_key(track_idx, transition_duration, to_offset.x * viewport_width)
	
	# Asegurar que el color_rect cubra todo
	var alpha_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(alpha_track, "ColorRect:color:a")
	anim.track_insert_key(alpha_track, 0.0, 1.0)
	anim.track_insert_key(alpha_track, transition_duration, 1.0)
	
	return anim

## Crea una animación de escala (para efecto de círculo)
func _create_scale_animation(from_scale: Vector2, to_scale: Vector2) -> Animation:
	var anim = Animation.new()
	
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "ColorRect:scale")
	anim.track_insert_key(track_idx, 0.0, from_scale)
	anim.track_insert_key(track_idx, transition_duration, to_scale)
	
	# Centrar el pivot
	var pivot_track = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(pivot_track, "ColorRect:pivot_offset")
	var viewport_size = Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 1920),
		ProjectSettings.get_setting("display/window/size/viewport_height", 1080)
	)
	anim.track_insert_key(pivot_track, 0.0, viewport_size / 2)
	
	return anim

## Callback cuando cualquier animación termina
func _on_animation_finished(anim_name: String) -> void:
	if anim_name.ends_with("_out") or anim_name == "circle_close":
		_on_transition_out_complete()
	elif anim_name.ends_with("_in") or anim_name == "circle_open":
		_on_transition_in_complete()

## Verifica si está en proceso de transición
func is_transitioning() -> bool:
	return _is_transitioning
