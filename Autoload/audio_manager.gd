extends Node

## AudioManager - Sistema global de audio
##
## Maneja reproducción de música, efectos de sonido (con pooling),
## y control de volumen por buses (Master, Music, SFX)

# Señales
signal music_started(track_name: String)
signal music_stopped()
signal music_finished()
signal sfx_played(sound_name: String)

# Configuración
@export var sfx_pool_size: int = 16  # Número de AudioStreamPlayers para SFX
@export var default_fade_duration: float = 1.0

# Buses de audio (deben coincidir con los del proyecto)
const BUS_MASTER = "Master"
const BUS_MUSIC = "Music"
const BUS_SFX = "SFX"

# Pool de AudioStreamPlayers para SFX
var sfx_players: Array[AudioStreamPlayer] = []
var next_sfx_player_index: int = 0

# Reproductor dedicado para música
var music_player: AudioStreamPlayer
var music_tween: Tween
var current_music_track: String = ""

# Volúmenes actuales (0.0 a 1.0)
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

# Índices de buses
var master_bus_index: int
var music_bus_index: int
var sfx_bus_index: int

func _ready() -> void:
	_setup_audio_buses()
	_create_music_player()
	_create_sfx_pool()
	_load_volumes_from_settings()
	
	print("AudioManager initialized")
	print("- SFX Pool: %d players" % sfx_pool_size)
	print("- Music Player: Ready")
	print("- Master Volume: %.0f%%" % (master_volume * 100))
	print("- Music Volume: %.0f%%" % (music_volume * 100))
	print("- SFX Volume: %.0f%%" % (sfx_volume * 100))

## Configura los índices de los buses de audio
func _setup_audio_buses() -> void:
	master_bus_index = AudioServer.get_bus_index(BUS_MASTER)
	music_bus_index = AudioServer.get_bus_index(BUS_MUSIC)
	sfx_bus_index = AudioServer.get_bus_index(BUS_SFX)
	
	if master_bus_index == -1:
		push_error("Bus 'Master' not found!")
	if music_bus_index == -1:
		push_error("Bus 'Music' not found!")
	if sfx_bus_index == -1:
		push_error("Bus 'SFX' not found!")

## Crea el reproductor de música
func _create_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = BUS_MUSIC
	add_child(music_player)
	
	# Conectar señal de finished
	music_player.finished.connect(_on_music_finished)

## Crea el pool de reproductores de SFX
func _create_sfx_pool() -> void:
	for i in range(sfx_pool_size):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = BUS_SFX
		add_child(player)
		sfx_players.append(player)

## Carga volúmenes desde SettingsManager
func _load_volumes_from_settings() -> void:
	if not SettingsManager:
		push_warning("SettingsManager not found, using default volumes")
		return
	
	set_master_volume(SettingsManager.get_master_volume())
	set_music_volume(SettingsManager.get_music_volume())
	set_sfx_volume(SettingsManager.get_sfx_volume())

# ============================================================================
# MÚSICA
# ============================================================================

## Reproduce una pista de música
##
## @param music: AudioStream a reproducir
## @param fade_in: Duración del fade in (0 = sin fade)
## @param loop: Si la música debe hacer loop
func play_music(music: AudioStream, fade_in: float = 0.0, loop: bool = true) -> void:
	if not music:
		push_error("AudioManager.play_music: music is null")
		return
	
	# Si hay música sonando, hacer fade out primero
	if music_player.playing:
		stop_music(fade_in)
		await music_stopped
	
	# Configurar nueva música
	music_player.stream = music
	
	# Configurar loop según el tipo de stream
	if music_player.stream is AudioStreamOggVorbis:
		music_player.stream.loop = loop
	elif music_player.stream is AudioStreamMP3:
		music_player.stream.loop = loop
	elif music_player.stream is AudioStreamWAV:
		# Para WAV, configurar loop mode
		if loop:
			music_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		else:
			music_player.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	
	# Fade in si se solicita
	if fade_in > 0.0:
		music_player.volume_db = -80.0  # Silencio inicial para fade in (FIX: evita NaN)
		music_player.play()
		_fade_music_to(1.0, fade_in)
	else:
		music_player.volume_db = 0.0
		music_player.play()
	
	current_music_track = music.resource_path if music.resource_path else "Unknown"
	music_started.emit(current_music_track)
	print("Playing music: %s (loop: %s)" % [current_music_track, loop])

