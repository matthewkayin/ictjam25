extends CharacterBody2D

enum Mode {
    PROWL,
    STALK,
    CHASE
}

const PROWL_SPEED: float = 200
const STALK_SPEED: float = 200
const CHASE_SPEED: float = 400
const PATH_POINT_DISTANCE_REQUIRED: float = 2.0

@onready var sprite = $sprite
@onready var nav_agent = $nav_agent

var mode: Mode = Mode.PROWL
var player = null

func _ready():
    $nav_timer.timeout.connect(on_nav_timer_timeout)

func on_nav_timer_timeout():
    if player == null:
        return
    nav_agent.set_target_position(player.global_position)

func _physics_process(_delta: float) -> void:
    if player == null:
        player = get_parent().get_node("player")
    if player == null:
        return

    velocity = global_position.direction_to(nav_agent.get_next_path_position()) * get_speed()
    move_and_slide()

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
