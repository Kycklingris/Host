class_name LobbyV1
extends Node

enum State { NOT_INITIALIZED, FAILED, LOBBY_CREATED, LOBBY_SDP_SET }

signal lobby_created;
signal player_joined(player: PlayerV1);

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


var players: Array[PlayerV1]:
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
	return;
