extends CharacterBody2D

@export var velocidade = 100.0

@export var player: CharacterBody2D
@export_group("Timers do Ataque")
@export var duracaoMira: float = 2.0
@export var ducacaoLock: float = 0.5
@export var duracaoTiro: float = 1.0
@export var tiroCooldown: float = 5

@export_group("Cristal - Refração Config")
@export var quantidade_mini_lasers: int = 3
@export var dano_mini_laser: int = 20 
@export_range(0, 90) var abertura_leque: float = 45.0 
@export_range(0, 30) var grau_de_tortura: float = 15.0 

@export_group("Cristal - Refração Visual")
@export var scale_mini_largura: float = 0.3 
@export var comprimento_mini_px: float = 250.0 
@export var distancia_saida_borda: float = 20.0 

var reflexoes_ativas: Array = [] 
var escala_original_laser_x: float = 1.0 
var posicao_original_laser_x: float = 0.0
var textura_luz_impacto: Texture2D 

@export var tempo_vida_maximo: float = 30.0 
var tempo_vida_atual: float = 0.0

@onready var sprite: Sprite2D = $Inimigo
@onready var fire_point: Node2D = $FirePoint
@onready var linha: Line2D = $FirePoint/linha
@onready var linha_2: Line2D = $FirePoint/linha2
@onready var laserbeam: Sprite2D = $FirePoint/Laserbeam
@onready var ray_cast_2d: RayCast2D = $FirePoint/RayCast2D
@onready var collision_area: Area2D = $CollisionArea
@onready var audio_stream_player_2d: AudioStreamPlayer = $AudioStreamPlayer2D
@onready var impact_light: Sprite2D = $FirePoint/ImpactLight 
@onready var prep_laser: AudioStreamPlayer = $prep_laser

enum Estado { IDLE, MIRANDO, LOCKADO, ATIRANDO, COOLDOWN }
var estadoAtual = Estado.IDLE
var state_timer: float = 0.0
var locked_angle: float = 0.0
var alvo_atingido_neste_tiro: bool = false

var knockback = false
var tempo_knockback_atual = 0.0
@export var forca_knockback = 600.0

func _ready() -> void:
	add_to_group("inimigo")
	player = get_node_or_null("/root/Node2D/player")
	if not player:
		player = get_node_or_null("/root/fase_teste/player")
	
	ray_cast_2d.enabled = false
	
	if laserbeam:
		escala_original_laser_x = laserbeam.scale.x 
		posicao_original_laser_x = laserbeam.position.x
	
	if impact_light:
		impact_light.visible = false
		if impact_light.texture:
			textura_luz_impacto = impact_light.texture
	
	mudar_para_estado(Estado.COOLDOWN)

func _physics_process(delta: float) -> void:
	if Global.paused or !visible: return
	
	tempo_vida_atual += delta * Global.fator_tempo
	if tempo_vida_atual >= tempo_vida_maximo:
		queue_free()
		return
		
	if knockback:
		tempo_knockback_atual += delta
		if tempo_knockback_atual >= 0.3:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)
		move_and_slide()
		return

	if is_instance_valid(player):
		if estadoAtual in [Estado.IDLE, Estado.COOLDOWN, Estado.MIRANDO]:
			var direction_to_player = (player.global_position - global_position).normalized()
			sprite.rotation = direction_to_player.angle() + PI / 2

	if is_instance_valid(player) and estadoAtual in [Estado.IDLE, Estado.COOLDOWN]:
		var direcao = (player.global_position - global_position).normalized()
		velocity = direcao * velocidade * Global.fator_tempo
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0 * Global.fator_tempo)
	move_and_slide()

func _process(delta: float) -> void:
	if Global.paused or !visible: return
	match estadoAtual:
		Estado.IDLE: pass
		Estado.MIRANDO: modo_mira(delta)
		Estado.LOCKADO: modo_lockado(delta)
		Estado.ATIRANDO: modo_atirando(delta)
		Estado.COOLDOWN: modo_cooldown(delta)

