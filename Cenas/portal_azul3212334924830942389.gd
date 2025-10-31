extends Area2D

func _on_body_entered(body: Node2D) -> void:
	body.position = Vector2(4939.0, -12.0)
	$"../inimigo_4".visible = true
	$"../inimigo_5".visible = true
	$"../inimigo_9".visible = true
	$"../inimigo_10".visible = true
	$"../inimigo_11".visible = true
	$"../inimigo_12".visible = true
	$"../inimigo_13".visible = true
	$"../inimigo_15".visible = true
