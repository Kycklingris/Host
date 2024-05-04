class_name Lobby extends Node

const POLLING_TIME = 0.1;

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

enum LobbyState { NOT_INITIALIZED, FAILED, LOBBY_CREATED, LOBBY_SDP_SET, POLLING_FOR_PLAYERS }
var current_state: LobbyState = LobbyState.NOT_INITIALIZED;

var create_lobby_http_request: HTTPRequest = null;
var set_sdp_http_request: HTTPRequest = null;
var poll_players_http_request: HTTPRequest = null;

var polling = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	create_lobby_http_request = HTTPRequest.new();
	self.add_child(create_lobby_http_request);
	
	set_sdp_http_request = HTTPRequest.new();
	self.add_child(set_sdp_http_request);
	
	poll_players_http_request = HTTPRequest.new();
	self.add_child(poll_players_http_request);
	
	return;

# result, _response_code, _headers, _body

func new_lobby(game: String, maxPlayers: int, minPlayers: int):
	create_lobby_http_request.request($"/root/Globals".CreateHTTPRequest(
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
	
	# -------------------------------------------------------------------------
	
	var result = await create_lobby_http_request.request_completed; 
	
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
	
	# -------------------------------------------------------------------------
	
	# Spawn placeholder players, and set their sdp.
	var routines = ParallelCoroutines.new();
	for i in max_players:
		var new_player = PlayerPreload.new(); 
		self.add_child(new_player);
		placeholder_players.push_back(new_player);
		routines.append(new_player.initialize, [id, turn_password]);
	
	routines.run_all();
	await routines.completed;
	
	current_state = LobbyState.LOBBY_CREATED;
	
	# -------------------------------------------------------------------------
	
	var sdp: Array[Dictionary] = [];
	for player in placeholder_players:
		sdp.push_back(player.sdp);
	
	# Submit the lobby sdp value
	set_sdp_http_request.request($"/root/Globals".CreateHTTPRequest(
		$"/root/Globals".api_url, 
		"/api/Lobby/SetSdp", 
		[
			{ "name": "lobbyId", "value": id }, 
			{ "name": "turnPassword", "value": turn_password }
		]), 
		["accept: text/plain", "Content-Type: application/json"], 
		HTTPClient.METHOD_PATCH, 
		JSON.stringify(sdp)
	);
	
	# -------------------------------------------------------------------------

	result = await set_sdp_http_request.request_completed; 
	
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		current_state = LobbyState.FAILED;
		push_error("Could not set lobby SDP.");
		return;
	
	current_state = LobbyState.LOBBY_SDP_SET;
	_lobby_created();
	
	return;

func poll_players():
	if (!polling):
		return;
		
	poll_players_http_request.request($"/root/Globals".CreateHTTPRequest(
		$"/root/Globals".api_url, 
		"/api/Lobby/PollPlayers", 
		[
			{ "name": "lobbyId", "value": id }, 
			{ "name": "turnPassword", "value": turn_password }
		]), 
		["accept: text/plain", "Content-Type: text/plain"], 
		HTTPClient.METHOD_GET
	);
	
	# Wait for response
	var result = await poll_players_http_request.request_completed 
	
	var body_string = result[3].get_string_from_utf8();
	var response = JSON.new();
	var error = response.parse(body_string);
	
	if (result[0] != HTTPRequest.RESULT_SUCCESS):
		push_error("player polling failed");
		poll_players();
		return;
		
	if (result[3].size() == 0): # No Players
		poll_players();
		return;
	
	if error != OK:
		current_state = LobbyState.FAILED;
		push_error("JSON Parse Error: ", response.get_error_message(), " in ", body_string, " at line ", response.get_error_line())
		poll_players();
		return;
	
	var data = response.get_data();
	
	for i in data.size():		
		if (data[i]["sdp"] == null):
			continue;
		var already_joined = false;
		for player in players:
			if (player.username == data[i]["name"]):
				already_joined = true;
		if (already_joined == true):
			continue;
		
		
		var player = placeholder_players[i];
		player.username = data[i]["name"];
		player._set_remote_sdp(data[i]["sdp"]);
		players.push_back(player);
		player_joined.emit(player);
		print("Player joined: ", player.username);
	
	poll_players();
	return;

func _lobby_created():
	lobby_created.emit();
	current_state = LobbyState.POLLING_FOR_PLAYERS;
	polling = true;
	poll_players();
	
	return;
