extends Node

var main: Node;
var lobby: Lobby;

var loadingScreen = preload("res://games/game1/LobbyLoadingScreen.tscn").instantiate();
var lobbyScreen = preload("res://games/game1/Lobby.tscn").instantiate();

var currentChild;

# Called when the node enters the scene tree for the first time.
func _ready():
	main = $"/root/Main";
	lobby = $"/root/Main/Lobby";
	
	# Add "Connecting" loading screen to scene hierarchy
	currentChild = loadingScreen;
	main.add_child(loadingScreen);
	lobby.new_lobby("testing", 5, 2);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func _on_lobby_lobby_created():
	main.remove_child(currentChild);
	currentChild = lobbyScreen;
	main.add_child(lobbyScreen);
