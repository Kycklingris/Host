@tool
extends EditorPlugin

const ExportPanel = preload("Export.tscn")

var export_instance

func _enter_tree():
	export_instance = ExportPanel.instantiate()
	EditorInterface.get_editor_main_screen().add_child(export_instance)
	_make_visible(false)
	
	add_custom_type("Lobby", "Node", load("lobby.gd"), load("res://icon.svg"))
	return


func _exit_tree():
	pass


func _has_main_screen():
	return true
	
	
func _get_plugin_name():
	return "Export"

func _make_visible(visible):
	if export_instance:
		export_instance.visible = visible

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
