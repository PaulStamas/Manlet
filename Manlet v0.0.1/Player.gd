extends KinematicBody2D


var velocity: Vector2

const GRAVITY = 30
const GROUND_FRICTION = 0.75
const WALL_FRICTION = 0.75
const MIDAIR_FRICTION = 0.99
const FORCE_FALL = 60

const PLAYER_SPEED = 80
const PLAYER_JUMP_VEL = 630
const PLAYER_WALL_JUMP_VEL = 800
const PLAYER_MAX_SPEED = 800
const PLAYER_MAX_STOP_SPEED = 20
const WALL_JUMP_TOUCH_DELAY = 0.175 # seconds
const BAD_WALL_JUMP_MULT = 0.75

onready var player_sprite = $AnimatedSprite

var ani_state = "Idle"

var wall_jump_dir = null
var last_wall_jump_dir = null
var wall_touch_delta = 0;
var player_dir = "right"

func _ready():
	$"/root/Global".register_player(self)
	
func _physics_process(delta):
	move(delta)
	animate()

func move(delta):
	wall_touch_delta += delta;
	
	var input_up = Input.is_action_pressed("ui_up")
	var input_wall_jump = Input.is_action_just_pressed("ui_up")
	var input_left = Input.is_action_pressed("ui_left")
	var input_right = Input.is_action_pressed("ui_right")
	var input_down = Input.is_action_pressed("ui_down")
	
	velocity.x *= GROUND_FRICTION
	
	if is_on_wall():
		velocity.x = 0;
		for i in get_slide_count():
			var collision = get_slide_collision(i)
			if position.x < collision.position.x:
				wall_touch_delta = 0;
				wall_jump_dir = "left"
				if input_right && velocity.y > 0:
					velocity.y *= WALL_FRICTION
			if position.x > collision.position.x:
				wall_touch_delta = 0
				wall_jump_dir = "right"
				if input_left && velocity.y > 0:
					velocity.y *= WALL_FRICTION
	
	if input_wall_jump && wall_touch_delta < WALL_JUMP_TOUCH_DELAY && !is_on_floor():
		wall_touch_delta = 100000
		if wall_jump_dir == "left":
			if last_wall_jump_dir == "left":
				velocity.x = -PLAYER_WALL_JUMP_VEL * BAD_WALL_JUMP_MULT
				velocity.y = -PLAYER_JUMP_VEL * 0.25
			else:
				velocity.x = -PLAYER_WALL_JUMP_VEL
				velocity.y = -PLAYER_JUMP_VEL
			last_wall_jump_dir = "left"
		elif wall_jump_dir == "right":
			if last_wall_jump_dir == "right":
				velocity.x = PLAYER_WALL_JUMP_VEL * BAD_WALL_JUMP_MULT
				velocity.y = -PLAYER_JUMP_VEL * 0.25
			else:
				velocity.x = PLAYER_WALL_JUMP_VEL
				velocity.y = -PLAYER_JUMP_VEL
			last_wall_jump_dir = "right"
	
	if is_on_floor():
		velocity.y = 0
		last_wall_jump_dir = "none";
		if input_up:
			velocity.y = -PLAYER_JUMP_VEL
	else:
		velocity.y += GRAVITY;
		if input_down:
			velocity.y += FORCE_FALL

	
	
	#bounce off ceiling
	if is_on_ceiling():
		if input_up:
			velocity.x *= WALL_FRICTION
			velocity.y = -1
		elif velocity.y < 0:
			velocity.y = 0
			

	if input_left and !input_right:
		velocity.x -= PLAYER_SPEED
		player_sprite.flip_h = true
		player_dir = "left"
		ani_state = "Running"
	elif input_right and !input_left:
		velocity.x += PLAYER_SPEED
		player_sprite.flip_h = false
		player_dir = "right"
		ani_state = "Running"
	else:
		if abs(velocity.x) < PLAYER_MAX_STOP_SPEED:
			velocity.x = 0
		ani_state = "Idle"
	
	if velocity.x > PLAYER_MAX_SPEED:
		velocity.x = PLAYER_MAX_SPEED
	elif velocity.x < -PLAYER_MAX_SPEED:
		velocity.x = -PLAYER_MAX_SPEED
	
	# DELETE THIS LATER
	
	if position.y > 10000:
		position.x = 500
		position.y = 300
		velocity.y = 0
	
	move_and_slide(velocity, Vector2(0, -1))
	
func animate():
			
	if ani_state == "Running":
		player_sprite.play("Running")
		player_sprite.speed_scale = abs(velocity.x)/400
		#delete when white space is fixed
		player_sprite.position = Vector2(0,-21)
		
	if ani_state == "Idle":
		player_sprite.play("Idle Tired")
		player_sprite.speed_scale = 1
		player_sprite.position = Vector2(0,-2)
