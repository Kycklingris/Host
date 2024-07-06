class_name V1_Player
extends Node
var _internal: _V1_PlayerInternal
	
enum State { CREATED, GATHERING_SDP, SET_SDP, POLLING, WAITING_FOR_CONNECTION, CONNECTED, FAILED }

var username: String:
	get:
		if self._internal != null && self._internal.current_state == State.CONNECTED:
			return String(self._internal.username)
		printerr("Tried to access player variable \"username\" before initialization")
		return ""
	set(_value):
		pass

var root_element: V1_Element:
	get:
		if self._internal != null:
			return self._internal.root_element
		printerr("Tried to access player variable \"username\" before initialization")
		return null
	set(_value):
		pass

func _init(in_lobby_id: String, in_turn_username: String, in_turn_password: String, in_index: int):
	self._internal = _V1_PlayerInternal.new(in_lobby_id, in_turn_username, in_turn_password, in_index, self)
	self.add_child(self._internal)
	return

func send_bytes(p_packet: PackedByteArray):
	self._internal._send_packet(p_packet)
	return

func _notification(what):
	if self._internal:
		self._internal._outer_notification(what)
	return


class _V1_PlayerInternal:
	extends Node

	signal _connected(player: V1_Player)
	signal _sdp_complete()

	var outer = WeakRef

	var current_state: V1_Player.State = V1_Player.State.CREATED
	var first_connection = true

	var peer: WebRTCPeerConnection
	var channel: _Channel
	var sdp: Dictionary = { "session": "", "iceCandidates": [] }

	var username: String
	var lobby_id: String
	var turn_username: String
	var turn_password: String
	var index: int

	var http_request: HTTPRequest = null

	var turn_urls = Globals.turn_urls
	var api_url = Globals.api_url

	var element_manager: _ElementManager;

	func _init(p_lobby_id: String, p_turn_username: String, p_turn_password: String, p_index: int, p_outer: V1_Player):
		self.lobby_id = p_lobby_id
		self.turn_username = p_turn_username
		self.turn_password = p_turn_password
		self.index = p_index
		self.first_connection = true
		self.outer = weakref(p_outer)
		
		self.element_manager = _ElementManager.new(p_outer, self)
		return

	func _ready():
		self.http_request = HTTPRequest.new()
		self.add_child(http_request)
		self._initialize()
		return

	func _outer_notification(what):
		self.element_manager._player_notification(what)
		return

	func _initialize():
		self.current_state = V1_Player.State.CREATED
		
		self.peer = WebRTCPeerConnection.new()
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
		})
		self.channel = _Channel.new(peer)
		self.channel._packet.connect(self._on_packet)
		
		self.peer.ice_candidate_created.connect(self._on_ice_candidate)
		self.peer.session_description_created.connect(self._on_session)
		
		self.current_state = V1_Player.State.GATHERING_SDP
		self.peer.create_offer()
		
		await self._sdp_complete
		
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
		)
		
		var result = await self.http_request.request_completed 
		
		if result[0] != HTTPRequest.RESULT_SUCCESS:
			push_error("Lobby Sdp could not be set on player index: " + str(self.index))
			
		self.current_state = V1_Player.State.POLLING
		self._poll()
		return

	func _poll():
		if (self.current_state != V1_Player.State.POLLING):
			return
		
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
		)
		
		# Wait for response
		var result = await self.http_request.request_completed 
		
		var body_string = result[3].get_string_from_utf8()
		var response_json = JSON.new()
		var error = response_json.parse(body_string)
		
		if result[1] != 201 || error != OK:
			self._poll()
			return
		
		var response = response_json.get_data()
		
		self._set_data(response)
		return

	func _set_data(data: Dictionary):
		self.peer.set_remote_description("answer", data["session"])
		for candidate in data["iceCandidates"]:
			self.peer.add_ice_candidate(candidate["media"], candidate["index"], candidate["name"])
			
		self.current_state = V1_Player.State.WAITING_FOR_CONNECTION
		return

	func _process(_delta):
		self.peer.poll()
		self.channel._poll()
		
		var gathering_state = self.peer.get_gathering_state()
		var connection_state = self.peer.get_connection_state()
		
		if (self.current_state == V1_Player.State.GATHERING_SDP and gathering_state == WebRTCPeerConnection.GATHERING_STATE_COMPLETE):
			self.current_state = V1_Player.State.SET_SDP
			self._sdp_complete.emit()
		
		if (self.current_state == V1_Player.State.WAITING_FOR_CONNECTION and connection_state == WebRTCPeerConnection.STATE_CONNECTED):
			self.current_state = V1_Player.State.CONNECTED
			self._on_connected()
			
		if (self.current_state == V1_Player.State.CONNECTED and connection_state == WebRTCPeerConnection.STATE_CLOSED):
			self.current_state = V1_Player.State.FAILED
			print("DISCONNECTED!")
			_initialize()
		
		return

	func _on_connected():
		if self.first_connection:
			self.channel._send_magic(_Channel._InternalMagicByte.USERNAME)
		
		
		#var dict = self.root_element._internal.to_dict(true)
		#var data = JSON.stringify({
			#"parent": "root",
			#"children": dict["children"],
		#})
		#
		#self.channel._prepend_and_send(_Channel._InternalMagicByte.ADD_CHILDREN, data.to_utf8_buffer())
		return

	func _on_packet(magic: int, packet: PackedByteArray):
		#print("Magic: " + str(magic) + ", Packet: " + packet.get_string_from_utf8())
		
		match magic:
			_Channel._InternalMagicByte.USERNAME:
				self.first_connection = false
				self.username = packet.get_string_from_utf8()
				self._connected.emit(self.outer.get_ref())
				return
			_Channel._InternalMagicByte.LOCAL_EVENT:
				var data = packet.get_string_from_utf8()
				var json = JSON.new()
				var error = json.parse(data)
				if error != OK:
					printerr("Unable to parse json of local event")
					return
				var elem = Globals.GetElementFromUniqueId(json.data["unique_id"]).get_ref()
				if elem != null:
					elem.Event.emit(json.data["event"], json.data["data"])
				return
			_:
				#self.packet.emit(magic, packet)
				return

	func _on_ice_candidate(media, sdp_index, ice_name):
		self.sdp["iceCandidates"].push_back({ "media": media, "index": sdp_index, "name": ice_name })
		return

	func _on_session(type, session):
		self.peer.set_local_description(type, session)
		self.sdp["session"] = session
		return 


	class _Channel:
		extends RefCounted
		enum _InternalMagicByte { USERNAME = -1, BYTES = -2, EVENT = -3, ADD_CHILDREN = -4, DISCONNECT = -5, UPDATE_ATTRIBUTE = -6, REPARENT = -7, REQUEST_ATTRIBUTE = -8, LOCAL_BYTES = -9, LOCAL_EVENT = -10 }

		signal _packet(int ,PackedByteArray)

		var channel: WebRTCDataChannel

		func _init(peer: WebRTCPeerConnection):
			self.channel = peer.create_data_channel("data", {"negotiated": true, "id": 1})
			self.channel.write_mode = WebRTCDataChannel.WRITE_MODE_BINARY
			return

		func _poll():
			self.channel.poll()
			if (self.channel.get_ready_state() == self.channel.STATE_OPEN):
				while self.channel.get_available_packet_count() > 0:
					self._on_packet(self.channel.get_packet())
			return

		func _on_packet(packet: PackedByteArray):
			var magic: int = packet.decode_s32(0)
			# send signal with magic byte separated
			self._packet.emit(magic, packet.slice(4)) 
			return

		func _send_packet(packet: PackedByteArray):
			self.channel.put_packet(packet)
			return
			
		func _send_magic(magic: int):
			var packet = PackedByteArray()
			packet.resize(4)
			packet.encode_s32(0, magic)
			self._send_packet(packet)
			
		func _prepend_and_send(magic: int, packet: PackedByteArray):
			var with_magic = PackedByteArray()
			with_magic.resize(packet.size() + 4)
			with_magic.encode_s32(0, magic)
			for i in packet.size():
				with_magic.set(i + 4, packet[i])
			self._send_packet(with_magic)
			return


	class _ElementManager:
		extends RefCounted
		var outer: WeakRef
		var root: WeakRef
		
		func _init(p_root: V1_Player, p_outer: _V1_PlayerInternal):
			self.root = weakref(p_root)
			self.outer = weakref(p_outer)
			return
		
		func _player_notification(what):
			
			return
		
		func element_removed(elem: V1_Element):
			
			return
		
		func element_added(elem: V1_Element):
			var internal: V1_Element._V1_ElementInternal = elem._internal
			
			var data
			if internal.parent_node.get_ref() == self.root.get_ref():
				data = JSON.stringify({
					"parent": "root",
					"children": [internal.to_dict()]
				})
			else:
				data = JSON.stringify({
					"parent": internal.parent_node.get_ref()._internal.unique_id,
					"children": [internal.to_dict()]
				})
			
			self.outer.get_ref().channel._prepend_and_send(_Channel._InternalMagicByte.ADD_CHILDREN, data.to_utf8_buffer())
			return
		
		func attribute_update(elem: V1_Element, attribute: String, value):
			if value == null:
				self.outer.get_ref().channel._prepend_and_send(_Channel._InternalMagicByte.UPDATE_ATTRIBUTE, JSON.stringify({
					"unique_id": elem._internal.unique_id,
					"attribute": attribute,
				}
				).to_utf8_buffer())
			else:
				self.outer.get_ref().channel._prepend_and_send(_Channel._InternalMagicByte.UPDATE_ATTRIBUTE, JSON.stringify({
					"unique_id": elem._internal.unique_id,
					"attribute": attribute,
					"value": value,
				}
				).to_utf8_buffer())
			return
