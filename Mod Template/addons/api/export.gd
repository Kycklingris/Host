class_name Export

const files: Array[String] = [
	"res://addons/api/lobby.gd",
	"res://Main.tscn",
]

static func export():
	var config = ConfigFile.new()
	var err = config.load("res://mod.cfg")
	if err != OK:
		printerr("Invalid mod config")
		return
	
	var name = config.get_value("mod", "name")
	var id = str(config.get_value("mod", "id"))
	
	var packer = PCKPacker.new()
	packer.pck_start("res://export/mod.pck.tmp")
	
	
	for file in files:
		var pck_path = file.replace("res://", "res://mods/" + id + "/")
		packer.add_file(pck_path, file, false)
	
	packer.flush(true);
	_update_paths(id, files)
	
	DirAccess.remove_absolute("res://export/mod.pck.tmp")
	DirAccess.copy_absolute("res://mod.cfg", "res://export/mod.cfg")
	
	copy_dir_recursively("res://export/", "C:/Users/malte/AppData/Roaming/Godot/app_userdata/Host/mods/bingo/")

	return


static func _update_paths(id: String, added_files: Array[String]):
	var added_files_bytes: Array[PackedByteArray] = []
	for added_file in added_files:
		added_files_bytes.push_back(added_file.to_utf8_buffer())
	
	var tmp = FileAccess.get_file_as_bytes("res://export/mod.pck.tmp")
	var out = FileAccess.open("res://export/mod.pck", FileAccess.WRITE)
	
	var i = 0
	while i < tmp.size():
		var byte = tmp.decode_u8(i)
		if byte != 114: # The utf-8 encoding of "r" as in "res://"
			out.store_8(byte)
			i += 1
			continue
		var updated = false
		for l in added_files.size():
			var num_bytes = added_files_bytes[l].size()
			if num_bytes + i > tmp.size():
				continue
			var original_bytes = tmp.slice(i, i + num_bytes)
			if compare_bytes(original_bytes, added_files_bytes[l]):
				i = i + num_bytes
				out.store_buffer(added_files[l].replace("res://", "res://mods/" + id + "/").to_utf8_buffer())
				updated = true
				break
		if not updated:
			out.store_8(byte)
			i += 1
	
	out.flush()
	print("PCK file updated")


static func compare_bytes(original: PackedByteArray, new: PackedByteArray) -> bool:
	for i in original.size():
		if original[i] != new[i]:
			return false
	return true

static func copy_dir_recursively(source: String, destination: String):
	DirAccess.make_dir_recursive_absolute(destination)
	
	var source_dir = DirAccess.open(source);
	
	for filename in source_dir.get_files():
		source_dir.copy(source + filename, destination + filename)
		
	for dir in source_dir.get_directories():
		copy_dir_recursively(source + dir + "/", destination + dir + "/")
