extends CanvasLayer

@onready var barra_carga: TextureProgressBar = $Control2/BarraCarga
@onready var coracoes = [
	$Control/coracao3,
	$Control/coracao2,
	$Control/coracao1
]

var tween_carga: Tween
# Nova variável para lembrar quem é o player atual
var player_conectado: Node = null 

func _ready():
	print("HUD: Iniciado.")
	if barra_carga:
		barra_carga.value = barra_carga.max_value
	
	for i in range(coracoes.size()):
		coracoes[i].modulate = Color(2.0, 2.0, 2.0, 1.0)
	
	# Tenta conectar logo de cara
	conectar_com_player()

func _process(_delta):
	atualizar_vidas(Global.vida)
	
	# --- VIGILÂNCIA DE CONEXÃO (A CORREÇÃO É AQUI) ---
	# Se a variável 'player_conectado' estiver vazia (null) ou o nó dela foi deletado (troca de cena)
	if not is_instance_valid(player_conectado):
		# Tenta encontrar o novo player que acabou de chegar na cena
		conectar_com_player()
	# -------------------------------------------------

	var cena_atual = get_tree().current_scene
	
	if cena_atual:
		if cena_atual.name in ["MainMenu", "PauseMenu", "SettingsMenu", "LostScene", "WinScene"]:
			self.visible = false
		else:
			self.visible = true
			
	if Dialogo.tutorial or Global.paused:
		self.visible = false

func conectar_com_player():
	# Busca alguém do grupo player
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		# Se achou o player, verifica se já estamos conectados a ELE ESPECIFICAMENTE
		if player != player_conectado:
			print("HUD: Novo Player detectado na troca de cena! Reconectando...")
			
			# Salva a referência para não buscar todo frame
			player_conectado = player
			
			# Desconecta do antigo se por acaso ainda existir (segurança)
			if player.dash_usado.is_connected(_on_player_dash_usado):
				player.dash_usado.disconnect(_on_player_dash_usado)
			
			# Conecta no novo
			player.dash_usado.connect(_on_player_dash_usado)
			
			# Garante que a barra comece cheia na nova fase
			if barra_carga: barra_carga.value = barra_carga.max_value

func atualizar_vidas(vida_atual: int):
	for i in range(coracoes.size()):
		var coracao = coracoes[i]
		var limite_inferior = i * 4
		var vida_neste_coracao = clamp(vida_atual - limite_inferior, 0, 4)
		coracao.frame = vida_neste_coracao
		coracao.modulate = Color(0.5 * vida_neste_coracao, 0.5 * vida_neste_coracao, 0.5 * vida_neste_coracao, 1)

func _on_player_dash_usado(tempo_recarga: float):
	if not barra_carga: return
	
	if tween_carga:
		tween_carga.kill()
	
	barra_carga.max_value = tempo_recarga
	barra_carga.value = 0.0 
	
	tween_carga = create_tween()
	tween_carga.tween_property(barra_carga, "value", tempo_recarga, tempo_recarga)
