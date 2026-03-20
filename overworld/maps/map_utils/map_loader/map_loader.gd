extends Node2D

@onready
var map_holder: Node2D = $MapHolder

@export
var maps: Dictionary[String, PackedScene] = {}

@export
var default_map: String

@export
var player: Player

func _ready() -> void:
	Signals.map_change.connect(change_map)
	if player.current_map in maps:
		add_map(player.current_map)
		return
	change_map(default_map, 0, false)

func add_map(name: String) -> Map:
	if name not in maps:
		name = default_map
	Core.load_map(name)
	var map_scene := maps.get(name) as PackedScene
	var map: Map = map_scene.instantiate()
	for child in map_holder.get_children():
		child.queue_free()
	await get_tree().process_frame
	map_holder.add_child(map)
	return map

func change_map(name: String, gate: int, transition := true):
	if name not in maps:
		name = default_map
	await Signals.call_with_event_block(_change_map.bind(name, gate, transition))
func _change_map(name: String, gate: int, transition := true):
	if transition:
		await Signals.do_map_transition_start()
	player.teleport(Vector2.ZERO)
	var map := await add_map(name)
	player.current_map = name
	var chosen_gate := map.in_gates[clampi(gate, 0, len(map.in_gates)-1)]
	player.direction = chosen_gate.direction
	player.teleport(chosen_gate.global_position)
	if transition:
		await Signals.do_map_transition_end()
	Signals.show_map_name()
	Signals.event_full_unblock()
	await get_tree().process_frame
	Signals.map_initialised_emit()
