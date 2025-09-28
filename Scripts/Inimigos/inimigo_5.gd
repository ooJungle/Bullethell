extends CharacterBody2D

# --- Variáveis de Movimento e Combate ---
@export var velocidade = 100.0 # Representa a velocidade MÁXIMA BASE
@export var player: Node2D
@export var forca_maxima_direcao = 200.0 # Quão rápido o inimigo pode virar.
@export var forca_knockback = 450.0

# --- Nós Filhos ---
@onready var sprite: AnimatedSprite2D = $sprite
@onready var navigation_agent := $NavigationAgent2D as NavigationAgent2D
@onready var area_deteccao: Area2D = $Area2D
@onready var perception_timer: Timer = $PerceptionTimer

# --- Disparos e Variáveis Internas ---
const obj_tiro_azul = preload("res://Cenas/Projeteis/tiro_azul.tscn")
var timer = 0.0
var knockback = false
var tempo_knockback = 0.0
var buraco_negro_proximo: Node2D = null
var buraco_minhoca_proximo: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	perception_timer.timeout.connect(makepath)
	area_deteccao.body_entered.connect(_on_area_2d_body_entered)
	makepath()


func _physics_process(delta: float) -> void:
	if Global.paused:
		return
	
	timer += delta
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide(); return

	if knockback:
		tempo_knockback += delta
		if tempo_knockback >= 0.4:
			knockback = false
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0 * Global.fator_tempo)
		move_and_slide(); return
	
	# O inimigo também calcula as forças externas que atuam sobre ele
	var forca_externa = calcular_forcas_externas()
	velocity += forca_externa * delta * Global.fator_tempo

	var direcao_alvo = Vector2.ZERO
	if not navigation_agent.is_navigation_finished():
		direcao_alvo = global_position.direction_to(navigation_agent.get_next_path_position())

	if direcao_alvo.length() > 0:
		var velocidade_desejada = direcao_alvo * velocidade * Global.fator_tempo
		var forca_direcao = velocidade_desejada - velocity
		forca_direcao = forca_direcao.limit_length(forca_maxima_direcao)
		velocity += forca_direcao * delta * Global.fator_tempo
		velocity = velocity.limit_length(velocidade * Global.fator_tempo)
	else:
		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0 * Global.fator_tempo)

	move_and_slide()
	
	update_animation_and_flip()
	
	if is_instance_valid(player) and (player.global_position - global_position).length() < 500:
		shoot()


func makepath() -> void:
	if is_instance_valid(player):
		navigation_agent.target_position = player.global_position


# --- Funções de Física e Suporte para o Inimigo ---

func calcular_forcas_externas() -> Vector2:
	buraco_negro_proximo = encontrar_corpo_celeste_mais_proximo("buracos_negros")
	buraco_minhoca_proximo = encontrar_corpo_celeste_mais_proximo("buracos_minhoca")

	var in_bn_field = false
	if is_instance_valid(buraco_negro_proximo) and global_position.distance_to(buraco_negro_proximo.global_position) < buraco_negro_proximo.raio_maximo:
		in_bn_field = true

	var in_wh_field = false
	if is_instance_valid(buraco_minhoca_proximo) and global_position.distance_to(buraco_minhoca_proximo.global_position) < buraco_minhoca_proximo.raio_maximo:
		in_wh_field = true

	if in_bn_field and in_wh_field:
		return Vector2.ZERO

	var forca_total = Vector2.ZERO
	
	if in_bn_field:
		var dist = global_position.distance_to(buraco_negro_proximo.global_position)
		if dist > 1.0:
			var direcao = (buraco_negro_proximo.global_position - global_position).normalized()
			var forca = (buraco_negro_proximo.forca_gravidade / max(sqrt(dist), 20))
			forca_total += direcao * forca
			
	if in_wh_field:
		var dist = global_position.distance_to(buraco_minhoca_proximo.global_position)
		if dist > 1.0:
			var direcao = (global_position - buraco_minhoca_proximo.global_position).normalized()
			var forca = (buraco_minhoca_proximo.forca_repulsao_campo / max(sqrt(dist), 20))
			forca_total += direcao * forca

	return forca_total


func encontrar_corpo_celeste_mais_proximo(grupo: String) -> Node2D:
	var nos_no_grupo = get_tree().get_nodes_in_group(grupo)
	var mais_proximo = null
	var min_dist = INF
	if nos_no_grupo.is_empty(): return null
	for no in nos_no_grupo:
		var dist = global_position.distance_squared_to(no.global_position)
		if dist < min_dist:
			min_dist = dist
			mais_proximo = no
	return mais_proximo


func update_animation_and_flip():
	if velocity.length() > 10:
		sprite.play("Walking")
		if velocity.x > 0: sprite.flip_h = false
		elif velocity.x < 0: sprite.flip_h = true
	else:
		sprite.play("Idle")


func aplicar_knockback(direcao: Vector2):
	knockback = true
	tempo_knockback = 0.0
	velocity = direcao * forca_knockback


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == self: return
	if knockback: return
	if body.is_in_group("players"):
		var direcao = (global_position - body.global_position).normalized()
		aplicar_knockback(direcao)


func shoot():
	if timer >= 4:
		var new_bullet = obj_tiro_azul.instantiate()
		var direction = (player.global_position - global_position).normalized()
		new_bullet.player = player
		new_bullet.global_position = global_position
		new_bullet.velocity = direction * velocidade * 1.5
		get_parent().add_child(new_bullet)
		timer = 0.0
