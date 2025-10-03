## Analyzes a script and extracts documentation for properties and methods
## Usage: var analyzer = ScriptDocumentationAnalyzer.new()
##        var docs = analyzer.analyze_script(my_node)
extends Node


#region Type String Conversion
func get_type_string(type: int) -> String:
	"""Converts Godot type enum to human-readable string"""
	match type:
		TYPE_NIL: return "void"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR2I: return "Vector2i"
		TYPE_RECT2: return "Rect2"
		TYPE_VECTOR3: return "Vector3"
		TYPE_VECTOR3I: return "Vector3i"
		TYPE_TRANSFORM2D: return "Transform2D"
		TYPE_VECTOR4: return "Vector4"
		TYPE_VECTOR4I: return "Vector4i"
		TYPE_PLANE: return "Plane"
		TYPE_QUATERNION: return "Quaternion"
		TYPE_AABB: return "AABB"
		TYPE_BASIS: return "Basis"
		TYPE_TRANSFORM3D: return "Transform3D"
		TYPE_PROJECTION: return "Projection"
		TYPE_COLOR: return "Color"
		TYPE_STRING_NAME: return "StringName"
		TYPE_NODE_PATH: return "NodePath"
		TYPE_RID: return "RID"
		TYPE_OBJECT: return "Object"
		TYPE_CALLABLE: return "Callable"
		TYPE_SIGNAL: return "Signal"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_ARRAY: return "Array"
		TYPE_PACKED_BYTE_ARRAY: return "PackedByteArray"
		TYPE_PACKED_INT32_ARRAY: return "PackedInt32Array"
		TYPE_PACKED_INT64_ARRAY: return "PackedInt64Array"
		TYPE_PACKED_FLOAT32_ARRAY: return "PackedFloat32Array"
		TYPE_PACKED_FLOAT64_ARRAY: return "PackedFloat64Array"
		TYPE_PACKED_STRING_ARRAY: return "PackedStringArray"
		TYPE_PACKED_VECTOR2_ARRAY: return "PackedVector2Array"
		TYPE_PACKED_VECTOR3_ARRAY: return "PackedVector3Array"
		TYPE_PACKED_COLOR_ARRAY: return "PackedColorArray"
		_: return "Variant"

#endregion

#region Property Documentation

func load_property_documentation(node: Object) -> Dictionary:
	"""Extracts documentation comments (##) above variable declarations"""
	var docs = {}
	var script = node.get_script()
	if not script:
		return docs
	
	var source_code: String = script.source_code
	if source_code == "":
		return docs
	
	var lines = source_code.split("\n")
	var prev_line = ""
	
	for line in lines:
		var stripped = line.strip_edges()
		
		# Check if previous line had ## comment
		if prev_line.begins_with("##"):
			var comment = prev_line.trim_prefix("##").strip_edges()
			
			# Check if current line is a variable declaration
			if stripped.begins_with("@export") or stripped.begins_with("var "):
				# Handle @export annotations
				var var_line = stripped
				if stripped.begins_with("@export"):
					# Look ahead to find the actual var declaration
					continue
				
				# Extract variable name (handle "var name:", "var name =", etc.)
				var parts = var_line.split(" ", false, 2)
				if parts.size() >= 2:
					var var_name = parts[1].split(":")[0].split("=")[0].strip_edges()
					docs[var_name] = comment
		
		# Handle @export on previous line
		if prev_line.begins_with("@export") and stripped.begins_with("var "):
			# Check two lines back for documentation
			var parts = stripped.split(" ", false, 2)
			if parts.size() >= 2:
				var _var_name = parts[1].split(":")[0].split("=")[0].strip_edges()
				# Documentation might be two lines back, store for now
		
		prev_line = stripped
	
	return docs

#endregion

#region Method Documentation