func mudar_para_estado(novoEstado: Estado):
	limpar_reflexoes()
	
	estadoAtual = novoEstado
	linha.visible = false
	linha_2.visible = false
	laserbeam.visible = false
	ray_cast_2d.enabled = false 
	if impact_light: impact_light.visible = false
	
	laserbeam.scale.x = escala_original_laser_x 
	laserbeam.position.x = posicao_original_laser_x
	
	match novoEstado:
		Estado.MIRANDO:
			state_timer = duracaoMira
			linha.visible = true
			linha_2.visible = true
			linha.default_color = Color("ffd900dc")
			linha_2.default_color = Color("ffd900dc")
			
		Estado.LOCKADO:
			state_timer = ducacaoLock
			linha.visible = true
			linha_2.visible = true
			linha.default_color = Color("ff7b00")
			linha_2.default_color = Color("ff7b00")
			prep_laser.play()
		Estado.ATIRANDO:
			prep_laser.pitch_scale = 1.2
			state_timer = duracaoTiro
			laserbeam.visible = true
			ray_cast_2d.enabled = true
			alvo_atingido_neste_tiro = false
			prep_laser.stop()
		Estado.COOLDOWN:
			state_timer = randf_range(3, tiroCooldown)
		Estado.IDLE:
			mudar_para_estado(Estado.COOLDOWN)
	
func modo_mira(delta: float):
	if is_instance_valid(player):
		var direcao_do_player = player.global_position - fire_point.global_position
		fire_point.rotation = direcao_do_player.angle()
	state_timer -= delta * Global.fator_tempo
	if state_timer <= 0:
		locked_angle = fire_point.rotation
		mudar_para_estado(Estado.LOCKADO)
		

func modo_lockado(delta: float):
	fire_point.rotation = locked_angle
	state_timer -= delta * Global.fator_tempo
	if state_timer <= 0:
		mudar_para_estado(Estado.ATIRANDO)
		audio_stream_player_2d.play()

func modo_atirando(delta: float):
	fire_point.rotation = locked_angle
	
	ray_cast_2d.clear_exceptions()
	ray_cast_2d.force_raycast_update()
	
	var ponto_final_visual = ray_cast_2d.target_position.x
	var colidiu_com_parede_ou_cristal = false
	
	var max_loops = 5
	var loops = 0
	
	while ray_cast_2d.is_colliding() and loops < max_loops:
		loops += 1
		var collider = ray_cast_2d.get_collider()
		
		if collider == player:
			if not alvo_atingido_neste_tiro:
				if "take_damage" in player: player.take_damage(40)
				alvo_atingido_neste_tiro = true
			
			ray_cast_2d.add_exception(player)
			ray_cast_2d.force_raycast_update()
		else:
			colidiu_com_parede_ou_cristal = true
			var ponto_colisao_global = ray_cast_2d.get_collision_point()
			var distancia = fire_point.global_position.distance_to(ponto_colisao_global)
			ponto_final_visual = distancia 
			
			if impact_light:
				impact_light.visible = true
				impact_light.global_position = ponto_colisao_global
			
			if collider.is_in_group("cristal"):
				gerar_mini_lasers(collider.global_position, fire_point.global_rotation)
				if collider.has_method("brilhar_impacto"):
					collider.brilhar_impacto()
			else:
				limpar_reflexoes()
			
			break 
	
	if not colidiu_com_parede_ou_cristal:
		limpar_reflexoes()
		if impact_light: impact_light.visible = false

	if laserbeam.texture:
		var largura_textura = laserbeam.texture.get_width()
		var nova_escala = ponto_final_visual / float(largura_textura)
		laserbeam.scale.x = nova_escala
		
		if laserbeam.centered:
			laserbeam.position.x = ponto_final_visual / 2.0
		else:
			laserbeam.position.x = 0

	state_timer -= delta * Global.fator_tempo
	if state_timer <= 0:
		mudar_para_estado(Estado.COOLDOWN)

