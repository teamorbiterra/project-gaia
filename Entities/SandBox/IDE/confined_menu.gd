extends Button
class_name ConfinedMenu


@export_group("Items")
@export var items: PackedStringArray

signal id_pressed(id: int)

var panel: Panel

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	# If already open → close first
	if panel and is_instance_valid(panel):
		panel.queue_free()
		panel = null
		return
	
	# Panel (the dropdown box)
	panel = Panel.new()
	add_child(panel)
	
	# VBox container (no scroll for now, direct children)
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Add menu items
	for i in items.size():
		var button = Button.new()
		button.text = items[i]
		button.custom_minimum_size = Vector2(size.x, 0)
		vbox.add_child(button)
		button.pressed.connect(func():
			id_pressed.emit(i)
			if is_instance_valid(panel):
				panel.queue_free()
			panel = null)
	
	# Wait for layout to calculate sizes
	await get_tree().process_frame
	
	# Position below the button using global coordinates
	panel.global_position = global_position + size * Vector2.DOWN
	
	# Resize panel to fit all buttons
	panel.custom_minimum_size = vbox.size
	panel.size = vbox.size

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if panel and is_instance_valid(panel):
			if not panel.get_global_rect().has_point(event.global_position):
				panel.queue_free()
				panel = null
