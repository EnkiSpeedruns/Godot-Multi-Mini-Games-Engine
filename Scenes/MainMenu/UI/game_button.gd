class_name GameButton
extends PanelContainer

## GameButton - Botón de minijuego con audio integrado

signal game_selected(game_id: String)

@export var game_id: String = ""
@export var game_name: String = "":
	set(value):
		game_name = value
		if name_label:
			name_label.text = value

@export var description: String = "":
	set(value):
		description = value
		if description_label:
			description_label.text = value

@export var thumbnail: Texture2D:
	set(value):
		thumbnail = value
		if thumbnail_rect:
			thumbnail_rect.texture = value

@export var high_score: int = 0:
	set(value):
		high_score = value
		if high_score_label:
			high_score_label.text = "High Score: " + str(value)
			
@export var is_locked: bool = false

# Referencias a nodos hijos
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel
@onready var thumbnail_rect: TextureRect = $MarginContainer/VBoxContainer/ThumbnailRect
@onready var high_score_label: Label = $MarginContainer/VBoxContainer/HighScoreLabel
@onready var click_button: Button = $ClickButton

# Recursos de audio
var hover_sound: AudioStream
var click_sound: AudioStream

func _ready() -> void:
	_load_audio_resources()
	_update_display()
	
	if is_locked:
		_set_locked_state()
	else:
		_setup_audio_signals()

## Carga los recursos de audio
func _load_audio_resources() -> void:
	hover_sound = load("res://Resources/Audio/SFX/tap-a.ogg")
	click_sound = load("res://Resources/Audio/SFX/click-a.ogg")

## Configura las señales de audio
func _setup_audio_signals() -> void:
	# Hover sound
	click_button.mouse_entered.connect(_on_hover)
	
	# Click sound se reproduce en _on_click_button_pressed

func _update_display() -> void:
	if name_label:
		name_label.text = game_name
	if description:
		description_label.text = description
	if thumbnail_rect:
		thumbnail_rect.texture = thumbnail
	if high_score_label:
		high_score_label.text = "High Score: " + str(high_score)

func _set_locked_state() -> void:
	click_button.disabled = true
	modulate = Color(0.5, 0.5, 0.5, 1)

## Callback cuando el mouse entra al botón
func _on_hover() -> void:
	if not is_locked and AudioManager:
		AudioManager.play_sfx(hover_sound, -8.0)  # Volumen bajo para hover

## Callback cuando se presiona el botón
func _on_click_button_pressed() -> void:
	if not is_locked:
		# Reproducir sonido de click
		if AudioManager:
			AudioManager.play_sfx(click_sound)
		
		# Emitir señal
		game_selected.emit(game_id)
		print("GameButton: Selected game '%s'" % game_id)
