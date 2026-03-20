@tool
extends Node

class IdGenerator:
	var next_id: int = 0
	var free_ids: Set = Set.new()
	func get_id() -> int:
		if free_ids.is_empty():
			var current_id := next_id
			next_id += 1
			return current_id
		var id: int = free_ids.values()[0]
		free_ids.delete(id)
		return id
	func return_id(id: int):
		free_ids.add(id)
class IdAwaiter:
	signal id_await(arg: Array)
	var search_id: int
	var id_index: int
	var s: Signal
	func _init(s: Signal, search_id: int, id_index: int):
		self.s = s
		self.search_id = search_id
		self.id_index = id_index
		s.connect(id_await_caller)

	func id_await_caller(...arg):
		var id = arg[id_index]
		if id != search_id: return
		s.disconnect(id_await_caller)
		arg.remove_at(id_index)
		id_await.emit(arg)

class BlockHandler:
	var block_ids := Set.new()
	var is_blocked: bool:
		get(): return not block_ids.is_empty()
	signal full_unblock
	signal on_block
	func _init(block_signal: Signal, unblock_signal: Signal):
		block_signal.connect(_on_block)
		unblock_signal.connect(_on_unblock)
	func _on_block(id: int):
		if block_ids.is_empty():
			on_block.emit()
		block_ids.add(id)
	func _on_unblock(id: int):
		block_ids.delete(id)
		if not block_ids.is_empty(): return
		full_unblock.emit()
	func wait_for_unblock() -> void:
		if not is_blocked: return
		await full_unblock
	func force_unblock() -> void:
		if not is_blocked: return
		block_ids.clear()
		full_unblock.emit()

func call_with_block(c: Callable, block_signal: Signal, unblock_signal: Signal):
	var id := global_id_generator.get_id()
	block_signal.emit(id)
	var result = await c.call()
	unblock_signal.emit(id)
	return result
	
class RegisterableAsyncQueue:
	var ids := Set.new()
	var last_id := -1
	signal end_signal(id)
	signal next_start
	var has_item: bool:
		get(): return not ids.is_empty()
	func wait_queue(id: int):
		if not has_item:
			ids.add(id)
			last_id = id
			return
		var current_last_id = last_id
		ids.add(id)
		last_id = id
		await Signals.wait_for_id(end_signal, current_last_id)
	func register(c: Callable) -> Callable:
		var wrapper := func(...args):
			var id := Signals.global_id_generator.get_id()
			await wait_queue(id)
			next_start.emit()
			var result = await c.callv(args)
			end_signal.emit(id)
			ids.delete(id)
			Signals.global_id_generator.return_id(id)
			return result
		return wrapper


func wait_for_id(s: Signal, id: int, id_index: int = 0) -> Array[Variant]:
	return await IdAwaiter.new(s, id, id_index).id_await

var global_id_generator := IdGenerator.new()

func register_ided_handler(c: Callable, starter: Signal, start_id_location: int, ender: Signal, returns_value: bool):
	var wrapper = func(...args):
		var id: int = args[start_id_location]
		args.remove_at(start_id_location)
		var result = await c.callv(args)
		await get_tree().process_frame
		if not returns_value:
			ender.emit(id)
			return
		ender.emit(id, result)
	starter.connect(wrapper)
	return wrapper

func register_object_ided_handler(c: Callable, starter: Signal, start_id_location: int, ender: Signal, returns_value: bool):
	var wrapper = func(...args):
		var id_obj: Object = args[start_id_location]
		var result = await c.callv(args)
		await get_tree().process_frame
		if not returns_value:
			ender.emit(id_obj.get_instance_id())
			return
		ender.emit(id_obj.get_instance_id(), result)
	starter.connect(wrapper)
	return wrapper


signal player_interact
signal player_interact_continouse
signal player_interact_released
signal player_pressed_back

