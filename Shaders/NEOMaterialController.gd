extends Control
class_name NEOMaterialController

# Material generator instance
var material_generator: NEOMaterialGenerator

# UI Elements - Version Control
var version_option_button: OptionButton

# UI Elements - Textures
var noise_texture_button: Button
var normal_texture_button: Button
var noise_texture_rect: TextureRect
var normal_texture_rect: TextureRect
var texture_file_dialog: FileDialog

# UI Elements - Basic Parameters
var sphere_radius_slider: HSlider
var sphere_radius_label: Label
var amplitude_slider: HSlider
var amplitude_label: Label
var mix_ratio_slider: HSlider
var mix_ratio_label: Label
var roughness_slider: HSlider
var roughness_label: Label

# UI Elements - UV and Scaling
var uv_scale_x_spinbox: SpinBox
var uv_scale_y_spinbox: SpinBox
var axis_scale_x_spinbox: SpinBox
var axis_scale_y_spinbox: SpinBox
var axis_scale_z_spinbox: SpinBox

# UI Elements - Colors
var mix_color_picker: ColorPicker

# UI Elements - World Center
var world_center_x_spinbox: SpinBox
var world_center_y_spinbox: SpinBox
var world_center_z_spinbox: SpinBox

# UI Elements - Method Selection
var seam_fix_option_button: OptionButton

# UI Elements - V2 Specific
var max_distance_slider: HSlider
var max_distance_label: Label
var min_amplitude_ratio_slider: HSlider
var min_amplitude_ratio_label: Label
var parallax_scale_slider: HSlider
var parallax_scale_label: Label
var parallax_steps_spinbox: SpinBox

# UI Elements - Actions
var save_preset_button: Button
var load_preset_button: Button
var reset_button: Button

# Current texture selection state
enum TextureType { NOISE, NORMAL }
var current_texture_type: TextureType

signal material_changed(material: ShaderMaterial)

func _ready():
	material_generator = NEOMaterialGenerator.new()
	add_child(material_generator)
	
	create_ui()
	connect_signals()
	update_ui_from_material()
	
	# Emit initial material
	material_changed.emit(material_generator._get_material())

