class_name Lobby extends Node

signal lobby_created;
signal player_joined(player: Player);

@export var id: String;
@export var players: Array[Player];
@export var started: bool = false;
@export var max_players: int = 0;
@export var min_players: int = 0;

var PlayerPreload = preload("res://scripts/Player.gd");

var placeholder_players: Array[Player];
var current_sdp_ready_count: int = 0;
var turn_password: String = "";

enum LobbyState { NOT_INITIALIZED, FAILED, LOBBY_CREATED, LOBBY_SDP_SET }
var current_state: LobbyState = LobbyState.NOT_INITIALIZED;

var http_request: HTTPRequest = null;

var polling = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	http_request = HTTPRequest.new();
	self.add_child(http_request);
	
	return;

func new_lobby(game: String, maxPlayers: int, minPlayers: int):
	#=========================================================================#
	# Send "Create Lobby" request to the Web Server.
	#=========================================================================#
	http_request.request($"/root/Globals".CreateHTTPRequest(
		$"/root/Globals".api_url, 
		"/api/Lobby/New", 
		[
			{ "name": "game", "value": game }, 
			{ "name": "minPlayers", "value": str(minPlayers) }, 
			{ "name": "maxPlayers", "value": str(maxPlayers) }
		]), 
		["accept: text/plain", "Content-Type: text/plain"], 
		HTTPClient.METHOD_POST
	);
	
	var result = await http_request.request_completed; 
	
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		push_error("Lobby could not be created.");
		return;

	var body_string = result[3].get_string_from_utf8();
	var response_json = JSON.new();
	var error = response_json.parse(body_string);
	if error != OK:
		current_state = LobbyState.FAILED;
		push_error(
			"JSON Parse Error: ", 
			response_json.get_error_message(), 
			" in ", 
			body_string, 
			" at line ", 
			response_json.get_error_line()
		);
		return;
	
	var response = response_json.get_data();
	
	id = response["id"];
	turn_password = response["turnPassword"];
	max_players = response["maxPlayers"];
	min_players = response["minPlayers"];
	
	print(id);
	print(turn_password);
	
	#=========================================================================#
	# Spawn players and wait for Ice Candidates and Session to generate
	#=========================================================================#
	
	var promise = Promise.new();
	for i in max_players:
		var new_player = PlayerPreload.new(id, id, turn_password, i); 
		self.add_child(new_player);
		placeholder_players.push_back(new_player);
		new_player._connected.connect(self._player_connected);
		promise.append(new_player._sdp_complete);
	
	await promise.completed;
	
	#=========================================================================#
	# Set lobby state
	#=========================================================================#
	
	http_request.request($"/root/Globals".CreateHTTPRequest(
		$"/root/Globals".api_url, 
		"/api/Lobby/SetState", 
		[
			{ "name": "lobbyId", "value": id }, 
			{ "name": "turnPassword", "value": turn_password }, 
			{ "name": "state", "value": str(0) }
		]), 
		["accept: text/plain", "Content-Type: text/plain"], 
		HTTPClient.METHOD_PATCH
	);
	await http_request.request_completed; 
	
	current_state = LobbyState.LOBBY_CREATED;
	_lobby_created();
	return;

func _player_connected(player: Player):
	player_joined.emit(player);
	return;

func _lobby_created():
	lobby_created.emit();
	
	return;
