@abstract
extends Node2D
class_name Holder

signal changed

enum OnState {
	HAVE_TARGET,
	NO_TARGET
}

var can_change := true

@export
var on_state: OnState = OnState.HAVE_TARGET

@abstract
func has_target() -> bool

@abstract
func _remove_target() -> void

@abstract
func _restore_target() -> void

func remove_target() -> void:
	if not has_target(): return
	can_change = false
	_remove_target()
	changed.emit()
	can_change = true
func restore_target() -> void:
	if has_target(): return
	can_change = false
	_restore_target()
	changed.emit()
	can_change = true

func is_on() -> bool:
	match on_state:
		OnState.HAVE_TARGET:
			return has_target()
		OnState.NO_TARGET:
			return not has_target()
	return has_target()

func turn_on():
	match on_state:
		OnState.HAVE_TARGET:
			restore_target()
			return
		OnState.NO_TARGET:
			remove_target()
			return
	restore_target()

func turn_off():
	match on_state:
		OnState.HAVE_TARGET:
			remove_target()
			return
		OnState.NO_TARGET:
			restore_target()
			return
	remove_target()

func change_state(is_on: bool):
	if is_on:
		turn_on()
		return
	turn_off()

func _internal_change():
	if not can_change: return
	changed.emit()
