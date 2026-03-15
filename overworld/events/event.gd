@tool
extends Node2D
class_name Event

signal done()

enum Type {
	DIALOGUE = 1,
	TURN = 2,
	MOVE = 3,
	MOVE_X = 4,
	MOVE_Y = 5,
	CHANGE_TERMINAL_STATE = 6,
	OPEN_DATABASE = 7,
	TURN_ON_HOLDER = 8,
	TURN_OFF_HOLDER = 9,
	HOLDER_CHOICE = 10,
	NONE = 0
}

enum Starter {
	PREV_EVENT,
	IMMEDIATE,
	PLAYER_INTERACT
}

enum {
	RUN_ALL = -1
}

var type_map: Dictionary[Type, Callable] = {
	Type.DIALOGUE: handle_dialogue,
	Type.TURN: handle_turn,
	Type.MOVE: handle_move,
	Type.MOVE_X: handle_move_x,
	Type.MOVE_Y: handle_move_y,
	Type.CHANGE_TERMINAL_STATE: handle_terminal_state_change,
	Type.OPEN_DATABASE: handle_open_database,
	Type.TURN_ON_HOLDER: handle_turn_holder_on,
	Type.TURN_OFF_HOLDER: handle_turn_holder_off,
	Type.HOLDER_CHOICE: handle_holder_choice
}

@export
var start_type: Starter = Starter.PREV_EVENT
@export
var type: Type = Type.DIALOGUE:
	set(val):
		type = val
		notify_property_list_changed()
@export
var is_blocking: bool = true
@export
var enabled: bool = true
@export
var one_time: bool = true


@export_multiline()
var character_name: String
@export_multiline()
var dialogue: String


@export
var direction: CharacterBase.Direction = CharacterBase.Direction.UP

@export
var state: TerminalCharacter.TerminalState = TerminalCharacter.TerminalState.SHUT

@export
var duration := 0.3

@export
var holders: Array[Holder] = []

@export
var target: Node:
	get():
		if Engine.is_editor_hint(): return target
		if is_player: return Core.player
		return target

const character_target_type := [Type.TURN, Type.MOVE, Type.MOVE_X, Type.MOVE_Y]

@export
var is_player: bool:
	get():
		if type not in character_target_type: return false
		return is_player
	set(val):
		is_player = val
		notify_property_list_changed()

@export
var save_status: bool = false:
	set(val):
		save_status = val
		notify_property_list_changed()

@export
var terminal: TerminalCharacter

@export
var wait_for_events: Array[Event] = []

@export
var next_events: Array[Event] = []

const target_type_map: Dictionary[Type, StringName] = {
	Type.TURN: &"CharacterBase",
	Type.MOVE_Y: &"CharacterBase",
	Type.MOVE_X: &"CharacterBase",
	Type.MOVE: &"CharacterBase",
	Type.CHANGE_TERMINAL_STATE: &"TerminalCharacter",
	Type.TURN_ON_HOLDER: &"Holder",
	Type.TURN_OFF_HOLDER: &"Holder"
}
func target_transform(property: Dictionary):
	property.class_name = target_type_map.get(type, &"Node")
	property.hint_string = str(property.class_name)

var binary_converter := BinaryConverter.new().add_part(
	BinaryConverter.U8.new(
		func(): return enabled,
		func(val): enabled = val
	)
)

var property_validator := PropertyValidator.new().add(
	PropertyValidator.ValidatorPart.new(
		func(name: String): return name in ["character_name", "dialogue"],
		func(): return type == Type.DIALOGUE
	)
).add(
	PropertyValidator.ValidatorPart.new(
		func(name: String): return name in ["direction"],
		func(): return type == Type.TURN
	)
).add(
	PropertyValidator.ValidatorPart.new(
		func(name: String): return name == "duration",
		func(): return type in [Type.TURN, Type.CHANGE_TERMINAL_STATE]
	)
).add(
	PropertyValidator.ValidatorPart.new(
		func(name: String): return name == "target",
		func(): return type in [
			Type.TURN, 
			Type.MOVE, 
			Type.MOVE_X, 
			Type.MOVE_Y, 
			Type.CHANGE_TERMINAL_STATE,
			Type.TURN_ON_HOLDER,
			Type.TURN_OFF_HOLDER
		] and not is_player,
	target_transform
	)
).add(
	PropertyValidator.ValidatorPart.new(
		func(name: String): return name == "is_player",
		func(): return type in character_target_type
	)
).add(
	PropertyValidator.ValidatorPart.new(
		func(name: String): return name == "terminal",
		func(): return save_status
	)
).add(
	PropertyValidator.ValidatorPart.new(
		func(name: String): return name == "holders",
		func(): return type == Type.HOLDER_CHOICE
	)
)

