class_name PlayerV1
extends Node

#signal packet(magic: int, packet: PackedByteArray);

enum State { CREATED, GATHERING_SDP, SET_SDP, POLLING, WAITING_FOR_CONNECTION, CONNECTED, FAILED }

var username: String:
	get:
		return "";
	set(_value):
		pass;

var root_element: ElementV1:
	get:
		return null;
	set(_value):
		pass;

func _init(in_lobby_id: String, in_turn_username: String, in_turn_password: String, in_index: int):
	return;

func send_bytes(p_packet: PackedByteArray):
	return;
