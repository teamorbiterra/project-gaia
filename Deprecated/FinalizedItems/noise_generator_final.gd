extends Node2D
class_name NoiseGeneratorF

@onready var control = %Control
@export var noise_texture: NoiseTexture2D
@export var noise:FastNoiseLite	
@export var texture_rect: TextureRect

@export var texture_size:Vector3 = Vector3(100,100,0):
	set(value):
		texture_size= value
		noise_texture.width= round(value.x)
		noise_texture.height= round(value.y)
	get:
		return texture_size


func _ready():
	var editor = PropertyEditorGenerator.generate_property_editor(self, control,
	[
		"control","noise_texture","texture_rect","noise"
	])
	await get_tree().process_frame

	var target_container: ScrollContainer

	texture_rect = TextureRect.new()
	texture_rect.texture = noise_texture if noise_texture != null else load("res://icon.svg")
	
	if control.get_child(0) is ScrollContainer:
		target_container = control.get_child(0)
		target_container.add_child(texture_rect)
		target_container.move_child(texture_rect, 0)

	control.print_tree_pretty()
	
	