func _validate_property(property: Dictionary) -> void:
	property_validator.validate(property)

func _ready() -> void:
	if Engine.is_editor_hint(): return
	_handle_save_load()
	if start_type == Starter.IMMEDIATE:
		call_from_event.call_deferred()

func _handle_save_load() -> void:
	if not save_status: return
	if terminal == null: return
	if terminal.is_log_first_load():
		terminal.save_log(get_instance_id(), binary_converter.to_bytes())
		return
	var terminal_log := terminal.get_log(get_instance_id(), binary_converter.length)
	binary_converter.from_bytes(terminal_log)

func call_from_event(last_was_blocking: bool = false):
	if not last_was_blocking and is_blocking:
		await Signals.call_with_event_block(handle_event)
		return
	if not is_blocking:
		handle_event()
		return
	await handle_event()

func handle_event():
	if not enabled:
		return
	var choice: int = await type_map.get(type, default_run).call()
	await wait_for_other_events()
	done.emit()
	if one_time:
		enabled = false
	await run_next(choice)
	save()

func save():
	if not save_status: return
	if terminal == null: return
	terminal.save_log(get_instance_id(), binary_converter.to_bytes())

func run_next(choice: int):
	if choice == RUN_ALL:
		await run_all()
		return
	await run_choice(choice)

func wait_for_other_events():
	var runners: Array[Callable] = []
	for event in wait_for_events:
		if not event.enabled: continue
		runners.append(func(): await event.done)
	await AsyncUtils.run_together(runners)

func run_choice(choice: int):
	if choice < 0:
		await run_all()
		return
	if choice >= len(next_events):
		return
	await next_events[choice].call_from_event(is_blocking)

func run_all():
	var runners: Array[Callable] = []
	for event in next_events:
		runners.append(func(): await event.call_from_event(is_blocking))
	await AsyncUtils.run_together(runners)

func default_run() -> int:
	return RUN_ALL

func handle_dialogue() -> int:
	await Signals.do_dialogue(character_name, dialogue)
	return RUN_ALL

func handle_turn() -> int:
	var character: CharacterBase = target
	if character == null:
		return RUN_ALL
	character.direction = direction
	await get_tree().create_timer(duration).timeout
	return RUN_ALL

func handle_move() -> int:
	var character: CharacterBase = target
	if character == null: return RUN_ALL
	var controller: ControllerBase = character.controller
	await controller.move_to(self)
	return RUN_ALL

func handle_move_x() -> int:
	var character: CharacterBase = target
	if character == null: return RUN_ALL
	var controller := character.controller
	var prev_y := global_position.y
	global_position.y = controller.global_position.y
	await handle_move()
	global_position.y = prev_y
	return RUN_ALL

func handle_move_y() -> int:
	var character: CharacterBase = target
	if character == null: return RUN_ALL
	var controller := character.controller
	var prev_x := global_position.x
	global_position.x = controller.global_position.x
	await handle_move()
	global_position.x = prev_x
	return RUN_ALL

func handle_terminal_state_change() -> int:
	var terminal: TerminalCharacter = target
	if terminal == null: return RUN_ALL
	terminal.state = state
	await get_tree().create_timer(duration).timeout
	return RUN_ALL

func handle_open_database() -> int:
	Core.os_open_map_dir()
	return RUN_ALL

func handle_turn_holder_on() -> int:
	var holder: Holder = target
	if holder == null: return RUN_ALL
	holder.turn_on()
	return RUN_ALL

func handle_turn_holder_off() -> int:
	var holder: Holder = target
	if holder == null: return RUN_ALL
	holder.turn_off()
	return RUN_ALL

func handle_holder_choice() -> int:
	for holder_index in range(len(holders)):
		var holder := holders[holder_index]
		if holder.is_on(): return holder_index
	return len(holders)
