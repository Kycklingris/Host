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
		return

	func start():
		self._internal.start();
		return;

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
	extends Node2D

	signal Event(event, data);
	signal Bytes(data);

	func _init(tag: String,  attributes: Dictionary = {}, children: Array[V1.Element] = []):
		return;
		
	func set_attribute(attribute: String, value):
		return;
	
	#=========================================================================#
	# Custom Elements                                                         #
	#=========================================================================#
	
	#class GridElement:
		#extends V1.Element
		#var rows: int:
			#get:
				#return rows;
			#set(value):
				#rows = value;
				#pass;
				#
		#var columns: int:
			#get:
				#return columns;
			#set(value):
				#columns = value;
				#pass;
		#
		#func _init(num_rows: int, num_columns: int, attributes: Dictionary = {}, children: Array[V1.Element] = []):
			#return;
	#
	#
	#class JoystickElement:
		#extends V1.Element
		#var x: float:
			#get:
				#return x;
			#set(_value):
				#printerr("Tried to assign a value to Joystick.x which is not allowed.");
				#return;
		#var y: float:
			#get:
				#return y;
			#set(_value):
				#printerr("Tried to assign a value to Joystick.y which is not allowed.");
				#return;
		#
		#func _init(keyboard_inputs: Dictionary = { "up": [], "left": [], "down": [], "right": [] }, attributes: Dictionary = {}, children: Array[V1.Element] = []):
			#return;
		#
		#func set_keyboard_input(keyboard_inputs: Dictionary = { "up": [], "left": [], "down": [], "right": [] }):
			#return;
		#
		#
	#class ButtonElement:
		#extends V1.Element
		#
		#signal Down();
		#signal Up();
		#signal Pressed();
		#
		#func _init(text: String = "", keyboard_inputs: Array[String] = [], attributes: Dictionary = {}, children: Array[V1.Element] = []):
			#return;
		#
		#func set_text(text: String = ""):
			#return;
		#
		#func set_keyboard_inputs(keyboard_inputs: Array[String] = []):
			#return;
