extends CharacterBody2D

# --- REFERÊNCIAS AOS FILHOS (CÉREBROS DE MOVIMENTO) ---
@onready var move_topdown: Node = $MovementTopDown
@onready var move_platform: Node = $MovementPlatform

var componente_ativo: Node = null
var tempo = 0.0
# --- REFERÊNCIAS VISUAIS ---
@onready var sprite: AnimatedSprite2D = $sprite 
@onready var som_ataque: AudioStreamPlayer = $AudioStreamPlayer
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_colisao: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var barra_carga: TextureProgressBar = $BarraCarga
@onready var dano_timer: Timer = $dano_timer

# --- VARIÁVEIS DE ESTADO ---
var vida_maxima: int = 300
var vida: int = vida_maxima
var atacando: bool = false
var pode_atacar: bool = true
var tem_arma: bool = true
var esta_carregando: bool = false
var carga_atual: float = 0.0

# --- A PONTE (Controle de permissão de movimento) ---
var pode_se_mexer: bool:
	set(valor):
		if componente_ativo and "pode_se_mexer" in componente_ativo:
			componente_ativo.pode_se_mexer = valor
	get:
		if componente_ativo and "pode_se_mexer" in componente_ativo:
			return componente_ativo.pode_se_mexer
		return true

#bill de invencivel
var invencivel: bool = false
@export var tempo_invencibilidade: float = 0.5

# --- CONFIGURAÇÕES ---
@export var dano_do_player: int = 10
@export var tempo_para_carregar: float = 1.5
@export var raio_max_dilatacao: float = 500.0
@export var fator_tempo_maximo: float = 3.0
@export var raio_max_aceleracao: float = 500.0
@export var fator_tempo_minimo: float = 0.2

var buraco_negro_proximo: Node2D = null
var buraco_minhoca_proximo: Node2D = null

const SWORD_BEAM_SCENE = preload("res://Cenas/Projeteis/sword_beam.tscn")

# --- GUIAS ---
@onready var seta_pivo: Node2D = $SetaPivo
var alvo_seta: Vector2 = Vector2.ZERO
var offset_visual_seta: Vector2 = Vector2(0, -8)
@onready var transparente: bool = true
@onready var ativo: bool = true
@onready var particula: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	vida = vida_maxima
	Global.vida = vida
	hitbox_colisao.disabled = true
	
	if barra_carga:
		barra_carga.visible = false
		barra_carga.max_value = tempo_para_carregar
		barra_carga.value = 0
		
	if seta_pivo:
		seta_pivo.top_level = true
		seta_pivo.visible = false

	# --- BLOQUEIO NUCLEAR ---
	move_topdown.set_process(false)
	move_topdown.set_physics_process(false)
	move_topdown.set_process_input(false)
	
	move_platform.set_process(false)
	move_platform.set_physics_process(false)
	move_platform.set_process_input(false)

	# Conexão segura do sinal de animação
	if sprite.animation_finished.is_connected(_on_sprite_animation_finished):
		sprite.animation_finished.disconnect(_on_sprite_animation_finished)
	sprite.animation_finished.connect(_on_sprite_animation_finished)

	atualizar_modo_de_jogo()
	
	print("--- DEBUG DE NÓS ---")
	print("Script no TopDown: ", $MovementTopDown.get_script().resource_path)
	print("Script no Platform: ", $MovementPlatform.get_script().resource_path)
	print("--------------------")

func _process(_delta: float) -> void:
	if transparente:
		get_tree().get_root().set_transparent_background(true)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true, 0)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true, 0)
		ativo = false
		transparente = false

	if seta_pivo and seta_pivo.visible:
		seta_pivo.global_position = global_position + offset_visual_seta
		seta_pivo.look_at(alvo_seta)

