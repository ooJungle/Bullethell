extends Area2D

func _on_body_entered(body: Node2D) -> void:
	body.position = Vector2(1716.0, 10.0)
	$"../Fase3/inimigo_1".visible = true
	$"../Fase3/inimigo_2".visible = true
	$"../Fase3/inimigo_polvo".visible = true
	$"../Fase3/inimigo_polvo2".visible = true
	$"../Fase3/inimigo_3".visible = true
	$"../Fase3/inimigo_polvo4".visible = true
	$"../Fase3/inimigo_polvo5".visible = true

func _on_portal_azul_3_body_entered(body: Node2D) -> void:
	queue_free()
	$"../Portal_azul3".queue_free()
	var filhos_fase_3 = $"../Fase3".get_children()
	for filho in filhos_fase_3:
		filho.queue_free()
	$"../Fase3".queue_free()
	body.position = Vector2(112.0, 1065.0)
