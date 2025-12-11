extends Control

# Referência ao coração animado (ajuste o caminho se necessário)
@onready var coracao_anim: AnimatedSprite2D = $coracao_boss
var vida_maxima = 550

func _ready():
	# Começa invisível até o Boss aparecer (opcional)
	visible = false 

# Esta função será chamada pelo SINAL do Boss
func atualizar_coracao(vida_atual: int):
	# Mostra a HUD se estiver escondida
	if not visible: 
		visible = true
		
	coracao_anim.play("pulsar")
	# --- 1. LÓGICA DE COR (Escurecer) ---
	var porcentagem = float(vida_atual) / vida_maxima
	porcentagem = max(porcentagem, 0.3) # Não deixa ficar totalmente preto
	var tween = create_tween()
	tween.tween_property(coracao_anim, "modulate", Color(porcentagem, porcentagem, porcentagem), 0.2)
	# --- 2. LÓGICA DE VELOCIDADE (Acelerar) ---
	if porcentagem <= 0.6 and porcentagem > 0.3: coracao_anim.speed_scale = 1.8
	elif porcentagem <= 0.3: coracao_anim.speed_scale = 3.0
	elif vida_atual <= 0: 
		# Esconde quando morre
		visible = false
