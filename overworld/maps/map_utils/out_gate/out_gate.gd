extends Area2D
class_name OutGate

@export
var enter_directions: Array[CharacterBase.Direction] = [
	CharacterBase.Direction.UP
]
@export
var map: String
@export
var gate: int
@export
var is_disabled: bool

func _ready() -> void:
	body_entered.connect(_on_body_enter)
	body_exited.connect(_on_body_exited)

func _on_body_enter(body: Node2D):
	if is_disabled: return
	if body is not CharacterBase: return
	var character: CharacterBase = body
	if is_zero_approx(character.velocity.length()):
		_add_direction_change_handler(character)
		return
	if character.direction not in enter_directions:
		_add_direction_change_handler(character)
		return
	_handle_map_change(character)

func _add_direction_change_handler(character: CharacterBase):
	if character.velocity_changed.is_connected(_handle_character_direction_change):
		return
	character.velocity_changed.connect(_handle_character_direction_change)
func _remove_direction_change_handler(character: CharacterBase):
	if not character.velocity_changed.is_connected(_handle_character_direction_change):
		return
	character.velocity_changed.disconnect(_handle_character_direction_change)

func _handle_character_direction_change(character: CharacterBase):
	if is_disabled: return
	if is_zero_approx(character.velocity.length()): return
	if character.direction not in enter_directions: return
	_handle_map_change(character)

func _on_body_exited(body: Node2D):
	if body is not CharacterBase: return
	_remove_direction_change_handler(body)

func _handle_map_change(character: CharacterBase):
	_remove_direction_change_handler(character)
	if character is Player:
		_handle_player()
		return
	_handle_non_player_character(character)

func _handle_non_player_character(character: CharacterBase):
	character.delete_self()

func _handle_player():
	Signals.map_change_emit(map, gate)
