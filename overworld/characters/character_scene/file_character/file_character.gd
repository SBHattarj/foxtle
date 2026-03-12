@tool
extends CharacterBase
class_name FileCharacter

@export
var in_world_name := ""
@export
var appearance := 0:
	set(val):
		if val == appearance: return
		appearance = val
		set_sprite_frames()

func set_sprite_frames():
	if sprite == null: return
	sprite.sprite_frames = appearances[min(appearance, len(appearances)-1)]
@export
var appearances: Array[SpriteFrames] = []
@export
var dialogue_index := 0
@export
var dialogues: Array[FileCharacterDialogueHolder] = []
@export
var is_spawner := false

const APPEARANCE_OFFSET := 4
const APPEARANCE_SIZE := 1
const IN_WORLD_NAME_OFFSET := 3
const IN_WORLD_NAME_SIZE := 20

var binary_converter := make_binary_converter(
	func(): return global_position.x,
	func(val): global_position.x = val,
	func(): return global_position.y,
	func(val): global_position.y = val,
	func(): return direction,
	func(val): direction = val,
	func(): return in_world_name,
	func(val): in_world_name = val,
	func(): return appearance,
	func(val): appearance = val,
	func(): return dialogue_index,
	func(val): dialogue_index = val
)

static func dummy_getter():
	return

static func dummy_setter(_val):
	pass

static func make_binary_converter(
	position_x_getter := dummy_getter,
	position_x_setter := dummy_setter,
	position_y_getter := dummy_getter,
	position_y_setter := dummy_setter,
	direction_getter := dummy_getter,
	direction_setter := dummy_setter,
	in_world_name_getter := dummy_getter,
	in_world_name_setter := dummy_setter,
	appearance_getter := dummy_getter,
	appearance_setter := dummy_setter,
	dialogue_index_getter := dummy_getter,
	dialogue_index_setter := dummy_setter
) -> BinaryConverter:
	return BinaryConverter.new().add_part(
		BinaryConverter.Float.new(
			position_x_getter,
			position_x_setter
		)
	).add_part(
		BinaryConverter.Float.new(
			position_y_getter,
			position_y_setter
		)
	).add_part(
		BinaryConverter.U8.new(
			direction_getter,
			direction_setter
		)
	).add_part(
		BinaryConverter.UTF8String.new(
			in_world_name_getter,
			in_world_name_setter,
			IN_WORLD_NAME_SIZE
		)
	).add_part(
		BinaryConverter.U16.new(
			appearance_getter,
			appearance_setter
		)
	).add_part(
		BinaryConverter.U16.new(
			dialogue_index_getter,
			dialogue_index_setter
		)
	)

func _enter_tree() -> void:
	if Engine.is_editor_hint(): return
	if not is_spawner: return
	_spawn()
	delete_self.call_deferred()

func _spawn():
	if not Core.map_first_load:
		delete_self.call_deferred()
		return
	Core.load_file_character(name)
	_save()

var event_block_handler := Signals.make_event_block_handler()

func _ready() -> void:
	interacted_by.connect(_handle_interact)
	event_block_handler.full_unblock.connect(_save)
	set_sprite_frames()
	if Engine.is_editor_hint():
		return
	load_from_file()

func load_from_file():
	binary_converter.from_bytes(Core.get_file_character(name, binary_converter.length))

func _handle_interact(by: CharacterBase):
	if by is not Player: return
	if dialogue_index < len(dialogues):
		var result: int = await Signals.call_with_event_block(dialogues[dialogue_index].run)
		if result > 0:
			dialogue_index = result
	await Signals.call_with_event_block(_read_label)
func _save():
	Core.set_file_character(name, binary_converter.to_bytes())

func read_label():
	await Signals.call_with_event_block(_read_label)

func _read_label():
	await Signals.do_dialogue("[color={protag_color}]{protag_name}[/color]", "[color={protag_color}]I read its digital label.[/color]")
	await Signals.do_dialogue("[color={protag_color}]{protag_name}[/color]", "[color={protag_color}]%s; type %s; file name: %s[/color]" % [
		in_world_name,
		SharedVars.type_map.get(appearance, ""),
		name
	])
