extends Node
class_name ProgramManager

@onready var ide = $".."
@onready var editor = %EDITOR
@onready var terminal = %TERMINAL

#region compilation thread management
var compilation_thread: Thread = null
var mutex: Mutex = null
var compilation_result: Dictionary = {}
var is_compiling: bool = false

# Constants
const COMPILATION_TIMEOUT = 5.0  # seconds
const CHECK_INTERVAL = 0.1  # seconds
#endregion

#region program state management
## Currently compiled script class
var compiled_script: GDScript = null

## Currently loaded program instance
var loaded_program: Variant = null

## Whether a program is currently running
var is_program_running: bool = false

## Program execution state
enum ProgramState {
	NONE,        ## No script compiled
	COMPILED,    ## Script compiled but not instantiated
	LOADED,      ## Program instance created and ready
	RUNNING,     ## Program is executing
	PAUSED,      ## Program is paused (if applicable)
	COMPLETED,   ## Program finished execution
	FAILED       ## Program encountered an error
}

var program_state: ProgramState = ProgramState.NONE
#endregion

func _ready():
	mutex = Mutex.new()

#region logging helper

func _log(msg: String):
	"""Helper to safely log messages through Console autoload"""
	# Direct access - Console must be configured as autoload
	if has_node("/root/Console"):
		get_node("/root/Console").Log(msg)
	else:
		print("[ProgramManager] ", msg)  # Fallback if Console not found

#endregion

#region program loading

func load_program():
	"""
	Handles the program compilation process asynchronously.
	Compiles the code from editor into a GDScript class but does NOT instantiate it.
	"""
	# Check if already compiling
	if is_compiling:
		_log("ERROR: A compilation is already in progress.")
		OS.alert("Compilation already in progress!")
		return
	
	# Clear any existing script/program
	if compiled_script != null or loaded_program != null:
		unload_program()
	
	_log("Compiling script from editor...")
	
	# Get the source code
	var code = editor.text
	
	# Pre-validation
	if not _validate_code_basic(code):
		program_state = ProgramState.FAILED
		return
	
	# Create GDScript and set source
	var new_script = GDScript.new()
	new_script.source_code = code
	
	# Compile the script
	var error = new_script.reload()
	
	if error == OK:
		if new_script.can_instantiate():
			compiled_script = new_script
			program_state = ProgramState.COMPILED
			_log("✓ Script successfully compiled and ready to load.")
			_log("Use 'Task > Run Program' to instantiate and execute.")
		else:
			compiled_script = null
			program_state = ProgramState.FAILED
			_log("✗ Script compiled but cannot be instantiated.")
			OS.alert("Script compiled but cannot be instantiated!")
	else:
		compiled_script = null
		program_state = ProgramState.FAILED
		var error_msg = "Compilation error: " + error_string(error)
		_log("✗ " + error_msg)
		OS.alert("Error compiling script!\n\n" + error_msg)

func load_program_fire_and_forget():
	"""Fire-and-forget program loading (original behavior)"""
	if is_compiling:
		_log("Compilation already in progress")
		return
	
	_start_compilation_async(editor.text, func(program):
		if program:
			_log("Successfully Loaded The Program.")
		else:
			_log("Failed to load program")
	)

func get_compiled_program() -> Variant:
	"""Returns the compiled program instance or null. Use with await."""
	if is_compiling:
		_log("Compilation already in progress, cannot start another")
		return null
	
	var code = editor.text
	
	# Pre-validation
	if not _validate_code_basic(code):
		return null
	
	# Start compilation
	is_compiling = true
	_reset_compilation_result()
	
	compilation_thread = Thread.new()
	var thread_error = compilation_thread.start(_compile_script_threaded.bind(code))
	
	if thread_error != OK:
		push_error("Failed to start compilation thread")
		is_compiling = false
		return null
	
	# Wait for result with timeout
	var result = await _wait_for_compilation_with_timeout()
	
	# Cleanup
	_cleanup_thread()
	is_compiling = false
	
	if result == null:
		return null
	
	if result.get("success", false):
		_log("Successfully Loaded The Program.")
		var script = result.get("script")
		if script and script.can_instantiate():
			return script.new()
		else:
			push_error("Script cannot be instantiated")
			return null
	else:
		var error_msg = result.get("error", "Unknown error")
		push_error("Compilation failed: " + error_msg)
		OS.alert("Error Loading Program. Check Syntax!\n\n" + error_msg)
		_log("Compilation failed: " + error_msg)
		return null

#endregion

#region program execution

