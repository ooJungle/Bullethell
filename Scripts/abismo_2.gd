extends Area2D

@export var dano_queda: int = 50
@export var ponto_retorno: Node2D
 
func _ready():
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node2D):
	if body.is_in_group("players"):
		if body.has_method("take_damage"):
			body.take_damage(dano_queda)
		if ponto_retorno:
			body.global_position = ponto_retorno.global_position
			body.velocity = Vector2.ZERO
