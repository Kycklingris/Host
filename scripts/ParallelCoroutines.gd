class_name ParallelCoroutines
extends RefCounted

## Emitted when all coroutines have completed from run_all()
signal completed

class QueuedCoroutine:
	var coroutine:Callable;
	var parameters:Array;
	var callback:Callable;
	func _init(p_coroutine, p_parameters, p_callback):
		coroutine = p_coroutine;
		parameters = p_parameters;
		callback = p_callback;

var _queued_coroutines:Array[QueuedCoroutine] = [];
var _total_count:int = 0;
var _completed_count:int = 0;

## Each coroutine that completes will have its result added to results.
## await completed to ensure all results are present.
## results will contain null values for coroutines with no return value.
var results:Array = [];

func _default_callback(_result):
	pass;
	
## Adds a coroutine to be started when run_all() is called.
## coroutine must be an asynchronous method i.e. it must call await at least once.
## callback can be provided if you wish to immediately act upon coroutine's completion.
## callback will be called with the result returned by coroutine.
## If coroutine does not return a value, the result will be null.
func append(coroutine:Callable, parameters: Array = [], callback:Callable = _default_callback) -> ParallelCoroutines:
	_queued_coroutines.append(QueuedCoroutine.new(coroutine, parameters, callback));
	return self;

## Runs all coroutines added by append in parallel.
## returns completed Signal as a convenience.
## You may await completed or this method.
func run_all() -> Signal:
	_total_count = _queued_coroutines.size();
	for _queued in _queued_coroutines:
		_run(_queued);
	return completed;
	
func _run(routine:QueuedCoroutine) -> void:
	var result = await routine.coroutine.callv(routine.parameters);
	results.append(result);
	routine.callback.call(result);
	_on_completed();

func _on_completed() -> void:
	_completed_count += 1;
	if _completed_count >= _total_count:
		completed.emit();
