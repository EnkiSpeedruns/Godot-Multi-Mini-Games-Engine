class_name Coin
extends Area2D

## Coin - Moneda coleccionable

@export var points: int = 10
@export var collect_sound: AudioStream

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var collected: bool = false

func _ready() -> void:
	# Conectar señal de entrada de área
	body_entered.connect(_on_body_entered)
	
	# Reproducir animación idle
	if sprite:
		sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	
	# Verificar si es el player
	if body is Player:
		_collect(body)

func _collect(player: Player) -> void:
	collected = true
	
	# Desactivar colisión
	collision_shape.set_deferred("disabled", true)
	
	# Dar puntos
	var game_logic = get_tree().get_first_node_in_group("game_logic")
	if game_logic and game_logic.has_method("add_score"):
		game_logic.add_score(points)
	
	# Sonido
	if collect_sound:
		AudioManager.play_sfx(collect_sound)
	
	# Animación de recolección
	_play_collect_animation()
	
	print("[Coin] Collected by %s - Points: %d" % [player.name, points])

func _play_collect_animation() -> void:
	# Animación simple: fade + subir
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	
	# Subir
	tween.tween_property(self, "position:y", position.y - 30, 0.3)
	
	# Escala
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(sprite, "scale", Vector2(0, 0), 0.15).set_delay(0.15)
	
	await tween.finished
	queue_free()
