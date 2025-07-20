extends StaticBody2D

@onready var flames = [
    $flames/flame1,
    $flames/flame2,
    $flames/flame3,
    $flames/flame4,
]
@onready var levels = [
    get_node_or_null("../../level1"),
    get_node_or_null("../../level2"),
    get_node_or_null("../../level3"),
    get_node_or_null("../../level4"),
]

func _ready():
    for flame in flames:
        flame.visible = false

func fire_accept(fire_object):
    var level_object = fire_object.get_parent()
    for level_index in range(0, levels.size()):
        if levels[level_index] == null:
            continue
        if levels[level_index] == level_object:
            levels[level_index].level_finish()
            flames[level_index].visible = true