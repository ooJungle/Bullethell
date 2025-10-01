# Script: ponto_da_espiral.gd
extends Area2D
var velocidade: Vector2 = Vector2.ZERO
func _ready() -> void:
	# Conecta o seu próprio sinal de colisão
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		Global.vida -= 1
		Global.Tomou_ano()
		queue_free()

func _physics_process(delta: float) -> void:
	position = position.rotated(9*delta*Global.fator_tempo)
	position += velocidade * delta *  Global.fator_tempo
