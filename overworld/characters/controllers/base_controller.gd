@tool
extends Node2D
class_name ControllerBase

signal joystick_changed(joystick: Vector2)

@export
var character: CharacterBase

func change_joystick(joystick: Vector2):
	joystick_changed.emit(joystick)

func interact():
	var target := character.get_target()
	if target == null: return
	target.interacted_by_emit(character)
