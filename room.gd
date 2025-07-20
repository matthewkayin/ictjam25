extends Area2D

var is_finished = false
var tiger = null
@onready var fire_node = get_node_or_null("fire")

func _ready():
    body_entered.connect(on_body_entered)

func level_is_finished() -> bool:
    if fire_node == null:
        return false
    return fire_node.fire_is_finished()

func level_finish() -> void:
    fire_node.fire_finish()
    is_finished = true

func on_body_entered(body):
    if body.has_method("set_current_room"):
        if not level_is_finished():
            var tiger_spawn_node = get_node_or_null("tiger_spawn")
            if tiger_spawn_node != null:
                var tiger_scene = load("res://tiger/tiger.tscn")
                tiger = tiger_scene.instantiate()
                get_parent().add_child(tiger)
                var tiger_flee_point = get_node("tiger_flee_point")
                var tiger_path_parent = get_node("tiger_path")
                tiger.init(tiger_spawn_node.global_position, tiger_flee_point.global_position, tiger_path_parent)
        body.set_current_room(self)

func on_exit():
    if tiger != null:
        if not tiger.is_chasing_player():
            get_parent().remove_child(tiger)
            tiger.queue_free()
            tiger = null
