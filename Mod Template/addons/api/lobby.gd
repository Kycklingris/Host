class_name Lobby
extends Node

@export var game: String;
@export var min_players: int;
@export var max_players: int;

var lobby;

func _ready():
	lobby = load("res://scripts/Lobby.gd").new(game, min_players, max_players, false)
	add_child(lobby);
	lobby.start();
	return
