class_name Bingo
extends Node

const GAME_NAME = "bingo";
const MAX_PLAYERS = 10;
const MIN_PLAYERS = 2;

enum Packets { Start = 0, Predictions = 1, TextPrompt = 2, TextPromptAnswer = 3, TextPromptChoice = 4 };

@onready var lobby: Lobby = $Lobby;

var loadingScreen = preload("res://games/bingo/LobbyLoadingScreen.tscn").instantiate();
var lobbyScreen = preload("res://games/bingo/Lobby.tscn").instantiate();
var waitScreen = preload("res://games/bingo/Waiting.tscn");

var players: Array[BingoPlayer] = [];

var current_child: Node = null;

var lobby_leader: Player = null;

# Called when the node enters the scene tree for the first time.
func _ready():
	self.lobby.player_joined.connect(self._on_player_connected);
	
	# Add "Connecting" loading screen to scene hierarchy
	self._swap_child(self.loadingScreen);
	self.lobby.new_lobby(GAME_NAME, MAX_PLAYERS, MIN_PLAYERS);
	return;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	return;

func _on_player_connected(new_player: Player):
	if self.lobby_leader == null:
		self.lobby_leader = new_player;
		self.lobby_leader.packet.connect(self.start_event);
		self.lobby_leader.set_page("html/bingo/start.html");
		
	#if self.lobby.players.size() >= MIN_PLAYERS:
		#self.lobby_leader.set_page("html/bingo/start.html");
	
	
	return;

func start_event(magic, _packet):
	if magic != Packets.Start or self.lobby.has_started:
		return;
	
	self.lobby.start();
	await self.get_predictions();
	await self.text_prompt();
	
	return;

func select_bingo_player():
	self.players = [];
	
	for player in self.lobby.players:
		self.players.push_front(BingoPlayer.new(player));
	self.players.shuffle();
	
	for i in self.players.size():
		if i == self.players.size() - 1:
			self.players[i].set_predictee(self.players[0]);
		else:
			self.players[i].set_predictee(self.players[i + 1]);	
	return;

func get_predictions():
	self.select_bingo_player();
	
	for player in self.players:
		player.get_predictions(5);
	
	await self.wait_for_player_task(60.0);
	return;

func text_prompt():
	for player in self.players:
		player.fill_in_text_prompt();
	
	await self.wait_for_player_task(60.0);
	await Engine.get_main_loop().process_frame
	
	for player in self.players:
		player.answer_text_prompt();
	
	await self.wait_for_player_task(60.0);
	await Engine.get_main_loop().process_frame
	
	for player in self.players:
		player.select_text_prompt();
	
	await self.wait_for_player_task(60.0);
	await Engine.get_main_loop().process_frame
	
	return;

func wait_for_player_task(time: float):
	self._swap_child(self.waitScreen.instantiate());
	self.current_child.start(time);
	for player in self.players:
		self.current_child.add_player(player.player);
		player.TaskDone.connect(func(): self.current_child.player_ready(player.player));
	await self.current_child.Complete;
	return;

func _on_lobby_lobby_created():
	self._swap_child(self.lobbyScreen);
	return;

func _swap_child(new_child: Node):
	if self.current_child != null:
		self.remove_child(self.current_child);
	self.current_child = new_child;
	self.add_child(self.current_child);
