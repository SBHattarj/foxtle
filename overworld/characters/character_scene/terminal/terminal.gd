@tool
extends CharacterBase
class_name TerminalCharacter

enum TerminalState {
	SHUT,
	FACE,
	INFO,
	WARNING,
	PROCESSING,
	VALIDATION_BASED
}

@export
var component_checkers: Array[ComponentChecker] = []
@export
var report_override_event: Event
@export
var valid_event: Event
@export
var event_after_report: Event


var log_binary_converter := BinaryConverter.new().add_part(
	BinaryConverter.U8.new(
		func(): return state,
		func(val): state = val
	)
)

var next_log_location := log_binary_converter.length
var ids: Dictionary[int, int] = {}

func get_next_log_location(size := 1) -> int:
	var current_next_log_location := next_log_location
	next_log_location += size
	return current_next_log_location

func get_id_location(id: int, size: int = 1) -> int:
	if ids.has(id):
		return ids[id]
	ids[id] = get_next_log_location(size)
	return ids[id]

@export
var state := TerminalState.SHUT:
	set(val):
		if state == val: return
		state = val
		_handle_animation_change()

@export
var terminal_name := "main_terminal"
@export
var terminal_show_name := "Main Terminal"

const terminal_state_animation_map := {
	TerminalState.SHUT: "shut",
	TerminalState.FACE: "face",
	TerminalState.INFO: "info",
	TerminalState.WARNING: "warning",
	TerminalState.PROCESSING: "processing"
}


var event_block_handler := Signals.make_event_block_handler()

var was_valid := false

func _ready() -> void:
	was_valid = are_component_valid()
	_ready_sprite()

func get_current_animation() -> String:
	return terminal_state_animation_map.get(state, _get_animation_for_validation())

func _get_animation_for_validation():
	if are_component_valid():
		return terminal_state_animation_map[TerminalState.INFO]
	return terminal_state_animation_map[TerminalState.WARNING]

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	interacted_by.connect(_handle_interacted_by)
	event_block_handler.full_unblock.connect(save)
	get_viewport().focus_entered.connect(_focus_entered)
	var file := Core.get_terminal_file(terminal_name, "log")
	if file.first_load:
		var buffer := log_binary_converter.to_bytes()
		file.set_buffer(0, buffer)
		return
	log_binary_converter.from_bytes(file.get_buffer(0, log_binary_converter.length))

func _focus_entered():
	if not was_valid and are_component_valid():
		Signals.run_ui_audio("PuzzleSolveJingleAudio")
	was_valid = are_component_valid()
	_handle_animation_change()

func save():
	var file := Core.get_terminal_file(terminal_name, "log")
	var buffer := log_binary_converter.to_bytes()
	file.set_buffer(0, buffer)

func save_log(id: int, data: PackedByteArray):
	var size := data.size()
	var location := get_id_location(id, size)
	var file := Core.get_terminal_file(terminal_name, "log")
	file.set_buffer(location, data)

func terminal_file_exists(name: String) -> bool:
	return Core.terminal_file_exists(terminal_name, name)

func get_terminal_file(name: String) -> FS.LoadSaveFileReturn:
	return Core.get_terminal_file(terminal_name, name)

func save_terminal_file(name: String, location: int, data: PackedByteArray):
	var file := Core.get_terminal_file(terminal_name, name)
	file.set_buffer(location, data)

func unload_terminal_file(name: String):
	Core.unload_terminal_file(terminal_name, name)

func get_log(id: int, size: int) -> PackedByteArray:
	var location := get_id_location(id, size)
	var file := Core.get_terminal_file(terminal_name, "log")
	return file.get_buffer(location, size)

func is_log_first_load():
	var file := Core.get_terminal_file(terminal_name, "log")
	return file.first_load

func are_component_valid():
	var components := Core.get_terminal_components(terminal_name)
	components.erase("log")
	for component_checker in component_checkers:
		var result := component_checker.extract_valid_file(terminal_name, components)
		if not result.verified: return false
		if not result.file_name_match: return false
		components.erase(result.original_file_name)
	return len(components) == 0

func _handle_interacted_by(by: CharacterBase):
	if by is not Player: return
	if report_override_event != null:
		run_event(report_override_event, false)
		return
	if are_component_valid():
		run_event(valid_event, false)
		return
	report_components()

func report_components():
	await Signals.call_with_event_block(_report_components)

func _report_components():
	if are_component_valid():
		await Signals.do_dialogue(terminal_show_name, "components valid starting fully.")
		return
	var last_state := state
	await Signals.do_dialogue(terminal_show_name, "[color={error_color}]components invalid, reporting status.[/color]")
	state = TerminalState.PROCESSING
	var components := Core.get_terminal_components(terminal_name)
	components.erase("log")
	for component_checker in component_checkers:
		var result := component_checker.extract_valid_file(terminal_name, components)
		if not result.verified:
			await Signals.do_dialogue(terminal_show_name, "[color={info_color}]component:[/color] %s;\n[color={info_color}]type:[/color] %s;\n[color={info_color}]status:[/color] [color={error_color}]not present;[/color]\n" % [
				component_checker.character_name,
				SharedVars.type_map[component_checker.appearance]
			])
			continue
		if not result.file_name_match:
			await Signals.do_dialogue(
				terminal_show_name,
				"[color={info_color}]component:[/color] %s;\n[color={info_color}]type:[/color] %s;\n[color={info_color}]status:[/color] [color={error_color}]Error Database name mismatch[/color];\n[color={info_color}]expected file name:[/color] [color={file_color}]%s[/color];\n[color={info_color}]got:[/color] [color={error_color}]%s[/color];" % [
					component_checker.character_name,
					SharedVars.type_map[component_checker.appearance],
					result.file_name,
					result.original_file_name
				]
			)
			components.erase(result.original_file_name)
			continue
		await Signals.do_dialogue(
			terminal_show_name,
			"[color={info_color}]component:[/color] %s;\n[color={info_color}]type:[/color] %s;\n[color={info_color}]status:[/color] [color={success_color}]present and accepted[/color];\n" % [
				component_checker.character_name,
				SharedVars.type_map[component_checker.appearance],
			]
		)
		components.erase(result.original_file_name)
	if len(components) < 1:
		state = last_state
		await run_event(event_after_report, true)
		return
	await Signals.do_dialogue(
		terminal_show_name,
		"additional %d components found; database component names: %s;" % [
			len(components),
			", ".join(components)
		]
	)
	state = last_state
	await run_event(event_after_report, true)

func run_event(event: Event, blocked: bool):
	if event == null: return
	await event.call_from_event(blocked)
