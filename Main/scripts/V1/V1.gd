class_name V1

func Exit():
	
	return

	
	##=========================================================================#
	##region Custom Elements                                                    #
	##=========================================================================#
	#
	#class GridElement:
		#extends V1.Element
		#var rows: int:
			#get:
				#return rows
			#set(value):
				#rows = value
				#self.set_attribute("rows", value)
				#pass
				#
		#var columns: int:
			#get:
				#return columns
			#set(value):
				#columns = value
				#self.set_attribute("columns", value)
				#pass
		#
		#func _init(num_rows: int, num_columns: int, attributes: Dictionary = {}):
			#self.rows = num_rows
			#self.columns = num_columns
			#attributes["rows"] = num_rows
			#attributes["columns"] = num_columns
			#super._init("v1-grid", attributes)
			#self._internal.Event.connect(func(event, data): self.Event.emit(event, data))
			#self._internal.Bytes.connect(func(data): self.Bytes.emit(data))
			#return
	#
	#
	#class JoystickElement:
		#extends V1.Element
		#var x: float:
			#get:
				#return x
			#set(_value):
				#printerr("Tried to assign a value to Joystick.x which is not allowed.")
				#return
		#var y: float:
			#get:
				#return y
			#set(_value):
				#printerr("Tried to assign a value to Joystick.y which is not allowed.")
				#return
		#
		#func _init(keyboard_inputs: Dictionary = { "up": [], "left": [], "down": [], "right": [] }, attributes: Dictionary = {}):
			#attributes["keyboard_inputs"] = keyboard_inputs
			#super._init("v1-joystick", attributes)
			#self._internal.Event.connect(func(event, data): self.Event.emit(event, data))
			#self._internal.Bytes.connect(func(data): 
				#var data_string: String = data.get_string_from_utf8()
				#var floats = data_string.split_floats(",", false)
				#self.x = floats[0]
				#self.y = floats[1]
				#self.Bytes.emit(data)
			#)
			#return
		#
		#func set_keyboard_input(keyboard_inputs: Dictionary = { "up": [], "left": [], "down": [], "right": [] }):
			#self.set_attribute("keyboard_inputs", keyboard_inputs)
			#return
		#
		#
	#class ButtonElement:
		#extends V1.Element
		#
		#signal Pressed()
		#signal Down()
		#signal Up()
		#
		#func _init(text: String = "", keyboard_inputs: Array[String] = [], attributes: Dictionary = {}):
			#attributes["text"] = text
			#attributes["keyboard_inputs"] = keyboard_inputs
			#super._init("v1-button", attributes)
			#
			#self._internal.Event.connect(func(event, data):
				#match event:
					#"up":
						#self.Up.emit()
					#"down":
						#self.Down.emit()
					#"pressed":
						#self.Pressed.emit()
				#
				#self.Event.emit(event, data)
				#)
			#return
		#
		#func set_text(text: String = ""):
			#self.set_attribute("text", text)
			#return
		#
		#func set_keyboard_inputs(keyboard_inputs: Array[String] = []):
			#self.set_attribute("keyboard_inputs", keyboard_inputs)
			#return
	##endregion