func run_program():
	"""
	Instantiates the compiled script and executes it.
	Flow: compiled_script.new() -> program instance -> execute lifecycle methods
	"""
	# Validate we have a compiled script
	if compiled_script == null:
		_log("ERROR: No script compiled. Please load a program first.")
		OS.alert("No script compiled!\nPlease use 'Task > Load Program' first.")
		return
	
	# Check if script can be instantiated
	if not compiled_script.can_instantiate():
		_log("ERROR: Script cannot be instantiated.")
		OS.alert("Script cannot be instantiated!")
		return
	
	if is_program_running:
		_log("WARNING: Program is already running.")
		return
	
	# Check program state
	if program_state == ProgramState.FAILED:
		_log("ERROR: Cannot run a failed script. Please reload.")
		return
	
	_log("=" .repeat(60))
	_log("INSTANTIATING PROGRAM")
	_log("=" .repeat(60))
	
	# Create new instance from compiled script
	loaded_program = compiled_script.new()
	
	if loaded_program == null:
		_log("✗ ERROR: Failed to instantiate program.")
		program_state = ProgramState.FAILED
		return
	
	_log("✓ Program instance created successfully")
	program_state = ProgramState.LOADED
	
	# Show program info
	_show_program_info(loaded_program)
	
	_log("\n" + "=" .repeat(60))
	_log("STARTING PROGRAM EXECUTION")
	_log("=" .repeat(60))
	
	# Mark as running
	is_program_running = true
	program_state = ProgramState.RUNNING
	
	# Execute program entry points
	var execution_success = await _execute_program()
	
	# Update state based on execution result
	if execution_success:
		program_state = ProgramState.COMPLETED
		_log("=" .repeat(60))
		_log("✓ PROGRAM EXECUTION COMPLETED SUCCESSFULLY")
		_log("=" .repeat(60))
	else:
		program_state = ProgramState.FAILED
		_log("=" .repeat(60))
		_log("✗ PROGRAM EXECUTION FAILED")
		_log("=" .repeat(60))
	
	is_program_running = false

func stop_program():
	"""
	Stops the currently running program.
	This is a placeholder for future interrupt functionality.
	"""
	if not is_program_running:
		_log("No program is currently running.")
		return
	
	_log("Stopping program...")
	# TODO: Implement program interruption logic
	is_program_running = false
	program_state = ProgramState.PAUSED

func unload_program():
	"""
	Safely unloads the current program and clears the compiled script.
	Calls cleanup methods if they exist.
	"""
	ide.clear_terminal()
	_log("Unloading program and script...")
	
	# Cleanup program instance if it exists
	if loaded_program != null:
		# Call cleanup method if it exists
		if loaded_program.has_method("on_unload"):
			loaded_program.call("on_unload")
			_log("✓ on_unload() called")
		
		# Free the program instance if it's a RefCounted or Object
		if loaded_program is RefCounted or loaded_program is Object:
			if loaded_program.has_method("free"):
				loaded_program.free()
		
		loaded_program = null
	
	# Clear compiled script
	if compiled_script != null:
		compiled_script = null
	
	program_state = ProgramState.NONE
	is_program_running = false
	_log("✓ Program and script cleared")

#endregion

#region state queries

func get_program_state() -> ProgramState:
	"""Returns the current state of the program"""
	return program_state

func is_script_compiled() -> bool:
	"""Returns true if a script is currently compiled"""
	return compiled_script != null

func is_program_loaded() -> bool:
	"""Returns true if a program instance is currently loaded"""
	return loaded_program != null and program_state != ProgramState.NONE

#endregion

#region internal compilation methods

func _start_compilation_async(code: String, callback: Callable):
	"""Internal: Start async compilation with callback"""
	if is_compiling:
		callback.call(null)
		return
	
	if not _validate_code_basic(code):
		callback.call(null)
		return
	
	is_compiling = true
	_reset_compilation_result()
	
	compilation_thread = Thread.new()
	var thread_error = compilation_thread.start(_compile_script_threaded.bind(code))
	
	if thread_error != OK:
		push_error("Failed to start compilation thread")
		is_compiling = false
		callback.call(null)
		return
	
	# Monitor compilation in background
	_monitor_compilation(callback)

func _monitor_compilation(callback: Callable):
	"""Internal: Monitor compilation and call callback when done"""
	var elapsed = 0.0
	
	while elapsed < COMPILATION_TIMEOUT:
		await get_tree().create_timer(CHECK_INTERVAL).timeout
		elapsed += CHECK_INTERVAL
		
		var result = _get_compilation_result()
		
		if result.has("completed") and result["completed"]:
			_cleanup_thread()
			is_compiling = false
			
			if result.get("success", false):
				var script = result.get("script")
				if script and script.can_instantiate():
					callback.call(script.new())
				else:
					callback.call(null)
			else:
				var error_msg = result.get("error", "Unknown error")
				OS.alert("Error Loading Program. Check Syntax!\n\n" + error_msg)
				_log("Compilation failed: " + error_msg)
				callback.call(null)
			return
	
	# Timeout occurred
	_log("Compilation timed out after " + str(COMPILATION_TIMEOUT) + " seconds")
	OS.alert("Compilation timed out. The script may have severe syntax errors.")
	_cleanup_thread()
	is_compiling = false
	callback.call(null)

