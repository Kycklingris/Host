extends Control

var lobby: Lobby;

# Called when the node enters the scene tree for the first time.
func _ready():
	lobby = $"/root/Main/Lobby";
	
	%LobbyId.text = lobby.id;


