extends CanvasLayer

@onready
var dialogue_node: RichTextLabel = $Control/DialoguePanel/MarginContainer/Dialogue

@onready
var name_node: RichTextLabel = $Control/Panel/MarginContainer/Name

@onready
var type_timer: Timer = $TypeTimer

@export
var type_speed := 100.0:
	set(val):
		type_speed = val
		if type_timer == null: return
		type_timer.wait_time = 1.0/val

var dialogue := "":
	set(val):
		dialogue = val
		if dialogue_node == null: return
		dialogue_node.text = val

var character_name := "":
	set(val):
		character_name = val
		if name_node == null: return
		name_node.text = val

var visible_characters:
	get():
		if dialogue_node == null: return 0
		return dialogue_node.visible_characters
	set(val):
		if dialogue_node == null: return
		dialogue_node.visible_characters = val

var max_characters:
	get():
		if dialogue_node == null: return 0
		return dialogue_node.get_total_character_count()

var run_async_queue := Signals.RegisterableAsyncQueue.new()
var queued_run := run_async_queue.register(_run)

func _ready() -> void:
	type_timer.wait_time = 1.0/type_speed
	dialogue_node.text = dialogue
	name_node.text = character_name
	Signals.register_dialogue(run)

func run(
	name: String,
	dialogue: String
):
	await queued_run.call(name, dialogue)

func _run(
	chara_name: String,
	dialogue: String
):
	visible = true
	visible_characters = 0
	self.dialogue = dialogue.format(SharedVars.to_dict())
	character_name = chara_name.format(SharedVars.to_dict())
	type_timer.start()
	while visible_characters < max_characters:
		var wait_result := await AsyncUtils.wait_any([
			func(): await type_timer.timeout,
			func(): await Signals.player_interact
		])
		if wait_result == 1:
			visible_characters = max_characters
			break
		visible_characters += 1
	type_timer.stop()
	await Signals.player_interact
	handle_dialogue_hide()

func handle_dialogue_hide():
	var result := await AsyncUtils.wait_any([
		func(): await Core.wait_frames(2),
		func(): await run_async_queue.next_start
	])
	if result == 1:
		return
	dialogue = ""
	character_name = ""
	visible = false
