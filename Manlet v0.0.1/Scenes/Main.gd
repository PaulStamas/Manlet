extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _draw():
	if $HookShot != null:
		draw_line($Player.position, $HookShot.position, Color(.5, 1, 0), 5)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update()
