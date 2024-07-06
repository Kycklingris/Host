@tool
class_name TestElement
extends Control
@export var TopRightCornerRadius: float;

@export_group("Style")
@export var color: Color;

@export_subgroup("Corner Radius")
@export var TopLeftCornerRadius: float;
@export var BottomLeftCornerRadius: float;
@export var BottomRightCornerRadius: float;

func _set(property, value) -> bool:
	match property:
		"clip_contents":
			
			return false
		"custom_minimum_size":
			
			return false
		"anchor_left":
			
			return false
		"anchor_top":
			
			return false
		"anchor_right":
			
			return false
		"anchor_bottom":
			
			return false
		"offset_left":
			
			return false
		"offset_top":
			
			return false
		"offset_right":
			
			return false
		"offset_bottom":
			
			return false
		"grow_horizontal":
			
			return false
		"grow_vertical":
			
			return false
		"size":
			
			return false
		"position":
			
			return false
		"rotation":
			
			return false
		"scale":
			
			return false
		"pivot_offset":
			
			return false
		"mouse_filter":
			
			return false
		"mouse_default_cursor_shape":
			
			return false
		"z_index":
			
			return false
	print("Updated ", property)
	
	return false

func _init():
	self.layout_direction = Control.LAYOUT_DIRECTION_LTR
	self.z_as_relative = false
	notify_property_list_changed()

func _process(delta):
	#self.position += Vector2(0.1, 0)
	pass

func _validate_property(property):
	const properties_to_hide = [
		"theme",
		"theme_type_variation",
		"auto_translate",
		"localize_numeral_system",
		"tooltip_text",
		"focus_neighbor_left",
		"focus_neighbor_top",
		"focus_neighbor_right",
		"focus_neighbor_bottom",
		"focus_next",
		"focus_previous",
		"focus_mode",
		"process_mode",
		"process_priority",
		"process_physics_priority",
		"process_thread_group",
		"process_thread_group_order",
		"process_thread_messages",
		"editor_description",
		"texture_filter",
		"texture_repeat",
		"material",
		"use_parent_material",
		"visible",
		"modulate",
		"self_modulate",
		"show_behind_parent",
		"top_level",
		"clip_children",
		"light_mask",
		"visibility_layer",
		"layout_direction",
		"shortcut_context",
		"mouse_force_pass_scroll_events",
		"z_as_relative",
		"y_sort_enabled",
	]
	
	# If in list, hide from editor
	if (properties_to_hide.has(property.name)):
		property.usage = PROPERTY_USAGE_NO_EDITOR
		return
	
	#if (property.name == "anchors_preset"):
		#property.usage = PROPERTY_USAGE_EDITOR
	return

func _draw():
	
	return
