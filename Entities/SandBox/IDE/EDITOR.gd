extends CodeEdit

@onready var code_edit = %EDITOR

# Autocompletion options
var completion_options = []

# Basic language constructs only
var language_basics = [
	"func", "var", "const", "if", "elif", "else", "for", "while", 
	"match", "return", "await", "pass", "break", "continue", "extends",
	"class_name", "signal", "enum", "static", "export", "@export"
]

# Code templates for language basics
var basic_templates = {
	"func": "func function_name():\n\t",
	"var": "var variable_name = ",
	"const": "const CONSTANT_NAME = ",
	"for": "for i in range():\n\t",
	"for_array": "for item in array:\n\t",
	"if": "if condition:\n\t",
	"elif": "elif condition:\n\t",
	"else": "else:\n\t",
	"while": "while condition:\n\t",
	"match": "match value:\n\tpattern:\n\t\t",
	"return": "return ",
	"await": "await ",
	"pass": "pass",
	"extends": "extends RefCounted",
	"class_name": "class_name ClassName",
}

# Documentation cache for custom classes
var class_documentation_cache = {}

# Your custom classes - now dynamically loaded
var custom_classes = {}

# Quick templates for common patterns
var quick_templates = {
	"lv_setup": "var vehicle = LaunchVehicle.new()\nvehicle.NAME = \"Rocket\"\nvehicle.initialize()",
	"lv_launch_sequence": "vehicle.initiate_launch_sequence()\nawait get_tree().create_timer(3.0).timeout\nvehicle.ignite()",
	"lv_stage_check": "if vehicle.current_phase == LaunchVehicle.FlightPhase.STAGE_SEPARATION:\n\tvehicle.separate_stage()",
	"lv_telemetry": "var data = vehicle.get_telemetry_data()\nprint(\"Alt: \", data.altitude, \"m | Vel: \", data.velocity, \"m/s\")",
}

# Cache for type detection to avoid repeated parsing
var type_cache = {}
var cache_dirty = true

# Error checking
var error_lines = {}  # line_number: error_message

func _ready():
	setup_code_edit()
	load_custom_classes()
	populate_completion_options()
	
	# Start error checking timer
	var error_timer = Timer.new()
	error_timer.wait_time = 1.0
	error_timer.timeout.connect(_check_for_errors)
	add_child(error_timer)
	error_timer.start()

func setup_code_edit():
	code_edit.code_completion_enabled = true
	code_edit.code_completion_prefixes = [".", "@"]
	
	code_edit.code_completion_requested.connect(_on_code_completion_requested)
	code_edit.text_changed.connect(_on_text_changed)
	
	var highlighter = CodeHighlighter.new()
	setup_syntax_highlighter(highlighter)
	code_edit.syntax_highlighter = highlighter

func setup_syntax_highlighter(highlighter: CodeHighlighter):
	# Keywords
	var keyword_color = Color(1.0, 0.44, 0.57)
	for keyword in language_basics:
		highlighter.add_keyword_color(keyword, keyword_color)
	
	# Custom class names
	var custom_class_color = Color(0.4, 0.8, 1.0)
	for custom_class in custom_classes.keys():
		highlighter.add_keyword_color(custom_class, custom_class_color)
	
	highlighter.number_color = Color(0.67, 1.0, 0.82)
	highlighter.add_color_region("\"", "\"", Color(1.0, 0.93, 0.53), false)
	highlighter.add_color_region("'", "'", Color(1.0, 0.93, 0.53), false)
	highlighter.add_color_region("#", "", Color(0.5, 0.5, 0.5), true)
	highlighter.function_color = Color(0.53, 0.82, 1.0)

#region Custom Class Loading

func load_custom_classes():
	"""Dynamically loads custom classes using ScriptDocumentationAnalyzer"""
	custom_classes.clear()
	class_documentation_cache.clear()
	
	# Load LaunchVehicle
	var launch_vehicle = LaunchVehicle.new()
	_cache_class_documentation(launch_vehicle, "LaunchVehicle")
	
	# Load MissionControllerProgram
	var mission_controller = MissionControllerProgram.new()
	_cache_class_documentation(mission_controller, "MissionControllerProgram")
	
	# Add more classes as needed
	# var custom_class = CustomClass.new()
	# _cache_class_documentation(custom_class, "CustomClass")

