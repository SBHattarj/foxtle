@tool
extends Node2D
class_name ControllerBase

signal joystick_changed(joystick: Vector2)

@export
var character: CharacterBase:
	set(val):
		character = val
		if character == null: return
		if character.controller == self: return
		character.controller = self

@export
var displacement_threshold := 8.0

func change_joystick(joystick: Vector2):
	joystick_changed.emit(joystick)

func interact():
	var target := character.get_target()
	if target == null: return
	target.interacted_by_emit(character)

func move_to(target: Node2D):
	var displacement := target.global_position - global_position
	while displacement.length() > displacement_threshold:
		change_joystick(displacement.normalized())
		await get_tree().process_frame
		if is_queued_for_deletion(): return
		displacement = target.global_position - global_position
	change_joystick(Vector2.ZERO)
