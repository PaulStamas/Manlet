extends AnimatedSprite

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
onready var global = $"/root/Global"

func _ready():
	
	pass # Replace with function body.

#func _process(delta):
#	if global.player.ani_state == "Idle":
#		set_animation("Idle Tired")
#		speed_scale = 1
#		position = Vector2(0,-2)
#		
#	elif global.player.ani_state == "Running":
#		set_animation("Running")
#		speed_scale = abs(global.player.velocity.x)/400
#		#delete when white space is fixed
#		position = Vector2(0,-21)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
