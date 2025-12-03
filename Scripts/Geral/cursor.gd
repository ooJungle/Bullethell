extends CharacterBody2D

@export var velocidade_cursor: float = 200.0
@export var raio_da_roda: float = 170.0
var tween_dano: Tween
var angulo_arco: float = 10
var velocidade_roda: float = 10

func _ready() -> void:
	add_to_group("player")
func _physics_process(_delta: float):
	var direcao = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direcao * velocidade_cursor
	move_and_slide()

	if position.length() > raio_da_roda:
		position = position.limit_length(raio_da_roda)

func take_damage(angulo: float, velocidade: float, acelera_roda: float):
	if tween_dano:
		tween_dano.kill()
		modulate = Color(2.5, 0.0, 0.0, 1.0) 
		tween_dano = create_tween()
		tween_dano.tween_property(self, "modulate", Color.WHITE, 0.15).set_trans(Tween.TRANS_SINE)
		velocidade_cursor -= velocidade
		angulo_arco -= angulo
		velocidade_roda += acelera_roda
