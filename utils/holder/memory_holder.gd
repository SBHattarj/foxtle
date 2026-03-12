extends Holder
class_name MemoryHolder

@export
var terminal: TerminalCharacter

@export
var target: Holder:
	set(val):
		if target == val: return
		if target != null:
			target.changed.disconnect(changed.emit)
		target = val
		if target == null: return
		target.changed.connect(changed.emit)

var binary_converter := BinaryConverter.new().add_part(
	BinaryConverter.U8.new(
		is_on,
		change_state
	)
)

var event_block_handler := Signals.make_event_block_handler()

func _ready():
	event_block_handler.full_unblock.connect(save)
	if terminal.is_log_first_load():
		save()
		return
	binary_converter.from_bytes(terminal.get_log(get_instance_id(), binary_converter.length))

func save():
	terminal.save_log(get_instance_id(), binary_converter.to_bytes())

func has_target() -> bool:
	if target == null: return false
	return target.is_on()

func _remove_target() -> void:
	if target == null: return
	target.turn_off()

func _restore_target() -> void:
	if target == null: return
	target.turn_on()
