extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("desativar_seta_guia"):
			body.desativar_seta_guia()
	if Global.portais_ativos["Fase_espaco"] == false and Global.portais_ativos["Fase_plat"] == false and Global.portais_ativos["Fase_RPG"] == false:
		body.position = Vector2(-300.0, 2160.0)
	else:
		body.position = Vector2(112.0, 1065.0)
