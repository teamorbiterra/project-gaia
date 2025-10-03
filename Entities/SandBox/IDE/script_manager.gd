extends Node

@onready var ide = $".."
@onready var editor = %EDITOR

# Custom dialog overlays (not popups!)
var overlay: Control
var save_dialog: Control
var load_dialog: Control
var confirm_dialog: Control

# UI Components
var save_name: LineEdit
var script_list: ItemList
var delete_button: Button

# Data
var saved_scripts: Dictionary = {}
var current_script_name: String = ""
var last_saved_state: String = ""

# Pending actions
var pending_action: Callable

# Save directory
const SAVE_DIR = "user://saved_scripts/"
const SAVE_EXTENSION = ".gd"

func _ready():
	_ensure_save_directory()
	_load_all_scripts()
	_setup_overlay()
	_setup_save_dialog()
	_setup_load_dialog()
	_setup_confirm_dialog()

# ==================== FILE SYSTEM ====================

func _ensure_save_directory():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saved_scripts"):
		dir.make_dir("saved_scripts")

func _get_script_path(script_name: String) -> String:
	return SAVE_DIR + script_name + SAVE_EXTENSION

func _load_all_scripts():
	var dir = DirAccess.open(SAVE_DIR)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(SAVE_EXTENSION):
			var script_name = file_name.trim_suffix(SAVE_EXTENSION)
			var file_path = SAVE_DIR + file_name
			var code = _read_script_file(file_path)
			if code != "":
				saved_scripts[script_name] = code
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("[Script Manager] Loaded %d script(s) from disk" % saved_scripts.size())

func _read_script_file(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to read script: " + path)
		return ""
	
	var content = file.get_as_text()
	file.close()
	return content

func _write_script_file(script_name: String, code: String) -> bool:
	var file_path = _get_script_path(script_name)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null:
		push_error("Failed to write script: " + file_path)
		return false
	
	file.store_string(code)
	file.close()
	print("[Script Manager] Saved script to: " + file_path)
	return true

func _delete_script_file(script_name: String) -> bool:
	var file_path = _get_script_path(script_name)
	var dir = DirAccess.open(SAVE_DIR)
	
	if dir == null:
		return false
	
	var error = dir.remove(file_path)
	if error == OK:
		print("[Script Manager] Deleted script file: " + file_path)
		return true
	else:
		push_error("Failed to delete script: " + file_path)
		return false

# ==================== OVERLAY SYSTEM ====================

func _setup_overlay():
	# Create full-screen overlay for modal dialogs
	overlay = Control.new()
	overlay.name = "DialogOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	
	# Semi-transparent background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(bg)
	
	# Click outside to close
	bg.gui_input.connect(_on_overlay_input)
	
	ide.add_child.call_deferred(overlay)

func _on_overlay_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_hide_all_dialogs()

func _show_overlay():
	overlay.visible = true
	overlay.move_to_front()

func _hide_all_dialogs():
	overlay.visible = false
	save_dialog.visible = false
	load_dialog.visible = false
	confirm_dialog.visible = false

# ==================== SAVE DIALOG ====================

func _setup_save_dialog():
	save_dialog = Panel.new()
	save_dialog.name = "SaveDialog"
	save_dialog.custom_minimum_size = Vector2(450, 200)
	save_dialog.visible = false
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	vbox.add_theme_constant_override("margin_left", 20)
	vbox.add_theme_constant_override("margin_right", 20)
	vbox.add_theme_constant_override("margin_top", 20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	
	# Title
	var title = Label.new()
	title.text = "💾 Save Script"
	title.add_theme_font_size_override("font_size", 40)
	vbox.add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Enter a name for your script:"
	subtitle.add_theme_font_size_override("font_size", 13)
	vbox.add_child(subtitle)
	
	# Input field
	save_name = LineEdit.new()
	save_name.placeholder_text = "my_awesome_script"
	save_name.custom_minimum_size = Vector2(0, 40)
	save_name.alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_name.text_submitted.connect(func(_t): _on_save_confirmed())
	vbox.add_child(save_name)
	
	# Hint
	var hint = Label.new()
	hint.text = "💡 Tip: Use descriptive names for easy identification"
	hint.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hint)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 10
	vbox.add_child(spacer)
	
	# Buttons
	var button_box = HBoxContainer.new()
	button_box.alignment = BoxContainer.ALIGNMENT_END
	button_box.add_theme_constant_override("separation", 10)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(100, 36)
	cancel_btn.pressed.connect(_hide_all_dialogs)
	button_box.add_child(cancel_btn)
	
	var ok_btn = Button.new()
	ok_btn.text = "Save"
	ok_btn.custom_minimum_size = Vector2(100, 36)
	ok_btn.pressed.connect(_on_save_confirmed)
	button_box.add_child(ok_btn)
	
	vbox.add_child(button_box)
	save_dialog.add_child(vbox)
	overlay.add_child(save_dialog)

# ==================== LOAD DIALOG ====================

func _setup_load_dialog():
	load_dialog = Panel.new()
	load_dialog.name = "LoadDialog"
	load_dialog.custom_minimum_size = Vector2(550, 500)
	load_dialog.visible = false
	
	# Style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.18)
	panel_style.set_corner_radius_all(8)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.3, 0.5, 0.7, 0.8)
	load_dialog.add_theme_stylebox_override("panel", panel_style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)
	vbox.add_theme_constant_override("margin_left", 20)
	vbox.add_theme_constant_override("margin_right", 20)
	vbox.add_theme_constant_override("margin_top", 20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	
	# Title
	var title = Label.new()
	title.text = "📂 Load Script"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	vbox.add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Select a script to load:"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	vbox.add_child(subtitle)
	
	# Script list
	script_list = ItemList.new()
	script_list.select_mode = ItemList.SELECT_SINGLE
	script_list.custom_minimum_size = Vector2(0, 320)
	script_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_item_list(script_list)
	script_list.item_selected.connect(func(_idx): delete_button.disabled = false)
	script_list.item_activated.connect(func(_idx): _on_load_confirmed())
	vbox.add_child(script_list)
	
	# Bottom bar
	var bottom_box = HBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 10)
	
	delete_button = _create_button("🗑️ Delete", Color(0.8, 0.3, 0.3))
	delete_button.disabled = true
	delete_button.pressed.connect(_on_delete_pressed)
	bottom_box.add_child(delete_button)
	
	var count_label = Label.new()
	count_label.name = "CountLabel"
	count_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8))
	count_label.add_theme_font_size_override("font_size", 13)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_box.add_child(count_label)
	
	var cancel_btn = _create_button("Cancel", Color(0.4, 0.4, 0.45))
	cancel_btn.pressed.connect(_hide_all_dialogs)
	bottom_box.add_child(cancel_btn)
	
	var load_btn = _create_button("Load", Color(0.3, 0.6, 0.8))
	load_btn.pressed.connect(_on_load_confirmed)
	bottom_box.add_child(load_btn)
	
	vbox.add_child(bottom_box)
	load_dialog.add_child(vbox)
	overlay.add_child(load_dialog)

