class_name V1

func Exit():
	
	return;

class Lobby:
	extends Node

	enum State { NOT_INITIALIZED, FAILED, LOBBY_CREATED, LOBBY_SDP_SET }

	signal lobby_created;
	signal player_joined(player: V1.Player);

	var id: String:
		get:
			return "";
		set(_value):
			pass;

	var game: String:
		get:
			return "";
		set(_value):
			pass;


	var min_players: int:
		get:
			return 0;
		set(_value):
			pass;


	var max_players: int:
		get:
			return 0;
		set(_value):
			pass;


	var players: Array[V1.Player]:
		get:
			return [];
		set(_value):
			pass;


	var state: State:
		get:
			return State.NOT_INITIALIZED;
		set(_value):
			pass;


	func _init(p_game: String, p_min_players: int, p_max_players: int, allow_audience: bool):
		pass

	func start():
		pass;

class Player:
	extends Node
	
	enum State { CREATED, GATHERING_SDP, SET_SDP, POLLING, WAITING_FOR_CONNECTION, CONNECTED, FAILED }

	var username: String:
		get:
			return "";
		set(_value):
			pass;

	var root_element: V1.Element:
		get:
			return null;
		set(_value):
			pass;

	func _init(in_lobby_id: String, in_turn_username: String, in_turn_password: String, in_index: int):
		return;

	func send_bytes(p_packet: PackedByteArray):
		return;

class Element:
	extends RefCounted

	signal Event(event, data);
	signal Bytes(data);

	func _init(tag: String,  properties: Dictionary = {}):
		return;

	func add_children(children: Array[V1.Element]):
		return;
		
	func set_attribute(attribute: String, value):
		return;

#class Elems:
	
