extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var speed
var attached = false
var exists = false
# Called when the node enters the scene tree for the first time.
func init(fire_speed):
	speed = fire_speed
	attached = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if attached == false:
		position.x -= speed * delta
		position.y -= speed * delta

func _on_HookShot_body_entered(body):
	if body.get_name() != "Player":
		attached = true
