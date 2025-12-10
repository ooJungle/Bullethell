extends CanvasLayer

@onready var coracoes = [
	$Control/coracao3, 
	$Control/coracao2, 
	$Control/coracao1  
]

func _ready():
	Global.vida_mudou.connect(atualizar_vidas)
	atualizar_vidas(Global.vida)
	
func _process(_delta):
	var cena_atual = get_tree().current_scene
	if cena_atual:
		if cena_atual.name == "MainMenu" or cena_atual.name == "PauseMenu" or cena_atual.name == "SettingsMenu" or cena_atual.name == "LostScene" or cena_atual.name == "WinScene":
			self.visible = false
		else:
			self.visible = true

func atualizar_vidas(vida_atual: int):
	# Loop para atualizar cada coração individualmente
	for i in range(coracoes.size()):
		var coracao = coracoes[i]
		var limite_inferior = i * 4
		var vida_neste_coracao = clamp(vida_atual - limite_inferior, 0, 4)
		coracao.frame = vida_neste_coracao
		coracao.modulate = Color(0.5 * vida_neste_coracao, 0.5 * vida_neste_coracao, 0.5 * vida_neste_coracao, 1)
