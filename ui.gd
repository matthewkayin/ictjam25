extends CanvasLayer

@onready var kill_animation = $kill_animation

func _ready():
    kill_animation.stop()
    kill_animation.modulate.a = 0

func play_kill_animation():
    kill_animation.modulate.a = 1
    kill_animation.play()
    await kill_animation.animation_finished

func fade_in():
    var tween = get_tree().create_tween()
    tween.tween_property(kill_animation, "modulate", Color(1, 1, 1, 0), 1.0)
    await tween.finished
