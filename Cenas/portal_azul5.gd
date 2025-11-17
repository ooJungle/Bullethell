extends Area2D

func _on_body_entered(body: Node2D) -> void:
	body.position = Vector2(3330.0, -14.0)
	$"../Fase2/buraco_negro".visible = true
	$"../Fase2/buraco_de_mihoca".visible = true
	$"../Fase2/buraco_de_mihoca2".visible = true
	$"../Fase2/Inimigo laser".visible = true
	$"../Fase2/Inimigo laser2".visible = true
	$"../Fase2/Inimigo laser3".visible = true
	$"../Fase2/Inimigo laser4".visible = true
	$"../Fase2/Inimigo laser5".visible = true
	$"../Fase2/Inimigo laser6".visible = true
	$"../Fase2/BlasterSpawner".visible = true
	$"../Fase2/BattleManager".visible = true

func _on_portal_azul_2_body_entered(body: Node2D) -> void:
	$"../Fase2/BlasterSpawner".visible = false
	$"../Fase2/BattleManager".visible = false
	queue_free()
	$"../Portal_azul2".queue_free()
	var filhos_fase_2 = $"../Fase2".get_children()
	for filho in filhos_fase_2:
		filho.queue_free()
	$"../Fase2".queue_free()
	body.position = Vector2(112.0, 1065.0)
