extends CharacterBody2D

signal made_noise(noise_position: Vector2, noise_loudness: int)

enum FacingDirection {
    UP,
    RIGHT,
    DOWN,
    LEFT
}

const SNEAK_SPEED: float = 150
const WALK_SPEED: float = 350

const LOOK_DISTANCE: float = 180

@onready var sprite = $sprite
@onready var fire_sprite = $fire
@onready var camera = $camera
@onready var tilemap = get_node("../tilemap")

var facing_direction: FacingDirection = FacingDirection.DOWN
var finished_crouch_start_anim: bool = false

func _ready():
    sprite.animation_finished.connect(on_animation_finished)
    set_on_fire(false)

func is_sneaking() -> bool:
    return Input.is_action_pressed("sneak")

func is_on_fire() -> bool:
    return fire_sprite.visible

func set_on_fire(value: bool) -> void:
    fire_sprite.visible = value

func _physics_process(delta: float) -> void:
    # Get direction
    var direction: Vector2 = Vector2(
        Input.get_action_strength("right") - Input.get_action_strength("left"), 
        Input.get_action_strength("down") - Input.get_action_strength("up"))
    direction = direction.normalized()

    # Facing direction
    if direction.x != 0 && abs(direction.x) > abs(direction.y):
        if direction.x > 0:
            facing_direction = FacingDirection.RIGHT
        else:
            facing_direction = FacingDirection.LEFT
    elif direction.y != 0 && abs(direction.y) > abs(direction.x):
        if direction.y > 0:
            facing_direction = FacingDirection.DOWN
        else:
            facing_direction = FacingDirection.UP

    # Move
    velocity = direction * get_speed()
    move_and_slide()
    for index in range(0, get_slide_collision_count()):
        if get_slide_collision(index).get_collider().name == "fire":
            set_on_fire(true)

    # Make noise
    var is_moving = velocity.length_squared() != 0
    if is_moving and not is_sneaking():
        made_noise.emit(global_position, 1)

    # Look
    var desired_camera_offset = Vector2(0, 0)
    if is_looking():
        desired_camera_offset = direction * LOOK_DISTANCE
    camera.offset = camera.offset.lerp(desired_camera_offset, 4.0 * delta)

    update_sprite(is_moving)
    fire_sprite.animation = sprite.animation
    fire_sprite.frame = sprite.frame
    fire_sprite.flip_h = sprite.flip_h

func update_sprite(is_moving: bool):
    var direction_suffix = ["_up", "_side", "_down", "_side"][facing_direction]
    var animation: String
    if Input.is_action_just_pressed("sneak"):
        finished_crouch_start_anim = false
        sprite.play("crouch_start" + direction_suffix)
        return

    if is_sneaking() and not finished_crouch_start_anim:
        return
    elif is_sneaking() and is_moving:
        animation = "crouch_walk"
    elif is_sneaking() and not is_moving:
        animation = "crouch_idle"
    elif is_moving:
        animation = "run"
    else:
        animation = "idle"
    sprite.play(animation + direction_suffix)
    sprite.flip_h = facing_direction == FacingDirection.LEFT

func on_animation_finished() -> void:
    if not finished_crouch_start_anim and sprite.animation.begins_with("crouch_start"):
        finished_crouch_start_anim = true

func is_looking() -> bool:
    return Input.is_action_pressed("look")

func get_speed() -> float:
    if is_sneaking():
        return SNEAK_SPEED
    else:
        return WALK_SPEED

func on_hurtbox_body_entered(body: Node2D) -> void:
    if body.has_method("on_spear_hit"):
        body.on_spear_hit()

func is_in_tall_grass() -> bool:
    var cell = tilemap.local_to_map(position)
    return tilemap.get_cell_tile_data(0, cell).get_custom_data("tall_grass")
