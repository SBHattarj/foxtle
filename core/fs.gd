class_name FS

const save_folder := "foxtle"
const main_save_file := "main_database"
const main_save_key := "main_save"
const main_terminal_dir := "main_terminal"

var important_keys := [main_save_key]

var save_files: Dictionary[String, LoadSaveFileReturn] = {}
var current_map_directory: DirAccess = null
var current_main_terminal_directory: DirAccess = null

var fs_mutex := Mutex.new()

static func get_home_dir() -> String:
	return OS.get_environment("USERPROFILE" if OS.get_name() == "Windows" else "HOME")

func get_save_dir() -> DirAccess:
	var home_directory = DirAccess.open(get_home_dir())
	if not home_directory.dir_exists(save_folder):
		home_directory.make_dir(save_folder)
	home_directory.change_dir(save_folder)
	return home_directory

func save_file_exists() -> bool:
	var save_dir = get_save_dir()
	if not save_dir.file_exists(main_save_file):
		return false
	return true

func recursive_remove(dir: DirAccess, remove_self := false):
	for file in dir.get_files():
		dir.remove(file)
	for dir_path in dir.get_directories():
		recursive_remove(DirAccess.open(dir.get_current_dir().path_join(dir_path)), true)
	if not remove_self: return
	dir.remove(".")

class LoadSaveFileReturn:
	var save_file: FileAccess
	var first_load := false
	var was_written_this_frame := false
	func _init(save_file: FileAccess = null, first_load := false):
		self.save_file = save_file
		self.first_load = first_load
	func get_buffer(loc: int, size: int) -> PackedByteArray:
		if save_file == null: return PackedByteArray()
		if save_file.get_length() < (loc+size): return PackedByteArray()
		save_file.seek(loc)
		return save_file.get_buffer(size)
	func set_buffer(loc: int, buffer: PackedByteArray) -> void:
		if save_file == null: return
		if save_file.get_length() < (loc+buffer.size()):
			save_file.resize(loc+buffer.size())
		save_file.seek(loc)
		save_file.store_buffer(buffer)
		if was_written_this_frame: return
		was_written_this_frame = true
		flush_file.call_deferred()
	func close():
		save_file.close()
	
	func flush_file():
		save_file.flush()
		was_written_this_frame = false
	func get_path() -> String:
		return save_file.get_path()

func load_save_file(path: String, key: String) -> LoadSaveFileReturn:
	if save_files.has(key): return save_files[key]
	var save_dir := get_save_dir()
	var save_file_path := save_dir.get_current_dir().path_join(path)
	var result = LoadSaveFileReturn.new()
	if not FileAccess.file_exists(save_file_path):
		result.first_load = true
		if key == main_save_key:
			recursive_remove(save_dir)
		FileAccess.open(save_file_path, FileAccess.WRITE_READ).close()
	result.save_file = FileAccess.open(save_file_path, FileAccess.READ_WRITE)
	save_files[key] = result
	return result

func get_save_file(key: String) -> LoadSaveFileReturn:
	if not save_files.has(key):
		return null
	return save_files[key]

func delete_save_file(key: String):
	if not save_files.has(key):
		return
	var file := get_save_file(key)
	var file_path := file.get_path()
	file.close()
	save_files.erase(key)
	DirAccess.remove_absolute(file_path)

func get_save_buffer(key: String, loc: int, size: int) -> PackedByteArray:
	var file = get_save_file(key)
	if file == null: return PackedByteArray([0])
	if file.get_length() < loc+size: return PackedByteArray([0])
	return file.get_buffer(loc, size)

func unload_save_file(key: String):
	if not save_files.has(key):
		return
	fs_mutex.lock()
	save_files[key].close()
	save_files.erase(key)
	fs_mutex.unlock()

class MapLoadReturn:
	var map_first_load: bool
	var main_terminal_first_load: bool

func unload_files(keep_important: bool):
	var important_files: Dictionary[String, LoadSaveFileReturn] = {}
	if keep_important:
		for key in important_keys:
			important_files[key] = save_files[key]
			save_files.erase(key)
	
	for key in save_files.keys():
		save_files[key].close()
		save_files.erase(key)
	
	for key in important_files.keys():
		save_files[key] = important_files[key]

func load_map(name: String) -> MapLoadReturn:
	unload_files(true)
	var save_dir := get_save_dir()
	var result := MapLoadReturn.new()
	if not save_dir.dir_exists(name):
		save_dir.make_dir(name)
		result.map_first_load = true
	save_dir.change_dir(name)
	var map_dir := save_dir
	current_map_directory = map_dir
	if not map_dir.dir_exists(main_terminal_dir):
		result.main_terminal_first_load = true
		map_dir.make_dir(main_terminal_dir)
	var map_terminal_dir := DirAccess.open(map_dir.get_current_dir())
	map_terminal_dir.change_dir(main_terminal_dir)
	current_main_terminal_directory = map_terminal_dir
	return result

func load_terminal(name: String) -> bool:
	var map_dir := current_map_directory
	if not map_dir.dir_exists(name):
		map_dir.make_dir(name)
		return true
	return false

func get_terminal_file(terminal_name: String, name: String):
	load_terminal(terminal_name)
	var file := load_save_file(
		"%s/%s/%s" % [
			current_map_directory.get_current_dir().get_file(),
			terminal_name,
			name
		],
		"%s-%s" % [terminal_name, name]
	)
	return file

func get_map_dir_name():
	return current_map_directory.get_current_dir().get_file()

func lock():
	fs_mutex.lock()

func unlock():
	fs_mutex.unlock()

func get_terminal_dir(name: String) -> DirAccess:
	var terminal_dir := DirAccess.open(current_map_directory.get_current_dir())
	if not terminal_dir.dir_exists(name):
		terminal_dir.make_dir(name)
	terminal_dir.change_dir(name)
	return terminal_dir
