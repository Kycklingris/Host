@tool
extends EditorPlugin

class Exporter extends EditorExportPlugin:
	func _export_begin(features, is_debug, path, flags):
		self.copy_dir_recursively("res://resources/", path.get_base_dir() + "/resources/");
		return;
		
	func copy_dir_recursively(source: String, destination: String):
		DirAccess.make_dir_recursive_absolute(destination)
		var source_dir = DirAccess.open(source);
		
		for filename in source_dir.get_files():
			#OS.alert(source + filename, 'Datei erkannt')
			source_dir.copy(source + filename, destination + filename)
			
		for dir in source_dir.get_directories():
			self.copy_dir_recursively(source + dir + "/", destination + dir + "/")
		return;


var _exporter = Exporter.new();

func _enter_tree():
	add_export_plugin(_exporter);
	return;

func _exit_tree():
	remove_export_plugin(_exporter);
	return;