enum DirectionButtons {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

signal player_direction_button_pressed(button: DirectionButtons)

func player_direction_button_pressed_emit(button: DirectionButtons):
	player_direction_button_pressed.emit(button)

signal player_direction_button_released(button: DirectionButtons)

func player_direction_button_released_emit(button: DirectionButtons):
	player_direction_button_released.emit(button)

const action_button_map: Dictionary[String, DirectionButtons] = {
	"up": DirectionButtons.UP,
	"down": DirectionButtons.DOWN,
	"left": DirectionButtons.LEFT,
	"right": DirectionButtons.RIGHT
}

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if event.is_action_pressed("interact"):
		player_interact.emit()
	if event.is_action("interact"):
		player_interact_continouse.emit()
	if event.is_action_released("interact"):
		player_interact_released.emit()
	if event.is_action_pressed("back"):
		player_pressed_back.emit()
	for action in action_button_map:
		if event.is_action_pressed(action):
			player_direction_button_pressed_emit(action_button_map[action])
		if event.is_action_released(action):
			player_direction_button_released_emit(action_button_map[action])

func wait_for_direction_released(direction):
	await wait_for_id(player_direction_button_released, direction)

signal dialogue_start(id: int, name: String, dialogue: String, audio: AudioStream)

func dialogue_start_emit(id: int, name: String, dialogue: String, audio: AudioStream = null):
	dialogue_start.emit(id, name, dialogue, audio)

signal dialogue_end(id: int)

func register_dialogue(c: Callable):
	register_ided_handler(c, dialogue_start, 0, dialogue_end, false)

func do_dialogue(name: String, dialogue: String, audio: AudioStream = null):
	var id := global_id_generator.get_id()
	dialogue_start_emit(id, name, dialogue, audio)
	await wait_for_id(dialogue_end, id)
	global_id_generator.return_id(id)

signal event_block(event_id: int)

func event_block_emit(event_id: int):
	event_block.emit(event_id)

signal event_unblock(event_id: int)

func event_unblock_emit(event_id: int):
	event_unblock.emit(event_id)

func call_with_event_block(c: Callable):
	return await call_with_block(c, event_block, event_unblock)

signal event_full_unblock_signal
func event_full_unblock():
	event_full_unblock_signal.emit()

func make_event_block_handler() -> BlockHandler:
	var handler := BlockHandler.new(event_block, event_unblock)
	event_full_unblock_signal.connect(handler.force_unblock)
	return handler

signal map_change(map: String, gate_id: int)

func map_change_emit(map: String, gate_id: int):
	map_change.emit(map, gate_id)

signal map_transition_start_start(id: int)

func map_transition_start_start_emit(id: int):
	map_transition_start_start.emit(id)

signal map_transition_start_end(id: int)

func map_transition_start_end_emit(id: int):
	map_transition_start_end.emit(id)

func register_map_transition_start(c: Callable):
	register_ided_handler(c, map_transition_start_start, 0, map_transition_start_end, false)

func do_map_transition_start():
	var id := global_id_generator.get_id()
	map_transition_start_start_emit(id)
	await Signals.wait_for_id(map_transition_start_end, id)
	global_id_generator.return_id(id)

signal map_transition_end_start(id: int)
func map_transition_end_start_emit(id: int):
	map_transition_end_start.emit(id)

signal map_transition_end_end(id: int)
func map_transition_end_end_emit(id: int):
	map_transition_end_end.emit(id)

func register_map_transition_end(c: Callable):
	register_ided_handler(c, map_transition_end_start, 0, map_transition_end_end, false)

func do_map_transition_end():
	var id := global_id_generator.get_id()
	map_transition_end_start_emit(id)
	await Signals.wait_for_id(map_transition_end_end, id)
	global_id_generator.return_id(id)

signal show_map_name_signal
func show_map_name():
	show_map_name_signal.emit()

signal run_ui_audio_signal(name: String)

func run_ui_audio(name: String):
	run_ui_audio_signal.emit(name)

signal change_bgm_signal(stream: AudioStream, ease_duration: float)

func change_bgm(stream: AudioStream, ease_duration: float = 0.5):
	change_bgm_signal.emit(stream, ease_duration)
	
signal map_initialised

func map_initialised_emit():
	map_initialised.emit()
