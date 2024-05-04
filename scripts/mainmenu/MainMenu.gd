extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_start_button_up():
	get_tree().change_scene_to_file("res://games/game1/Main.tscn");


func _on_quit_button_up():
	pass # Replace with function body.
