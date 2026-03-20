@tool
extends CharacterBody2D
class_name CharacterBase

#region signals
signal interacted_by(other: CharacterBase)
signal velocity_changed(character: CharacterBase)
signal bump
#endregion
#region enums
enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}
#endregion
#region constants
const direction_interact_area_rotation_map: Dictionary[Direction, float] = {
	Direction.UP: 0.0,
	Direction.DOWN: PI,
	Direction.RIGHT: PI/2,
	Direction.LEFT: -PI/2
}
#endregion
#region onready
@onready
var interact_area: Area2D = $InteractArea
#endregion
#region exports
@export
var sprite: AnimatedSprite2D:
	set(val):
		if val == sprite: return
		sprite = val
		_ready_sprite()
@export
var controller: ControllerBase:
	set(val):
		if val == controller: return
		controller = val
		_ready_controller()

@export
var direction_animation_map: Dictionary[Direction, String] = {
	Direction.UP: "up",
	Direction.DOWN: "down",
	Direction.LEFT: "left",
	Direction.RIGHT: "right"
}

@export
var movement_animation_modifier: String = "walk"

@export
var direction: Direction = Direction.UP:
	set(val):
		if val == direction: return
		direction = val
		_handle_direction_change_interact_area()
		_handle_animation_change()
#endregion
#region methods
func _ready_controller() -> void:
	if controller == null: return
	controller.joystick_changed.connect(_handle_joystick_change)

func _ready_sprite() -> void:
	if sprite == null: return
	sprite.play(get_current_animation())

func _handle_direction_change_interact_area():
	if interact_area == null:
		return
	interact_area.rotation = direction_interact_area_rotation_map[direction]

func _handle_animation_change():
	if sprite == null: return
	sprite.play(get_current_animation())

func get_current_animation() -> String:
	var base_animation = direction_animation_map[direction]
	if not is_zero_approx(velocity.length()):
		base_animation += "_%s" % movement_animation_modifier
	
	return base_animation

var normal_speed := 100.0

func _handle_joystick_change(joystick: Vector2) -> void:
	velocity = joystick * normal_speed
	_handle_animation_change()
	_handle_direction()
	velocity_changed_emit(self)
func _handle_direction():
	if is_zero_approx(velocity.length()): return
	if not is_zero_approx(velocity.x):
		_handle_vertical_direction()
		return
	_handle_horizontal_direction()

func _handle_vertical_direction():
	if velocity.x > 0:
		direction = Direction.RIGHT
		return
	direction = Direction.LEFT

func _handle_horizontal_direction():
	if velocity.y > 0:
		direction = Direction.DOWN
		return
	direction = Direction.UP

func _physics_process(_delta: float) -> void:
	if is_zero_approx(velocity.length()): return
	if move_and_slide():
		_on_collison()

func _on_collison():
	for i in range(get_slide_collision_count()):
		var collison := get_slide_collision(i)
		if is_zero_approx(collison.get_normal().dot(velocity)):
			continue
		bump.emit()
		return

func get_target() -> CharacterBase:
	if not interact_area.has_overlapping_bodies(): return null
	for body in interact_area.get_overlapping_bodies():
		if body is not CharacterBase:
			continue
		return body
	return null

func velocity_changed_emit(character: CharacterBase):
	velocity_changed.emit(character)

func interacted_by_emit(other: CharacterBase):
	interacted_by.emit(other)

func delete_self():
	if is_inside_tree():
		# so that the character is removed immediately before being qued to be freed
		get_parent().remove_child(self)
	queue_free()
#endregion
