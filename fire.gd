extends StaticBody2D

enum Mode {
    FLAME,
    DOUSE,
    FINISHED
}

var mode = Mode.FLAME
@onready var fire = $fire

func _ready():
    fire.play()

func fire_is_finished() -> bool:
    return mode == Mode.FINISHED

func fire_douse():
    mode = Mode.DOUSE

func fire_finish():
    mode = Mode.FINISHED

func _physics_process(_delta: float) -> void:
    fire.visible = mode == Mode.FLAME