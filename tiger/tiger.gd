extends CharacterBody2D

enum Mode {
    PROWL,
    STALK,
    CHASE
}

const PROWL_SPEED: float = 100
const STALK_SPEED: float = 200
const CHASE_SPEED: float = 400
const PATH_POINT_DISTANCE_REQUIRED: float = 2.0

@onready var sprite = $sprite
@onready var tilemap = get_node("../tilemap") 

@export var debug_draw_path: bool = false
@export var CELL_SIZE: Vector2i = Vector2i(4, 4)

var mode: Mode = Mode.PROWL
var player = null
var path = []

func _ready():
    $nav_timer.timeout.connect(on_nav_timer_timeout)

func on_nav_timer_timeout():
    if player == null:
        return
    path = tilemap.pathfind(position, CELL_SIZE, player.position)

func _physics_process(_delta: float) -> void:
    if player == null:
        player = get_parent().get_node("player")
    if player == null:
        return

    if not path.is_empty():
        velocity = position.direction_to(path[0]) * get_speed()
        move_and_slide()
        if position.distance_to(path[0]) < PATH_POINT_DISTANCE_REQUIRED:
            path.pop_front()
    if debug_draw_path:
        queue_redraw()

func on_spear_hit():
    sprite.play("hurt")
    await get_tree().create_timer(0.5).timeout
    sprite.play("idle")

func get_speed() -> float:
    if mode == Mode.PROWL:
        return PROWL_SPEED
    elif mode == Mode.STALK:
        return STALK_SPEED
    elif mode == Mode.CHASE:
        return CHASE_SPEED
    else:
        return 0

func _draw():
    if debug_draw_path:
        var previous = position
        for point in path:
            draw_line(previous - position, point - position, Color.WHITE)
            previous = point
