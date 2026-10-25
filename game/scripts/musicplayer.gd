extends Node

const menu_music: AudioStream = preload("res://assets/music/hecatestheme.ogg")
const level_music: AudioStream = preload("res://assets/music/levelmusic.wav")
const boss_music: AudioStream = preload("res://assets/music/bossmusic.wav")

var music_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Music"
	play_track(menu_music)

func play_track(new_stream: AudioStream) -> void:
	if music_player.stream == new_stream and music_player.playing:
		return
		
	music_player.stop()
	music_player.stream = new_stream
	music_player.play()
