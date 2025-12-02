extends StaticBody2D 
signal fui_quebrado

@export var vida_maxima = 100
var vida_atual = 0

var tween_dano: Tween

func _ready():
	vida_atual = vida_maxima
	add_to_group("cristais")

func take_damage(amount: int) -> void:
	vida_atual -= amount

	if tween_dano:
		tween_dano.kill()
	modulate = Color(2.5, 2.5, 2.5) 
	tween_dano = create_tween()
	tween_dano.tween_property(self, "modulate", Color.WHITE, 0.15).set_trans(Tween.TRANS_SINE)
	
	if vida_atual <= 0:
		quebrar()

func quebrar():
	emit_signal("fui_quebrado")
	queue_free()
