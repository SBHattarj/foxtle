@tool
extends Control
class_name VarticalTiller

@onready
var start_texture: TextureRect = $StartTexture
@onready
var end_texture: TextureRect = $EndTexture
@onready
var mid_texture: TextureRect = $MidTextureContainer/MidTexture
@onready
var mid_texture_container: MarginContainer = $MidTextureContainer


@export
var start_tile: Texture2D
@export
var mid_tile: Texture2D
@export
var end_tile: Texture2D

@export
var target: Control:
	set(val):
		if target == null:
			target = val
			_on_target_changed()
			return
		if target.resized.is_connected(_on_target_changed):
			target.resized.disconnect(_on_target_changed)
		target = val
		_on_target_changed()

func texture_size_sorter(a: Texture2D, b: Texture2D):
	return a.get_width() > b.get_width()

func _ready() -> void:
	_on_target_changed()

func _on_target_changed():
	if not is_node_ready() or target == null:
		return
	if not target.resized.is_connected(_on_target_changed):
		target.resized.connect(_on_target_changed)
	custom_minimum_size = target.size
	size = custom_minimum_size
	if start_tile != null:
		start_texture.texture = start_tile
		start_texture.size = start_tile.get_size()
		mid_texture_container.add_theme_constant_override("margin_left", ceili(start_texture.size.x))
	else:
		start_texture.texture = null
		start_texture.size = Vector2.ZERO
		mid_texture_container.add_theme_constant_override("margin_left", 0)
	if end_tile != null:
		end_texture.texture = end_tile
		end_texture.size = end_tile.get_size()
		mid_texture_container.add_theme_constant_override("margin_right", ceili(end_texture.size.x))
	else:
		end_texture.texture = null
		end_texture.size = Vector2.ZERO
		mid_texture_container.add_theme_constant_override("margin_right", 0)
	if mid_tile == null:
		custom_minimum_size.x = max(custom_minimum_size.x, start_texture.size.x+end_texture.size.x)
		size.x = custom_minimum_size.x
		return
	if is_zero_approx(target.size.x):
		mid_texture.texture = null
		custom_minimum_size.x = max(custom_minimum_size.x, start_texture.size.x+end_texture.size.x)
		size.x = custom_minimum_size.x
		return
	var texture_width := mid_tile.get_width()
	var num_textures := ceili(target.size.x/texture_width)
	var mid_tile_width := num_textures*texture_width
	mid_texture.texture = mid_tile
	mid_texture.size = Vector2(mid_tile_width, mid_tile.get_height())
	custom_minimum_size.x = max(custom_minimum_size.x, start_texture.size.x+mid_tile_width+end_texture.size.x)
	size.x = custom_minimum_size.x