func _cache_class_documentation(instance: Object, type_name: String):
	"""Analyzes a class instance and caches its documentation"""
	var doc_data = ClassAnalyzer.analyze_script(instance, type_name)
	
	# Store documentation
	class_documentation_cache[type_name] = doc_data
	
	# Build custom_classes structure for completion
	custom_classes[type_name] = {
		"constructor": "var instance = %s.new()" % type_name,
		"properties": [],
		"methods": [],
		"enums": {},
		"property_types": {},  # property_name: type
		"method_signatures": {}  # method_name: full_signature
	}
	
	# Extract properties
	for prop in doc_data.get("properties", []):
		var prop_name = prop.get("name", "")
		var prop_type = prop.get("type", "Variant")
		custom_classes[type_name]["properties"].append(prop_name)
		custom_classes[type_name]["property_types"][prop_name] = prop_type
	
	# Extract methods
	for method in doc_data.get("methods", []):
		var method_name = method.get("name", "")
		var signature = method.get("signature", "")
		custom_classes[type_name]["methods"].append(signature)
		custom_classes[type_name]["method_signatures"][method_name] = signature
	
	# Try to extract enums from the instance
	_extract_enums(instance, type_name)

func _extract_enums(instance: Object, type_name: String):
	"""Attempts to extract enum values from a class instance"""
	var script = instance.get_script()
	if not script:
		return
	
	var source_code = script.source_code
	if source_code == "":
		return
	
	var lines = source_code.split("\n")
	var current_enum = ""
	var enum_values = []
	
	for line in lines:
		var stripped = line.strip_edges()
		
		# Detect enum declaration
		if stripped.begins_with("enum "):
			# Save previous enum if exists
			if current_enum != "" and enum_values.size() > 0:
				custom_classes[type_name]["enums"][current_enum] = enum_values.duplicate()
			
			# Start new enum
			var enum_name = stripped.replace("enum ", "").split("{")[0].strip_edges()
			current_enum = enum_name
			enum_values.clear()
			
			# Check if enum is on same line
			if "{" in stripped:
				var enum_content = stripped.split("{")[1].split("}")[0]
				var values = enum_content.split(",")
				for val in values:
					var clean_val = val.strip_edges()
					if clean_val != "":
						enum_values.append(clean_val)
		
		# Collect enum values (multiline enum)
		elif current_enum != "" and not stripped.begins_with("}"):
			if stripped != "" and not stripped.begins_with("#"):
				var value = stripped.split(",")[0].strip_edges()
				if value != "" and value != "{":
					enum_values.append(value)
		
		# End of enum
		elif stripped.begins_with("}") and current_enum != "":
			if enum_values.size() > 0:
				custom_classes[type_name]["enums"][current_enum] = enum_values.duplicate()
			current_enum = ""
			enum_values.clear()

#endregion

func populate_completion_options():
	completion_options.clear()
	
	# Add language basics
	for keyword in language_basics:
		completion_options.append({
			"text": keyword,
			"kind": CodeEdit.KIND_PLAIN_TEXT,
			"insert_text": basic_templates.get(keyword, keyword),
			"documentation": ""
		})
	
	# Add special for loop variants
	completion_options.append({
		"text": "for_array",
		"kind": CodeEdit.KIND_PLAIN_TEXT,
		"insert_text": basic_templates["for_array"],
		"documentation": "Iterate over array elements"
	})
	
	# Add custom classes
	for type_name in custom_classes.keys():
		completion_options.append({
			"text": type_name,
			"kind": CodeEdit.KIND_CLASS,
			"insert_text": type_name,
			"documentation": "Class: " + type_name
		})
		
		# Add constructor template
		completion_options.append({
			"text": type_name + "_new",
			"kind": CodeEdit.KIND_FUNCTION,
			"insert_text": custom_classes[type_name]["constructor"],
			"documentation": "Create new instance of " + type_name
		})
	
	# Add quick templates
	for template_name in quick_templates.keys():
		completion_options.append({
			"text": template_name,
			"kind": CodeEdit.KIND_PLAIN_TEXT,
			"insert_text": quick_templates[template_name],
			"documentation": "Quick template"
		})

func _on_code_completion_requested():
	var current_line = code_edit.get_line(code_edit.get_caret_line())
	var caret_column = code_edit.get_caret_column()
	
	# Check if we're accessing a class member (after a dot)
	if caret_column > 0 and current_line[caret_column - 1] == ".":
		_provide_member_completions(current_line, caret_column)
	else:
		_provide_general_completions(current_line, caret_column)

func _provide_general_completions(current_line: String, caret_column: int):
	var word_start = caret_column
	while word_start > 0 and current_line[word_start - 1].is_valid_identifier():
		word_start -= 1
	
	var current_word = current_line.substr(word_start, caret_column - word_start)
	
	for option in completion_options:
		if current_word.is_empty() or option["text"].begins_with(current_word):
			code_edit.add_code_completion_option(
				option["kind"],
				option["text"],
				option["insert_text"]
			)
	
	code_edit.update_code_completion_options(true)

