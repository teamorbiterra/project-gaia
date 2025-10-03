extends SceneBase

#region possible scene to instantiate
const GAME_MODE_SELECTOR = preload("uid://hupaolatm8pa")
#endregion possible scene to instantiate



@onready var new_game_button = %NewGameButton
@onready var continue_button = %ContinueButton
@onready var settings_button = %SettingsButton
@onready var quit_button = %QuitButton
@onready var headline = %Headline
@onready var tagline = %Tagline
@onready var credit_button = %CreditButton

func _ready():
	if is_node_ready():
		headline.visible_ratio=0.0
		tagline.visible_ratio=0.0
		var tween= create_tween()
		tween.tween_property(headline,'visible_ratio',1.0,1.0)
		await tween.finished
		tween.stop()
		tween.play()
		tween.tween_property(tagline,'visible_ratio',1.0,1.0)
		await  tween.finished
		tween.kill()
		
		new_game_button.pressed.connect(on_new_game_button_pressed)
		continue_button.pressed.connect(on_continue_button_pressed)
		settings_button.pressed.connect(on_settings_button_pressed)
		quit_button.pressed.connect(on_quit_button_pressed)
			
				
func on_new_game_button_pressed():
	SceneManager.load_composition(SceneManager.Composition.GAME_MODE_SELECTION)
	
func on_continue_button_pressed():
	pass

func on_settings_button_pressed():
	pass

func on_quit_button_pressed():
	pass
		
	
	
