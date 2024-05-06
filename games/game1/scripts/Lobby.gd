extends Control

var lobby: Lobby;

# Called when the node enters the scene tree for the first time.
func _ready():
	lobby = $"/root/Main/Lobby";
	
	lobby.player_joined.connect(self._on_player_connected);
	
	%LobbyId.text = lobby.id;

func _on_player_connected(player):
	print("Player joined");
	var label = Label.new();
	label.text = player.username;
	%Players.add_child(label);
	return;
