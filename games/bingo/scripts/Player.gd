class_name BingoPlayer
extends RefCounted

signal TaskDone();

var player: Player = null;
var predictee: BingoPlayer = null;

var prediction_amount: int = 5;
var predictions = [];

func _init(p_player: Player):
	self.player = p_player;
	return;

func set_predictee(p_predictee: BingoPlayer):
	self.predictee = p_predictee;
	return;

func get_predictions(amount: int):
	self.prediction_amount = amount;
	self.player.packet.connect(self.on_packet);
	
	self.player.set_page("html/bingo/prediction.html");
	self.player.set_text_content("#prediction-player-name", self.predictee.player.username);
	return;

func on_packet(magic: int, packet: PackedByteArray):
	match magic:
		Bingo.Packets.Predictions:
			var data := packet.get_string_from_utf8();
			self.predictions = Array(data.split("|", false));
			self.player.set_page("html/waiting.html");
			self.TaskDone.emit();
			return;
	return;
