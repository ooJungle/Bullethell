extends Area2D

func _on_body_entered(body: Node2D) -> void:
	body.position = Vector2(4939.0, -12.0)
	$"../Fase1/inimigo_4".visible = true
	$"../Fase1/inimigo_5".visible = true
	$"../Fase1/inimigo_9".visible = true
	$"../Fase1/inimigo_10".visible = true
	$"../Fase1/inimigo_11".visible = true
	$"../Fase1/inimigo_12".visible = true
	$"../Fase1/inimigo_13".visible = true
	$"../Fase1/inimigo_15".visible = true

func _on_portal_azul_body_entered(body: Node2D) -> void:
	queue_free()
	$"../Portal_azul".queue_free()
	var filhos_fase_1 = $"../Fase1".get_children()
	for filho in filhos_fase_1:
		filho.queue_free()
	$"../Fase1".queue_free()
	body.position = Vector2(112.0, 1065.0)
