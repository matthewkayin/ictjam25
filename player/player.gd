extends CharacterBody2D

signal made_noise(noise_position: Vector2, noise_loudness: int)

enum Mode {
    WALK,
    SNEAK,
    SPRINT
}

enum FacingDirection {
    UP,
    RIGHT,
    DOWN,
    LEFT
}

const SNEAK_SPEED: float = 100
const WALK_SPEED: float = 200
const SPRINT_SPEED: float = 400

const LOOK_DISTANCE: float = 180

@onready var sprite = $sprite
@onready var camera = $camera
@onready var tilemap = get_node("../tilemap")

var mode: Mode = Mode.WALK
var facing_direction: FacingDirection = FacingDirection.DOWN

func _ready():
    sprite.animation_finished.connect(on_animation_finished)

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

    # Check movement modes
    if Input.is_action_pressed("sprint"):
        mode = Mode.SPRINT
    elif Input.is_action_pressed("sneak"):
        mode = Mode.SNEAK
    else:
        mode = Mode.WALK

    # Move
    velocity = direction * get_speed()
    move_and_slide()

    # Make noise
    if velocity.length_squared() != 0:
        var loudness = 0
        if mode == Mode.WALK:
            loudness = 1
        if mode == Mode.SPRINT:
            loudness = 2
        if loudness != 0:
            made_noise.emit(global_position, loudness)

    # Look
    var desired_camera_offset = Vector2(0, 0)
    if is_looking():
        desired_camera_offset = direction * LOOK_DISTANCE
    camera.offset = camera.offset.lerp(desired_camera_offset, 4.0 * delta)

    # Update sprite
    if mode == Mode.SNEAK:
        sprite.play("sneak")
    else:
        sprite.play("walk")

    sprite.flip_h = facing_direction == FacingDirection.LEFT

func on_animation_finished() -> void:
    pass

func is_looking() -> bool:
    return Input.is_action_pressed("look")

func get_speed() -> float:
    if mode == Mode.SPRINT:
        return SPRINT_SPEED
    elif mode == Mode.SNEAK:
        return SNEAK_SPEED
    else:
        return WALK_SPEED

func on_hurtbox_body_entered(body: Node2D) -> void:
    if body.has_method("on_spear_hit"):
        body.on_spear_hit()

func is_in_tall_grass() -> bool:
    var cell = tilemap.local_to_map(position)
    return tilemap.get_cell_tile_data(0, cell).get_custom_data("tall_grass")
