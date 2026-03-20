@tool
extends MarginContainer
@onready
var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready
var label: Label = $Label


@export
var enabled: bool:
	set(val):
		if val == enabled: return
		enabled = val
		set_state_enabled_state()

func set_state_enabled_state():
	if animated_sprite_2d == null: return
	animated_sprite_2d.play("on" if enabled else "off")

@export_multiline()
var text: String:
	set(val):
		text = val
		if label == null: return
		label.text = val

func _ready() -> void:
	label.text = text
	set_state_enabled_state()
