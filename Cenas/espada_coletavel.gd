extends Area2D
@onready var sprite_2d: Sprite2D = $Sprite2D

@export var dados_espada: Dictionary = {
	"textura_equipada": null,
	"cena coletavel": sprite_2d
}

func _ready() -> void:
	if get_node_or_null("Sprite2D"):
		get_node("Sprite2D").texture = dados_espada.textura_equipada

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("equipar"):
			body.equipar(dados_espada)
