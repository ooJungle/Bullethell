extends Area2D

func _on_body_entered(body: Node2D) -> void:
	body.position = Vector2(112.0, 1065.0)

func _on_portal_azul_body_entered(body: Node2D) -> void:
	queue_free()
	$"../Portal_azul6".queue_free()
	var filhos_fase_1 = $"../Fase1".get_children()
	for filho in filhos_fase_1:
		filho.queue_free()
	$"../Fase1".queue_free()

func _on_portal_azul_2_body_entered(body: Node2D) -> void:
	$"../Fase2/BlasterSpawner".visible = false
	$"../Fase2/BattleManager".visible = false
	queue_free()
	$"../Portal_azul5".queue_free()
	var filhos_fase_2 = $"../Fase2".get_children()
	for filho in filhos_fase_2:
		filho.queue_free()
	$"../Fase2".queue_free()

func _on_portal_azul_3_body_entered(body: Node2D) -> void:
	queue_free()
	$"../Portal_azul4".queue_free()
	var filhos_fase_3 = $"../Fase3".get_children()
	for filho in filhos_fase_3:
		filho.queue_free()
	$"../Fase3".queue_free()
