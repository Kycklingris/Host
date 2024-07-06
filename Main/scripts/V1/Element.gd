class_name V1_Element
extends Node2D
var _internal: _V1_ElementInternal

signal Event(event, data)
signal Bytes(data)

func _init(tag: String,  attributes: Dictionary = {}):
	self._internal = _V1_ElementInternal.new(self, tag, attributes)
	self._internal.Event.connect(func(event, data): self.Event.emit(event, data))
	self._internal.Bytes.connect(func(data): self.Bytes.emit(data))
	return
	
func set_attribute(attribute: String, value):
	self._internal.set_attribute(attribute, value)
	return

func _notification(what):
	self._internal._outer_notification(what)
	return

class _V1_ElementInternal:
	extends RefCounted

	var outer: WeakRef
	var element_manager: V1_Player._V1_PlayerInternal._ElementManager
	var player: V1_Player

	signal Event(event: String, data: Dictionary)
	signal Bytes(data: PackedByteArray)

	var unique_id: String
	var can_have_children: bool = true
	var tag: String
	var attributes: Dictionary = {}

	var parent_node: WeakRef

	func _init(p_outer: V1_Element, p_tag: String,  p_attributes: Dictionary):
		self.outer = weakref(p_outer)
		self.tag = p_tag
		self.attributes = p_attributes

		self.unique_id = Globals.GetElementUniqueId(self)
		return

	func _outer_notification(what):
		match what:
			Node.NOTIFICATION_PARENTED:
				self.new_parent()
				return
			Node.NOTIFICATION_UNPARENTED:
				if !parent_node:
					return
				#self.element_manager.
				
				self.player = null
				self.element_manager = null
				self.parent_node = null
				
				return
			#Node.NOTIFICATION_ENTER_TREE:
				#self.new_parent()
				#return
			#Node.NOTIFICATION_EXIT_TREE: 
				#
				#return
			#Node.NOTIFICATION_DISABLED:
				#
				#return
			#Node.NOTIFICATION_ENABLED:
				#
				#return
		return

	func new_parent():
		var parent = self.outer.get_ref().get_parent()
		
		if parent is V1_Player:
			self.player = parent
			self.element_manager = parent._internal.element_manager
			self.parent_node = weakref(parent)
			self.added_to_tree()
		elif parent is V1_Element and parent.player and parent.element_manager:
			self.player = parent.player
			self.element_manager = parent.element_manager
			self.parent_node = weakref(parent)
			self.added_to_tree()
		else:
			self.player = null
			self.element_manager = null
			return
		return

	func removed_from_tree():
		
		return

	func added_to_tree():
		self.element_manager.element_added(self.outer.get_ref())
		
		for child in self.outer.get_ref().get_children():
			if child is V1_Element:
				var child_elem: V1_Element = child
				child_elem._internal.parent_node = self.outer.get_ref()
				child_elem._internal.element_manager = self.element_manager
				child_elem._internal.player = self.player
				child_elem._internal.added_to_tree() 
		
		return

	func remove():
		
		return

	func set_attribute(attribute: String, value):
		if value == null:
			self.attributes.erase(attribute)
		else:
			self.attributes[attribute] = value
		
		if self.element_manager == null:
			return
		self.element_manager.attribute_update(self.outer.get_ref(), attribute, value)
		return

	func request_data() -> Dictionary:
		
		
		return {}

	func to_dict() -> Dictionary:
		return {
			"unique_id": self.unique_id,
			"tag": self.tag,
			"attributes": self.attributes,
		}
