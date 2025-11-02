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
