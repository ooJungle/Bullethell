# Script: ponto_da_espiral.gd
extends Area2D

func _ready() -> void:
	# Conecta o seu próprio sinal de colisão
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("players"):
		# Assumimos que o jogador tem a função take_damage
		if body.has_method("take_damage"):
			body.take_damage(1)

	# O ponto individual desaparece ao colidir
	queue_free()

func _physics_process(delta: float) -> void:
	position = position.rotated(90*delta)
