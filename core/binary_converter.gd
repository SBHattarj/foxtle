class_name BinaryConverter

@abstract
class Part:
	var _getter: Callable
	var _setter: Callable
	var length: int
	func _init(getter: Callable, setter: Callable) -> void:
		_getter = getter
		_setter = setter
	func getter() -> Variant:
		return _getter.call()
	func setter(val: Variant) -> void:
		_setter.call(val)
	func to_bytes(bytes: PackedByteArray, offset: int) -> void:
		if len(bytes) <= (offset+length):
			bytes.resize(offset+length)
	@abstract
	func from_byte(bytes: PackedByteArray, offset: int) -> void

class U8 extends Part:
	const size = 1
	func _init(getter: Callable, setter: Callable) -> void:
		super(getter, setter)
		length = size
	func to_bytes(bytes: PackedByteArray, offset: int):
		super(bytes, offset)
		bytes.encode_u8(offset, getter())
	func from_byte(bytes: PackedByteArray, offset: int) -> void:
		setter(bytes.decode_u8(offset))
class U16 extends Part:
	const size = 2
	func _init(getter: Callable, setter: Callable) -> void:
		super(getter, setter)
		length = size
	func to_bytes(bytes: PackedByteArray, offset: int):
		super(bytes, offset)
		bytes.encode_u16(offset, getter())
	func from_byte(bytes: PackedByteArray, offset: int) -> void:
		setter(bytes.decode_u16(offset))
class U32 extends Part:
	const size = 4
	func _init(getter: Callable, setter: Callable) -> void:
		super(getter, setter)
		length = size
	func to_bytes(bytes: PackedByteArray, offset: int):
		super(bytes, offset)
		bytes.encode_u32(offset, getter())
	func from_byte(bytes: PackedByteArray, offset: int) -> void:
		setter(bytes.decode_u32(offset))
class Float extends Part:
	const size = 4
	func _init(getter: Callable, setter: Callable) -> void:
		super(getter, setter)
		length = size
	func to_bytes(bytes: PackedByteArray, offset: int):
		super(bytes, offset)
		bytes.encode_float(offset, getter())
	func from_byte(bytes: PackedByteArray, offset: int) -> void:
		setter(bytes.decode_float(offset))

class U8Array extends Part:
	func _init(getter: Callable, setter: Callable, length: int) -> void:
		super(getter, setter)
		self.length = length * U8.size
	func to_bytes(bytes: PackedByteArray, offset: int):
		super(bytes, offset)
		var values: Array = getter()
		for i in range(length/U8.size):
			if len(values) <= i:
				bytes.encode_u8(offset+i, 0)
				continue
			bytes.encode_u8(offset+i, values[i])
	func from_byte(bytes: PackedByteArray, offset: int) -> void:
		var arr: Array[int] = []
		for i in range(length/U8.size):
			arr.append(bytes.decode_u8(offset+i))
		setter(arr)

class UTF8String extends Part:
	func _init(getter: Callable, setter: Callable, length: int) -> void:
		super(getter, setter)
		self.length = length * U8.size
	func to_bytes(bytes: PackedByteArray, offset: int):
		super(bytes, offset)
		var values: String = getter()
		for i in range(length/U8.size):
			if len(values) <= i:
				bytes.encode_u8(offset+i, 0)
				continue
			bytes.encode_u8(offset+i, values.unicode_at(i))
	func from_byte(bytes: PackedByteArray, offset: int) -> void:
		var string := ""
		for i in range(length/U8.size):
			var value := bytes.decode_u8(offset+i)
			if value == 0: break
			string += char(value)
		setter(string)

var parts: Array[Part] = []
var offset := 0
var length: int:
	get():
		var _length = 0
		for part in parts:
			_length += part.length
		return _length
func add_part(part: Part) -> BinaryConverter:
	parts.append(part)
	return self
func to_bytes() -> PackedByteArray:
	var offset := self.offset
	var bytes := PackedByteArray()
	bytes.resize(length)
	for part in parts:
		part.to_bytes(bytes, offset)
		offset += part.length
	return bytes
func from_bytes(bytes: PackedByteArray) -> bool:
	var offset := self.offset
	if len(bytes) < (length+offset):
		return false
	for part in parts:
		part.from_byte(bytes, offset)
		offset += part.length
	return true
