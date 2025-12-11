extends Area2D

@onready var som_portal: AudioStreamPlayer = $AudioStreamPlayer
@onready var vida_boss: Control = $"../CanvasLayer/vida_boss"


# Adicione uma export variável para a cena do boss
@export var boss_scene: PackedScene

func _ready() -> void:
	modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_body_entered(body: Node2D) -> void:
	som_portal.play()
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
		boss_instance.vida_mudou.connect(vida_boss.atualizar_coracao)
		vida_boss.visible = true
		get_parent().add_child(boss_instance)
		boss_instance.global_position = Vector2(35, 3000) 
		boss_instance.add_to_group("boss")
