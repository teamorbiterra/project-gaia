extends Node2D
class_name OrbitalDataParser

var url = "https://raw.githubusercontent.com/teamorbiterra/project-gaia-data-base/main/neo_orbital_data.json"
		  

func _ready():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_http_request_completed)
	var error = http_request.request(url)
	if error != OK:
		push_error("An error occurred in the HTTP request.")

func _http_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Loading JSON failed")
		return
	if response_code != 200:
		push_error("HTTP error: %d" % response_code)
		return
	
	var body_text = body.get_string_from_utf8()
	
	# Parse JSON (Godot 4)
	var json = JSON.new()
	var error = json.parse(body_text)
	if error != OK:
		push_error("Failed to parse JSON: " + json.get_error_message())
		return
	
	var json_data = json.data  # Get the parsed data
	
	# json_data should now contain your parsed JSON
	if json_data is Dictionary:
		print("Successfully loaded ", json_data.size(), " NEOs")
	elif json_data is Array:
		print("Successfully loaded ", json_data.size(), " NEOs")
	else:
		print("Loaded JSON data: ", json_data)
	print(json_data)
	
	