## Detiene la música actual
##
## @param fade_out: Duración del fade out (0 = stop instantáneo)
func stop_music(fade_out: float = 0.0) -> void:
	if not music_player.playing:
		return
	
	if fade_out > 0.0:
		_fade_music_to(0.0, fade_out)
		await music_stopped
	else:
		music_player.stop()
		current_music_track = ""
		music_stopped.emit()
		print("Music stopped")

## Pausa la música
func pause_music() -> void:
	music_player.stream_paused = true
	print("Music paused")

## Resume la música pausada
func resume_music() -> void:
	music_player.stream_paused = false
	print("Music resumed")

## Crossfade entre dos pistas de música
##
## @param new_music: AudioStream de la nueva pista
## @param duration: Duración del crossfade
func crossfade_music(new_music: AudioStream, duration: float = 1.0) -> void:
	if not new_music:
		push_error("AudioManager.crossfade_music: new_music is null")
		return
	
	# Si no hay música sonando, solo play normal
	if not music_player.playing:
		play_music(new_music, duration)
		return
	
	# Fade out actual y fade in nueva
	stop_music(duration)
	await music_stopped
	play_music(new_music, duration)

## Fade de música a un volumen específico
func _fade_music_to(target_volume: float, duration: float) -> void:
	# Cancelar tween anterior si existe
	if music_tween:
		music_tween.kill()
	
	music_tween = create_tween()
	
	var target_db = linear_to_db(target_volume) if target_volume > 0 else -80.0
	
	music_tween.tween_property(
		music_player,
		"volume_db",
		target_db,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Si fade a 0, detener cuando termine
	if target_volume == 0.0:
		music_tween.finished.connect(
			func():
				music_player.stop()
				music_player.volume_db = 0.0
				current_music_track = ""
				music_stopped.emit()
		, CONNECT_ONE_SHOT)

## Callback cuando termina una pista de música (si no está en loop)
func _on_music_finished() -> void:
	current_music_track = ""
	music_finished.emit()
	print("Music finished")

## Verifica si hay música reproduciéndose
func is_music_playing() -> bool:
	return music_player.playing

## Obtiene el nombre de la pista actual
func get_current_music_track() -> String:
	return current_music_track

# ============================================================================
# EFECTOS DE SONIDO (SFX)
# ============================================================================

## Reproduce un efecto de sonido
##
## @param sound: AudioStream del SFX
## @param volume_db: Volumen en dB (0 = normal, negativo = más bajo)
## @param pitch_scale: Escala de pitch (1.0 = normal)
## @param position_2d: Posición 2D opcional para audio espacial (no implementado aún)
func play_sfx(
	sound: AudioStream,
	volume_db: float = 0.0,
	pitch_scale: float = 1.0
) -> void:
	if not sound:
		push_error("AudioManager.play_sfx: sound is null")
		return
	
	# Obtener siguiente player disponible del pool
	var player = _get_next_sfx_player()
	
	# Configurar y reproducir
	player.stream = sound
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	
	sfx_played.emit(sound.resource_path if sound.resource_path else "Unknown")

## Reproduce un SFX con pitch aleatorio (útil para variedad)
##
## @param sound: AudioStream del SFX
## @param min_pitch: Pitch mínimo
## @param max_pitch: Pitch máximo
## @param volume_db: Volumen en dB
func play_sfx_random_pitch(
	sound: AudioStream,
	min_pitch: float = 0.9,
	max_pitch: float = 1.1,
	volume_db: float = 0.0
) -> void:
	var random_pitch = randf_range(min_pitch, max_pitch)
	play_sfx(sound, volume_db, random_pitch)

## Obtiene el siguiente reproductor disponible del pool
func _get_next_sfx_player() -> AudioStreamPlayer:
	# Usar índice circular para rotar entre players
	var player = sfx_players[next_sfx_player_index]
	next_sfx_player_index = (next_sfx_player_index + 1) % sfx_pool_size
	
	# Si el player está ocupado, detenerlo (trunca el sonido anterior)
	if player.playing:
		player.stop()
	
	return player

## Detiene todos los SFX
func stop_all_sfx() -> void:
	for player in sfx_players:
		if player.playing:
			player.stop()
	print("All SFX stopped")

# ============================================================================
# CONTROL DE VOLUMEN
# ============================================================================

## Establece el volumen del bus Master
##
## @param volume: Volumen de 0.0 a 1.0
func set_master_volume(volume: float) -> void:
	volume = clamp(volume, 0.0, 1.0)
	master_volume = volume
	_set_bus_volume(master_bus_index, volume)

## Establece el volumen del bus Music
##
## @param volume: Volumen de 0.0 a 1.0
func set_music_volume(volume: float) -> void:
	volume = clamp(volume, 0.0, 1.0)
	music_volume = volume
	_set_bus_volume(music_bus_index, volume)

## Establece el volumen del bus SFX
##
## @param volume: Volumen de 0.0 a 1.0
func set_sfx_volume(volume: float) -> void:
	volume = clamp(volume, 0.0, 1.0)
	sfx_volume = volume
	_set_bus_volume(sfx_bus_index, volume)

## Establece el volumen de un bus específico
##
## @param bus_index: Índice del bus
## @param volume: Volumen de 0.0 a 1.0
func _set_bus_volume(bus_index: int, volume: float) -> void:
	if bus_index == -1:
		return
	
	# Convertir volumen lineal (0-1) a dB
	# -80 dB = silencio efectivo
	var volume_db = linear_to_db(volume) if volume > 0 else -80.0
	AudioServer.set_bus_volume_db(bus_index, volume_db)

## Obtiene el volumen del bus Master
func get_master_volume() -> float:
	return master_volume

## Obtiene el volumen del bus Music
func get_music_volume() -> float:
	return music_volume

## Obtiene el volumen del bus SFX
func get_sfx_volume() -> float:
	return sfx_volume

## Mutea/desmutea un bus específico
##
## @param bus_name: Nombre del bus ("Master", "Music", "SFX")
## @param muted: true para mutear, false para desmutear
func set_bus_mute(bus_name: String, muted: bool) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, muted)
		print("Bus '%s' %s" % [bus_name, "muted" if muted else "unmuted"])

