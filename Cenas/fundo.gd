extends ColorRect
func _ready() -> void:	
	var fase_1_concluida = Global.portais_ativos["Fase_espaco"]
	var fase_2_concluida = Global.portais_ativos["Fase_plat"]
	var fase_3_concluida = Global.portais_ativos["Fase_RPG"]
	
	if not(fase_1_concluida and fase_2_concluida and fase_3_concluida):
		visible = false
	else:
		visible = true
