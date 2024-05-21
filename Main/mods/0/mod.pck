GDPC                                                                                             res://mods/0/lobby.gd           	      ����<�Bۺzr��E�       res://mods/0/mod.cfg       7       #��Ts�T�<QS�S��       res://mods/0/Main.tscn  `            ���$��VU[t}��    class_name Lobby
extends Node

@export var game: String;
@export var min_players: int;
@export var max_players: int;

var lobby;

func _ready():
	lobby = load("res://scripts/Lobby.gd").new(game, min_players, max_players);
	add_child(lobby);
	lobby.start();
	return
                       [mod]
name="Your mod name here"
id=0
scene="Main.tscn"
         [gd_scene load_steps=2 format=3 uid="uid://bublylsgrfc52"]

[ext_resource type="Script" path="res://addons/api/lobby.gd" id="1_ac4jq"]

[node name="Main" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="Label" type="Label" parent="."]
layout_mode = 0
offset_right = 40.0
offset_bottom = 23.0
text = "Cummies"

[node name="Lobby" type="Node" parent="."]
script = ExtResource("1_ac4jq")
game = "mario"
min_players = 2
max_players = 15
                  