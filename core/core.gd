extends Node

func wait_frames(num := 1):
	for _i in range(max(1, num)):
		await get_tree().process_frame

var fs := FS.new()
var player: Player

var map_first_load := false

func ready_player(player: Player):
	self.player = player
	var world := fs.load_save_file(fs.main_save_file, fs.main_save_key)
	if world.first_load:
		world.set_buffer(0, player.binary_converter.to_bytes())
		return
	player.binary_converter.from_bytes(world.get_buffer(0, player.binary_converter.length))

func save_player():
	if Engine.is_editor_hint(): return
	if player == null: return
	var world := fs.get_save_file(fs.main_save_key)
	world.set_buffer(0, player.binary_converter.to_bytes())

func load_map(name: String):
	var result := fs.load_map(name)
	map_first_load = result.map_first_load

func get_terminal_file(terminal_name: String, name: String) -> FS.LoadSaveFileReturn:
	return fs.get_terminal_file(terminal_name, name)

func file_exists_in_current_map(path: String) -> bool:
	return fs.file_exists_in_current_map(path)
func terminal_file_exists(terminal_name: String, name: String) -> bool:
	return fs.terminal_file_exists(terminal_name, name)

func unload_terminal_file(terminal_name: String, name: String):
	return fs.unload_terminal_file(terminal_name, name)

func get_terminal_components(terminal_name: String) -> PackedStringArray:
	var files := fs.get_terminal_dir(terminal_name).get_files()
	return files

func get_file_character(name: String, size: int) -> PackedByteArray:
	var file := fs.get_save_file(name)
	if file == null: return PackedByteArray()
	return file.get_buffer(0, size)

func load_file_character(name: String) -> FS.LoadSaveFileReturn:
	return fs.load_save_file(fs.get_map_dir_name().path_join(name), name)

func set_file_character(name: String, data: PackedByteArray):
	var file = fs.get_save_file(name)
	if file == null: return
	file.set_buffer(0, data)

func get_file_characters_in_map() -> PackedStringArray:
	return fs.current_map_directory.get_files()

func unload_file_character(name: String):
	fs.unload_save_file(name)

func os_open_map_dir():
	OS.shell_open(Core.fs.current_map_directory.get_current_dir())

func get_map_name() -> String:
	return fs.get_map_dir_name()

func get_volume(bus: String) -> float:
	return AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus))

func set_volume(bus: String, volume: float):
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus), volume)

func get_default_viewport_size() -> Vector2:
	var width: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	return Vector2(width, height)

func get_current_viewport_size() -> Vector2:
	return get_window().size

func get_viewport_size_ratio() -> int:
	return ceili(get_current_viewport_size().x/get_default_viewport_size().x)

const default_viewport_ratio := 2

func set_viewport_ratio(val: int):
	if val < 1:
		val = default_viewport_ratio
	DisplayServer.window_set_size(get_default_viewport_size()*val)

func get_screen_size() -> Vector2:
	return DisplayServer.screen_get_size()

func increment_size_ratio():
	var current := get_viewport_size_ratio()
	var next_ratio := current + 1
	var default_size := get_default_viewport_size()
	var new_size := default_size * next_ratio
	var screen_size := get_screen_size()
	if screen_size.x < new_size.x or screen_size.y < new_size.y:
		next_ratio = 1
	set_viewport_ratio(next_ratio)
