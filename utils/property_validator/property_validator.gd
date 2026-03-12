@tool
class_name PropertyValidator
class ValidatorPart:
	var field: Callable
	var condition: Callable
	var transform := default_transform
	func default_transform(_property: Dictionary): return
	func _init(field: Callable, condition: Callable, transform := default_transform):
		self.field = field
		self.condition = condition
		self.transform = transform
	func validate(property: Dictionary):
		if not self.field.call(property.name): return
		self.transform.call(property)
		if self.condition.call():
			return
		property.usage = PROPERTY_USAGE_NO_EDITOR

var validator_part: Array[ValidatorPart]
func add(part: ValidatorPart) -> PropertyValidator:
	self.validator_part.append(part)
	return self
func validate(property: Dictionary):
	for part in validator_part:
		part.validate(property)
