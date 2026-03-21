extends Resource
class_name FileCharacterDialogueHolder

@export_multiline
var character_name: String

@export_multiline
var dialogue: String
@export
var sound: AudioStream = null

@export
var next_dialogue: FileCharacterDialogueHolder
@export
var return_value: int = -1

func run():
	await Signals.do_dialogue(character_name, dialogue, sound)
	if next_dialogue == null: return
	await next_dialogue.run()
	return return_value
