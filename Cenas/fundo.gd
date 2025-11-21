extends ColorRect
func _ready() -> void:	
	var fase_1_concluida = Global.portais_ativos["Fase_espaco"] == false
	var fase_2_concluida = Global.portais_ativos["Fase_plat"] == false
	var fase_3_concluida = Global.portais_ativos["Fase_RPG"] == false
	
	if fase_1_concluida or fase_2_concluida or fase_3_concluida:
		visible = false
	else:
		visible = true
