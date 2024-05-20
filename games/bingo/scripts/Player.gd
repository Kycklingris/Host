class_name BingoPlayer
extends RefCounted

signal TaskDone();

var player: Player = null;
var predictee: BingoPlayer = null;

var prediction_amount: int = 5;
var predictions = [];
var selected_prediction: int = 0;

var text_prompt: String = "";
var text_prompt_answer: String = "";

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

func fill_in_text_prompt():
	var file = FileAccess.open("res://resources/bingo/text/default.json", FileAccess.READ);
	var json = JSON.new();
	json.parse(file.get_as_text());
	var prompt = json.data.pick_random();
	self.text_prompt = prompt.prompt;
	
	var visual_prompt = self.text_prompt.replace("{}", "_____");
	
	self.player.set_page("html/bingo/text_prompt_fill.html");
	self.player.set_text_content("#prompt", visual_prompt);
	return;

func answer_text_prompt():
	print("Get Answer");
	self.player.set_page("html/bingo/text_prompt_answer.html");
	self.player.set_text_content("#prompt", self.text_prompt);
	return;
	
func select_text_prompt():
	var packet_predictions = "";
	for prediction in self.predictions:
		packet_predictions += prediction + "|";
	self.player.set_page("html/bingo/text_prompt_choose.html");
	self.player.prepend_and_send(Bingo.Packets.Predictions, packet_predictions.to_utf8_buffer(), true);
	self.player.prepend_and_send(Bingo.Packets.TextPromptAnswer, (self.predictee.text_prompt + "|" + self.predictee.text_prompt_answer).to_utf8_buffer(), true);
	return;

func on_packet(magic: int, packet: PackedByteArray):
	match magic:
		Bingo.Packets.Predictions:
			var data := packet.get_string_from_utf8();
			self.predictions = Array(data.split("|", false));
			self.player.set_page("html/waiting.html");
			self.TaskDone.emit();
			print("taskdone, predictions")
			return;
		Bingo.Packets.TextPrompt:
			var data := packet.get_string_from_utf8();
			self.predictee.text_prompt = self.text_prompt.replace("{}", data);
			self.player.set_page("html/waiting.html");
			self.TaskDone.emit();
			print("taskdone, textPrompt")
			return;
		Bingo.Packets.TextPromptAnswer:
			var data := packet.get_string_from_utf8();
			print(data);
			self.text_prompt_answer = data;
			self.player.set_page("html/waiting.html");
			self.TaskDone.emit();
			print("taskdone, answer")
			return;
		Bingo.Packets.TextPromptChoice:
			var data := packet.get_string_from_utf8();
			print(data);
			self.selected_prediction = int(data);
			self.player.set_page("html/waiting.html");
			self.TaskDone.emit();
			return;
	return;
