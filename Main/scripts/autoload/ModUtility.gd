extends Node

signal mod_loaded(Mod)

var mods: Array[Mod] = []

func _ready():
	var directories = self._get_mod_directories()
	for directory in directories:
		self._load_mod(directory)
	
	return

func _get_mod_directories() -> PackedStringArray:
	DirAccess.make_dir_recursive_absolute("user://mods")
	return DirAccess.get_directories_at("user://mods")


func _load_mod(directory: String):
	var mod_directory = "user://mods/" + directory + "/"
	if not FileAccess.file_exists(mod_directory + "mod.pck") or not FileAccess.file_exists(mod_directory + "mod.cfg"):
		printerr("The mod at \"" + mod_directory + "\" is invalid")
		return
	
	var config_file = ConfigFile.new()
	var err = config_file.load(mod_directory + "mod.cfg")
	if err != OK:
		printerr("The mod config at \"" + mod_directory + "\" is unloadable")
		return
	
	var config = Config.new(config_file, mod_directory)
	var mod = Mod.new(mod_directory, config)
	self.mods.push_back(mod)
	self.mod_loaded.emit(mod)
	return

class Mod:
	var directory: String
	var pck_path: String
	var config: Config
	
	func _init(p_directory: String, p_config: Config):
		self.directory = p_directory
		self.pck_path = "res://mods/" + str(p_config.id) + "/"
		self.config = p_config
		
		ProjectSettings.load_resource_pack(p_directory + "mod.pck")
		return
	
class Config:
	var name: String
	var id: int
	var scene: String
	
	func _init(file: ConfigFile, directory: String):		
		self.name = file.get_value("mod", "name")
		self.id = int(file.get_value("mod", "id"))
		self.scene = file.get_value("mod", "scene")
		
		if self.name == null or self.id == null or self.scene == null:
			printerr("The config file in \"" + directory + "\" does not contain the required fields.")
		return
