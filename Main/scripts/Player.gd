class_name Player 
extends Node

signal _connected(Player);
signal _sdp_complete();
signal packet(magic: int, packet: PackedByteArray);

@export var username: String = "";

var internal: _Internal;
var http_request: HTTPRequest;

func _init(in_lobby_id: String, in_turn_username: String, in_turn_password: String, in_index: int):
	self.internal = _Internal.new(in_lobby_id, in_turn_username, in_turn_password, in_index, self);
	return;

func _ready():
	self.http_request = HTTPRequest.new();
	self.add_child(http_request);
	self.internal.http_request = http_request;
	
	await self.internal._initialize();

func _process(delta):
	self.internal._process(delta);
	return;

func set_page(p_page: String):
	self.internal._set_page(p_page);
	return;

func set_text_content(p_selector: String, p_content: String):
	self.internal._set_text_content(p_selector, p_content);
	return;

func send_packet(p_packet: PackedByteArray, wait_for_page: bool):
	self.internal._send_packet(p_packet, wait_for_page);
	return;

func send_magic(magic: int, wait_for_page: bool):
	self.internal._send_magic(magic, wait_for_page);
	return;

func prepend_and_send(magic: int, p_packet: PackedByteArray, wait_for_page: bool):
	self.internal._prepend_and_send(magic, p_packet, wait_for_page);
	return;

