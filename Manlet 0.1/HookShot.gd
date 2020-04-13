extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var speed = 0
var attached = false
var exists = false
var direction
# Called when the node enters the scene tree for the first time.
func _ready():
	$"/root/Global".register_hook_shot(self)
	
func init(fire_speed, dir, init_position, visibility):
	direction = dir
	speed = fire_speed
	speed = -fire_speed
	position = init_position
	if visibility == "Show":
		show()
	if visibility == "Hide":
		hide()
	
	$AnimatedSprite.play("default")
	$AnimatedSprite.position.y = 0
	if direction == "right":
		$AnimatedSprite.flip_h = false
	if direction == "left":
		$AnimatedSprite.flip_h = true
		
	attached = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if attached == false:
		if direction == "right":
			position.x -= speed * delta
		if direction == "left":
			position.x += speed * delta
		position.y += speed * delta
	if speed == 0:
		position = $"/root/Global".player.position

func _on_HookShot_body_entered(body):
	if direction != "none":
		if body.get_name() != "Manlet":
			$AnimatedSprite.position.y -= 5
			$AnimatedSprite.play("Attached")
			print(body.get_name())
			attached = true
