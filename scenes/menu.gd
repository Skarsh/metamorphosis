extends Control

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_play_button_texture_pressed() -> void:
	$ClickBop.play()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_exit_button_texture_pressed() -> void:
	$ClickBop.play()
	get_tree().quit()

func _on_play_button_texture_mouse_entered() -> void:
	$HoverBop.play()

func _on_exit_button_texture_mouse_entered() -> void:
	$HoverBop.play()