func modo_cooldown(delta: float):
	state_timer -= delta * Global.fator_tempo
	if state_timer <= 0:
		mudar_para_estado(Estado.MIRANDO)

func gerar_mini_lasers(origem: Vector2, angulo_base: float):
	if reflexoes_ativas.is_empty():
		for i in range(quantidade_mini_lasers):
			var container = Node2D.new()
			get_parent().add_child(container) 
			
			var angulo_do_leque = 0.0
			if quantidade_mini_lasers > 1:
				var t = float(i) / (quantidade_mini_lasers - 1)
				angulo_do_leque = lerp(-abertura_leque/2, abertura_leque/2, t)
			
			var tortura = randf_range(-grau_de_tortura, grau_de_tortura)
			var angulo_relativo = deg_to_rad(angulo_do_leque + tortura)
			var rotacao_total = angulo_base + angulo_relativo
			
			var novo_sprite = Sprite2D.new()
			novo_sprite.texture = laserbeam.texture
			novo_sprite.modulate = laserbeam.modulate
			novo_sprite.modulate.a = 0.9 
			
			novo_sprite.scale.y = laserbeam.scale.y * scale_mini_largura
			
			if novo_sprite.texture:
				novo_sprite.scale.x = comprimento_mini_px / novo_sprite.texture.get_width()
				if novo_sprite.centered:
					novo_sprite.position.x = comprimento_mini_px / 2.0
			
			container.add_child(novo_sprite)
			
			var novo_luz_base = Sprite2D.new()
			if textura_luz_impacto:
				novo_luz_base.texture = textura_luz_impacto
				novo_luz_base.modulate = laserbeam.modulate
				var escala_luz = scale_mini_largura * 0.8
				novo_luz_base.scale = Vector2(escala_luz, escala_luz)
				novo_luz_base.position = Vector2.ZERO
				container.add_child(novo_luz_base)
			
			var novo_ray = RayCast2D.new()
			novo_ray.target_position = Vector2(comprimento_mini_px, 0) 
			novo_ray.collision_mask = ray_cast_2d.collision_mask
			novo_ray.enabled = true
			container.add_child(novo_ray)
			
			var vetor_offset = Vector2.RIGHT.rotated(rotacao_total) * distancia_saida_borda
			
			reflexoes_ativas.append({
				"node": container, 
				"ray": novo_ray,
				"light_base": novo_luz_base,
				"hit": false,
				"angulo_relativo": angulo_relativo,
				"offset_borda": vetor_offset
			})

	for ref in reflexoes_ativas:
		var container = ref["node"]
		var ray = ref["ray"]
		var light_base = ref["light_base"]
		
		container.global_position = origem + ref["offset_borda"]
		container.rotation = angulo_base + ref["angulo_relativo"]
		
		ray.force_raycast_update()
		
		if ray.is_colliding():
			var col = ray.get_collider()
			if col == player and not ref["hit"]:
				if player.has_method("take_damage"):
					player.take_damage(dano_mini_laser)
				ref["hit"] = true
		else:
			ref["hit"] = false
			
		if light_base:
			light_base.visible = true

func limpar_reflexoes():
	if reflexoes_ativas.is_empty(): return
	for ref in reflexoes_ativas:
		if is_instance_valid(ref["node"]):
			ref["node"].queue_free()
	reflexoes_ativas.clear()

func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback_atual = 0.0
	velocity = direcao * forca_knockback * 2
	if estadoAtual in [Estado.MIRANDO, Estado.LOCKADO, Estado.ATIRANDO]:
		mudar_para_estado(Estado.COOLDOWN)

func _on_collision_area_body_entered(body: Node2D) -> void:
	if knockback or body == self: return
	if body.is_in_group("player"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)
		if body.has_method("take_damage"): body.take_damage(5)

func take_damage(_amount: int) -> void:
	queue_free()
