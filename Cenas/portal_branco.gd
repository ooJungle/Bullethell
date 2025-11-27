extends Area2D

# Adicione uma export variável para a cena do boss
@export var boss_scene: PackedScene

func _on_body_entered(body: Node2D) -> void:
	body.pode_se_mexer = false
	if body.has_method("desativar_seta_guia"):
			body.desativar_seta_guia()
	if Global.portais_ativos["Fase_espaco"] == false and Global.portais_ativos["Fase_plat"] == false and Global.portais_ativos["Fase_RPG"] == false:
		Transicao.transition()
		await Transicao.on_transition_finished
		body.pode_se_mexer = true
		body.position = Vector2(35.0, 2770.0)
		spawn_boss()
	else:
		Transicao.transition()
		await Transicao.on_transition_finished
		body.pode_se_mexer = true
		body.position = Vector2(112.0, 1065.0)

func spawn_boss():
	# Só spawna o boss se ele não existir já
	if get_tree().get_nodes_in_group("boss").size() == 0:
		var boss_instance = boss_scene.instantiate()
		get_parent().add_child(boss_instance)
		boss_instance.global_position = Vector2(35, 3000) 
		boss_instance.add_to_group("boss")
