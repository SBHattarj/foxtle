@tool
extends Node
signal changed(name: String)

func changed_emit(name: String):
	changed.emit(name)

var type_map: Dictionary[int, String] = {
	0: "Cooler",
	1: "Graphics",
	2: "Memory",
	3: "Power",
	4: "Processing"
}

@export
var protag_name := "Arew"

@export
var protag_color := color_to_hex(Color("14fffcff"))
@export
var info_color := color_to_hex(Color("dfe089ff"))
@export
var file_color := color_to_hex(Color("edcd3bff"))
@export
var error_color := color_to_hex(Color("db6b5aff"))
@export
var success_color := color_to_hex(Color("83ed4eff"))

func color_to_hex(color: Color, with_alpha = false) -> String:
	return "#" + color.to_html(with_alpha)

func _set(property: StringName, value: Variant) -> bool:
	if value == get(property): return false
	changed_emit(property)
	return false

func sanitize_for_bbcode(val: Variant) -> Variant:
	if val is not String: return val
	var text: String = val
	return text.replace("[", "[​")

func to_dict() -> Dictionary[String, Variant]:
	var props: Dictionary[String, Variant] = {}
	for prop in get_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE): continue
		if not (prop.usage & PROPERTY_USAGE_EDITOR): continue
		props[prop.name] = sanitize_for_bbcode(get(prop.name))
	return props

func get_settable_strings() -> Array[String]:
	var props: Array[String] = []
	for prop in get_property_list():
		if (prop.usage & PROPERTY_USAGE_READ_ONLY): continue
		if prop.type != TYPE_STRING: continue
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE): continue
		if not (prop.usage & PROPERTY_USAGE_EDITOR): continue
		props.append(prop.name)
	return props


func get_flags() -> Array[String]:
	var props: Array[String] = []
	for prop in get_property_list():
		if not (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE): continue
		if prop.type != TYPE_BOOL: continue
		props.append(prop.name)
	return props