# ==================== CONFIRM DIALOG ====================

func _setup_confirm_dialog():
	confirm_dialog = Panel.new()
	confirm_dialog.name = "ConfirmDialog"
	confirm_dialog.custom_minimum_size = Vector2(450, 180)
	confirm_dialog.visible = false
	
	# Style - default to warning
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.18)
	panel_style.set_corner_radius_all(8)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.8, 0.5, 0.2, 0.8)
	confirm_dialog.add_theme_stylebox_override("panel", panel_style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	vbox.add_theme_constant_override("margin_left", 20)
	vbox.add_theme_constant_override("margin_right", 20)
	vbox.add_theme_constant_override("margin_top", 20)
	vbox.add_theme_constant_override("margin_bottom", 20)
	
	# Title
	var title = Label.new()
	title.name = "Title"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	vbox.add_child(title)
	
	# Message
	var message = Label.new()
	message.name = "Message"
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 13)
	message.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(message)
	
	# Buttons container
	var button_box = HBoxContainer.new()
	button_box.name = "ButtonBox"
	button_box.alignment = BoxContainer.ALIGNMENT_END
	button_box.add_theme_constant_override("separation", 10)
	vbox.add_child(button_box)
	
	confirm_dialog.add_child(vbox)
	overlay.add_child(confirm_dialog)

func _show_confirm(title_text: String, message_text: String, on_confirm: Callable, confirm_text: String = "OK", cancel_text: String = "Cancel", color: Color = Color(0.8, 0.5, 0.2, 0.8)):
	var title = confirm_dialog.get_node("VBoxContainer/Title")
	var message = confirm_dialog.get_node("VBoxContainer/Message")
	var button_box = confirm_dialog.get_node("VBoxContainer/ButtonBox")
	
	title.text = title_text
	message.text = message_text
	
	# Update border color
	var panel_style = confirm_dialog.get_theme_stylebox("panel").duplicate()
	panel_style.border_color = color
	confirm_dialog.add_theme_stylebox_override("panel", panel_style)
	
	# Clear and rebuild buttons
	for child in button_box.get_children():
		child.queue_free()
	
	var cancel_btn = _create_button(cancel_text, Color(0.4, 0.4, 0.45))
	cancel_btn.pressed.connect(_hide_all_dialogs)
	button_box.add_child(cancel_btn)
	
	var confirm_btn = _create_button(confirm_text, Color(0.3, 0.6, 0.8) if color == Color(0.8, 0.5, 0.2, 0.8) else Color(0.8, 0.3, 0.3))
	confirm_btn.pressed.connect(func():
		on_confirm.call()
		_hide_all_dialogs()
	)
	button_box.add_child(confirm_btn)
	
	_center_dialog(confirm_dialog)
	_show_overlay()
	confirm_dialog.visible = true

