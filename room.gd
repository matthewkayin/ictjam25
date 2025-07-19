extends Area2D

func _ready():
    body_entered.connect(on_body_entered)

func on_body_entered(body):
    if body.has_method("set_current_room"):
        body.set_current_room(self)