func load_method_documentation(node: Object) -> Dictionary:
	"""Extracts documentation comments (##) above function declarations"""
	var docs = {}
	var script = node.get_script()
	if not script:
		return docs
	
	var source_code: String = script.source_code
	if source_code == "":
		return docs
	
	var lines = source_code.split("\n")
	var current_doc = ""
	
	for i in range(lines.size()):
		var line = lines[i]
		var stripped = line.strip_edges()
		
		# Collect multi-line documentation
		if stripped.begins_with("##"):
			var comment = stripped.trim_prefix("##").strip_edges()
			if current_doc != "":
				current_doc += "\n"
			current_doc += comment
		# Check if current line is a function declaration
		elif stripped.begins_with("func "):
			if current_doc != "":
				# Extract function name
				var func_name = stripped.split("(")[0].replace("func ", "").strip_edges()
				docs[func_name] = current_doc
			current_doc = ""
		# Reset documentation if we hit a non-comment, non-function line
		elif not stripped.is_empty() and not stripped.begins_with("#"):
			current_doc = ""
	
	return docs

#endregion

#region Method Signature Building

func build_method_signature(method: Dictionary) -> String:
	"""Builds a readable method signature from method dictionary"""
	var sig = "func " + method["name"] + "("
	var args = method.get("args", [])
	var param_strings = []
	
	for arg in args:
		var param = arg["name"]
		if arg.has("type") and arg["type"] != TYPE_NIL:
			param += ": " + get_type_string(arg["type"])
		param_strings.append(param)
	
	sig += ", ".join(param_strings) + ")"
	
	# Add return type if specified
	if method.has("return") and method["return"]["type"] != TYPE_NIL:
		sig += " -> " + get_type_string(method["return"]["type"])
	
	return sig

#endregion

#region Main Documentation Loading

func analyze_script(node: Object, title: String = "") -> Dictionary:
	"""
	Analyzes a node's script and returns complete documentation
	
	Returns a Dictionary with structure:
	{
		"title": String,
		"properties": Array[Dictionary],
		"methods": Array[Dictionary]
	}
	"""
	var result = {
		"title": title if title != "" else node.get_class(),
		"properties": [],
		"methods": []
	}
	
	var script = node.get_script()
	if not script:
		push_warning("No script attached to node")
		return result
	
	# Load documentation from script source
	var property_docs = load_property_documentation(node)
	var method_docs = load_method_documentation(node)
	
	# Extract properties
	for prop in node.get_property_list():
		if prop["usage"] & (PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			var prop_name = prop["name"]
			var prop_type = get_type_string(prop["type"])
			var doc = property_docs.get(prop_name, "No documentation available")
			
			result["properties"].append({
				"name": prop_name,
				"type": prop_type,
				"documentation": doc
			})
	
	# Extract methods (only script-defined methods)
	var script_methods = []
	if script:
		for method in script.get_script_method_list():
			script_methods.append(method["name"])
	
	for method in node.get_method_list():
		var method_name = method["name"]
		
		# Only show methods that are defined in the script
		if method_name in script_methods:
			var signature = build_method_signature(method)
			var doc = method_docs.get(method_name, "No documentation available")
			
			result["methods"].append({
				"name": method_name,
				"signature": signature,
				"documentation": doc,
				"raw_data": method
			})
	
	return result

#endregion

#region Formatting Utilities

func format_documentation(doc_data: Dictionary) -> String:
	"""Formats the documentation dictionary into a readable string"""
	var output = ""
	
	output += "=" .repeat(60) + "\n"
	output += "Class: " + doc_data["title"] + "\n"
	output += "=" .repeat(60) + "\n\n"
	
	# Properties section
	if doc_data["properties"].size() > 0:
		output += "PROPERTIES:\n"
		output += "-" .repeat(60) + "\n"
		for prop in doc_data["properties"]:
			output += "• %s: %s\n" % [prop["name"], prop["type"]]
			output += "  %s\n\n" % prop["documentation"]
	
	# Methods section
	if doc_data["methods"].size() > 0:
		output += "\nMETHODS:\n"
		output += "-" .repeat(60) + "\n"
		for method in doc_data["methods"]:
			output += "• %s\n" % method["signature"]
			output += "  %s\n\n" % method["documentation"]
	
	return output
	
	
func export_to_json(doc_data: Dictionary) -> String:
	"""Exports documentation data to JSON format"""
	return JSON.stringify(doc_data, "  ")

#endregion
