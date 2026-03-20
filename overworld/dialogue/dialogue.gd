extends CanvasLayer

@onready
var dialogue_node: RichTextLabel = $Control/DialogueMargin/Dialogue

@onready
var name_node: RichTextLabel = $Control/NameMargin/Name
@onready
var dialogue_pointer: Sprite2D = $DialoguePointer

const AI_SOUND: AudioStream = preload("uid://d16m2bqeiteke")

@onready
var type_timer: Timer = $TypeTimer
@onready
var audio: AudioStreamPlayer = $AudioStreamPlayer

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

var parsed_dialogue := "":
	get():
		if dialogue_node == null: return ""
		return dialogue_node.get_parsed_text()

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
	dialogue: String,
	sound: AudioStream = AI_SOUND
):
	await queued_run.call(name, dialogue, sound)

func _run(
	chara_name: String,
	dialogue: String,
	sound: AudioStream = AI_SOUND
):
	if sound == null:
		sound = AI_SOUND
	dialogue_pointer.visible = false
	visible = true
	visible_characters = 0
	self.dialogue = dialogue.format(SharedVars.to_dict())
	character_name = chara_name.format(SharedVars.to_dict())
	type_timer.start()
	audio.stream = sound
	while visible_characters < max_characters:
		audio.pitch_scale = (ord(parsed_dialogue[visible_characters])+127.5)/255.0
		var wait_result := await AsyncUtils.wait_any([
			func(): await type_timer.timeout,
			func(): await Signals.player_interact
		])
		audio.stop()
		if wait_result == 1:
			Signals.run_ui_audio("SelectAudio")
			visible_characters = max_characters
			break
		visible_characters += 1
		audio.play()
	dialogue_pointer.visible = true
	type_timer.stop()
	audio.stop()
	await Signals.player_interact
	Signals.run_ui_audio("SelectAudio")
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
