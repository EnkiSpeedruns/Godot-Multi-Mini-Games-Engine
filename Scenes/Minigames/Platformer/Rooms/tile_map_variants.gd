class_name TileMapVariant
extends Node2D

## TileMapVariant - Contenedor de variantes de TileMap
##
## Cada room puede tener múltiples layouts de TileMap.
## El sistema elige uno al azar cuando se inicializa el room.

# Señales
signal variant_selected(variant_index: int)

# Configuración
@export_group("Variant Selection")
@export var selection_mode: SelectionMode = SelectionMode.RANDOM

enum SelectionMode {
	RANDOM,          # Totalmente aleatorio
	SEQUENTIAL,      # Va rotando (1, 2, 3, 1, 2, 3...)
	WEIGHTED_RANDOM  # Random pero con pesos
}

@export_group("Weighted Random (solo si selection_mode = WEIGHTED_RANDOM)")
## Pesos para cada variante (el índice corresponde al hijo)
## Ejemplo: [1.0, 2.0, 1.0] = segunda variante tiene el doble de chance
@export var variant_weights: Array[float] = []

# Estado
var active_variant: TileMapLayer = null
var active_variant_index: int = -1
var last_used_index: int = -1  # Para modo SEQUENTIAL

func _ready() -> void:
	# No hacer nada en _ready, esperar a que el room llame a select_variant()
	pass

func select_variant() -> TileMapLayer:
	"""
	Selecciona y activa una variante de TileMap.
	Retorna el TileMapLayer seleccionado.
	"""
	var variants = _get_all_variants()
	
	if variants.is_empty():
		push_error("[TileMapVariant] No TileMapLayer children found!")
		return null
	
	# Si solo hay una variante, no hay que elegir
	if variants.size() == 1:
		return _activate_variant(0)
	
	# Elegir variante según modo
	var selected_index: int
	
	match selection_mode:
		SelectionMode.RANDOM:
			selected_index = randi() % variants.size()
		
		SelectionMode.SEQUENTIAL:
			selected_index = (last_used_index + 1) % variants.size()
			last_used_index = selected_index
		
		SelectionMode.WEIGHTED_RANDOM:
			selected_index = _select_weighted_random(variants.size())
	
	return _activate_variant(selected_index)

func _get_all_variants() -> Array[TileMapLayer]:
	"""Retorna todos los TileMapLayer hijos"""
	var variants: Array[TileMapLayer] = []
	
	for child in get_children():
		if child is TileMapLayer:
			variants.append(child)
	
	return variants

func _activate_variant(index: int) -> TileMapLayer:
	"""
	Desactiva todas las variantes excepto la seleccionada.
	"""
	var variants = _get_all_variants()
	
	if index < 0 or index >= variants.size():
		push_error("[TileMapVariant] Invalid index: %d" % index)
		return null
	
	# Desactivar todas
	for i in range(variants.size()):
		var variant = variants[i]
		variant.visible = (i == index)
		variant.set_process(i == index)
		
		# Importante: desactivar colisiones de las variantes no activas
		if i != index:
			variant.collision_enabled = false
		else:
			variant.collision_enabled = true
	
	active_variant = variants[index]
	active_variant_index = index
	
	variant_selected.emit(index)
	
	print("[TileMapVariant] Activated variant %d/%d" % [index + 1, variants.size()])
	
	return active_variant

func _select_weighted_random(variant_count: int) -> int:
	"""
	Selección aleatoria ponderada.
	Si no hay pesos configurados, usa random normal.
	"""
	# Si no hay pesos o no coinciden, usar random normal
	if variant_weights.is_empty() or variant_weights.size() != variant_count:
		push_warning("[TileMapVariant] Weights not configured properly, using random")
		return randi() % variant_count
	
	# Calcular suma total de pesos
	var total_weight = 0.0
	for weight in variant_weights:
		total_weight += weight
	
	# Generar número random
	var random_value = randf() * total_weight
	
	# Encontrar qué variante corresponde
	var cumulative = 0.0
	for i in range(variant_count):
		cumulative += variant_weights[i]
		if random_value <= cumulative:
			return i
	
	# Fallback (no debería llegar aquí)
	return variant_count - 1

func get_active_variant() -> TileMapLayer:
	"""Retorna la variante actualmente activa"""
	return active_variant

func get_active_variant_index() -> int:
	"""Retorna el índice de la variante activa"""
	return active_variant_index

func get_variant_count() -> int:
	"""Retorna cuántas variantes hay disponibles"""
	return _get_all_variants().size()