# ==================== PUBLIC METHODS ====================

func save_script():
	if current_script_name != "":
		save_name.text = current_script_name
	else:
		save_name.text = ""
	
	_center_dialog(save_dialog)
	_show_overlay()
	save_dialog.visible = true
	save_name.grab_focus()
	save_name.select_all()

func load_script():
	if _has_unsaved_changes():
		_show_unsaved_warning()
	else:
		_show_load_dialog()

# ==================== SAVE LOGIC ====================

func _on_save_confirmed():
	var _name = save_name.text.strip_edges()
	
	if _name == "":
		_show_error("Script name cannot be empty!")
		return
	
	if not _is_valid_name(_name):
		_show_error("Invalid name! Use only letters, numbers, and underscores.")
		return
	
	# Check if overwriting
	if saved_scripts.has(_name) and _name != current_script_name:
		_show_confirm(
			"⚠️ Overwrite Script?",
			"A script named '%s' already exists.\nDo you want to overwrite it?" % _name,
			_force_save,
			"Overwrite",
			"Cancel"
		)
		return
	
	_force_save()

func _force_save():
	var _name = save_name.text.strip_edges()
	var code = editor.text
	
	# Save to disk
	if not _write_script_file(_name, code):
		_show_error("Failed to save script to disk!")
		return
	
	# Update memory
	saved_scripts[_name] = code
	current_script_name = _name
	last_saved_state = code
	
	_update_script_list()
	_show_notification("Script '%s' saved successfully!" % _name)
	_hide_all_dialogs()

# ==================== LOAD LOGIC ====================

func _show_load_dialog():
	_update_script_list()
	_center_dialog(load_dialog)
	_show_overlay()
	load_dialog.visible = true
	
	# Pre-select current script
	if current_script_name != "":
		for i in script_list.item_count:
			if script_list.get_item_text(i) == current_script_name:
				script_list.select(i)
				delete_button.disabled = false
				break

func _on_load_confirmed():
	var selected = script_list.get_selected_items()
	if selected.size() == 0:
		return
	
	var idx = selected[0]
	var _name = script_list.get_item_text(idx)
	var code = saved_scripts.get(_name, "")
	
	editor.text = code
	current_script_name = _name
	last_saved_state = code
	
	_hide_all_dialogs()
	_show_notification("Script '%s' loaded" % _name)

func _on_delete_pressed():
	var selected = script_list.get_selected_items()
	if selected.size() == 0:
		return
	
	var idx = selected[0]
	var _name = script_list.get_item_text(idx)
	
	_show_confirm(
		"🗑️ Delete Script?",
		"Are you sure you want to delete '%s'?\nThis cannot be undone." % _name,
		func():
		# Delete from disk
		_delete_script_file(_name)
		
		# Delete from memory
		saved_scripts.erase(_name)
		if current_script_name == _name:
			current_script_name = ""
			last_saved_state = ""
		_update_script_list()
		_show_notification("Script '%s' deleted" % _name)
		_show_load_dialog()  # Refresh the load dialog
		,
		"Delete",
		"Cancel",
		Color(0.8, 0.3, 0.3, 0.8)
	)

# ==================== UNSAVED CHANGES ====================

func _has_unsaved_changes() -> bool:
	if editor.text == "":
		return false
	
	if current_script_name != "":
		return editor.text != saved_scripts.get(current_script_name, "")
	
	return editor.text != last_saved_state

func _show_unsaved_warning():
	_show_confirm(
		"⚠️ Unsaved Changes",
		"You have unsaved changes in the editor.\nDo you want to save before loading?",
		func():
		save_script()
		# After save dialog closes, show load dialog
		pending_action = _show_load_dialog
		,
		"Save & Load",
		"Discard & Load"
	)
	
	# Add third button for "Cancel"
	var button_box = confirm_dialog.get_node("VBoxContainer/ButtonBox")
	var cancel_only = _create_button("Cancel", Color(0.3, 0.3, 0.35))
	cancel_only.pressed.connect(_hide_all_dialogs)
	button_box.move_child(cancel_only, 0)

