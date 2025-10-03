extends Node

enum sounds {
	DAY,
	NIGHT,
	SEASHORE,
	TITLE,
	BUTTON_PRESS,
	SINGLE_KEY_PRESS
}

# Configuration: Set which sounds should be single-instance (music/ambience)
# All others will automatically support multiple simultaneous plays (SFX)
var SINGLE_INSTANCE_SOUNDS: Array[sounds] = [
	sounds.DAY,
	sounds.NIGHT,
	sounds.TITLE,
]

var SOUND_ARRAY: Dictionary = {
	sounds.DAY: "res://SFX/day.ogg",
	sounds.NIGHT: "res://SFX/night.ogg",
	sounds.SEASHORE: "res://SFX/seashore-60589.mp3",
	sounds.TITLE: "res://SFX/title.ogg",
	sounds.BUTTON_PRESS: "res://SFX/button_press.mp3",
	sounds.SINGLE_KEY_PRESS:"res://SFX/single_key_press.mp3"
}

# Single instance players (for music/background)
var _single_players: Dictionary = {}

# Multi-instance players (for SFX)
var _multi_players: Array = []
var _next_id: int = 0

# Volume settings
var _master_volume: float = 1.0
var _sound_volumes: Dictionary = {}


#region templates
func play_button_press_sound():	
	play(sounds.BUTTON_PRESS,false,0.5)




func _ready() -> void:
	# Initialize default volumes
	for sound in sounds.values():
		_sound_volumes[sound] = 1.0


## Play a sound - automatically handles single vs multi-instance
## @param sound: The sound enum to play
## @param loop: Whether to loop (usually for music/ambience)
## @param volume: Volume multiplier (0.0 to 1.0), -1 uses default
## @param fade_in: Fade-in duration in seconds
## @return: Instance ID (useful for multi-instance sounds), -1 for single-instance
func play(sound: sounds, loop: bool = false, volume: float = -1.0, fade_in: float = 0.0) -> int:
	if not SOUND_ARRAY.has(sound):
		push_error("Sound not found: " + str(sound))
		return -1
	
	# Check if this is a single-instance sound
	if sound in SINGLE_INSTANCE_SOUNDS:
		return _play_single(sound, loop, volume, fade_in)
	else:
		return _play_multi(sound, loop, volume, fade_in)


## Stop a sound
## @param sound: The sound to stop (stops all instances if multi-instance)
## @param fade_out: Fade-out duration in seconds
func stop(sound: sounds, fade_out: float = 0.0) -> void:
	if sound in SINGLE_INSTANCE_SOUNDS:
		_stop_single(sound, fade_out)
	else:
		_stop_all_multi(sound, fade_out)


## Stop a specific instance by ID (for multi-instance sounds)
func stop_instance(instance_id: int, fade_out: float = 0.0) -> void:
	for i in range(_multi_players.size() - 1, -1, -1):
		if _multi_players[i]["id"] == instance_id:
			_cleanup_multi_player(i, fade_out)
			return


## Stop all sounds
func stop_all(fade_out: float = 0.0) -> void:
	for sound in _single_players.keys():
		_stop_single(sound, fade_out)
	
	for i in range(_multi_players.size() - 1, -1, -1):
		_cleanup_multi_player(i, fade_out)


## Pause a sound
func pause(sound: sounds) -> void:
	if sound in SINGLE_INSTANCE_SOUNDS and _single_players.has(sound):
		_single_players[sound].stream_paused = true


## Resume a sound
func resume(sound: sounds) -> void:
	if sound in SINGLE_INSTANCE_SOUNDS and _single_players.has(sound):
		_single_players[sound].stream_paused = false


## Check if a sound is playing
func is_playing(sound: sounds) -> bool:
	if sound in SINGLE_INSTANCE_SOUNDS:
		return _single_players.has(sound) and _single_players[sound].playing
	else:
		# Check if any instance is playing
		for data in _multi_players:
			if data["sound"] == sound and data["player"].playing:
				return true
		return false


## Set master volume (affects all sounds)
func set_master_volume(vol: float) -> void:
	_master_volume = clamp(vol, 0.0, 1.0)
	_update_all_volumes()


## Get master volume
func get_master_volume() -> float:
	return _master_volume


## Set default volume for a sound type
func set_sound_volume(sound: sounds, vol: float) -> void:
	_sound_volumes[sound] = clamp(vol, 0.0, 1.0)
	
	# Update if currently playing
	if sound in SINGLE_INSTANCE_SOUNDS and _single_players.has(sound):
		var final_vol = _sound_volumes[sound] * _master_volume
		_single_players[sound].volume_db = linear_to_db(final_vol)


## Get default volume for a sound type
func get_sound_volume(sound: sounds) -> float:
	return _sound_volumes.get(sound, 1.0)


## Set volume of currently playing sound
func set_playing_volume(sound: sounds, vol: float, fade: float = 0.0) -> void:
	if not (sound in SINGLE_INSTANCE_SOUNDS and _single_players.has(sound)):
		return
	
	var player = _single_players[sound]
	var target_db = linear_to_db(clamp(vol * _master_volume, 0.0, 1.0))
	
	if fade > 0.0:
		var tween = create_tween()
		tween.tween_property(player, "volume_db", target_db, fade)
	else:
		player.volume_db = target_db


