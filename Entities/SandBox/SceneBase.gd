
## SceneBase.gd - Base class with enum support
extends Node
class_name SceneBase

## Set this to match your scene's enum value
var scene_id: SceneManager.Scene

## Navigation helpers using enums

## Replace this scene with another
func goto(new_scene: SceneManager.Scene) -> void:
	SceneManager.replace(scene_id, new_scene)

## Add a scene alongside this one
func show(scene: SceneManager.Scene) -> void:
	SceneManager.add(scene)

## Remove a scene
func hide_scene(scene: SceneManager.Scene) -> void:
	SceneManager.remove(scene)

## Close this scene
func close() -> void:
	SceneManager.remove(scene_id)

## Load a preset composition
func load_preset(composition: SceneManager.Composition) -> void:
	SceneManager.load_composition(composition)