func create_ui():
	# Main scroll container
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)
	
	# === VERSION SELECTION ===
	var version_group = create_group("Shader Version", vbox)
	version_option_button = OptionButton.new()
	version_option_button.add_item("Version 1 (Basic)")
	version_option_button.add_item("Version 2 (Advanced)")
	version_option_button.selected = 0
	version_group.add_child(version_option_button)
	
	# === TEXTURE SECTION ===
	var texture_group = create_group("Textures", vbox)
	
	# Noise texture
	var noise_container = HBoxContainer.new()
	texture_group.add_child(noise_container)
	noise_container.add_child(Label.new())
	noise_container.get_child(0).text = "Noise Texture:"
	noise_texture_button = Button.new()
	noise_texture_button.text = "Select Noise Texture"
	noise_container.add_child(noise_texture_button)
	noise_texture_rect = TextureRect.new()
	noise_texture_rect.custom_minimum_size = Vector2(64, 64)
	noise_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	noise_container.add_child(noise_texture_rect)
	
	# Normal texture
	var normal_container = HBoxContainer.new()
	texture_group.add_child(normal_container)
	normal_container.add_child(Label.new())
	normal_container.get_child(0).text = "Normal Map:"
	normal_texture_button = Button.new()
	normal_texture_button.text = "Select Normal Map"
	normal_container.add_child(normal_texture_button)
	normal_texture_rect = TextureRect.new()
	normal_texture_rect.custom_minimum_size = Vector2(64, 64)
	normal_texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	normal_container.add_child(normal_texture_rect)
	
	# File dialog
	texture_file_dialog = FileDialog.new()
	texture_file_dialog.access = FileDialog.ACCESS_RESOURCES
	texture_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	texture_file_dialog.add_filter("*.png", "PNG Images")
	texture_file_dialog.add_filter("*.jpg", "JPEG Images")
	texture_file_dialog.add_filter("*.exr", "EXR Images")
	add_child(texture_file_dialog)
	
	# === BASIC PARAMETERS ===
	var basic_group = create_group("Basic Parameters", vbox)
	
	# Sphere radius
	var radius_container = create_slider_control("Sphere Radius", 0.1, 5.0, 0.1, 1.0, basic_group)
	sphere_radius_slider = radius_container[0]
	sphere_radius_label = radius_container[1]
	
	# Amplitude
	var amplitude_container = create_slider_control("Amplitude", 0.0, 2.0, 0.01, 0.3, basic_group)
	amplitude_slider = amplitude_container[0]
	amplitude_label = amplitude_container[1]
	
	# Mix ratio
	var mix_ratio_container = create_slider_control("Mix Ratio", 0.0, 1.0, 0.01, 0.5, basic_group)
	mix_ratio_slider = mix_ratio_container[0]
	mix_ratio_label = mix_ratio_container[1]
	
	# Roughness
	var roughness_container = create_slider_control("Roughness", 0.0, 1.0, 0.01, 0.0, basic_group)
	roughness_slider = roughness_container[0]
	roughness_label = roughness_container[1]
	
	# === UV AND SCALING ===
	var scaling_group = create_group("UV & Scaling", vbox)
	
	# UV Scale
	var uv_container = HBoxContainer.new()
	scaling_group.add_child(uv_container)
	uv_container.add_child(Label.new())
	uv_container.get_child(0).text = "UV Scale:"
	uv_container.add_child(Label.new())
	uv_container.get_child(1).text = "X:"
	uv_scale_x_spinbox = create_spinbox(0.1, 10.0, 0.1, 1.0)
	uv_container.add_child(uv_scale_x_spinbox)
	uv_container.add_child(Label.new())
	uv_container.get_child(3).text = "Y:"
	uv_scale_y_spinbox = create_spinbox(0.1, 10.0, 0.1, 1.0)
	uv_container.add_child(uv_scale_y_spinbox)
	
	# Axis Scale
	var axis_container = HBoxContainer.new()
	scaling_group.add_child(axis_container)
	axis_container.add_child(Label.new())
	axis_container.get_child(0).text = "Axis Scale:"
	axis_container.add_child(Label.new())
	axis_container.get_child(1).text = "X:"
	axis_scale_x_spinbox = create_spinbox(0.1, 5.0, 0.1, 1.0)
	axis_container.add_child(axis_scale_x_spinbox)
	axis_container.add_child(Label.new())
	axis_container.get_child(3).text = "Y:"
	axis_scale_y_spinbox = create_spinbox(0.1, 5.0, 0.1, 1.0)
	axis_container.add_child(axis_scale_y_spinbox)
	axis_container.add_child(Label.new())
	axis_container.get_child(5).text = "Z:"
	axis_scale_z_spinbox = create_spinbox(0.1, 5.0, 0.1, 1.0)
	axis_container.add_child(axis_scale_z_spinbox)
	
	# === COLOR SECTION ===
	var color_group = create_group("Color", vbox)
	color_group.add_child(Label.new())
	color_group.get_child(0).text = "Mix Color:"
	mix_color_picker = ColorPicker.new()
	mix_color_picker.color = Color(1, 1, 1)
	mix_color_picker.custom_minimum_size = Vector2(200, 150)
	color_group.add_child(mix_color_picker)
	
	# === WORLD CENTER ===
	var world_group = create_group("World Center", vbox)
	var world_container = HBoxContainer.new()
	world_group.add_child(world_container)
	world_container.add_child(Label.new())
	world_container.get_child(0).text = "World Center:"
	world_container.add_child(Label.new())
	world_container.get_child(1).text = "X:"
	world_center_x_spinbox = create_spinbox(-100.0, 100.0, 0.1, 0.0)
	world_container.add_child(world_center_x_spinbox)
	world_container.add_child(Label.new())
	world_container.get_child(3).text = "Y:"
	world_center_y_spinbox = create_spinbox(-100.0, 100.0, 0.1, 0.0)
	world_container.add_child(world_center_y_spinbox)
	world_container.add_child(Label.new())
	world_container.get_child(5).text = "Z:"
	world_center_z_spinbox = create_spinbox(-100.0, 100.0, 0.1, 0.0)
	world_container.add_child(world_center_z_spinbox)
	
	# === SEAM FIX METHOD ===
	var method_group = create_group("Seam Fix Method", vbox)
	seam_fix_option_button = OptionButton.new()
	seam_fix_option_button.add_item("Original (UV-based)")
	seam_fix_option_button.add_item("3D Noise (Recommended)")
	seam_fix_option_button.add_item("Improved UV")
	seam_fix_option_button.add_item("Legacy Improved")
	seam_fix_option_button.add_item("Distance Adaptive (V2 only)")
	seam_fix_option_button.selected = 1
	method_group.add_child(seam_fix_option_button)
	
	# === V2 SPECIFIC PARAMETERS ===
	var v2_group = create_group("Version 2 Parameters", vbox)
	
	# Max distance
	var max_dist_container = create_slider_control("Max Distance", 1.0, 100.0, 1.0, 20.0, v2_group)
	max_distance_slider = max_dist_container[0]
	max_distance_label = max_dist_container[1]
	
	# Min amplitude ratio
	var min_amp_container = create_slider_control("Min Amplitude Ratio", 0.0, 1.0, 0.01, 0.1, v2_group)
	min_amplitude_ratio_slider = min_amp_container[0]
	min_amplitude_ratio_label = min_amp_container[1]
	
	# Parallax scale
	var parallax_scale_container = create_slider_control("Parallax Scale", 0.0, 0.1, 0.001, 0.02, v2_group)
	parallax_scale_slider = parallax_scale_container[0]
	parallax_scale_label = parallax_scale_container[1]
	
	# Parallax steps
	var parallax_steps_container = HBoxContainer.new()
	v2_group.add_child(parallax_steps_container)
	parallax_steps_container.add_child(Label.new())
	parallax_steps_container.get_child(0).text = "Parallax Steps:"
	parallax_steps_spinbox = create_spinbox(1, 32, 1, 8)
	parallax_steps_container.add_child(parallax_steps_spinbox)
	
	# === ACTION BUTTONS ===
	var action_group = create_group("Actions", vbox)
	var button_container = HBoxContainer.new()
	action_group.add_child(button_container)
	
	save_preset_button = Button.new()
	save_preset_button.text = "Save Preset"
	button_container.add_child(save_preset_button)
	
	load_preset_button = Button.new()
	load_preset_button.text = "Load Preset"
	button_container.add_child(load_preset_button)
	
	reset_button = Button.new()
	reset_button.text = "Reset to Defaults"
	button_container.add_child(reset_button)

