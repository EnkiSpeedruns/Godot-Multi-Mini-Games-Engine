extends CanvasLayer

## HUD - Interfaz de usuario del platformer

@export var heart_full_texture: Texture2D
@export var heart_empty_texture: Texture2D

@onready var hearts_container: HBoxContainer = $MarginContainer/VBoxContainer/HeartsContainer
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel

var max_hearts: int = 3
var current_hearts: int = 3

func _ready() -> void:
	_setup_hearts()
	update_score(0)

func _setup_hearts() -> void:
	# Limpiar corazones existentes
	for child in hearts_container.get_children():
		child.queue_free()
	
	# Crear corazones
	for i in range(max_hearts):
		var heart = TextureRect.new()
		heart.texture = heart_full_texture if heart_full_texture else null
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(32, 32)
		hearts_container.add_child(heart)

func update_health(current_hp: int, max_hp: int) -> void:
	max_hearts = max_hp
	current_hearts = current_hp
	
	# Actualizar visual de corazones
	var hearts = hearts_container.get_children()
	for i in range(hearts.size()):
		if i < current_hearts:
			hearts[i].texture = heart_full_texture
		else:
			hearts[i].texture = heart_empty_texture

func update_score(score: int) -> void:
	score_label.text = "Score: %d" % score
