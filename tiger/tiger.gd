extends CharacterBody2D

enum Mode {
    PROWL,
    STALK,
    CHASE
}

const PROWL_SPEED: float = 100
const STALK_SPEED: float = 200
const CHASE_SPEED: float = 400
const TALL_GRASS_SIGHT_RANGE: float = 64
const NOISE_HEARING_RANGE: float = 256
const LOST_SIGHT_DURATION: float = 1.0

@onready var sprite = $sprite
@onready var nav_agent = $nav_agent
@onready var player = get_node("../player")
@onready var sight_cones = [
    $sight_cone_up,
    $sight_cone_right,
    $sight_cone_down,
    $sight_cone_left
]
@onready var lost_sight_timer = $lost_sight_timer

enum FacingDirection {
    UP,
    RIGHT,
    DOWN,
    LEFT
}

var mode: Mode = Mode.PROWL
var point_of_interest: Vector2
var facing_direction = FacingDirection.DOWN

func _ready():
    $nav_timer.timeout.connect(on_nav_timer_timeout)
    player.made_noise.connect(on_player_made_noise)
    $lost_sight_timer.timeout.connect(on_lost_sight_timer_timeout)

func on_nav_timer_timeout():
    nav_agent.set_target_position(point_of_interest)

func on_player_made_noise(noise_position: Vector2, noise_loudness: int):
    assert(noise_loudness > 0)
    var noise_distance = global_position.distance_to(noise_position)
    var hearing_range = NOISE_HEARING_RANGE * noise_loudness
    # If it's too far away, you can't hear it
    if noise_distance > hearing_range:
        return
    # If it's kinda loud and close, then chase right away
    if noise_loudness > 1 and noise_distance < (NOISE_HEARING_RANGE * (noise_loudness - 1)):
        mode = Mode.CHASE
        return
    # Otherwise, stalk
    point_of_interest = noise_position
    if mode == Mode.PROWL:
        mode = Mode.STALK

func _physics_process(_delta: float) -> void:
    # Look for player
    if (mode == Mode.PROWL or mode == Mode.STALK) and can_see_player():
        mode = Mode.CHASE
    elif mode == Mode.CHASE:
        if can_see_player():
            point_of_interest = player.global_position
            lost_sight_timer.stop()
        elif lost_sight_timer.is_stopped():
            lost_sight_timer.start(LOST_SIGHT_DURATION)
    elif mode == Mode.STALK and nav_agent.is_navigation_finished():
        mode = Mode.PROWL

    velocity = global_position.direction_to(nav_agent.get_next_path_position()) * get_speed()
    move_and_slide()

    # Facing direction
    if velocity.x != 0 && abs(velocity.x) > abs(velocity.y):
        if velocity.x > 0:
            facing_direction = FacingDirection.RIGHT
        else:
            facing_direction = FacingDirection.LEFT
    elif velocity.y != 0 && abs(velocity.y) > abs(velocity.x):
        if velocity.y > 0:
            facing_direction = FacingDirection.DOWN
        else:
            facing_direction = FacingDirection.UP


    if mode == Mode.PROWL:
        sprite.play("prowl")
    elif mode == Mode.STALK:
        sprite.play("stalk")
    elif mode == Mode.CHASE:
        sprite.play("chase")

    $eyes.visible = can_see_player()

func can_see_player() -> bool:
    if not sight_cones[facing_direction].overlaps_body(player):
        return false
    if player.is_in_tall_grass() and position.distance_to(player.position) > TALL_GRASS_SIGHT_RANGE:
        return false
    return true

func on_lost_sight_timer_timeout():
    if mode == Mode.CHASE and not can_see_player() and nav_agent.is_navigation_finished():
        mode = Mode.STALK

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