func create_group(title: String, parent: Node) -> VBoxContainer:
	var group_container = VBoxContainer.new()
	parent.add_child(group_container)
	
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	group_container.add_child(title_label)
	
	var separator = HSeparator.new()
	group_container.add_child(separator)
	
	return group_container

func create_slider_control(label_text: String, min_val: float, max_val: float, step: float, default_val: float, parent: Node) -> Array:
	var container = HBoxContainer.new()
	parent.add_child(container)
	
	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(120, 0)
	container.add_child(label)
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.value = default_val
	slider.custom_minimum_size = Vector2(200, 0)
	container.add_child(slider)
	
	var value_label = Label.new()
	value_label.text = str(default_val)
	value_label.custom_minimum_size = Vector2(60, 0)
	container.add_child(value_label)
	
	return [slider, value_label]

func create_spinbox(min_val: float, max_val: float, step: float, default_val: float) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.min_value = min_val
	spinbox.max_value = max_val
	spinbox.step = step
	spinbox.value = default_val
	return spinbox

func connect_signals():
	# Version selection
	version_option_button.item_selected.connect(_on_version_changed)
	
	# Texture buttons
	noise_texture_button.pressed.connect(_on_noise_texture_pressed)
	normal_texture_button.pressed.connect(_on_normal_texture_pressed)
	texture_file_dialog.file_selected.connect(_on_texture_selected)
	
	# Basic parameters
	sphere_radius_slider.value_changed.connect(_on_sphere_radius_changed)
	amplitude_slider.value_changed.connect(_on_amplitude_changed)
	mix_ratio_slider.value_changed.connect(_on_mix_ratio_changed)
	roughness_slider.value_changed.connect(_on_roughness_changed)
	
	# UV and scaling
	uv_scale_x_spinbox.value_changed.connect(_on_uv_scale_changed)
	uv_scale_y_spinbox.value_changed.connect(_on_uv_scale_changed)
	axis_scale_x_spinbox.value_changed.connect(_on_axis_scale_changed)
	axis_scale_y_spinbox.value_changed.connect(_on_axis_scale_changed)
	axis_scale_z_spinbox.value_changed.connect(_on_axis_scale_changed)
	
	# Color
	mix_color_picker.color_changed.connect(_on_mix_color_changed)
	
	# World center
	world_center_x_spinbox.value_changed.connect(_on_world_center_changed)
	world_center_y_spinbox.value_changed.connect(_on_world_center_changed)
	world_center_z_spinbox.value_changed.connect(_on_world_center_changed)
	
	# Method selection
	seam_fix_option_button.item_selected.connect(_on_seam_fix_method_changed)
	
	# V2 parameters
	max_distance_slider.value_changed.connect(_on_max_distance_changed)
	min_amplitude_ratio_slider.value_changed.connect(_on_min_amplitude_ratio_changed)
	parallax_scale_slider.value_changed.connect(_on_parallax_scale_changed)
	parallax_steps_spinbox.value_changed.connect(_on_parallax_steps_changed)
	
	# Action buttons
	save_preset_button.pressed.connect(_on_save_preset)
	load_preset_button.pressed.connect(_on_load_preset)
	reset_button.pressed.connect(_on_reset)

