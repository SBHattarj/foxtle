extends Control

const MenuOption = preload("uid://cj4ygk70e7dhx")

const MenuOptionScene = preload("uid://c3h61eotbxnk6")

const OPEN_DATABASE_TEXT := "Open Database"
const SYSTEM_CONFIGURATION_TEXT := "System Configuration"
const BACK_TEXT := "Back"
const END_SESSION_TEXT := "End Session"

const base_menu_items: Array[String] = [
	OPEN_DATABASE_TEXT,
	SYSTEM_CONFIGURATION_TEXT,
	BACK_TEXT,
	END_SESSION_TEXT
]

@onready
var menu_items: VBoxContainer = $MenuItems
@onready
var first_redo_timer: Timer = $FirstRedoTimer
@onready
var redo_timer: Timer = $RedoTimer
@onready
var menu_animation: AnimationPlayer = $MenuAnimation

var even_block_handler := Signals.make_event_block_handler()

var option_map: Dictionary[String, Callable] = {
	OPEN_DATABASE_TEXT: _handle_open_database,
	SYSTEM_CONFIGURATION_TEXT: _handle_system_configuration,
	END_SESSION_TEXT: _handle_end_session
}

func populate_menu_items(items: Array[String]):
	for child in menu_items.get_children():
		child.queue_free()
	await get_tree().process_frame
	if len(items) < 1: return 
	for item in items:
		var option: MenuOption = MenuOptionScene.instantiate()
		option.text = item
		menu_items.add_child(option)
	(menu_items.get_child(0) as MenuOption).enabled = true

func _get_current_option() -> String:
	var option_count := menu_items.get_child_count()
	if option_count < 1:
		return ""
	for i in range(option_count):
		var option: MenuOption = menu_items.get_child(i)
		if option.enabled:
			return option.text
	var option_0: MenuOption = menu_items.get_child(0)
	option_0.enabled = true
	return option_0.text

func _ready() -> void:
	Signals.player_pressed_back.connect(run)

func run():
	if even_block_handler.is_blocked: return
	Signals.call_with_event_block(_run)

func _run():
	Signals.run_ui_audio("BackAudio")
	menu_animation.play("open_menu")
	await menu_animation.animation_finished
	await populate_menu_items(base_menu_items)
	Signals.player_direction_button_pressed.connect(_handle_direction_button)
	while true:
		var interact_type := await AsyncUtils.wait_any([
			func(): await Signals.player_interact,
			func(): await Signals.player_pressed_back
		])
		if interact_type == 1:
			break
		var current_option_text := _get_current_option()
		if current_option_text == "Back":
			break
		Signals.run_ui_audio("SelectAudio")
		var back_flag: bool = await option_map.get(current_option_text, func(): return true).call()
		if back_flag:
			break
	Signals.run_ui_audio("BackAudio")
	Signals.player_direction_button_pressed.disconnect(_handle_direction_button)
	await populate_menu_items([])
	menu_animation.play("menu_close")
	await menu_animation.animation_finished

func _handle_direction_button(direction: Signals.DirectionButtons, spawn_redo := true):
	var selected_index := 0
	var last_selected_option: MenuOption = null
	var option_count := menu_items.get_child_count()
	if option_count < 1:
		return
	for i in range(option_count):
		var option: MenuOption = menu_items.get_child(i)
		if option.enabled:
			last_selected_option = option
			selected_index = i
			break
	if last_selected_option == null:
		last_selected_option = menu_items.get_child(0)
	match direction:
		Signals.DirectionButtons.UP:
			selected_index += option_count-1
		Signals.DirectionButtons.DOWN:
			selected_index += 1
	Signals.run_ui_audio("CursorMoveAudio")
	if spawn_redo:
		_redo_direction(direction)
	selected_index %= option_count
	last_selected_option.enabled = false
	var selected_option: MenuOption = menu_items.get_child(selected_index)
	selected_option.enabled = true

func _redo_direction(direction: Signals.DirectionButtons):
	first_redo_timer.start()
	var redo_flag := await AsyncUtils.wait_any([
		func(): await first_redo_timer.timeout,
		func(): await Signals.wait_for_direction_released(direction)
	])
	if redo_flag != 0:
		return
	_handle_direction_button(direction, false)
	redo_timer.stop()
	redo_timer.start()
	while true:
		redo_flag = await AsyncUtils.wait_any([
			func(): await redo_timer.timeout,
			func(): await Signals.wait_for_direction_released(direction)
		])
		if redo_flag != 0:
			return
		_handle_direction_button(direction, false)


func _handle_open_database():
	Core.os_open_map_dir()
	return false

func _handle_end_session():
	get_tree().quit()
	return true

func _handle_system_configuration():
	await populate_menu_items([
		"Master Volume: %s%%" % roundi(Core.get_volume("Master")*100),
		"Music Volume: %s%%" % roundi(Core.get_volume("Music")*100),
		"SFX Volume: %s%%" % roundi(Core.get_volume("SFX")*100),
		"Back"
	])
	while true:
		var interact_flag := await AsyncUtils.wait_any([
			func(): await Signals.player_interact,
			func(): await Signals.player_pressed_back
		])
		if interact_flag == 1:
			break
		var current_option_text := _get_current_option()
		if current_option_text == "Back":
			break
		var type := current_option_text.split(" ")[0]
		Signals.run_ui_audio("SelectAudio")
		_handle_volume_change(type)
		_redo_volume_interact(type)
	await populate_menu_items(base_menu_items)
	Signals.run_ui_audio("BackAudio")
	return false

func _redo_volume_interact(type: String):
	first_redo_timer.start()
	var redo_flag := await AsyncUtils.wait_any([
		func(): await first_redo_timer.timeout,
		func(): await Signals.player_interact_released
	])
	if redo_flag == 1: return
	var current_option := _get_current_option()
	var new_type := current_option.split(" ")[0]
	if new_type != type: return
	_handle_volume_change(type)
	redo_timer.stop()
	redo_timer.start()
	while true:
		redo_flag = await AsyncUtils.wait_any([
			func(): await redo_timer.timeout,
			func(): await Signals.player_interact_released
		])
		if redo_flag == 1: return
		current_option = _get_current_option()
		new_type = current_option.split(" ")[0]
		if new_type != type: return
		_handle_volume_change(type)
		

const type_index_map: Dictionary[String, int] = {
	"Master": 0,
	"Music": 1,
	"SFX": 2
}

func _handle_volume_change(type: String):
	Signals.run_ui_audio("SelectAudio")
	var current_volume := Core.get_volume(type)
	var current_integer_value := roundi(current_volume * 100) + 1
	current_integer_value %= 101
	current_volume = current_integer_value/100.0
	Core.set_volume(type, current_volume)
	var option: MenuOption = menu_items.get_child(type_index_map[type])
	option.text = "%s Volume: %s%%" % [type, current_integer_value]
	Core.save_player()
