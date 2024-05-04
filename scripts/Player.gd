class_name Player extends Node

signal _sdp_complete();
signal _connected(Player);

@export var sdp: Dictionary = { "session": "", "iceCandidates": [] };
@export var username: String = "";

var peer: WebRTCPeerConnection = WebRTCPeerConnection.new();

var turn_username;
var turn_password;

var channel: WebRTCDataChannel;

var finished_gathering = false;
var has_connected = false;

func initialize(turn_name: String, turn_credential: String):
	turn_username = turn_name;
	turn_password = turn_credential;
	
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

	peer.create_offer();
	
	await _sdp_complete;
	return;

func _set_remote_sdp(in_sdp: Dictionary):	
	peer.set_remote_description("answer", in_sdp["session"]);
	for candidate in in_sdp["iceCandidates"]:
		#print(candidate["media"], " ", str(candidate["index"]), " ", candidate["name"])
		peer.add_ice_candidate(candidate["media"], candidate["index"], candidate["name"]);
	return;

func _ready():
	return;

func _process(_delta):
	peer.poll();
	channel.poll();
	if (finished_gathering == false && peer.get_gathering_state() == WebRTCPeerConnection.GATHERING_STATE_COMPLETE):
		finished_gathering = true;
		_sdp_complete.emit();
	
	if (has_connected == false && peer.get_connection_state() == WebRTCPeerConnection.STATE_CONNECTED):
		has_connected = true;
		channel.put_packet("POggies".to_utf8_buffer());
		_connected.emit(self);
	
	return;

func _on_ice_candidate(media, index, ice_name):
	sdp["iceCandidates"].push_back({ "media": media, "index": index, "name": ice_name });

	return;

func _on_session(type, session):
	peer.set_local_description(type, session);
	sdp["session"] = session;
	
	return; 
