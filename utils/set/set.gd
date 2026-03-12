class_name Set


var _values: Dictionary = {}

func add(value):
	_values[value] = null

func delete(value):
	_values.erase(value)

func has(value) -> bool:
	return _values.has(value)

func is_empty() -> bool:
	return _values.is_empty()

func values() -> Array:
	return _values.keys()

func clear():
	_values.clear()