func _wait_for_compilation_with_timeout() -> Dictionary:
	"""Internal: Wait for compilation with timeout, returns result or null"""
	var elapsed = 0.0
	
	while elapsed < COMPILATION_TIMEOUT:
		await get_tree().create_timer(CHECK_INTERVAL).timeout
		elapsed += CHECK_INTERVAL
		
		var result = _get_compilation_result()
		
		if result.has("completed") and result["completed"]:
			return result
	
	# Timeout
	_log("Compilation timed out after " + str(COMPILATION_TIMEOUT) + " seconds")
	OS.alert("Compilation timed out. The script may have severe syntax errors.")
	return {}

func _compile_script_threaded(code: String):
	"""Internal: Compile script in thread (DO NOT CALL DIRECTLY)"""
	var program_class = GDScript.new()
	program_class.source_code = code
	
	# Attempt compilation
	var error = program_class.reload()
	
	# Store result thread-safely
	mutex.lock()
	if error == OK:
		if program_class.can_instantiate():
			compilation_result = {
				"completed": true,
				"success": true,
				"script": program_class,
				"error": ""
			}
		else:
			compilation_result = {
				"completed": true,
				"success": false,
				"script": null,
				"error": "Script compiled but cannot be instantiated"
			}
	else:
		compilation_result = {
			"completed": true,
			"success": false,
			"script": null,
			"error": error_string(error)
		}
	mutex.unlock()

func _validate_code_basic(code: String) -> bool:
	"""Internal: Basic validation before compilation"""
	if code.strip_edges().is_empty():
		_log("Script is empty")
		OS.alert("Script is empty!")
		return false
	
	# Check for minimum valid syntax
	if not code.contains("extends"):
		_log("Script must extend a class")
		OS.alert("Script must contain 'extends' declaration!")
		return false
	
	return true

func _get_compilation_result() -> Dictionary:
	"""Internal: Thread-safe result getter"""
	mutex.lock()
	var result = compilation_result.duplicate()
	mutex.unlock()
	return result

func _reset_compilation_result():
	"""Internal: Reset compilation result"""
	mutex.lock()
	compilation_result = {
		"completed": false,
		"success": false,
		"script": null,
		"error": ""
	}
	mutex.unlock()

func _cleanup_thread():
	"""Internal: Safely cleanup compilation thread"""
	if compilation_thread != null:
		if compilation_thread.is_alive():
			compilation_thread.wait_to_finish()
		compilation_thread = null

#endregion

#region internal execution methods

func _execute_program() -> bool:
	"""
	Internal: Executes the program's lifecycle methods.
	Returns true if execution was successful, false otherwise.
	"""
	var success = true
	
	# Check for main/run method
	if loaded_program.has_method("main"):
		_log("Calling main()...")
		var result = loaded_program.call("main")
		
		if result == null and not loaded_program.has_method("main"):
			_log("✗ ERROR: Failed to call main()")
			success = false
			return success
		
		if result is Callable:
			result = await result.call()
		
		_log("✓ main() completed")
	elif loaded_program.has_method("run"):
		_log("Calling run()...")
		var result = loaded_program.call("run")
		
		if result == null and not loaded_program.has_method("run"):
			_log("✗ ERROR: Failed to call run()")
			success = false
			return success
		
		if result is Callable:
			result = await result.call()
		
		_log("✓ run() completed")
	else:
		_log("WARNING: No main() or run() method found in program")
	
	# Check for on_complete method
	if loaded_program.has_method("on_complete"):
		_log("Calling on_complete()...")
		var result = loaded_program.call("on_complete")
		
		if result == null and not loaded_program.has_method("on_complete"):
			_log("✗ ERROR: Failed to call on_complete()")
			success = false
		
		if result is Callable:
			result = await result.call()
		
		_log("✓ on_complete() completed")
	
	return success

func _show_program_info(program_instance: Variant):
	"""
	Internal: Displays information about the loaded program.
	Shows available methods and properties for debugging.
	"""
	_log("\nProgram Information:")
	_log("-" .repeat(40))
	
	# Show class type
	var program_class
	if program_instance.has_method("get_custom_name"):
		program_class = program_instance.call("get_custom_name")
	else:
		program_class = program_instance.get_class()
	_log("Type: " + program_class)
	
	# List available methods
	var methods = program_instance.get_method_list()
	var user_methods = []
	
	for method in methods:
		var method_name = method["name"]
		# Filter out built-in methods
		if not method_name.begins_with("_") or method_name in ["on_load", "main", "run", "on_complete", "on_unload"]:
			if method_name in ["on_load", "main", "run", "on_complete", "on_unload"]:
				user_methods.append(method_name)
	
	if user_methods.size() > 0:
		_log("Entry points found: " + ", ".join(user_methods))
	else:
		_log("No standard entry points found (on_load, main, run)")
	
	_log("-" .repeat(40))

#endregion

func _exit_tree():
	"""Cleanup when node is removed"""
	_cleanup_thread()
