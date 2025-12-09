extends Sprite2D

func _ready():
	ghosting()

func set_property(tx_pos, tx_scale):
	position = tx_pos
	scale = tx_scale
	
func ghosting():
	var tween_fade = get_tree().create_tween()
	
	tween_fade.tween_property(self, "self_modulate", Color(1.0, 1.0, 1.0, 0.0),0.75)
	
	await tween_fade.finished
	
	queue_free()

func fade_out():
	var tween = create_tween()

	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
	
	# Espera a animação terminar e então remove o nó da memória
	await tween.finished
	queue_free()
