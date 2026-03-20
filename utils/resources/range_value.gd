extends Resource
class_name RangeValue

@export
var low: float = 0

@export
var high: float = 1:
	set(val):
		high = max(val, low)