# ==================== HELPERS ====================

func _update_script_list():
	script_list.clear()
	delete_button.disabled = true
	
	var names = saved_scripts.keys()
	names.sort()
	
	for _name in names:
		var preview = saved_scripts[_name]
		if preview.length() > 50:
			preview = preview.substr(0, 50) + "..."
		preview = preview.replace("\n", " ")
		
		script_list.add_item(_name)
		var idx = script_list.item_count - 1
		script_list.set_item_tooltip(idx, "Preview: %s" % preview)
		
		if name == current_script_name:
			script_list.set_item_custom_bg_color(idx, Color(0.3, 0.5, 0.3, 0.3))
	
	var count_label = load_dialog.get_node_or_null("VBoxContainer/HBoxContainer/CountLabel")
	if count_label:
		count_label.text = "%d script(s)" % saved_scripts.size()

func _is_valid_name(_name: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_]+$")
	return regex.search(_name) != null

func _show_error(message: String):
	_show_confirm(
		"❌ Error",
		message,
		func(): pass,
		"OK",
		"",
		Color(0.8, 0.3, 0.3, 0.8)
	)
	
	# Remove cancel button for error dialogs
	var button_box = confirm_dialog.get_node("VBoxContainer/ButtonBox")
	if button_box.get_child_count() > 1:
		button_box.get_child(0).queue_free()

func _show_notification(message: String):
	print("[Script Manager] ", message)

func _center_dialog(dialog: Control):
	var viewport_size = get_viewport().get_visible_rect().size
	dialog.position = (viewport_size - dialog.custom_minimum_size) / 2

# ==================== STYLING HELPERS ====================

func _create_button(text: String, color: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(100, 36)
	_style_button(btn, color)
	return btn

func _style_button(button: Button, base_color: Color):
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = base_color
	normal_style.set_corner_radius_all(6)
	normal_style.content_margin_left = 16
	normal_style.content_margin_right = 16
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8
	button.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = base_color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = base_color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed_style)
	
	var disabled_style = normal_style.duplicate()
	disabled_style.bg_color = Color(0.3, 0.3, 0.3)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_font_size_override("font_size", 14)

func _style_line_edit(line_edit: LineEdit):
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = Color(0.1, 0.1, 0.12)
	input_style.set_corner_radius_all(6)
	input_style.set_border_width_all(2)
	input_style.border_color = Color(0.4, 0.6, 0.8, 0.3)
	input_style.content_margin_left = 12
	input_style.content_margin_right = 12
	line_edit.add_theme_stylebox_override("normal", input_style)
	
	var input_focus = input_style.duplicate()
	input_focus.border_color = Color(0.4, 0.7, 1.0, 0.8)
	line_edit.add_theme_stylebox_override("focus", input_focus)
	
	line_edit.add_theme_color_override("font_color", Color(1, 1, 1))
	line_edit.add_theme_color_override("font_placeholder_color", Color(0.5, 0.5, 0.55))
	line_edit.add_theme_font_size_override("font_size", 16)

func _style_item_list(item_list: ItemList):
	var list_style = StyleBoxFlat.new()
	list_style.bg_color = Color(0.1, 0.1, 0.12)
	list_style.set_corner_radius_all(6)
	list_style.set_border_width_all(2)
	list_style.border_color = Color(0.4, 0.6, 0.8, 0.3)
	item_list.add_theme_stylebox_override("panel", list_style)
	
	var selected_style = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.3, 0.5, 0.7, 0.4)
	selected_style.set_corner_radius_all(4)
	item_list.add_theme_stylebox_override("selected", selected_style)
	item_list.add_theme_stylebox_override("selected_focus", selected_style)
	
	item_list.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	item_list.add_theme_color_override("font_selected_color", Color(1, 1, 1))
	item_list.add_theme_font_size_override("font_size", 15)
	item_list.add_theme_constant_override("v_separation", 8)

# ==================== UTILITY ====================

func get_current_script_name() -> String:
	return current_script_name

func has_unsaved_changes() -> bool:
	return _has_unsaved_changes()

func export_scripts() -> Dictionary:
	return saved_scripts.duplicate(true)

func import_scripts(data: Dictionary):
	for script_name in data.keys():
		var code = data[script_name]
		_write_script_file(script_name, code)
		saved_scripts[script_name] = code
	_update_script_list()
	_show_notification("Imported %d script(s)" % data.size())

func get_save_directory() -> String:
	return ProjectSettings.globalize_path(SAVE_DIR)

func open_save_folder():
	OS.shell_open(get_save_directory())
