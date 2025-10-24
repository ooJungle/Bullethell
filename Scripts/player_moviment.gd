extends CharacterBody2D

@export var speed: float = 300.0
@export var aceleracao: float = 1500.0
@export var atrito: float = 1200.0
@export var forca_salto_inimigo: float = 200.0
@export var raio_max_dilatacao: float = 500.0
@export var fator_tempo_maximo: float = 3.0
@export var raio_max_aceleracao: float = 500.0
@export var fator_tempo_minimo: float = 0.2

@onready var sprite: AnimatedSprite2D = $sprite
@onready var dano_timer: Timer = $dano_timer
@onready var hitbox: Area2D = $AreaHitbox

@onready var iventario: Node2D = $Inventario
@onready var arma_sprite: Sprite2D = $Inventario/ArmaEquipada
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_timer: Timer = $AttackTimer
@onready var hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

var vida_maxima: int = 300
var vida: int = vida_maxima
var buraco_negro_proximo: Node2D = null
var buraco_minhoca_proximo: Node2D = null
var JUMP_VELOCITY = -450
var SPEED = 250

var tem_arma: bool = false
var pode_atacar: bool = true
var arma_atual_dados: Dictionary

func _ready() -> void:
	vida = vida_maxima
	Global.vida = vida
	
	attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
	attack_timer.timeout.connect(_on_attack_timer_timeout)


func _physics_process(delta: float) -> void:
	if Global.paused:
		return
		
	if Global.plataforma:
		if not is_on_floor():
			velocity += get_gravity() * delta
		var direction := Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
		if direction > 0:
			sprite.flip_h = false
		elif direction < 0:
			sprite.flip_h = true
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		if Input.is_action_just_released("ui_accept") and velocity.y < 0:
			velocity.y *= 0.5
	else:
		atualizar_fator_tempo()

		var forca_externa = calcular_forcas_externas()
		velocity += forca_externa * delta
		
		var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

		if input_direction != Vector2.ZERO:
			var target_velocity = input_direction * speed
			velocity = velocity.move_toward(target_velocity, aceleracao * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, atrito * delta)

		if input_direction.x > 0:
			sprite.flip_h = false
		elif input_direction.x < 0:
			sprite.flip_h = true

		if velocity.length() > 10.0:
			if sprite.animation != "Walking":
				sprite.play("Walking")
		else:
			if sprite.animation != "Idle":
				sprite.play("Idle")
		
		if tem_arma:
			rotacionar_arma_para_mouse()
		
	move_and_slide()
	handle_enemy_bounce()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not Global.paused:
			$".."/PauseMenu.start_pause()
	
	if event.is_action_pressed("atacar") and tem_arma and pode_atacar:
		atacar()
		
	if event.is_action_pressed("dropar") and tem_arma:
		dropar_arma()


# ==================================================================
# 			--- Funções do Sistema de Armas ---
# ==================================================================
func rotacionar_arma_para_mouse():
	var direcao_mouse = get_global_mouse_position() - iventario.global_position
	iventario.rotation = direcao_mouse.angle()

func equipar_arma(dados_da_arma: Dictionary):
	if tem_arma:
		dropar_arma()

	tem_arma = true
	arma_atual_dados = dados_da_arma
	
	arma_sprite.texture = arma_atual_dados.textura_equipada
	arma_sprite.visible = true

func dropar_arma():
	if not tem_arma:
		return

	var cena_coletavel: PackedScene = arma_atual_dados.cena_coletavel
	
	if cena_coletavel:
		var arma_instancia = cena_coletavel.instantiate()
		arma_instancia.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 40
		get_parent().add_child(arma_instancia)

	tem_arma = false
	pode_atacar = true
	arma_atual_dados = {}
	arma_sprite.visible = false

func atacar():
	pode_atacar = false
	hitbox_shape.disabled = false
	attack_timer.start(0.2)

func _on_attack_timer_timeout():
	hitbox_shape.disabled = true
	await get_tree().create_timer(0.3).timeout
	pode_atacar = true

func _on_attack_hitbox_body_entered(body: Node2D):
	if body.is_in_group("enemies"):
		print("Acertei o inimigo: ", body.name)
		if body.has_method("take_damage"):
			body.receber_dano(10)

func take_damage(amount: int) -> void:
	vida -= amount
	Global.vida = vida
	print("Player tomou dano. Vida:", vida)
	if vida <= 0:
		die()

func die() -> void:
	print("morreu")
	get_tree().change_scene_to_file("res://Cenas/Menu/LostScene.tscn")

func dano():
	sprite.modulate = Color(1.0, 0.325, 0.349)
	dano_timer.start(0.3)

func handle_enemy_bounce():
	if is_on_floor():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider and collider.is_in_group("enemies"):
				velocity.y = -forca_salto_inimigo
				break
			
func calcular_forcas_externas() -> Vector2:
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

func atualizar_fator_tempo():
	buraco_negro_proximo = encontrar_corpo_celeste_mais_proximo("buracos_negros")
	buraco_minhoca_proximo = encontrar_corpo_celeste_mais_proximo("buracos_minhoca")
	
	var efeito_buraco_negro = 1.0
	var efeito_buraco_minhoca = 1.0
	
	if is_instance_valid(buraco_negro_proximo):
		var dist = global_position.distance_to(buraco_negro_proximo.global_position)
		if dist < raio_max_dilatacao:
			efeito_buraco_negro = remap(dist, 0, raio_max_dilatacao, fator_tempo_maximo, 1.0)

	if is_instance_valid(buraco_minhoca_proximo):
		var dist = global_position.distance_to(buraco_minhoca_proximo.global_position)
		if dist < raio_max_aceleracao:
			efeito_buraco_minhoca = remap(dist, 0, raio_max_aceleracao, fator_tempo_minimo, 1.0)
	
	var fator_tempo_combinado = efeito_buraco_negro + efeito_buraco_minhoca - 1.0
	Global.fator_tempo = max(0.001, fator_tempo_combinado)

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

func _on_dano_timer_timeout() -> void:
	sprite.modulate = Color(1.0, 1.0, 1.0)
