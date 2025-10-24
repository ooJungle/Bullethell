# Script: ponto_da_espiral.gd
extends Area2D

func _ready() -> void:
	# Conecta o seu próprio sinal de colisão
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		queue_free()

func _physics_process(delta: float) -> void:
	position = position.rotated(9*delta*Global.fator_tempo)
