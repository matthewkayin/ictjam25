extends Node

@onready var music_chase = $music_chase
@onready var music_sneak = $music_sneak

var current_track: String = "sneak"

func _ready():
    pass

func start_music():
    music_sneak.play()
    current_track = "sneak"

func stop_music():
    music_sneak.stop()
    music_chase.stop()

func set_track(track: String):
    if current_track == track:
        return
    if track == "sneak":
        music_sneak.play(music_chase.get_playback_position())
        music_chase.stop()
    elif track == "chase":
        music_chase.play(music_sneak.get_playback_position())
        music_sneak.stop()
    current_track = track
