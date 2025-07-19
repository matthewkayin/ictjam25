extends CharacterBody2D

const PROWL_SPEED: float = 100
const CHASE_SPEED: float = 400

@onready var sprite = $sprite
@onready var nav_agent = $nav_agent
@onready var player = get_node("../player")
@onready var raycast_anchor = $raycasts

enum FacingDirection {
    UP,
    RIGHT,
    DOWN,
    LEFT
}

var has_seen_player = false
var facing_direction = FacingDirection.DOWN
var point_of_interest = null
var raycasts = []

func _ready():
    $nav_timer.timeout.connect(on_nav_timer_timeout)
    player.made_noise.connect(on_player_made_noise)

    for angle in range(-30, 30, 5):
        var raycast = RayCast2D.new()
        raycast.target_position.y = 256
        raycast.rotation = deg_to_rad(angle)
        raycast_anchor.add_child(raycast)
        raycasts.push_back(raycast)

func can_see_player() -> bool:
    for raycast in raycasts:
        if raycast.is_colliding() and raycast.get_collider() == player and not player.is_in_tall_grass():
            return true
    
    return false

func on_nav_timer_timeout():
    if has_seen_player:
        nav_agent.set_target_position(player.global_position)
    elif point_of_interest != null:
        nav_agent.set_target_position(point_of_interest)

func on_player_made_noise(noise_position: Vector2, noise_loudness: int):
    const NOISE_HEARING_RANGE: float = 256
    var noise_distance = global_position.distance_to(noise_position)
    var hearing_range = NOISE_HEARING_RANGE * noise_loudness
    # If it's too far away, you can't hear it
    if noise_distance > hearing_range:
        return
    # If it's kinda loud and close, then chase right away
    if noise_loudness == 2 and noise_distance < NOISE_HEARING_RANGE: 
        has_seen_player = true
        return
    # Otherwise, stalk
    point_of_interest = noise_position

func _physics_process(_delta: float) -> void:
    if can_see_player():
        has_seen_player = true

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

    var raycast_angles = [180, 270, 0, 90]
    raycast_anchor.rotation_degrees = raycast_angles[facing_direction]

    if has_seen_player:
        sprite.play("chase")
    else:
        sprite.play("prowl")

func get_speed() -> float:
    if has_seen_player:
        return CHASE_SPEED
    else:
        return PROWL_SPEED
