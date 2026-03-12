extends Holder
class_name GateHolder

@export
var gate: OutGate

func has_target() -> bool:
	if gate == null: return false
	return not gate.is_disabled

func _remove_target() -> void:
	if gate == null: return
	gate.is_disabled = true

func _restore_target() -> void:
	if gate == null: return
	gate.is_disabled = false