class _Internal:
	var outer: Player;

	enum State { CREATED, GATHERING_SDP, SET_SDP, POLLING, WAITING_FOR_CONNECTION, CONNECTED, FAILED }
	var current_state: State = State.CREATED;
	var first_connection = true;

	var peer: WebRTCPeerConnection;
	var channel: _Channel;
	var sdp: Dictionary = { "session": "", "iceCandidates": [] };

	var lobby_id: String;
	var turn_username: String;
	var turn_password: String;
	var index: int;

	var http_request: HTTPRequest = null;
	
	var turn_urls = Globals.turn_urls;
	var api_url = Globals.api_url;
	
	var current_page: String = "html/waiting.html";
	var actual_current_page: String = "html/home.html";
	var text_content: Array[String] = [];
	var chached_packets: Array[PackedByteArray] = [];
	
	func _init(p_lobby_id: String, p_turn_username: String, p_turn_password: String, p_index: int, p_outer: Player):
		self.lobby_id = p_lobby_id;
		self.turn_username = p_turn_username;
		self.turn_password = p_turn_password;
		self.index = p_index;
		self.first_connection = true;
		self.outer = p_outer;
		return;
	
	func _initialize():
		self.current_state = State.CREATED;
		
		self.peer = WebRTCPeerConnection.new();
		self.peer.initialize({
			"iceServers": [ 
				{
					"urls": turn_urls,
					"username": turn_username,
					"credential": turn_password,
				}
				#{
					#"urls": ["stun:stun1.l.google.com:19302", "stun:stun3.l.google.com:19302"]
				#}
			]
		});
		self.channel = _Channel.new(peer);
		self.channel._packet.connect(self._on_packet);
		
		self.peer.ice_candidate_created.connect(self._on_ice_candidate);
		self.peer.session_description_created.connect(self._on_session);
		
		self.current_state = State.GATHERING_SDP;
		self.peer.create_offer();
		
		await self.outer._sdp_complete;
		
		self.http_request.request(Globals.CreateHTTPRequest(
			Globals.api_url, 
			"/api/Lobby/SetSdp", 
			[
				{ "name": "lobbyId", "value": self.lobby_id }, 
				{ "name": "turnPassword", "value": self.turn_password }, 
				{ "name": "index", "value": str(self.index) }
			]), 
			["accept: text/plain", "Content-Type: application/json"], 
			HTTPClient.METHOD_PATCH,
			JSON.stringify(self.sdp)
		);
		
		var result = await self.http_request.request_completed; 
		
		if result[0] != HTTPRequest.RESULT_SUCCESS:
			push_error("Lobby Sdp could not be set on player index: " + str(self.index));
			
		self.current_state = State.POLLING;
		self._poll();
		return;

	func _poll():
		if (self.current_state != State.POLLING):
			return;
		
		self.http_request.request(Globals.CreateHTTPRequest(
			Globals.api_url, 
			"/api/Lobby/PollPlayer", 
			[
				{ "name": "lobbyId", "value": self.lobby_id }, 
				{ "name": "turnPassword", "value": self.turn_password },
				{ "name": "index", "value": str(self.index) }
			]), 
			["accept: text/plain", "Content-Type: text/plain"], 
			HTTPClient.METHOD_GET
		);
		
		# Wait for response
		var result = await self.http_request.request_completed 
		
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
		self.peer.set_remote_description("answer", data["session"]);
		for candidate in data["iceCandidates"]:
			self.peer.add_ice_candidate(candidate["media"], candidate["index"], candidate["name"]);
			
		self.current_state = State.WAITING_FOR_CONNECTION;
		return;

	func _process(_delta):
		self.peer.poll();
		self.channel._poll();
		
		var gathering_state = self.peer.get_gathering_state();
		var connection_state = self.peer.get_connection_state();
		
		if (self.current_state == State.GATHERING_SDP and gathering_state == WebRTCPeerConnection.GATHERING_STATE_COMPLETE):
			self.current_state = State.SET_SDP;
			self.outer._sdp_complete.emit();
		
		if (self.current_state == State.WAITING_FOR_CONNECTION and connection_state == WebRTCPeerConnection.STATE_CONNECTED):
			self.current_state = State.CONNECTED;
			self._on_connected();
			
		if (self.current_state == State.CONNECTED and connection_state == WebRTCPeerConnection.STATE_CLOSED):
			self.current_state = State.FAILED;
			print("DISCONNECTED!");
			_initialize();
		
		return;

	func _on_connected():
		if self.first_connection:
			self._send_magic(_Channel._InternalMagicByte.USERNAME, false);
		
		self._set_page(self.current_page);
		for text_change in self.text_content:
			self._prepend_and_send(_Channel._InternalMagicByte.SETTEXTCONTENT, self.text_content.front(), true);
		return;
	
	func _on_packet(magic: int, packet: PackedByteArray):
		print("Magic: " + str(magic) + ", Packet: " + packet.get_string_from_utf8());
		
		match magic:
			_Channel._InternalMagicByte.USERNAME:
				self.first_connection = false;
				self.outer.username = packet.get_string_from_utf8();
				self.outer._connected.emit(self.outer);
				return;
			_Channel._InternalMagicByte.SETPAGE:
				self.actual_current_page = packet.get_string_from_utf8();
				if self.actual_current_page == self.current_page:
					self._send_cached();
				return;
			_:
				self.outer.packet.emit(magic, packet);
				return;
		return;
	
	func _send_cached():
		for packet in self.chached_packets:
			self.channel._send_packet(packet);
			
		self.chached_packets = [];
		return;
	
	func _on_ice_candidate(media, sdp_index, ice_name):
		self.sdp["iceCandidates"].push_back({ "media": media, "index": sdp_index, "name": ice_name });
		return;

	func _on_session(type, session):
		self.peer.set_local_description(type, session);
		self.sdp["session"] = session;
		return; 
	
	func _set_page(p_page: String):
		self.current_page = p_page;
		self.text_content = [];
		self.chached_packets = [];
		self._prepend_and_send(_Channel._InternalMagicByte.SETPAGE, self.current_page.to_utf8_buffer(), false);
		return;

	func _set_text_content(p_selector: String, p_content: String):
		self.text_content.push_front(p_selector + "|" + p_content);
		self._prepend_and_send(_Channel._InternalMagicByte.SETTEXTCONTENT, self.text_content.front().to_utf8_buffer(), true);
		return;
	
	func _send_packet(packet: PackedByteArray, wait_for_page: bool):
		if wait_for_page and self.current_page != self.actual_current_page:
			self.chached_packets.push_front(packet);
			return;
		self.channel._send_packet(packet);
		return;
	
	func _send_magic(magic: int, wait_for_page: bool):
		var packet = PackedByteArray();
		packet.resize(4);
		packet.encode_s32(0, magic);
		self._send_packet(packet, wait_for_page);
		
	func _prepend_and_send(magic: int, packet: PackedByteArray, wait_for_page: bool):
		var with_magic = PackedByteArray();
		with_magic.resize(packet.size() + 4);
		with_magic.encode_s32(0, magic);
		for i in packet.size():
			with_magic.set(i + 4, packet[i]);
		self._send_packet(with_magic, wait_for_page);
		return;

class _Channel:
	enum _InternalMagicByte { USERNAME = -1, SETPAGE = -2, SETTEXTCONTENT = -3 };
	
	signal _packet(int ,PackedByteArray);
	
	var channel: WebRTCDataChannel;
	
	func _init(peer: WebRTCPeerConnection):
		self.channel = peer.create_data_channel("data", {"negotiated": true, "id": 1});
		self.channel.write_mode = WebRTCDataChannel.WRITE_MODE_BINARY;
		return;
	
	func _poll():
		self.channel.poll();
		if (self.channel.get_ready_state() == self.channel.STATE_OPEN):
			while self.channel.get_available_packet_count() > 0:
				self._on_packet(self.channel.get_packet());
		return;
	
	func _on_packet(packet: PackedByteArray):
		var magic: int = packet.decode_s32(0);
		self._packet.emit(magic, packet.slice(4)); # send signal with magic byte separated
		return;
	
	func _send_packet(packet: PackedByteArray):
		self.channel.put_packet(packet);
		return;
