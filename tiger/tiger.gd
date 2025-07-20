extends CharacterBody2D

const PROWL_SPEED: float = 100
const CHASE_SPEED: float = 400

@onready var sprite = $sprite
@onready var nav_agent = $nav_agent
@onready var player = get_node("../player")
@onready var raycast_anchor = $raycasts

var prowl_path = []
var prowl_path_index = 0

enum FacingDirection {
    UP,
    RIGHT,
    DOWN,
    LEFT
}

enum Mode {
    PROWL,
    STALK,
    CHASE,
    FLEE
}

var facing_direction = FacingDirection.DOWN
var point_of_interest = null
var raycasts = []
var mode = Mode.PROWL
var flee_position: Vector2

func _ready():
    $nav_timer.timeout.connect(on_nav_timer_timeout)
    player.made_noise.connect(on_player_made_noise)

    for angle in range(-30, 30, 5):
        var raycast = RayCast2D.new()
        raycast.target_position.y = 256
        raycast.rotation = deg_to_rad(angle)
        raycast_anchor.add_child(raycast)
        raycasts.push_back(raycast)

func init(spawn_point: Vector2, level_flee_position: Vector2, prowl_path_parent: Node):
    global_position = spawn_point
    flee_position = level_flee_position
    var prowl_path_nodes = prowl_path_parent.get_children()
    for path_node in prowl_path_nodes:
        prowl_path.push_back(path_node.position)
    start_prowl_pathing()

func can_see_player() -> bool:
    for raycast in raycasts:
        if raycast.is_colliding() and raycast.get_collider() == player and not (player.is_in_tall_grass() and player.is_sneaking()):
            return true
    
    return false

func is_chasing_player() -> bool:
    return mode == Mode.CHASE

func begin_flee():
    mode = Mode.FLEE

func on_nav_timer_timeout():
    if mode == Mode.FLEE:
        nav_agent.set_target_position(flee_position)
    elif mode == Mode.CHASE:
        nav_agent.set_target_position(player.global_position)
    elif mode == Mode.STALK: 
        nav_agent.set_target_position(point_of_interest)
    else:
        nav_agent.set_target_position(prowl_path[prowl_path_index])

func start_prowl_pathing():
    var nearest_index = 0
    for index in range(0, prowl_path.size()):
        if position.distance_to(prowl_path[index]) < position.distance_to(prowl_path[nearest_index]):
            nearest_index = index
    prowl_path_index = nearest_index
    mode = Mode.PROWL

func on_player_made_noise(noise_position: Vector2, noise_loudness: int):
    const NOISE_HEARING_RANGE: float = 256
    var noise_distance = global_position.distance_to(noise_position)
    var hearing_range = NOISE_HEARING_RANGE * noise_loudness
    # If it's too far away, you can't hear it
    if noise_distance > hearing_range:
        return
    # If it's kinda loud and close, then chase right away
    if noise_loudness == 2 and noise_distance < NOISE_HEARING_RANGE: 
        mode = Mode.CHASE
        return
    # Otherwise, stalk
    mode = Mode.STALK
    point_of_interest = noise_position

func _physics_process(_delta: float) -> void:
    if can_see_player() and not mode == Mode.FLEE:
        mode = Mode.CHASE

    velocity = global_position.direction_to(nav_agent.get_next_path_position()) * get_speed()
    move_and_slide()

    const TARGET_DISTANCE = 64
    if mode == Mode.FLEE and global_position.distance_to(flee_position) < TARGET_DISTANCE:
        queue_free()
    if mode == Mode.PROWL and global_position.distance_to(prowl_path[prowl_path_index]) < TARGET_DISTANCE:
        prowl_path_index = (prowl_path_index + 1) % prowl_path.size()
    elif mode == Mode.STALK and position.distance_to(point_of_interest) < TARGET_DISTANCE:
        start_prowl_pathing()

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

    var raycast_angles = [180, 270, 0, 90]
    raycast_anchor.rotation_degrees = raycast_angles[facing_direction]

    if mode == Mode.CHASE or mode == Mode.FLEE:
        sprite.play("chase")
    else:
        sprite.play("prowl")

func get_speed() -> float:
    if mode == Mode.CHASE or mode == Mode.FLEE:
        return CHASE_SPEED
    else:
        return PROWL_SPEED