func _provide_member_completions(current_line: String, caret_column: int):
	# Find the object before the dot
	var dot_pos = caret_column - 1
	var word_end = dot_pos
	var word_start = word_end - 1
	
	while word_start >= 0 and current_line[word_start].is_valid_identifier():
		word_start -= 1
	word_start += 1
	
	var object_name = current_line.substr(word_start, word_end - word_start)
	
	# Update type cache if needed
	if cache_dirty:
		_update_type_cache()
		cache_dirty = false
	
	# Try to get type from cache
	var detected_type = type_cache.get(object_name, "")
	
	# Check if it's a class type access (e.g., LaunchVehicle.FlightPhase)
	if object_name in custom_classes:
		detected_type = object_name
	
	if detected_type in custom_classes:
		var type_data = custom_classes[detected_type]
		
		# Add properties with type information
		for prop in type_data["properties"]:
			var prop_type = type_data["property_types"].get(prop, "Variant")
			var doc_data = class_documentation_cache.get(detected_type, {})
			var prop_doc = _get_property_documentation(doc_data, prop)
			
			code_edit.add_code_completion_option(
				CodeEdit.KIND_MEMBER,
				prop + " : " + prop_type,
				prop,
				Color.CYAN,
				null,
				prop_doc
			)
		
		# Add methods with signatures
		for method_sig in type_data["methods"]:
			var method_name = method_sig.split("(")[0].replace("func ", "").strip_edges()
			var doc_data = class_documentation_cache.get(detected_type, {})
			var method_doc = _get_method_documentation(doc_data, method_name)
			
			code_edit.add_code_completion_option(
				CodeEdit.KIND_FUNCTION,
				method_sig.replace("func ", ""),
				method_name + "()",
				Color.GREEN,
				null,
				method_doc
			)
		
		# Add enums
		for enum_name in type_data["enums"].keys():
			code_edit.add_code_completion_option(
				CodeEdit.KIND_ENUM,
				enum_name,
				enum_name,
				Color.YELLOW
			)
			
			# If we're accessing the enum, show its values
			var after_dot = current_line.substr(caret_column).strip_edges()
			if after_dot.begins_with(enum_name + ".") or object_name + "." + enum_name in current_line:
				for enum_value in type_data["enums"][enum_name]:
					code_edit.add_code_completion_option(
						CodeEdit.KIND_CONSTANT,
						enum_value,
						enum_value,
						Color.ORANGE
					)
	
	code_edit.update_code_completion_options(true)

func _get_property_documentation(doc_data: Dictionary, prop_name: String) -> String:
	"""Retrieves documentation for a specific property"""
	for prop in doc_data.get("properties", []):
		if prop.get("name", "") == prop_name:
			return prop.get("documentation", "No documentation available")
	return "No documentation available"

func _get_method_documentation(doc_data: Dictionary, method_name: String) -> String:
	"""Retrieves documentation for a specific method"""
	for method in doc_data.get("methods", []):
		if method.get("name", "") == method_name:
			return method.get("documentation", "No documentation available")
	return "No documentation available"

func _update_type_cache():
	type_cache.clear()
	var lines = code_edit.text.split("\n")
	
	# Limit scan to first 500 lines to prevent freezing
	var max_lines = min(lines.size(), 500)
	
	for i in range(max_lines):
		var line = lines[i].strip_edges()
		
		# Skip comments
		if line.begins_with("#"):
			continue
		
		# Look for "var xxx = ClassName.new()"
		for type_name in custom_classes.keys():
			var pattern1 = "var "
			if line.begins_with(pattern1):
				var rest = line.substr(4).strip_edges()
				var equals_pos = rest.find("=")
				if equals_pos > 0:
					var var_name = rest.substr(0, equals_pos).strip_edges()
					var_name = var_name.split(":")[0].strip_edges()  # Handle type hints
					var value = rest.substr(equals_pos + 1).strip_edges()
					if value.begins_with(type_name + ".new"):
						type_cache[var_name] = type_name
			
			# Look for "var xxx: ClassName"
			var pattern2 = "var "
			if line.begins_with(pattern2):
				if ": " + type_name in line or ":" + type_name in line:
					var var_name = line.split(":")[0].replace("var ", "").strip_edges()
					type_cache[var_name] = type_name

