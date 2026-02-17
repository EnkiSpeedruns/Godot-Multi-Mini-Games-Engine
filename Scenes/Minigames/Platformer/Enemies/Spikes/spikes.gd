class_name Spikes
extends StaticBody2D

## Spikes - Enemigo estático e indestructible que solo daña

@export var contact_damage: int = 1

@onready var hitbox: HitboxComponent = $Hitbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Configurar hitbox
	if hitbox:
		hitbox.damage = contact_damage
		hitbox.activate()
	
	sprite.play("default")
	print("[Spikes] Ready at %s" % global_position)
