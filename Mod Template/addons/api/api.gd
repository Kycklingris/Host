@tool
extends EditorPlugin


class Exporter extends EditorExportPlugin:
	func _get_name():
		return "Abow"
	
	func _export_end():
		DirAccess.copy_absolute("res://export/mod.pck", "res://export/mod.pck.tmp");
		#_update_paths()
		DirAccess.remove_absolute("res://export/mod.pck.tmp");
		copy_dir_recursively("res://export/", "C:/Users/malte/AppData/Roaming/Godot/app_userdata/Host/mods/bingo/")
		return;
	
	static func copy_dir_recursively(source: String, destination: String):
		DirAccess.make_dir_recursive_absolute(destination)
		
		var source_dir = DirAccess.open(source);
		
		for filename in source_dir.get_files():
			source_dir.copy(source + filename, destination + filename)
			
		for dir in source_dir.get_directories():
			copy_dir_recursively(source + dir + "/", destination + dir + "/")
			
	static func _update_paths():
		var path_to_update = "res://addons/api";
		var path_to_update_bytes = path_to_update.to_utf8_buffer();
		
		var tmp = FileAccess.get_file_as_bytes("res://export/mod.pck.tmp")
		var out = FileAccess.open("res://export/mod.pck", FileAccess.WRITE)
		
		var i = 0
		while i < tmp.size():
			var byte = tmp.decode_u8(i)
			if byte != 114: # The utf-8 encoding of "r" as in "res://"
				out.store_8(byte)
				i += 1
				continue;
			if path_to_update_bytes.size() + i > tmp.size():
				break;
			var original_bytes = tmp.slice(i, i + path_to_update_bytes.size())
			if compare_bytes(original_bytes, path_to_update_bytes):
				i = i + path_to_update_bytes.size()
				out.store_buffer("res://scripts".to_utf8_buffer())
				continue;
			out.store_8(byte)
			i += 1
			continue;
		
		out.flush()
		print("PCK file updated")
		
	static func compare_bytes(original: PackedByteArray, new: PackedByteArray) -> bool:
		for i in original.size():
			if original[i] != new[i]:
				return false
		return true




const ExportPanel = preload("Export.tscn")

var export_instance
var exporter = Exporter.new();

func _enter_tree():
	add_export_plugin(exporter)
	export_instance = ExportPanel.instantiate()
	EditorInterface.get_editor_main_screen().add_child(export_instance)
	_make_visible(false)
	
	#add_custom_type("Lobby", "Node", load("lobby.gd"), load("res://icon.svg"))
	return

func _exit_tree():
	remove_export_plugin(exporter);
	return


func _has_main_screen():
	return true
	
	
func _get_plugin_name():
	return "Export"
	return

func _make_visible(visible):
	if export_instance:
		export_instance.visible = visible
	return

func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
	return
