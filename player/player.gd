extends CharacterBody2D

enum Mode {
    WALK,
    SNEAK,
    SPRINT,
    ATTACK
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

@onready var hurtbox_areas = [
    $hurtbox_top,
    $hurtbox_right, 
    $hurtbox_bottom, 
    $hurtbox_left, 
]
@onready var hurtbox_colliders = [
    $hurtbox_top/collider,
    $hurtbox_right/collider,
    $hurtbox_bottom/collider,
    $hurtbox_left/collider,
]

var mode: Mode = Mode.WALK
var facing_direction: FacingDirection = FacingDirection.DOWN

func _ready():
    sprite.animation_finished.connect(on_animation_finished)
    for hurtbox_area in hurtbox_areas:
        hurtbox_area.body_entered.connect(on_hurtbox_body_entered)
    for hurtbox_collider in hurtbox_colliders:
        hurtbox_collider.set_disabled(true)

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

    # Attack
    # Attacking overrides any movement inputs
    if Input.is_action_just_pressed("attack"):
        attack_begin()
    elif mode != Mode.ATTACK:
        # Check movement modes
        if Input.is_action_pressed("sprint"):
            mode = Mode.SPRINT
        elif Input.is_action_pressed("sneak"):
            mode = Mode.SNEAK
        else:
            mode = Mode.WALK

    # Move
    velocity = direction * get_speed()
    var _ret = move_and_slide()

    # Look
    var desired_camera_offset = Vector2(0, 0)
    if is_looking():
        desired_camera_offset = direction * LOOK_DISTANCE
    camera.offset = camera.offset.lerp(desired_camera_offset, 4.0 * delta)

    # Update sprite
    if mode == Mode.ATTACK:
        return
    if mode == Mode.ATTACK:
        sprite.play("attack")
    if mode == Mode.SNEAK:
        sprite.play("sneak")
    else:
        sprite.play("walk")

    sprite.flip_h = facing_direction == FacingDirection.LEFT

func attack_begin() -> void:
    hurtbox_colliders[facing_direction].set_disabled(false)
    if facing_direction == FacingDirection.UP:
        sprite.play("attack_up")
    elif facing_direction == FacingDirection.DOWN:
        sprite.play("attack_down")
    else:
        sprite.play("attack_side")
    mode = Mode.ATTACK

func attack_end() -> void:
    mode = Mode.WALK
    for hurtbox_collider in hurtbox_colliders:
        hurtbox_collider.set_disabled(true)

func on_animation_finished() -> void:
    if mode == Mode.ATTACK and sprite.animation.begins_with("attack"):
        attack_end()

func is_looking() -> bool:
    return Input.is_action_pressed("look")

func get_speed() -> float:
    if is_looking() or mode == Mode.ATTACK:
        return 0
    elif mode == Mode.SPRINT:
        return SPRINT_SPEED
    elif mode == Mode.SNEAK:
        return SNEAK_SPEED
    else:
        return WALK_SPEED

func on_hurtbox_body_entered(body: Node2D) -> void:
    if body.has_method("on_spear_hit"):
        body.on_spear_hit()