func _physics_process(delta: float) -> void:
	tempo = delta
	if Dialogo.is_active:
		particula.emitting = false
		velocity = Vector2(0,0)
		var dir = Vector2.DOWN
		if "last_move_direction" in move_topdown:
			dir = move_topdown.last_move_direction
		
		if dir.y < 0:
			tocar_anim("idle_costas")
			sprite.flip_h = (dir.x > 0)
		elif dir.y > 0:
			tocar_anim("idle_frente")
		else:
			tocar_anim("idle_lado")
	if Global.paused: return

	atualizar_modo_de_jogo()

	# --- 1. BLOQUEIO DE ATAQUE (Prioridade Máxima) ---
	if atacando:
		self.pode_se_mexer = false 
		velocity = Vector2.ZERO
		move_and_slide()
		return 

	# --- 2. BLOQUEIO EXTERNO (Portal/Cutscene) ---
	# Se não estiver atacando, mas "pode_se_mexer" for false (ex: portal setou isso)
	# Congelamos o player e tocamos a animação idle correta.
	if not self.pode_se_mexer:
		
		velocity = Vector2.ZERO
		move_and_slide()
		tocar_idle_forcado() # Nova função auxiliar
		return

	# --- 3. SE PUDER SE MEXER ---
	# (Removi a linha 'self.pode_se_mexer = true' que estava aqui forçando o movimento)

	processar_ataque_carregado(delta)

	if Global.plataforma:
		move_platform.handle_movement(delta)
		if not atacando:
			atualizar_animacao_plataforma()
	else:
		atualizar_fator_tempo()
		var forca_externa = calcular_forcas_externas()
		move_topdown.handle_movement(delta, forca_externa)
		if not atacando:
			atualizar_animacao_topdown()

	global_position = global_position.round()
	atualizar_particulas_poeira()

func atualizar_particulas_poeira():
	var esta_se_movendo = velocity.length() > 10 
	if particula.emitting != esta_se_movendo:
		particula.emitting = esta_se_movendo

func atualizar_modo_de_jogo():
	if Global.plataforma:
		if componente_ativo != move_platform:
			componente_ativo = move_platform
	else:
		if componente_ativo != move_topdown:
			componente_ativo = move_topdown

# --- GERENCIADOR DE ANIMAÇÕES ---

# Função nova para tocar Idle na direção certa quando travado
func tocar_idle_forcado():
	if Global.plataforma:
		tocar_anim("idle_lado")
	else:
		var dir = Vector2.DOWN
		if "last_move_direction" in move_topdown:
			dir = move_topdown.last_move_direction
		
		if dir.y < 0:
			tocar_anim("idle_costas")
		elif dir.y > 0:
			tocar_anim("idle_frente")
		else:
			tocar_anim("idle_lado")

func atualizar_animacao_plataforma():
	if not self.pode_se_mexer: return

	if abs(velocity.x) > 10:
		sprite.flip_h = velocity.x > 0
		if is_on_floor(): 
			tocar_anim("run")
	elif is_on_floor():
		tocar_anim("idle_lado") 
			
	if not is_on_floor():
		if velocity.y < 0: tocar_anim("jump_up")
		else: tocar_anim("jump_down")

func atualizar_animacao_topdown():
	if not self.pode_se_mexer: return

	var dir = Vector2.DOWN
	if "last_move_direction" in move_topdown:
		dir = move_topdown.last_move_direction
	
	if velocity.length() > 10:
		if dir.x != 0:
			tocar_anim("andando_lado")
			sprite.flip_h = (dir.x > 0)
		elif dir.y < 0:
			sprite.flip_h = false
			tocar_anim("andando_costas")
		elif dir.y > 0:
			sprite.flip_h = false
			tocar_anim("andando_frente")
	else:
		if dir.x != 0:
			tocar_anim("idle_lado")
			sprite.flip_h = (dir.x > 0)
		elif dir.y < 0:
			sprite.flip_h = false
			tocar_anim("idle_costas")
		else:
			sprite.flip_h = false
			tocar_anim("idle_frente")

func tocar_anim(nome: String):
	if nome == "idle_frente" or nome == "idle_costas" or nome == "idle_lado":
		if sprite.speed_scale >= 0.45:
			sprite.speed_scale -= 0.05 * tempo
	if atacando: return 
	
	if sprite.sprite_frames.has_animation(nome):
		if sprite.animation != nome:
			sprite.speed_scale = 1.0
			sprite.play(nome)
	if not pode_se_mexer: sprite.play("ataque_lado")
# --- COMBATE ---

