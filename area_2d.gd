extends Area2D

func _on_body_entered(body: Node2D) -> void:
	print("Colidiu com: ", body.name)
	if body.name == "player":
		if Global.vida < 12:
			body.vida += 1
			Global.vida += 1
			Global.atualizar_hud_vida(Global.vida)
			queue_free()