# === SIGNAL HANDLERS ===
func _on_version_changed(index: int):
	material_generator.material_version = index as NEOMaterialGenerator.MaterialVersions
	_emit_material_changed()

func _on_noise_texture_pressed():
	current_texture_type = TextureType.NOISE
	texture_file_dialog.popup_centered(Vector2i(800, 600))

func _on_normal_texture_pressed():
	current_texture_type = TextureType.NORMAL
	texture_file_dialog.popup_centered(Vector2i(800, 600))

func _on_texture_selected(path: String):
	var texture = load(path) as Texture2D
	if texture:
		match current_texture_type:
			TextureType.NOISE:
				material_generator.noise_texture = texture
				noise_texture_rect.texture = texture
			TextureType.NORMAL:
				material_generator.normal_map_texture = texture
				normal_texture_rect.texture = texture
	_emit_material_changed()

func _on_sphere_radius_changed(value: float):
	material_generator.sphere_radius = value
	sphere_radius_label.text = str(value)
	_emit_material_changed()

func _on_amplitude_changed(value: float):
	material_generator.amplitude = value
	amplitude_label.text = str(value)
	_emit_material_changed()

func _on_mix_ratio_changed(value: float):
	material_generator.mix_ratio = value
	mix_ratio_label.text = str(value)
	_emit_material_changed()

func _on_roughness_changed(value: float):
	material_generator.roughness_value = value
	roughness_label.text = str(value)
	_emit_material_changed()

func _on_uv_scale_changed(_value: float):
	material_generator.uv_scale = Vector2(uv_scale_x_spinbox.value, uv_scale_y_spinbox.value)
	_emit_material_changed()

func _on_axis_scale_changed(_value: float):
	material_generator.axis_scale = Vector3(axis_scale_x_spinbox.value, axis_scale_y_spinbox.value, axis_scale_z_spinbox.value)
	_emit_material_changed()

func _on_mix_color_changed(color: Color):
	material_generator.mix_color = Vector3(color.r, color.g, color.b)
	_emit_material_changed()

func _on_world_center_changed(_value: float):
	material_generator.world_center = Vector3(world_center_x_spinbox.value, world_center_y_spinbox.value, world_center_z_spinbox.value)
	_emit_material_changed()

func _on_seam_fix_method_changed(index: int):
	material_generator.seam_fix_method = index
	_emit_material_changed()

func _on_max_distance_changed(value: float):
	material_generator.max_distance = value
	max_distance_label.text = str(value)
	_emit_material_changed()

