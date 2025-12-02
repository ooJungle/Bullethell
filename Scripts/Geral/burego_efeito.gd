# Anexe este script ao seu nó com o shader (ex: ColorRect.gd)
extends ColorRect # Ou Sprite2D, dependendo do seu nó

func _process(delta: float) -> void:
	# Envia continuamente o tamanho do nó para uma variável no shader chamada "node_size"
	if material:
		material.set_shader_parameter("node_size", size)
