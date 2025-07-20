extends CharacterBody2D

const PROWL_SPEED: float = 200
const CHASE_SPEED: float = 500

@onready var sprite = $sprite
@onready var nav_agent = $nav_agent
@onready var player = get_node("../player")
@onready var raycast_anchor = $raycasts
@onready var beatbox = get_node("../beatbox")
@onready var shadow_side = $shadow_side
@onready var shadow_updown = $shadow_updown

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
    $tiger_kill_hurtbox.body_entered.connect(on_hurtbox_body_entered)
    $nav_timer.timeout.connect(on_nav_timer_timeout)
    player.made_noise.connect(on_player_made_noise)

    for angle in range(-30, 30, 5):
        var raycast = RayCast2D.new()
        raycast.target_position.y = 256
        raycast.rotation = deg_to_rad(angle)
        raycast_anchor.add_child(raycast)
        raycasts.push_back(raycast)

func on_hurtbox_body_entered(body):
    if body == player and not player.is_on_fire():
        get_parent().remove_child(self)
        queue_free()
        player.kill_player()

func init(spawn_point: Vector2, level_flee_position: Vector2, prowl_path_parent: Node):
    global_position = spawn_point
    flee_position = level_flee_position
    var prowl_path_nodes = prowl_path_parent.get_children()
    for path_node in prowl_path_nodes:
        prowl_path.push_back(path_node.position)
    start_prowl_pathing()

func can_see_player() -> bool:
    for raycast in raycasts:
        if raycast.is_colliding() and raycast.get_collider() == player and not (player.is_in_tall_grass() and player.is_sneaking() and player.global_position.distance_to(global_position) > 64.0):
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

func on_player_made_noise(noise_position: Vector2):
    if mode == Mode.FLEE or mode == Mode.CHASE:
        return
    const NOISE_HEARING_RANGE: float = 1024
    var noise_distance = global_position.distance_to(noise_position)
    if noise_distance < NOISE_HEARING_RANGE:
        mode = Mode.STALK
        point_of_interest = noise_position

func _physics_process(_delta: float) -> void:
    if not mode == Mode.CHASE and can_see_player() and not mode == Mode.FLEE:
        mode = Mode.CHASE
        beatbox.set_track("chase")

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

    var direction_suffix = ["_up", "_side", "_down", "_side"][facing_direction]
    var animation: String
    var is_moving = velocity.length_squared() != 0
    if not is_moving:
        animation = "idle"
    elif mode == Mode.CHASE or mode == Mode.FLEE:
        animation = "run"
    else:
        animation = "walk"
    sprite.play(animation + direction_suffix)
    sprite.flip_h = facing_direction == FacingDirection.LEFT

    shadow_side.visible = facing_direction == FacingDirection.RIGHT or facing_direction == FacingDirection.LEFT
    shadow_updown.visible = facing_direction == FacingDirection.UP or facing_direction == FacingDirection.DOWN

func get_speed() -> float:
    if mode == Mode.CHASE or mode == Mode.FLEE:
        return CHASE_SPEED
    else:
        return PROWL_SPEED
