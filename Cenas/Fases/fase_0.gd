extends Node2D

func _ready() -> void:
	$Timer.start()
	
func _process(delta: float) -> void:
	var time_remaining: float = max(0.0, $Timer.time_left)	
	
	var total_seconds: int = int(time_remaining)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	
	$player/Camera2D/Label.text = "%02d:%02d" % [minutes, seconds]
	
func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://Cenas/Menu/WinScene.tscn")