## Set volume of a specific instance
func set_instance_volume(instance_id: int, vol: float, fade: float = 0.0) -> void:
	for data in _multi_players:
		if data["id"] == instance_id:
			var player = data["player"]
			var target_db = linear_to_db(clamp(vol * _master_volume, 0.0, 1.0))
			
			if fade > 0.0:
				var tween = create_tween()
				tween.tween_property(player, "volume_db", target_db, fade)
			else:
				player.volume_db = target_db
			return


## Get count of active instances for a sound
func get_instance_count(sound: sounds) -> int:
	if sound in SINGLE_INSTANCE_SOUNDS:
		return 1 if is_playing(sound) else 0
	
	var count = 0
	for data in _multi_players:
		if data["sound"] == sound and data["player"].playing:
			count += 1
	return count


# === INTERNAL FUNCTIONS ===

func _play_single(sound: sounds, loop: bool, volume: float, fade_in: float) -> int:
	# Stop existing if playing
	if _single_players.has(sound):
		_stop_single(sound, 0.0)
	
	var player = _create_player(sound, loop, volume, fade_in)
	if player == null:
		return -1
	
	_single_players[sound] = player
	
	if not loop:
		player.finished.connect(_on_single_finished.bind(sound))
	
	return -1  # Single instance doesn't need ID


func _play_multi(sound: sounds, loop: bool, volume: float, fade_in: float) -> int:
	var player = _create_player(sound, loop, volume, fade_in)
	if player == null:
		return -1
	
	var instance_id = _next_id
	_next_id += 1
	
	var data = {
		"id": instance_id,
		"sound": sound,
		"player": player
	}
	_multi_players.append(data)
	
	if not loop:
		player.finished.connect(_on_multi_finished.bind(instance_id))
	
	return instance_id


func _create_player(sound: sounds, loop: bool, volume: float, fade_in: float) -> AudioStreamPlayer:
	var sound_path = SOUND_ARRAY[sound]
	var audio_stream = load(sound_path)
	
	if audio_stream == null:
		push_error("Failed to load: " + sound_path)
		return null
	
	var player = AudioStreamPlayer.new()
	player.stream = audio_stream
	player.bus = "Master"
	
	# Set volume
	var final_vol = volume if volume >= 0.0 else _sound_volumes[sound]
	final_vol = clamp(final_vol * _master_volume, 0.0, 1.0)
	player.volume_db = linear_to_db(final_vol)
	
	# Handle looping
	if audio_stream is AudioStreamOggVorbis or audio_stream is AudioStreamMP3:
		audio_stream.loop = loop
	elif audio_stream is AudioStreamWAV:
		audio_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	
	add_child(player)
	player.play()
	
	# Fade in
	if fade_in > 0.0:
		player.volume_db = -80.0
		var tween = create_tween()
		tween.tween_property(player, "volume_db", linear_to_db(final_vol), fade_in)
	
	return player


func _stop_single(sound: sounds, fade_out: float) -> void:
	if not _single_players.has(sound):
		return
	
	var player = _single_players[sound]
	
	if fade_out > 0.0:
		var tween = create_tween()
		tween.tween_property(player, "volume_db", -80.0, fade_out)
		tween.tween_callback(func(): _cleanup_single_player(sound))
	else:
		_cleanup_single_player(sound)


func _stop_all_multi(sound: sounds, fade_out: float) -> void:
	for i in range(_multi_players.size() - 1, -1, -1):
		if _multi_players[i]["sound"] == sound:
			_cleanup_multi_player(i, fade_out)


func _cleanup_single_player(sound: sounds) -> void:
	if _single_players.has(sound):
		var player = _single_players[sound]
		player.stop()
		player.queue_free()
		_single_players.erase(sound)


func _cleanup_multi_player(index: int, fade_out: float = 0.0) -> void:
	if index >= _multi_players.size():
		return
	
	var player = _multi_players[index]["player"]
	
	if fade_out > 0.0:
		var tween = create_tween()
		tween.tween_property(player, "volume_db", -80.0, fade_out)
		tween.tween_callback(func():
			player.stop()
			player.queue_free()
		)
	else:
		player.stop()
		player.queue_free()
	
	_multi_players.remove_at(index)


func _on_single_finished(sound: sounds) -> void:
	_cleanup_single_player(sound)


func _on_multi_finished(instance_id: int) -> void:
	for i in range(_multi_players.size() - 1, -1, -1):
		if _multi_players[i]["id"] == instance_id:
			_cleanup_multi_player(i)
			return


func _update_all_volumes() -> void:
	# Update single instance players
	for sound in _single_players.keys():
		var final_vol = _sound_volumes[sound] * _master_volume
		_single_players[sound].volume_db = linear_to_db(final_vol)
	
	# Update multi instance players
	for data in _multi_players:
		var sound = data["sound"]
		var final_vol = _sound_volumes[sound] * _master_volume
		data["player"].volume_db = linear_to_db(final_vol)
