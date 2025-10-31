extends Area2D

func _on_body_entered(body: Node2D) -> void:
	body.position = Vector2(1716.0, 10.0)
	$"../inimigo_1".visible = true
	$"../inimigo_polvo".visible = true
	$"../inimigo_polvo2".visible = true
	$"../inimigo_3".visible = true
	$"../inimigo_polvo4".visible = true
	$"../inimigo_polvo5".visible = true
