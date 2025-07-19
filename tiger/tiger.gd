extends CharacterBody2D

enum Mode {
    PROWL,
    STALK,
    CHASE
}

const PROWL_SPEED: float = 100
const STALK_SPEED: float = 200
const CHASE_SPEED: float = 400
const SIGHT_RANGE: float = 512
const TALL_GRASS_SIGHT_RANGE: float = 96

@onready var sprite = $sprite
@onready var nav_agent = $nav_agent

var mode: Mode = Mode.PROWL
var player = null

func _ready():
    $nav_timer.timeout.connect(on_nav_timer_timeout)

func on_nav_timer_timeout():
    if player == null:
        return
    if mode == Mode.CHASE:
        nav_agent.set_target_position(player.global_position)

func _physics_process(_delta: float) -> void:
    if player == null:
        player = get_parent().get_node("player")
    if player == null:
        return

    var space_state = get_world_2d().direct_space_state
    var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
    var result = space_state.intersect_ray(query)
    var can_see_player = did_raycast_see_player(result)

    # Look for player
    if mode == Mode.PROWL and can_see_player:
        mode = Mode.CHASE

    velocity = global_position.direction_to(nav_agent.get_next_path_position()) * get_speed()
    move_and_slide()

func did_raycast_see_player(raycast_result) -> bool:
    if not raycast_result:
        return false
    if raycast_result.collider != player:
        return false
    var distance = position.distance_to(player.position)
    if distance > SIGHT_RANGE:
        return false
    if player.is_in_tall_grass() and distance > TALL_GRASS_SIGHT_RANGE:
        return false
    return true

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
