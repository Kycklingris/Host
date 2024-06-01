class_name _LobbyInternalV1
extends Node

signal lobby_created;
signal player_joined(player: V1.Player);

var id: String;
var min_players: int = 0;
var max_players: int = 0;
var players: Array[V1.Player];
var has_started: bool = false;
var game: String = "";

var current_state: V1.Lobby.State = V1.Lobby.State.NOT_INITIALIZED;

var placeholder_players: Array[V1.Player];
var turn_password: String = "";

var http_request: HTTPRequest = null;
var polling = false;

# Called when the node enters the scene tree for the first time.
func _init(p_game: String, p_min_players: int, p_max_players: int, _allow_audience: bool):
	self.game = p_game;
	self.min_players = p_min_players;
	self.max_players = p_max_players;
	return;
	
func _ready():
	self.get_tree().set_auto_accept_quit(false);
	self.tree_exiting.connect(self._exit_tree);
	
	self.http_request = HTTPRequest.new();
	self.add_child(http_request);
	
	self._new_lobby();
	return;

func _notification(what):
	if what == Node.NOTIFICATION_WM_CLOSE_REQUEST:
		await self._delete();
		self.get_tree().quit();
	return;

func _exit_tree():
	await self._delete();
	self.get_tree().set_auto_accept_quit(true);
	return;

## Delete the lobby on server
func _delete():
	if self.current_state == V1.Lobby.State.NOT_INITIALIZED:
		return;
	
	for player in self.players:
		player._internal.channel._send_magic(_PlayerInternalV1._Channel._InternalMagicByte.DISCONNECT);
	
	self.http_request.request(Globals.CreateHTTPRequest(
		Globals.api_url, 
		"/api/Lobby/Delete", 
		[
			{ "name": "lobbyId", "value": self.id }, 
			{ "name": "turnPassword", "value": self.turn_password }
		]), 
		["accept: text/plain", "Content-Type: text/plain"], 
		HTTPClient.METHOD_DELETE
	);
	
	var result = await http_request.request_completed;
	print("Deleted lobby, Status Code: ", str(result[1]));
	return;

func _set_state(state: V1.Lobby.State):
	self.current_state = state;
	print("Lobby state set to: " + V1.Lobby.State.keys()[state]);
	return;

func _new_lobby():
	#=========================================================================#
	# Send "Create Lobby" request to the Web Server.
	#=========================================================================#
	self.http_request.request(Globals.CreateHTTPRequest(
		Globals.api_url, 
		"/api/Lobby/New", 
		[
			{ "name": "game", "value": self.game }, 
			{ "name": "minPlayers", "value": str(self.min_players) }, 
			{ "name": "maxPlayers", "value": str(self.max_players) }
		]), 
		["accept: text/plain", "Content-Type: text/plain"], 
		HTTPClient.METHOD_POST
	);
	
	var result = await self.http_request.request_completed; 
	
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		push_error("Lobby could not be created.");
		return;

	var body_string = result[3].get_string_from_utf8();
	var response_json = JSON.new();
	var error = response_json.parse(body_string);
	if error != OK:
		self._set_state(V1.Lobby.State.FAILED);
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

	self.id = response["id"];
	self.turn_password = response["turnPassword"];
	self.max_players = response["maxPlayers"];
	self.min_players = response["minPlayers"];
	
	print(self.id);
	print(self.turn_password);
	
	#=========================================================================#
	# Spawn players and wait for Ice Candidates and Session to generate
	#=========================================================================#
	
	var promise = Promise.new();
	for i in self.max_players:
		var new_player = V1.Player.new(self.id, self.id, turn_password, i);
		self.add_child(new_player);
		self.placeholder_players.push_back(new_player);
		new_player._internal._connected.connect(self._player_connected);
		promise.append(new_player._internal._sdp_complete);
	
	await promise.completed;
	self._set_state(V1.Lobby.State.LOBBY_SDP_SET);
	
	#=========================================================================#
	# Set lobby state
	#=========================================================================#
	await self.set_lobby_state(0);
	
	self._set_state(V1.Lobby.State.LOBBY_CREATED);

	self._lobby_created();
	return;

func start():
	if self.has_started == true:
		return;
	
	await self.set_lobby_state(1);
	
	# Delete Placeholder players
	for i in range(self.placeholder_players.size(), 0, -1):
		if not self.players.find(self.placeholder_players[i - 1]):
			self.placeholder_players.remove_at(i - 1);
	return;

func set_lobby_state(state: int):
	if self.http_request.get_http_client_status() != 0:
		await self.http_request.request_completed
	
	self.http_request.request(Globals.CreateHTTPRequest(
		Globals.api_url, 
		"/api/Lobby/SetState", 
		[
			{ "name": "lobbyId", "value": self.id }, 
			{ "name": "turnPassword", "value": self.turn_password }, 
			{ "name": "state", "value": str(state) }
		]), 
		["accept: text/plain", "Content-Type: text/plain"], 
		HTTPClient.METHOD_PATCH
	);
	await self.http_request.request_completed;
	return;

func _player_connected(player: V1.Player):
	print("Player joined: " + player.username);
	self.players.push_back(player);
	self.player_joined.emit(player);
	return;

func _lobby_created():
	self.lobby_created.emit();
	return;
