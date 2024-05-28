extends AudioStreamPlayer

const level_music = preload ("res://Sounds/28_finish - spaced out.ogg")

func _play_music(audio, volume=0.0, is_looped=true) -> void:
	if stream == audio:
		return
	
	stream = audio
	volume_db = volume
	stream.set_loop(is_looped)
	play()

func play_music_level() -> void:
	_play_music(level_music)
