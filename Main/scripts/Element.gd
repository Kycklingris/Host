class_name ElementV1
extends RefCounted
var _internal: _Internal;

signal Event(event, data);
signal Bytes(data);

func _init(tag: String,  properties: Dictionary = {}):
	self._internal = _Internal.new(self, tag, properties);
	self._internal.Event.connect(func(event, data): self.Event.emit(event, data));
	self._internal.Bytes.connect(func(data): self.Bytes.emit(data));
	return;

func add_children(children: Array[ElementV1]):
	self._internal.add_children(children);
	return;
	
func set_attribute(attribute: String, value: String):
	self._internal.set_attribute(attribute, value);
	return;

class _Internal:
	extends RefCounted
	var outer: ElementV1;
	var parent: ElementV1;
	var player: PlayerV1._Internal;
	
	signal Event(event, data);
	signal Bytes(data);
	
	var unique_id: String;
	var is_root: bool = false;
	var can_have_children: bool = true;
	var tag: String;
	var attributes: Dictionary = {};
	var children: Array[ElementV1] = [];
	
	func _init(p_outer: ElementV1, p_tag: String,  p_attributes: Dictionary):
		self.outer = weakref(p_outer);
		self.tag = p_tag;
		self.attributes = p_attributes;

		self.unique_id = Globals.GetElementUniqueId(weakref(self));
		return;
	
	func add_children(p_children: Array[ElementV1]):
		for child in p_children:
			child._internal.parent = weakref(self);
			child._internal._update_player(self.player);
			self.children.push_back(child);
		
		if self.player == null:
			return;
		
		var new_children = [];
		for child in p_children:
			new_children.push_back(child._internal.to_dict(true));
		
		var data = JSON.stringify({
			"parent": self.get_unique_id(),
			"children": new_children,
		});
		
		self.player.channel._prepend_and_send(PlayerV1._Channel._InternalMagicByte.ADD_CHILDREN, data.to_utf8_buffer());
		return;
	
	func _update_player(p_player: PlayerV1._Internal):
		self.player = p_player;
		for child in self.children:
			if child == null:
				continue;
			
			child._internal._update_player(self.player);
		return;
	
	
	func remove():
		
		return;
	
	func set_attribute(attribute: String, value: String):
		if self.is_root:
			printerr("Cannot update attributes on root");
			return;
		if value == null:
			self.attributes.erase(attribute);
			if self.player == null:
				return;
			self.player.channel._prepend_and_send(PlayerV1._Channel._InternalMagicByte.UPDATE_ATTRIBUTE, JSON.stringify({
				"unique_id": self.unique_id,
				"attribute": attribute,
			}).to_utf8_buffer());
		else:
			self.attributes[attribute] = value;
			if self.player == null:
				return;
			self.player.channel._prepend_and_send(PlayerV1._Channel._InternalMagicByte.UPDATE_ATTRIBUTE, JSON.stringify({
				"unique_id": self.unique_id,
				"attribute": attribute,
				"value": value,
			}
			).to_utf8_buffer());
	
	func request_data() -> Dictionary:
		
		
		return {};
	
	func get_unique_id():
		if self.is_root:
			return "root";
		else:
			return self.unique_id;
	
	func to_dict(with_children: bool):
		var out = {};
		
		out["unique_id"] = self.get_unique_id();
		out["tag"] = self.tag;
		out["attributes"] = self.attributes;
		
		if with_children:
			var dict_children = [];
			for child in self.children:
				if child != null:
					dict_children.push_back(child._internal.to_dict(true));
			out["children"] = dict_children;
		
		return out;
	