func _on_text_changed():
	# Mark cache as dirty for next completion request
	cache_dirty = true
	
	var current_line = code_edit.get_line(code_edit.get_caret_line())
	var caret_column = code_edit.get_caret_column()
	
	if caret_column > 0:
		var prev_char = current_line[caret_column - 1]
		
		# Trigger on dot
		if prev_char == ".":
			code_edit.request_code_completion()
		# Trigger after typing 2+ characters
		elif prev_char.is_valid_identifier():
			var word_start = caret_column - 1
			while word_start > 0 and current_line[word_start - 1].is_valid_identifier():
				word_start -= 1
			if caret_column - word_start >= 2:
				code_edit.request_code_completion()

#region Error Checking

func _check_for_errors():
	"""Periodically checks for common errors in the code"""
	error_lines.clear()
	var lines = code_edit.text.split("\n")
	
	# Update type cache for error checking
	_update_type_cache()
	
	for line_num in range(lines.size()):
		var line = lines[line_num].strip_edges()
		
		# Skip empty lines and comments
		if line.is_empty() or line.begins_with("#"):
			continue
		
		# Check for invalid property access
		_check_member_access_errors(line, line_num)
		
		# Check for undefined variables
		_check_undefined_variables(line, line_num)
		
		# Check for missing colons
		_check_missing_colons(line, line_num)
	
	# Update error display
	_update_error_display()

func _check_member_access_errors(line: String, line_num: int):
	"""Checks for invalid property or method access"""
	if not "." in line:
		return
	
	var parts = line.split(".")
	if parts.size() < 2:
		return
	
	# Get the object name (before the first dot)
	var object_part = parts[0].strip_edges()
	var words = object_part.split(" ")
	var object_name = words[words.size() - 1].strip_edges()
	
	# Remove any trailing operators
	object_name = object_name.replace("(", "").replace(")", "").replace("=", "").strip_edges()
	
	# Check if this object has a known type
	var object_type = type_cache.get(object_name, "")
	if object_type == "":
		return  # Unknown type, can't validate
	
	if not object_type in custom_classes:
		return
	
	# Get the member being accessed
	var member_part = parts[1].split("(")[0].split(" ")[0].strip_edges()
	
	# Check if member exists
	var type_data = custom_classes[object_type]
	var valid_member = false
	
	# Check properties
	if member_part in type_data["properties"]:
		valid_member = true
	
	# Check methods
	if member_part in type_data["method_signatures"]:
		valid_member = true
	
	# Check enums
	if member_part in type_data["enums"]:
		valid_member = true
	
	if not valid_member:
		error_lines[line_num] = "Unknown property/method '%s' in class '%s'" % [member_part, object_type]

func _check_undefined_variables(line: String, line_num: int):
	"""Checks for usage of undefined variables"""
	# Simple check: look for identifiers that aren't in type_cache and aren't keywords
	var words = line.split(" ")
	for word in words:
		word = word.strip_edges()
		if word.is_empty():
			continue
		
		# Clean up the word
		word = word.replace("(", "").replace(")", "").replace(":", "").replace("=", "")
		word = word.replace(",", "").replace("[", "").replace("]", "").strip_edges()
		
		if word.is_empty():
			continue
		
		# Skip if it's a keyword or custom class
		if word in language_basics or word in custom_classes:
			continue
		
		# Skip if it's a number or string
		if word.is_valid_float() or word.begins_with("\"") or word.begins_with("'"):
			continue
		
		# Check if variable is defined
		if not word in type_cache and line.begins_with(word + "."):
			# This might be an undefined variable
			# (More sophisticated checking would track all variable declarations)
			pass  # Disabled for now as it creates too many false positives

func _check_missing_colons(line: String, line_num: int):
	"""Checks for missing colons after control structures"""
	var control_keywords = ["if", "elif", "else", "for", "while", "func", "match"]
	
	for keyword in control_keywords:
		if line.begins_with(keyword + " ") or line == keyword:
			if keyword == "else":
				if not line.strip_edges().ends_with(":"):
					error_lines[line_num] = "Missing ':' after '%s'" % keyword
			elif not ":" in line:
				error_lines[line_num] = "Missing ':' after '%s'" % keyword

func _update_error_display():
	"""Updates the visual display of errors in the editor"""
	# Clear all line backgrounds
	for line in range(code_edit.get_line_count()):
		code_edit.set_line_background_color(line, Color(0, 0, 0, 0))
	
	# Highlight error lines
	for line_num in error_lines.keys():
		code_edit.set_line_background_color(line_num, Color(0.5, 0.0, 0.0, 0.2))
		
		# Optionally show tooltip (would need custom implementation)
		# For now, errors are logged
	
	# Log errors to console (optional)
	if error_lines.size() > 0:
		for line_num in error_lines.keys():
			push_warning("Line %d: %s" % [line_num + 1, error_lines[line_num]])

#endregion
