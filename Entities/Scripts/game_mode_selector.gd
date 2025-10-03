extends SceneBase




@onready var story_mode_button = %StoryModeButton
@onready var sandbox_mode_button = %SandboxModeButton
@onready var back_to_main_button = %BackToMainButton


func _ready():
	sandbox_mode_button.pressed.connect(
		func():
		SceneManager.load_composition(SceneManager.Composition.NEO_LIBRARY_VIWER_COMPOSITION)
		SoundManager.play_button_press_sound()
	)
	back_to_main_button.pressed.connect(
		func():
		SceneManager.load_composition(SceneManager.Composition.MAIN_MENU)
		SoundManager.play_button_press_sound()	
	)
