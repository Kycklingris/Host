class_name V1

func Exit():
	
	return;

class Lobby:
	extends Node
	var _internal: _LobbyInternalV1;

	enum State { NOT_INITIALIZED, FAILED, LOBBY_CREATED, LOBBY_SDP_SET }

	signal lobby_created;
	signal player_joined(player: V1.Player);

	var id: String:
		get:
			if self._internal != null && self._internal.id != null:
				return String(self._internal.id);
			printerr("Tried to access lobby variable \"id\" before initialization");
			return "";
		set(_value):
			pass;

	var game: String:
		get:
			if self._internal != null && self._internal.game != null:
				return String(self._internal.game);
			printerr("Tried to access lobby variable \"game\" before initialization");
			return "";
		set(_value):
			pass;


	var min_players: int:
		get:
			if self._internal != null && self._internal.min_players != null:
				return self._internal.min_players;
			printerr("Tried to access lobby variable \"min_players\" before initialization");
			return 0;
		set(_value):
			pass;


	var max_players: int:
		get:
			if self._internal != null && self._internal.max_players != null:
				return self._internal.max_players;
			printerr("Tried to access lobby variable \"max_players\" before initialization");
			return 0;
		set(_value):
			pass;


	var players: Array[V1.Player]:
		get:
			if self._internal != null && self._internal.players != null:
				return self._internal.players.duplicate(false);
			printerr("Tried to access lobby variable \"players\" before initialization");
			return [];
		set(_value):
			pass;


	var state: State:
		get:
			if self._internal != null && self._internal.current_state != null:
				return self._internal.current_state;
			printerr("Tried to access lobby variable \"state\" before initialization");
			return State.NOT_INITIALIZED;
		set(_value):
			pass;


	func _init(p_game: String, p_min_players: int, p_max_players: int, allow_audience: bool):
		self._internal = _LobbyInternalV1.new(p_game, p_min_players, p_max_players, allow_audience);
		self.add_child(self._internal);
		self._internal.player_joined.connect(func(player): self.player_joined.emit(player));
		self._internal.lobby_created.connect(func(): self.lobby_created.emit());
		return

	func start():
		self._internal.start();
		return;

class Player:
	extends Node
	var _internal: _PlayerInternalV1;
	
	enum State { CREATED, GATHERING_SDP, SET_SDP, POLLING, WAITING_FOR_CONNECTION, CONNECTED, FAILED }

	var username: String:
		get:
			if self._internal != null && self._internal.current_state == State.CONNECTED:
				return String(self._internal.username);
			printerr("Tried to access player variable \"username\" before initialization");
			return "";
		set(_value):
			pass;

	var root_element: V1.Element:
		get:
			if self._internal != null:
				return self._internal.root_element;
			printerr("Tried to access player variable \"username\" before initialization");
			return null;
		set(_value):
			pass;

	func _init(in_lobby_id: String, in_turn_username: String, in_turn_password: String, in_index: int):
		self._internal = _PlayerInternalV1.new(in_lobby_id, in_turn_username, in_turn_password, in_index, self);
		self.add_child(self._internal);
		return;

	func send_bytes(p_packet: PackedByteArray):
		self._internal._send_packet(p_packet);
		return;

class Element:
	extends RefCounted
	var _internal: _ElementInternalV1;

	signal Event(event, data);
	signal Bytes(data);

	func _init(tag: String,  properties: Dictionary = {}):
		self._internal = _ElementInternalV1.new(self, tag, properties);
		self._internal.Event.connect(func(event, data): self.Event.emit(event, data));
		self._internal.Bytes.connect(func(data): self.Bytes.emit(data));
		return;

	func add_children(children: Array[V1.Element]):
		self._internal.add_children(children);
		return;
		
	func set_attribute(attribute: String, value):
		self._internal.set_attribute(attribute, value);
		return;

#class Elems:
	
