extends ColorRect

func _ready() -> void:
	var p1_ativo = Global.portais_ativos["Fase_espaco"]
	var p2_ativo = Global.portais_ativos["Fase_plat"]
	var p3_ativo = Global.portais_ativos["Fase_RPG"]
	
	if p1_ativo and p2_ativo and p3_ativo:
		visible = true
		print("com fundo")
	else:
		visible = false
		print("sem fundo")
	print("ESTADO DOS PORTAIS: ", p1_ativo, " | ", p2_ativo, " | ", p3_ativo)
