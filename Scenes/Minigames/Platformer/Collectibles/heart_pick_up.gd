class_name HeartPickup
extends Area2D

## HeartPickup - Corazón que cura 1 HP

@export var heal_amount: int = 1
@export var collect_sound: AudioStream

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if sprite:
		sprite.play("idle")

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	
	if body is Player:
		_collect(body)

func _collect(player: Player) -> void:
	# Solo curar si no está a vida máxima
	if player.health_component.current_health >= player.health_component.max_health:
		print("[HeartPickup] Player already at max health")
		return
	
	collected = true
	
	collision_shape.set_deferred("disabled", true)
	
	# Curar
	player.heal(heal_amount)
	
	# Sonido
	if collect_sound:
		AudioManager.play_sfx(collect_sound)
	
	# Animación
	_play_collect_animation()
	
	print("[HeartPickup] Collected - Healed %d HP" % heal_amount)

func _play_collect_animation() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "position:y", position.y - 40, 0.3)
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.15)
	
	await tween.finished
	queue_free()
