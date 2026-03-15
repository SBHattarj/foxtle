class_name RandomUtils

static func random_string(
	min_size: int = 1,
	max_size: int = 10,
	characters: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
) -> String:
	max_size = max(max_size, 1)
	min_size = clamp(min_size, 1, max_size)
	var size := randi_range(min_size, max_size)
	var result := ""
	for _i in range(size):
		result += characters[randi_range(0, len(characters)-1)]
	return result
