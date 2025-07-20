extends StaticBody2D

enum Mode {
    FLAME,
    DOUSE,
    FINISHED
}

var mode = Mode.FLAME

func fire_is_finished() -> bool:
    return mode == Mode.FINISHED

func fire_douse():
    mode = Mode.DOUSE

func fire_finish():
    mode = Mode.FINISHED