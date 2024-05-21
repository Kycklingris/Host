class_name LobbyV1
extends Node
var _internal: _Internal;

signal lobby_created;
signal player_joined(player: Player);

var id: String;
var max_players: int = 0;
var min_players: int = 0;
var players: Array[Player];
var has_started: bool = false;
var game: String = "";

enum LobbyState { NOT_INITIALIZED, FAILED, LOBBY_CREATED, LOBBY_SDP_SET }
var current_state: LobbyState = LobbyState.NOT_INITIALIZED;

func _init(p_game: String, p_min_players: int, p_max_players: int, _allow_audience: bool):
	self.game = p_game;
	self.min_players = p_min_players;
	self.max_players = p_max_players;
	return

func _ready():
	var http_request = HTTPRequest.new();
	self.add_child(http_request);
	self._internal = _Internal.new(self, http_request);
	
	self._internal._new_lobby(self.game, self.max_players, self.min_players);
	return;

func start():
	self.has_started = true;
	self._internal.start();
	return;

func _notification(notif):
	if self._internal:
		self._internal._notification(notif);
	return;

class _Internal:
	var outer: LobbyV1;

	var placeholder_players: Array[Player];
	var turn_password: String = "";

	var http_request: HTTPRequest = null;
	var polling = false;

	# Called when the node enters the scene tree for the first time.
	func _init(p_outer: LobbyV1, p_http_request: HTTPRequest):
		self.outer = p_outer;
		self.http_request = p_http_request;
		
		self.outer.get_tree().set_auto_accept_quit(false);
		self.outer.tree_exiting.connect(self._exit_tree);
		return;
	
	func _notification(notif):
		if notif == Node.NOTIFICATION_WM_CLOSE_REQUEST:
			await self._delete();
			self.outer.get_tree().quit();
		return;
	
	func _exit_tree():
		await self._delete();
		self.outer.get_tree().set_auto_accept_quit(true);
		return;
	
	## Delete the lobby on server
	func _delete():
		if self.outer.current_state == LobbyState.NOT_INITIALIZED:
			return;
		self.http_request.request(Globals.CreateHTTPRequest(
			Globals.api_url, 
			"/api/Lobby/Delete", 
			[
				{ "name": "lobbyId", "value": self.outer.id }, 
				{ "name": "turnPassword", "value": self.turn_password }
			]), 
			["accept: text/plain", "Content-Type: text/plain"], 
			HTTPClient.METHOD_DELETE
		);
		
		var result = await http_request.request_completed;
		print("Deleted lobby, Status Code: ", str(result[1]));
		return;

	func _new_lobby(game: String, maxPlayers: int, minPlayers: int):
		#=========================================================================#
		# Send "Create Lobby" request to the Web Server.
		#=========================================================================#
		http_request.request(Globals.CreateHTTPRequest(
			Globals.api_url, 
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
			self.outer.current_state = LobbyState.FAILED;
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
		
		self.outer.id = response["id"];
		turn_password = response["turnPassword"];
		self.outer.max_players = response["maxPlayers"];
		self.outer.min_players = response["minPlayers"];
		
		print(self.outer.id);
		print(turn_password);
		
		#=========================================================================#
		# Spawn players and wait for Ice Candidates and Session to generate
		#=========================================================================#
		
		var promise = Promise.new();
		for i in self.outer.max_players:
			var new_player = Player.new(self.outer.id, self.outer.id, turn_password, i);
			self.outer.add_child(new_player);
			self.placeholder_players.push_back(new_player);
			new_player._connected.connect(self._player_connected);
			promise.append(new_player._sdp_complete);
		
		await promise.completed;
		
		#=========================================================================#
		# Set lobby state
		#=========================================================================#
		
		await self.set_lobby_state(0);
		
		self.outer.current_state = LobbyState.LOBBY_CREATED;
		self._lobby_created();
		return;

	func start():
		if self.outer.has_started == true:
			return;
		
		self.set_lobby_state(1);
		
		# Delete Placeholder players
		for i in range(self.placeholder_players.size(), 0, -1):
			if not self.outer.players.find(self.placeholder_players[i - 1]):
				self.placeholder_players.remove_at(i - 1);
		return;

	func set_lobby_state(state: int):
		self.http_request.request(Globals.CreateHTTPRequest(
			Globals.api_url, 
			"/api/Lobby/SetState", 
			[
				{ "name": "lobbyId", "value": self.outer.id }, 
				{ "name": "turnPassword", "value": self.turn_password }, 
				{ "name": "state", "value": str(state) }
			]), 
			["accept: text/plain", "Content-Type: text/plain"], 
			HTTPClient.METHOD_PATCH
		);
		await self.http_request.request_completed; 
		return;

	func _player_connected(player: Player):
		self.outer.players.push_back(player);
		self.outer.player_joined.emit(player);
		return;

	func _lobby_created():
		self.outer.lobby_created.emit();
		return;
