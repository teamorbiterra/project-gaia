extends Control
class_name IDE

#region internals
@onready var documentation = %Documentation
@onready var editor = %EDITOR
@onready var terminal = %TERMINAL
@onready var menu = %menu
@onready var task = %task
@onready var help = %help
@onready var settings_manager = %SettingsManager
@onready var script_manager = %ScriptManager
@onready var program_manager = %ProgramManager
#endregion

#region property variables
var font_size: int = 40
#endregion

enum task_menu_items {
	LOAD_PROGRAM,
	RUN_PROGRAM,
	LOAD_TEMPLATE,
	CLEAR_TERMINAL
}

enum help_menu_items {
	HELP_MISSION_CONTROL_PROGRAM,
	HELP_LAUNCH_VEHICLE,
}

enum menu_items {
	SAVE_SCRIPT,
	LOAD_SCRIPT,
	EDIT_PREFERENCE
}

func _ready():
	#region global signal connections 
	Console.LogMessage.connect(log_message)
	#endregion
	
	#region menubar setup
	task.id_pressed.connect(
		func(id: int):
			match id:
				task_menu_items.LOAD_PROGRAM:
					Console.Log("Loading program...")
					program_manager.load_program()
				task_menu_items.LOAD_TEMPLATE:
					_handle_load_template()
				task_menu_items.RUN_PROGRAM:
					program_manager.run_program()
				task_menu_items.CLEAR_TERMINAL:
					clear_terminal()
	)
	
	help.id_pressed.connect(
		func(id: int):
			match id:
				help_menu_items.HELP_MISSION_CONTROL_PROGRAM:
					var dummy_mission_controller = MissionControllerProgram.new()
					load_documentation(dummy_mission_controller, "Mission Controller Program")	
				help_menu_items.HELP_LAUNCH_VEHICLE:
					var dummy_launch_vehicle = LaunchVehicle.new()
					load_documentation(dummy_launch_vehicle, "Launch Vehicle")
	)
	
	menu.id_pressed.connect(
		func(id: int):
			match id:
				menu_items.SAVE_SCRIPT:
					script_manager.save_script()
				menu_items.EDIT_PREFERENCE:
					settings_manager.manage_settings()
				menu_items.LOAD_SCRIPT:
					script_manager.load_script()
	)
	#endregion

#region utility functions

func log_message(msg):
	"""Appends a message to the terminal output"""
	terminal.text = terminal.text + msg + "\n"

func clear_terminal():
	"""Clears all text from the terminal"""
	terminal.text = ""

func _handle_load_template():
	"""
	Handles loading a program template into the editor.
	Placeholder for future template functionality.
	"""
	Console.Log("Template loading not yet implemented.")
	# TODO: Implement template loading system

#endregion

#region documentation loading

func load_documentation(w_class: Object, title_name: String):
	"""Loads and displays documentation for a given class using ClassAnalyzer"""
	
	# Prepare documentation display
	documentation.scroll_active = true
	documentation.clear()
	await get_tree().process_frame  # Wait one frame for clear to process
	
	# Use the ClassAnalyzer to analyze the class
	var doc_data = ClassAnalyzer.analyze_script(w_class, title_name)
	
	# Display formatted documentation
	_display_documentation(doc_data)

func _display_documentation(doc_data: Dictionary):
	"""Formats and displays the documentation in the RichTextLabel"""
	
	var title = doc_data.get("title", "Unknown Class")
	
	# Title
	documentation.append_text("[center][b][font_size=40]%s[/font_size][/b][/center]\n\n" % title)
	
	# Properties section
	var properties = doc_data.get("properties", [])
	if properties.size() > 0:
		documentation.append_text("[b][font_size=26]Properties[/font_size][/b]\n")
		documentation.append_text("[color=gray]" + "─".repeat(60) + "[/color]\n\n")
		
		for prop in properties:
			var prop_name = prop.get("name", "unknown")
			var prop_type = prop.get("type", "Variant")
			var prop_doc = prop.get("documentation", "No documentation available")
			
			# Property name and type
			documentation.append_text("[color=cyan]%s[/color]: [color=yellow]%s[/color]\n" % [prop_name, prop_type])
			# Documentation
			documentation.append_text("  [color=lightgray]%s[/color]\n\n" % prop_doc)
	
	# Methods section
	var methods = doc_data.get("methods", [])
	if methods.size() > 0:
		documentation.append_text("\n[b][font_size=40]Methods[/font_size][/b]\n")
		documentation.append_text("[color=gray]" + "─".repeat(60) + "[/color]\n\n")
		
		for method in methods:
			var signature = method.get("signature", "func unknown()")
			var method_doc = method.get("documentation", "No documentation available")
			
			# Method signature
			documentation.append_text("[color=green]%s[/color]\n" % signature)
			# Documentation
			documentation.append_text("  [color=lightgray]%s[/color]\n\n" % method_doc)
	
	# If no properties or methods found
	if properties.size() == 0 and methods.size() == 0:
		documentation.append_text("[center][color=orange]No documentation available for this class[/color][/center]\n")

#endregion
