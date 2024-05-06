class_name Promise
extends RefCounted

signal completed

class QueuedSignal:
	var _signal: Signal;
	var callback: Callable;
	func _init(p_signal, p_callback):
		_signal = p_signal;
		callback = p_callback;
		_signal.connect(self._signal_emitted);
		return;
	func _signal_emitted():
		_signal.disconnect(self._signal_emitted);
		callback.call(self);
		return;

var _queued_signals: Array[QueuedSignal] = [];

func append(p_signal: Signal) -> Promise:
	_queued_signals.push_back(QueuedSignal.new(p_signal, self._signal_emitted));
	return self;

func _signal_emitted(source: QueuedSignal):
	_queued_signals.erase(source);
	if _queued_signals.size() <= 0:
		completed.emit();
	return;
