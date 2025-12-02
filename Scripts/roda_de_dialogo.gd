extends Node2D

func _ready():
	if has_node("RodaVisual"):
		$RodaVisual.abertura = 0.0
		
		var tween = create_tween()
		tween.tween_property($RodaVisual, "abertura", 1.0, 1.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_player_morreu():
	RodaManager.fechar_roda("perdeu")

func _on_opcao_certa_selecionada():
	RodaManager.fechar_roda("venceu")
