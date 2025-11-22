extends StaticBody2D 
signal fui_quebrado

@export var vida_maxima = 30
var vida_atual = 0

func _ready():
	vida_atual = vida_maxima
	add_to_group("cristais")

func take_damage(amount: int) -> void:
	vida_atual -= amount

	modulate = Color(10, 10, 10)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if vida_atual <= 0:
		quebrar()

func quebrar():
	emit_signal("fui_quebrado")
	
	queue_free()
