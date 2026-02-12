class_name GameButton
extends PanelContainer

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

func _ready() -> void:
	_update_display()
	if is_locked:
		_set_locked_state()

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

func _on_click_button_pressed() -> void:
	if not is_locked:
		game_selected.emit(game_id)
		print("GameButton: Selected game '%s'" % game_id)
