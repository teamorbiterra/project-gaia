## Scene Manager with Composition Support (Enum Edition)
## Handles complex scene combinations and transitions
## Add as Autoload: SceneManager
extends Node

## Scene enum - add your scenes here
enum Scene {
	MAIN,
	EARTH_ASTEROID_SYSTEM,
	GAME_MODE_SELECTOR,
	IDE_SCENE,
	NEO_LIBRARY_VIEWER,
	IMPACT_MODELER,
	CREDIT_SCENE
}

## Composition enum - add your presets here
enum Composition {
	MAIN_MENU,
	GAME_MODE_SELECTION,
	IDE_COMPOSITION,
	NEO_LIBRARY_VIWER_COMPOSITION,
	IMPACT_MODELING_COMPOSITION
}

## Scene paths mapped to enum
const SCENE_PATHS = {
	Scene.MAIN: "res://Entities/Scenes/Main.tscn",
	Scene.EARTH_ASTEROID_SYSTEM: "res://Entities/Scenes/EarthAesteroidSystem.tscn",
	Scene.GAME_MODE_SELECTOR:"res://Entities/Scenes/Game Mode Selector.tscn" , 
	Scene.IDE_SCENE:"res://Entities/SandBox/IDE/IDE.tscn",
	Scene.NEO_LIBRARY_VIEWER: "res://Entities/Scenes/NEOLibraryViewer.tscn",
	Scene.IMPACT_MODELER: "res://MissionDesignPhase/ImpactModeler.tscn",
	Scene.CREDIT_SCENE: "res://Entities/Scenes/CreditScene.tscn"
}



## Composition definitions mapped to enum
const COMPOSITION_SCENES = {
	Composition.MAIN_MENU: [Scene.MAIN, Scene.EARTH_ASTEROID_SYSTEM],
	Composition.GAME_MODE_SELECTION: [Scene.EARTH_ASTEROID_SYSTEM, Scene.GAME_MODE_SELECTOR],
	Composition.IDE_COMPOSITION:[Scene.IDE_SCENE],
	Composition.NEO_LIBRARY_VIWER_COMPOSITION:[Scene.NEO_LIBRARY_VIEWER],
	Composition.IMPACT_MODELING_COMPOSITION:[Scene.IMPACT_MODELER] #TODO: add more items related to impact modeling 

}

## Currently active scenes (key = Scene enum, value = instance)
var active_scenes: Dictionary = {}

signal scene_added(scene: Scene, instance: Node)
signal scene_removed(scene: Scene)
signal composition_loaded(composition: Composition)

## Load a composition (combination of scenes)
func load_composition(composition: Composition) -> void:
	if not composition in COMPOSITION_SCENES:
		push_error("Composition not found: " + str(composition))
		return
	
	# Clear all current scenes
	clear_all()
	
	# Load all scenes in the composition
	for scene in COMPOSITION_SCENES[composition]:
		add(scene)
	
	composition_loaded.emit(composition)

## Add a single scene (if not already active)
func add(scene: Scene) -> Node:
	if scene in active_scenes:
		push_warning("Scene already active: " + str(scene))
		return active_scenes[scene]
	
	if not scene in SCENE_PATHS:
		push_error("Scene not found: " + str(scene))
		return null
	
	var instance = load(SCENE_PATHS[scene]).instantiate()
	get_tree().root.add_child.call_deferred(instance)
	active_scenes[scene] = instance
	
	scene_added.emit(scene, instance)
	return instance

## Remove a single scene
func remove(scene: Scene) -> void:
	if not scene in active_scenes:
		push_warning("Scene not active: " + str(scene))
		return
	
	var instance = active_scenes[scene]
	instance.queue_free()
	active_scenes.erase(scene)
	
	scene_removed.emit(scene)

## Replace one scene with another (atomic operation)
func replace(old_scene: Scene, new_scene: Scene) -> Node:
	remove(old_scene)
	return add(new_scene)

## Add multiple scenes at once
func add_multiple(scenes: Array[Scene]) -> void:
	for scene in scenes:
		add(scene)

## Remove multiple scenes at once
func remove_multiple(scenes: Array[Scene]) -> void:
	for scene in scenes:
		remove(scene)

## Check if scene is active
func has(scene: Scene) -> bool:
	return scene in active_scenes

## Get instance of an active scene
func get_scene(scene: Scene) -> Node:
	return active_scenes.get(scene, null)

## Clear all active scenes
func clear_all() -> void:
	var scenes_to_remove = active_scenes.keys()
	for scene in scenes_to_remove:
		remove(scene)

## Get list of currently active scenes
func get_active_scenes() -> Array:
	return active_scenes.keys()

## Batch operations - queue multiple operations and execute atomically
var _operation_queue: Array = []
var _is_batching: bool = false

func begin_batch() -> void:
	_is_batching = true
	_operation_queue.clear()

func end_batch() -> void:
	_is_batching = false
	
	# Execute all queued operations
	for op in _operation_queue:
		match op.type:
			"add":
				add(op.scene)
			"remove":
				remove(op.scene)
			"replace":
				replace(op.old_scene, op.new_scene)
	
	_operation_queue.clear()

func _queue_or_execute(operation: Dictionary) -> void:
	if _is_batching:
		_operation_queue.append(operation)
	else:
		match operation.type:
			"add":
				add(operation.scene)
			"remove":
				remove(operation.scene)
			"replace":
				replace(operation.old_scene, operation.new_scene)