func _on_min_amplitude_ratio_changed(value: float):
	material_generator.min_amplitude_ratio = value
	min_amplitude_ratio_label.text = str(value)
	_emit_material_changed()

func _on_parallax_scale_changed(value: float):
	material_generator.parallax_scale = value
	parallax_scale_label.text = str(value)
	_emit_material_changed()

func _on_parallax_steps_changed(value: float):
	material_generator.parallax_steps = int(value)
	_emit_material_changed()

func _on_save_preset():
	var file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.add_filter("*.json", "JSON Files")
	add_child(file_dialog)
	file_dialog.file_selected.connect(_save_preset_to_file)
	file_dialog.popup_centered(Vector2i(800, 600))

func _save_preset_to_file(path: String):
	var preset_data = material_generator.get_property_dict()
	var json_string = JSON.stringify(preset_data, "\t")
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Preset saved to: ", path)

func _on_load_preset():
	var file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.json", "JSON Files")
	add_child(file_dialog)
	file_dialog.file_selected.connect(_load_preset_from_file)
	file_dialog.popup_centered(Vector2i(800, 600))

func _load_preset_from_file(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var preset_data = json.get_data()
			material_generator.apply_property_dict(preset_data)
			update_ui_from_material()
			_emit_material_changed()
			print("Preset loaded from: ", path)

func _on_reset():
	# Reset to default values
	material_generator = NEOMaterialGenerator.new()
	remove_child(get_children()[-1])  # Remove old material generator
	add_child(material_generator)
	update_ui_from_material()
	_emit_material_changed()

func update_ui_from_material():
	# Update all UI elements to match current material generator values
	version_option_button.selected = material_generator.material_version
	
	sphere_radius_slider.value = material_generator.sphere_radius
	sphere_radius_label.text = str(material_generator.sphere_radius)
	
	amplitude_slider.value = material_generator.amplitude
	amplitude_label.text = str(material_generator.amplitude)
	
	mix_ratio_slider.value = material_generator.mix_ratio
	mix_ratio_label.text = str(material_generator.mix_ratio)
	
	roughness_slider.value = material_generator.roughness_value
	roughness_label.text = str(material_generator.roughness_value)
	
	uv_scale_x_spinbox.value = material_generator.uv_scale.x
	uv_scale_y_spinbox.value = material_generator.uv_scale.y
	
	axis_scale_x_spinbox.value = material_generator.axis_scale.x
	axis_scale_y_spinbox.value = material_generator.axis_scale.y
	axis_scale_z_spinbox.value = material_generator.axis_scale.z
	
	var color = material_generator.mix_color
	mix_color_picker.color = Color(color.x, color.y, color.z)
	
	world_center_x_spinbox.value = material_generator.world_center.x
	world_center_y_spinbox.value = material_generator.world_center.y
	world_center_z_spinbox.value = material_generator.world_center.z
	
	seam_fix_option_button.selected = material_generator.seam_fix_method
	
	max_distance_slider.value = material_generator.max_distance
	max_distance_label.text = str(material_generator.max_distance)
	
	min_amplitude_ratio_slider.value = material_generator.min_amplitude_ratio
	min_amplitude_ratio_label.text = str(material_generator.min_amplitude_ratio)
	
	parallax_scale_slider.value = material_generator.parallax_scale
	parallax_scale_label.text = str(material_generator.parallax_scale)
	
	parallax_steps_spinbox.value = material_generator.parallax_steps
	
	# Update texture previews
	if material_generator.noise_texture:
		noise_texture_rect.texture = material_generator.noise_texture
	if material_generator.normal_map_texture:
		normal_texture_rect.texture = material_generator.normal_map_texture

func _emit_material_changed():
	material_changed.emit(material_generator._get_material())

# === PUBLIC API ===
func _get_material() -> ShaderMaterial:
	return material_generator.get_material()

func get_material_generator() -> NEOMaterialGenerator:
	return material_generator

func apply_material_preset(preset_dict: Dictionary):
	material_generator.apply_property_dict(preset_dict)
	update_ui_from_material()
	_emit_material_changed()
