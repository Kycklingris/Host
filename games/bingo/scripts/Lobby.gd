extends Control

@onready var main: Bingo = $"/root/Main";
@onready var lobby: Lobby = $"/root/Main/Lobby";

# Called when the node enters the scene tree for the first time.
func _ready():
	lobby.player_joined.connect(self._on_player_connected);
	
	%LobbyId.text = lobby.id;

func _on_player_connected(player):
	var label = Label.new();
	label.text = player.username;
	%Players.add_child(label);
	return;
