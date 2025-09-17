extends CharacterBody2D
@export var velocidade = 90.0
@onready var sprite: AnimatedSprite2D = $sprite
@export var player = Node2D
const obj_tiro_roxo = preload("res://Cenas/Projeteis/tiro_central.tscn")

var girar = true
var timer = 0.0
var knockback = false
var tempo_knockback = 0.0
var rotacao = 200
var direction: Vector2 = Vector2.ZERO
func shoot(velocidade_tiro: float):
	if timer >= 3.0:
		var new_bullet = obj_tiro_roxo.instantiate()
		var direction = (player.position - position).normalized()
		new_bullet.position = position
		new_bullet.velocity = direction * velocidade_tiro
		get_parent().add_child(new_bullet)
		timer = 0.0

func _physics_process(delta: float) -> void:
	if Global.paused:
		return
	timer += delta
	direction = (player.position - position).normalized()
	look_at(player.position)
	
	# só anda se não estiver em knockback
	if not knockback:
		velocity = direction * velocidade

	# checa colisão apenas para iniciar knockback
	if not knockback:
		var nearby = get_tree().get_nodes_in_group("players")
		for other in nearby:
			if other == self:
				continue
			var dist = (other.position - position)
			if dist.length() <= 17:
				position -= velocity * delta * 10
				knockback = true
				tempo_knockback = 0.0
				break  # sai do loop para não reativar no mesmo frame

	# processa o estado de knockback
	if knockback:
		tempo_knockback += delta
		velocity = Vector2.ZERO
		if tempo_knockback >= 2.0:
			knockback = false
		
	move_and_slide()

	# Flip do sprite
	if velocity.x > 0:
		sprite.flip_h = false
	elif velocity.x < 0:
		sprite.flip_h = true	
	# Animação
	if velocity.length() > 0:
		sprite.play("Walking")
	else:
		sprite.play("Idle")
	
	if (player.position - position).length() < 500:
		shoot(130)
	if girar:
		sprite.rotate(-3.14/2)
		girar = false