## Verifica si un bus está muteado
func is_bus_muted(bus_name: String) -> bool:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		return AudioServer.is_bus_mute(bus_index)
	return false

# ============================================================================
# UTILIDADES
# ============================================================================

## Reproduce un sonido de UI (botón, hover, etc.)
## Usa volumen más bajo por defecto
func play_ui_sound(sound: AudioStream) -> void:
	play_sfx(sound, -5.0)  # -5 dB más bajo que normal

## Convierte volumen lineal (0-1) a decibeles
func linear_to_db(linear: float) -> float:
	if linear <= 0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

## Convierte decibeles a volumen lineal (0-1)
func db_to_linear(db: float) -> float:
	if db <= -80.0:
		return 0.0
	return pow(10.0, db / 20.0)

## Info de debug
func print_audio_info() -> void:
	print("\n=== AUDIO MANAGER INFO ===")
	print("Music Playing: %s" % is_music_playing())
	print("Current Track: %s" % current_music_track)
	print("Master Volume: %.0f%%" % (master_volume * 100))
	print("Music Volume: %.0f%%" % (music_volume * 100))
	print("SFX Volume: %.0f%%" % (sfx_volume * 100))
	print("SFX Pool Size: %d" % sfx_pool_size)
	
	var active_sfx = 0
	for player in sfx_players:
		if player.playing:
			active_sfx += 1
	print("Active SFX: %d" % active_sfx)
	print("========================\n")
