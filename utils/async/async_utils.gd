class_name AsyncUtils

class OptionalCallable:
	var callable: Callable = default_callable
	var is_callable:
		get():
			return callable != default_callable
	static func make_callable(callable: Callable) -> OptionalCallable:
		var c = OptionalCallable.new()
		c.callable = callable
		return c
	func default_callable():
		pass
	static func none() -> OptionalCallable:
		return OptionalCallable.new()
	func call_(...arg: Array[Variant]):
		if not is_callable: return
		return callable.callv(arg)
	func call_coroutine(...arg: Array[Variant]):
		if not is_callable: return
		return await callable.callv(arg)

class RunTogetherReturn:
	var results := []
	var timeout_result: Variant
	func _init(results: Array, timeout: Variant = null) -> void:
		self.results = results
		self.timeout_result = timeout
class RunTogether:
	var num_ran: int = 0
	var num_callables: int
	var results: Array[Variant]
	signal done(results: RunTogetherReturn)
	func done_emit(results: RunTogetherReturn):
		## Using call deferred so that even if the done is called immediately, it still get processed by await
		## without this, anything that doesn't take about a frame to process, might not end the await call, and the programe deadlocks
		done.emit.call_deferred(results)
	func _init(callables: Array[Callable], timeout := OptionalCallable.none()) -> void:
		num_callables = len(callables)
		if num_callables < 1:
			done_emit(RunTogetherReturn.new([]))
			return
		results = []
		results.resize(num_callables)
		for i in range(num_callables):
			run_async(callables[i], i)
		run_timeout(timeout)

	func run_timeout(timeout: OptionalCallable):
		if not timeout.is_callable: return
		var timeout_result = await timeout.call_coroutine()
		done_emit(RunTogetherReturn.new(results, timeout_result))
	
	func run_async(callable: Callable, index: int):
		var result = await callable.call()
		results[index] = result
		num_ran += 1
		if num_ran < num_callables: return
		done_emit(RunTogetherReturn.new(results))

static func run_together(callables: Array[Callable], timeout := OptionalCallable.none()) -> RunTogetherReturn:
	return await RunTogether.new(callables, timeout).done

class WaitAny:
	signal done(index: int)
	func done_emit(index: int):
		## Using call deferred so that even if the done is called immediately, it still get processed by await
		## without this, anything that doesn't take about a frame to process, might not end the await call, and the programe deadlocks
		done.emit.call_deferred(index)
	func _init(callables: Array[Callable]) -> void:
		if len(callables) < 1:
			done_emit(-1)
			return
		for i in range(len(callables)):
			call_runner(callables[i], i)
	func call_runner(callable: Callable, index: int):
		await callable.call()
		done_emit(index)
static func wait_any(callables: Array[Callable]) -> int:
	return await WaitAny.new(callables).done
