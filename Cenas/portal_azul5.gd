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
