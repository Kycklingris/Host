class_name Player extends Node

signal _sdp_complete();
signal _connected(Player);

@export var username: String = "";

enum { CREATED, GATHERING_SDP, SET_SDP, POLLING, WAITING_FOR_CONNECTION, CONNECTED, FAILED }
var current_state = CREATED;

var peer: WebRTCPeerConnection = WebRTCPeerConnection.new();
var channel: WebRTCDataChannel;

var sdp: Dictionary = { "session": "", "iceCandidates": [] };

var lobby_id: String;
var turn_username: String;
var turn_password: String;
var index: int;

var http_request: HTTPRequest = null;

func _init(in_lobby_id: String, in_turn_username: String, in_turn_password: String, in_index: int):
	lobby_id = in_lobby_id;
	turn_username = in_turn_username;
	turn_password = in_turn_password;
	index = in_index;
	return;
	
func _ready():
	http_request = HTTPRequest.new();
	self.add_child(http_request);
	
	await _initialize();
	return;

func _initialize():
	current_state = CREATED;
	peer = WebRTCPeerConnection.new();
	
	peer.initialize({
		"iceServers": [ 
			{
				"urls": $"/root/Globals".turn_urls,
				"username": turn_username,
				"credential": turn_password,
			}
			#{
				#"urls": ["stun:stun1.l.google.com:19302", "stun:stun3.l.google.com:19302"]
			#}
		]
	});
	channel = peer.create_data_channel("data", {"negotiated": true, "id": 1});
	channel.write_mode = WebRTCDataChannel.WRITE_MODE_TEXT;
	
	peer.ice_candidate_created.connect(self._on_ice_candidate);
	peer.session_description_created.connect(self._on_session);

	current_state = GATHERING_SDP;
	peer.create_offer();
	
	await _sdp_complete;
	
	http_request.request($"/root/Globals".CreateHTTPRequest(
		$"/root/Globals".api_url, 
		"/api/Lobby/SetSdp", 
		[
			{ "name": "lobbyId", "value": lobby_id }, 
			{ "name": "turnPassword", "value": turn_password }, 
			{ "name": "index", "value": str(index) }
		]), 
		["accept: text/plain", "Content-Type: application/json"], 
		HTTPClient.METHOD_PATCH,
		JSON.stringify(sdp)
	);
	
	var result = await http_request.request_completed; 
	
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		push_error("Lobby Sdp could not be set on player index: " + str(index));
		
	current_state = POLLING;
	_poll();
	return;

func _poll():
	if (current_state != POLLING):
		return;
	
	http_request.request($"/root/Globals".CreateHTTPRequest(
		$"/root/Globals".api_url, 
		"/api/Lobby/PollPlayer", 
		[
			{ "name": "lobbyId", "value": lobby_id }, 
			{ "name": "turnPassword", "value": turn_password },
			{ "name": "index", "value": str(index) }
		]), 
		["accept: text/plain", "Content-Type: text/plain"], 
		HTTPClient.METHOD_GET
	);
	
	# Wait for response
	var result = await http_request.request_completed 
	
	var body_string = result[3].get_string_from_utf8();
	var response_json = JSON.new();
	var error = response_json.parse(body_string);
	
	if result[1] != 201 || error != OK:
		self._poll();
		return;
	
	var response = response_json.get_data();
	
	self._set_data(response);
	return;

func _set_data(data: Dictionary):
	peer.set_remote_description("answer", data["session"]);
	for candidate in data["iceCandidates"]:
		peer.add_ice_candidate(candidate["media"], candidate["index"], candidate["name"]);
		
	current_state = WAITING_FOR_CONNECTION;
	return;

func _process(_delta):
	peer.poll();
	channel.poll();
	
	var gathering_state = peer.get_gathering_state();
	var connection_state = peer.get_connection_state();
	
	if (current_state == GATHERING_SDP && gathering_state == WebRTCPeerConnection.GATHERING_STATE_COMPLETE):
		current_state = SET_SDP;
		_sdp_complete.emit();
	
	if (current_state == WAITING_FOR_CONNECTION && connection_state == WebRTCPeerConnection.STATE_CONNECTED):
		current_state = CONNECTED;
		_connected.emit(self);
		
	if (current_state == CONNECTED && connection_state == WebRTCPeerConnection.STATE_CLOSED):
		current_state == FAILED;
		print("DISCONNECTED!");
		_initialize();
	
	return;

func _on_ice_candidate(media, sdp_index, ice_name):
	sdp["iceCandidates"].push_back({ "media": media, "index": sdp_index, "name": ice_name });
	return;

func _on_session(type, session):
	peer.set_local_description(type, session);
	sdp["session"] = session;
	return; 
