extends Area2D

func _on_body_entered(body: Node2D) -> void:
	body.position = Vector2(3330.0, -14.0)
	$"../buraco_negro".visible = true
	$"../buraco_de_mihoca".visible = true
	$"../Inimigo laser".visible = true
	$"../Inimigo laser2".visible = true
	$"../Inimigo laser3".visible = true
	$"../Inimigo laser4".visible = true
	$"../Inimigo laser5".visible = true
	$"../Inimigo laser6".visible = true
