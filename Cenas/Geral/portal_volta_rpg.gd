extends Area2D

@export var id_desta_fase: String = "Fase_RPG"
@onready var som: AudioStreamPlayer = $som

func _ready():
	# Começa escondido e desativado por padrão
	desativar_portal()

func desativar_portal():
	visible = false
	monitoring = false
	# Se tiver colisão filha, desativa também para garantir
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)

func ativar_portal():
	print("PORTAL ATIVADO!") # Log para debug
	visible = true
	monitoring = true
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", false)
	
	# Opcional: Tocar som se tiver
	if has_node("SomAtivar"):
		$SomAtivar.play()

func _on_body_entered(body):
	if body.is_in_group("players"):
		body.pode_se_mexer = false
		som.play()
		Transicao.transition()
		await Transicao.on_transition_finished
		if Global.portais_ativos.has(id_desta_fase):
			Global.portais_ativos[id_desta_fase] = false
		
		call_deferred("voltar_para_hub")

func voltar_para_hub():
	# Ajuste o caminho da cena conforme seu projeto
	get_tree().change_scene_to_file("res://Cenas/Fases/Fase_0.tscn")