func iniciar_ataque(com_projetil: bool):
	print("--- DEBUG ATAQUE ---")
	
	atacando = true
	pode_atacar = false
	self.pode_se_mexer = false # Garante travamento
	hitbox_colisao.disabled = false
	
	var dir_ataque = Vector2.RIGHT
	if componente_ativo and "last_move_direction" in componente_ativo:
		dir_ataque = componente_ativo.last_move_direction
	elif Global.plataforma:
		dir_ataque = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	
	if dir_ataque == Vector2.ZERO: dir_ataque = Vector2.RIGHT 

	posicionar_hitbox(dir_ataque)
	if com_projetil: lancar_projetil(dir_ataque)

	var anim_name = "ataque_lado"
	var deve_flipar = false

	if Global.plataforma:
		anim_name = "ataque_lado"
		deve_flipar = (dir_ataque.x > 0)
	else:
		if abs(dir_ataque.x) > abs(dir_ataque.y):
			anim_name = "ataque_lado"
			deve_flipar = (dir_ataque.x > 0)
		else:
			if dir_ataque.y < 0: anim_name = "ataque_costas"
			else: anim_name = "ataque_frente"

	print("Tentando tocar animação: ", anim_name)

	sprite.stop()
	sprite.frame = 0
	sprite.flip_h = deve_flipar
	
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
		print("SUCESSO: Tocando ", anim_name)
	else:
		print("ERRO: '", anim_name, "' não existe. Usando 'ataque_lado'.")
		sprite.play("ataque_lado")

	som_ataque.pitch_scale = randf_range(0.5, 2.0)
	som_ataque.play()
	verificar_dano_nos_inimigos()
	
	get_tree().create_timer(0.6).timeout.connect(func():
		if atacando: 
			print("Timer de segurança destravou o player.")
			_on_sprite_animation_finished_force()
	)

func _on_sprite_animation_finished():
	if sprite.animation in ["ataque_frente", "ataque_costas", "ataque_lado"]:
		finalizar_ataque_logica()

func _on_sprite_animation_finished_force():
	finalizar_ataque_logica()

func finalizar_ataque_logica():
	atacando = false
	pode_atacar = true
	hitbox_colisao.disabled = true
	
	# RESTAURA O MOVIMENTO
	# Necessário porque removemos o reset automático do _physics_process
	self.pode_se_mexer = true 

# --- CARGA, PROJÉTIL, DANO ---

func processar_ataque_carregado(delta: float):
	# Agora verifica self.pode_se_mexer corretamente
	if Input.is_action_pressed("attack") and pode_atacar and tem_arma and self.pode_se_mexer:
		esta_carregando = true
		if barra_carga: barra_carga.visible = true
		carga_atual += delta
		if carga_atual > tempo_para_carregar:
			carga_atual = tempo_para_carregar
			if barra_carga: barra_carga.modulate = Color(1, 0.2, 0.2)
		if barra_carga: barra_carga.value = carga_atual
	elif Input.is_action_just_released("attack"):
		if esta_carregando:
			if carga_atual >= tempo_para_carregar: iniciar_ataque(true)
			else: iniciar_ataque(false)
		resetar_carga()
	elif not Input.is_action_pressed("attack") and esta_carregando:
		resetar_carga()

func resetar_carga():
	esta_carregando = false
	carga_atual = 0.0
	if barra_carga:
		barra_carga.value = 0.0
		barra_carga.visible = false
		barra_carga.modulate = Color.WHITE

func resetar_combate():
	finalizar_ataque_logica()
	resetar_carga()

func lancar_projetil(dir: Vector2):
	var beam = SWORD_BEAM_SCENE.instantiate()
	var offset = dir * 20.0
	beam.global_position = global_position + offset + Vector2(0, -15)
	beam.direction = dir
	beam.rotation = dir.angle()
	get_tree().current_scene.add_child(beam)

func posicionar_hitbox(dir: Vector2):
	if dir.y < 0:
		hitbox.position = Vector2(11.5, -10)
		hitbox.rotation_degrees = -90
	elif dir.y > 0:
		hitbox.position = Vector2(-11.5, -5)
		hitbox.rotation_degrees = 90
	elif dir.x > 0:
		hitbox.position = Vector2(0, 0)
		hitbox.rotation_degrees = 0
	elif dir.x < 0:
		hitbox.position = Vector2(0, -23)
		hitbox.rotation_degrees = 180

func verificar_dano_nos_inimigos():
	await get_tree().physics_frame
	await get_tree().physics_frame
	var corpos = hitbox.get_overlapping_bodies()
	for corpo in corpos:
		if (corpo.is_in_group("inimigo") or corpo.is_in_group("cristais") or corpo.is_in_group("boss")) and corpo.has_method("take_damage"):
			corpo.take_damage(dano_do_player)
			if corpo.is_in_group("inimigo") and "velocity" in corpo:
				var direcao_empurrao = (corpo.global_position - global_position).normalized()
				corpo.velocity += direcao_empurrao * 300

