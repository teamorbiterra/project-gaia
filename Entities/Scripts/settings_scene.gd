extends SceneBase

@onready var screen_size = %screen_size

enum screen_size_options {
	MAXIMIZED,
	FULLSCREEN,
	EXCLUSIVE_FULLSCREEN,
	# Common aspect ratios (16:9)
	WINDOWED_1280x720,
	WINDOWED_1600x900,
	WINDOWED_1920x1080,
	# 16:10 aspect ratios
	WINDOWED_1280x800,
	WINDOWED_1680x1050,
	WINDOWED_1920x1200,
	# Ultrawide 21:9
	WINDOWED_2560x1080,
}

# Dictionary to store resolution data
var resolution_data: Dictionary = {
	screen_size_options.WINDOWED_1280x720: Vector2i(1280, 720),
	screen_size_options.WINDOWED_1600x900: Vector2i(1600, 900),
	screen_size_options.WINDOWED_1920x1080: Vector2i(1920, 1080),
	screen_size_options.WINDOWED_1280x800: Vector2i(1280, 800),
	screen_size_options.WINDOWED_1680x1050: Vector2i(1680, 1050),
	screen_size_options.WINDOWED_1920x1200: Vector2i(1920, 1200),
	screen_size_options.WINDOWED_2560x1080: Vector2i(2560, 1080),
}

# Menu display names
var option_names: Dictionary = {
	screen_size_options.MAXIMIZED: "Maximized",
	screen_size_options.FULLSCREEN: "Fullscreen",
	screen_size_options.EXCLUSIVE_FULLSCREEN: "Exclusive Fullscreen",
	screen_size_options.WINDOWED_1280x720: "1280×720 (16:9) HD",
	screen_size_options.WINDOWED_1600x900: "1600×900 (16:9)",
	screen_size_options.WINDOWED_1920x1080: "1920×1080 (16:9) Full HD",
	screen_size_options.WINDOWED_1280x800: "1280×800 (16:10)",
	screen_size_options.WINDOWED_1680x1050: "1680×1050 (16:10)",
	screen_size_options.WINDOWED_1920x1200: "1920×1200 (16:10)",
	screen_size_options.WINDOWED_2560x1080: "2560×1080 (21:9) Ultrawide",
}

var current_selection: screen_size_options = screen_size_options.WINDOWED_1280x720

#region externals
@onready var background_music_volume = %background_music_volume
@onready var close_button = %close_button


#endregion externals





func _ready():
	background_music_volume.value_changed.connect(
		func(value:float):
		SoundManager.set_playing_volume(SoundManager.sounds.DAY,value,0.0)
		SoundManager.set_playing_volume(SoundManager.sounds.NIGHT,value,0.0)
		SoundManager.set_playing_volume(SoundManager.sounds.TITLE,value,0.0)		
	)
	close_button.pressed.connect(
		func():
		if SceneManager.has(SceneManager.Scene.SETTINGS_SCENE):
			SceneManager.remove(SceneManager.Scene.SETTINGS_SCENE)
	)
	
	
	
	
	var screen_size_popup = screen_size.get_popup()
	
	# Populate the menu
	for option in screen_size_options.values():
		var display_name = option_names.get(option, "Unknown")
		screen_size_popup.add_item(display_name, option)
	
	# Connect the selection signal
	screen_size_popup.index_pressed.connect(_on_screen_size_selected)
	
	# Set initial display text
	screen_size.text = option_names[current_selection]


func _on_screen_size_selected(index: int) -> void:
	var screen_size_popup = screen_size.get_popup()
	var selected_option = screen_size_popup.get_item_id(index)
	
	# Update the button text
	screen_size.text = option_names[selected_option]
	
	# Apply the screen size setting
	apply_screen_size(selected_option)
	
	# Store selection
	current_selection = selected_option


func apply_screen_size(option: screen_size_options) -> void:
	var window = get_window()
	
	match option:
		screen_size_options.MAXIMIZED:
			window.mode = Window.MODE_MAXIMIZED
			
		screen_size_options.FULLSCREEN:
			window.mode = Window.MODE_FULLSCREEN
			
		screen_size_options.EXCLUSIVE_FULLSCREEN:
			window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
			
		_:
			# Handle windowed resolutions
			if resolution_data.has(option):
				var resolution = resolution_data[option]
				
				# Set to windowed mode first
				window.mode = Window.MODE_WINDOWED
				
				# Set the size
				window.size = resolution
				
				# Center the window on screen
				var screen_center = DisplayServer.screen_get_size() / 2
				var window_center = resolution / 2
				window.position = screen_center - window_center
			else:
				push_warning("Unknown screen size option: " + str(option))


# Optional: Save/Load settings
func save_screen_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("display", "screen_mode", current_selection)
	config.save("user://settings.cfg")


func load_screen_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err == OK:
		current_selection = config.get_value("display", "screen_mode", screen_size_options.WINDOWED_1280x720)
		apply_screen_size(current_selection)
		screen_size.text = option_names[current_selection]
