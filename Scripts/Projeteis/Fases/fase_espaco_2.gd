extends Node2D
@onready var portal_volta: Area2D = $portal_volta
@onready var colisao_portal = $portal_volta/CollisionShape2D
@onready var player: CharacterBody2D = $player
@onready var battle_manager: Node2D = $Node2D/BattleManager
var tempo: float = 0

func _ready() -> void:
	colisao_portal.set_deferred("disabled", true)
	portal_volta.visible = false

func _process(delta: float) -> void:
	if battle_manager.contagem > 57:
		abrir_portal()
		tempo += delta

func abrir_portal():
	portal_volta.visible = true
	if tempo > 1:
		colisao_portal.set_deferred("disabled", false)
		
	if player:
		player.ativar_seta_guia(portal_volta.global_position)
