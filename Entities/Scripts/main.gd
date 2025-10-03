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
		credit_button.pressed.connect(on_credit_button_pressed)
		
		#play the sound
		SoundManager.play(SoundManager.sounds.TITLE,true,0.5,0.1)
		
				
func on_new_game_button_pressed():
	SceneManager.load_composition(SceneManager.Composition.GAME_MODE_SELECTION)
	
func on_continue_button_pressed():
	pass

func on_settings_button_pressed():
	pass

func on_quit_button_pressed():
	print("Quiting game")
	await get_tree().create_timer(1.0).timeout
	get_tree().quit(0)
		

func on_credit_button_pressed():
	SceneManager.add(SceneManager.Scene.CREDIT_SCENE)


func _input(event):
	if event is InputEventKey and event.is_pressed():
		if event.keycode==KEY_ESCAPE and SceneManager.has(SceneManager.Scene.CREDIT_SCENE):
			SceneManager.remove(SceneManager.Scene.CREDIT_SCENE)