func take_damage(amount: int) -> void:
	if invencivel: 
		return
	var is_dashing = false
	if componente_ativo and "is_dashing" in componente_ativo:
		is_dashing = componente_ativo.is_dashing
	if not is_dashing:
		vida -= amount
		Global.vida = vida
		dano()
		ficar_invencivel()
		if vida <= 0: die()
		
func ficar_invencivel():
	invencivel = true
	var tween = create_tween()
	tween.set_loops() # repete infinito
	
	# Anima a opacidade para 0.2 (quase invisível) em 0.1 segundos
	tween.tween_property(sprite, "modulate:a", 0.2, 0.1)
	# Anima a opacidade para 1.0 (visível) em 0.1 segundos
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	
	await get_tree().create_timer(tempo_invencibilidade).timeout
	if is_instance_valid(tween):
		tween.kill()
	sprite.modulate.a = 1.0
	invencivel = false
	
func die() -> void:
	get_tree().change_scene_to_file("res://Cenas/Menu/LostScene.tscn")

func dano():
	sprite.modulate = Color(1.0, 0.325, 0.349)
	dano_timer.start(0.3)

func _on_dano_timer_timeout() -> void:
	sprite.modulate = Color(1.0, 1.0, 1.0)
	
func ativar_seta_guia(pos):
	alvo_seta = pos
	if seta_pivo: seta_pivo.visible = true

func desativar_seta_guia():
	if seta_pivo: seta_pivo.visible = false

# --- CALCULO BURACOS NEGROS ---
func calcular_forcas_externas() -> Vector2:
	var in_bn = is_instance_valid(buraco_negro_proximo) and global_position.distance_to(buraco_negro_proximo.global_position) < buraco_negro_proximo.raio_maximo
	var in_wh = is_instance_valid(buraco_minhoca_proximo) and global_position.distance_to(buraco_minhoca_proximo.global_position) < buraco_minhoca_proximo.raio_maximo
	if in_bn and in_wh: return Vector2.ZERO
	var total = Vector2.ZERO
	if in_bn:
		var dist = global_position.distance_to(buraco_negro_proximo.global_position)
		if dist > 1.0:
			total += (buraco_negro_proximo.global_position - global_position).normalized() * (buraco_negro_proximo.forca_gravidade / max(sqrt(dist), 20))
	if in_wh:
		var dist = global_position.distance_to(buraco_minhoca_proximo.global_position)
		if dist > 1.0:
			total += (global_position - buraco_minhoca_proximo.global_position).normalized() * (buraco_minhoca_proximo.forca_repulsao_campo / max(sqrt(dist), 20))
	return total

func atualizar_fator_tempo():
	buraco_negro_proximo = encontrar_corpo_celeste_mais_proximo("buracos_negros")
	buraco_minhoca_proximo = encontrar_corpo_celeste_mais_proximo("buracos_minhoca")
	var ef_bn = 1.0
	var ef_wh = 1.0
	if is_instance_valid(buraco_negro_proximo):
		var dist = global_position.distance_to(buraco_negro_proximo.global_position)
		if dist < raio_max_dilatacao: ef_bn = remap(dist, 0, raio_max_dilatacao, fator_tempo_maximo, 1.0)
	if is_instance_valid(buraco_minhoca_proximo):
		var dist = global_position.distance_to(buraco_minhoca_proximo.global_position)
		if dist < raio_max_aceleracao: ef_wh = remap(dist, 0, raio_max_aceleracao, fator_tempo_minimo, 1.0)
	Global.fator_tempo = max(0.001, ef_bn + ef_wh - 1.0)

func encontrar_corpo_celeste_mais_proximo(grupo: String) -> Node2D:
	var nos = get_tree().get_nodes_in_group(grupo)
	var mais_prox = null
	var min_dist = INF
	for no in nos:
		var dist = global_position.distance_squared_to(no.global_position)
		if dist < min_dist:
			min_dist = dist
			mais_prox = no
	return mais_prox

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel") and not Global.paused:
		get_node("%PauseMenu").start_pause()
