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

const FIRE_SPEED = 500

var gravity_on = true
onready var player_sprite = $AnimatedSprite

var state = "Idle"

var wall_jump_dir = null
var last_wall_jump_dir = null
var wall_touch_delta = 0;
var player_dir = "right"

#Inputs
var input_up
var input_wall_jump
var input_left
var input_right
var input_down 
var input_shoot

#Hook shot variables
var rope_init = true
var grapple_point
var rope_point
var rope_angle_velocity
var rope_angle
var rope_length 
var hook_shot = preload("res://Scenes/HookShot.tscn").instance()
	
func _ready():
	$"/root/Global".register_player(self)
	
func _physics_process(delta):
	move(delta)
	rope_swing(delta)
	animate()

func move(delta):
	input_up = Input.is_action_pressed("ui_up")
	input_wall_jump = Input.is_action_just_pressed("ui_up")
	input_left = Input.is_action_pressed("ui_left")
	input_right = Input.is_action_pressed("ui_right")
	input_down = Input.is_action_pressed("ui_down")
	
	velocity.x *= GROUND_FRICTION
	wall_touch_delta += delta
	
	on_wall()
	
	if is_on_floor():
		velocity.y = 0
		last_wall_jump_dir = "none";
		if input_up:
			velocity.y = -PLAYER_JUMP_VEL
	else:
		if gravity_on:
			velocity.y += GRAVITY;
			if input_down:
				velocity.y += FORCE_FALL
	
	if state == "swing":
		velocity.x = 0
		velocity.y = 0

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
		state = "Running"
	elif input_right and !input_left:
		velocity.x += PLAYER_SPEED
		player_sprite.flip_h = false
		player_dir = "right"
		state = "Running"
	else:
		if abs(velocity.x) < PLAYER_MAX_STOP_SPEED:
			velocity.x = 0
		state = "Idle"
	
	if velocity.x > PLAYER_MAX_SPEED:
		velocity.x = PLAYER_MAX_SPEED
	elif velocity.x < -PLAYER_MAX_SPEED:
		velocity.x = -PLAYER_MAX_SPEED
	
	# DELETE THIS LATER
	
	if position.y > 10000:
		position.x = 500
		position.y = 300
		velocity.y = 0
	
func on_wall():
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
			
	move_and_slide(velocity, Vector2(0, -1))	
	
func rope_swing(delta):
	input_up = Input.is_action_pressed("ui_up")
	input_shoot = Input.is_action_just_pressed("ui_shoot")
	if input_shoot:
		hook_shot.init(FIRE_SPEED)
		hook_shot.position = get_global_position()
		get_parent().add_child(hook_shot)
		
	if hook_shot.attached:
		gravity_on = false
		if rope_init:
			velocity = Vector2(0,0)
			grapple_point = hook_shot.position
			rope_point = position
			rope_angle_velocity = 0
			rope_length = sqrt(pow(grapple_point.x - position.x, 2) + pow(grapple_point.y - position.y, 2))
			print(rope_length)
			rope_init = false
		

		rope_angle = find_angle(hook_shot.position, position)
		var rope_angle_accel = 0.2 * cos(deg2rad(rope_angle))
		rope_angle_velocity += rope_angle_accel
		rope_angle += rope_angle_velocity
		if is_on_wall() or is_on_floor():
			rope_angle_velocity = 0
		rope_angle_velocity *= 0.99
		
		rope_point.x = grapple_point.x + (rope_length * cos(deg2rad(rope_angle)))
		rope_point.y = grapple_point.y + (rope_length * sin(deg2rad(rope_angle)))
		
		position.x += (rope_point.x - position.x)
		position.y += (rope_point.y - position.y)
		
		if input_up:
			velocity.y = -PLAYER_JUMP_VEL
			velocity.x = PLAYER_WALL_JUMP_VEL
			
		
	else: 
		rope_init = true
		
func animate():
	if state == "Idle":
		player_sprite.play("Idle Tired")
		player_sprite.speed_scale = 1
		player_sprite.position = Vector2(0,-2)
	
	else:
		player_sprite.play("Running")
		player_sprite.speed_scale = abs(velocity.x)/400
		#delete when white space is fixed
		player_sprite.position = Vector2(0,-21)
		
func find_angle(point1, point2):
	var vector1 = Vector2(point1.x - point1.x - 10, 0)
	var vector2 = Vector2(point1.x - point2.x, point1.y - point2.y)
	var mag = sqrt(pow(vector1.x, 2) + pow(vector1.y, 2))
	mag = mag * sqrt(pow(vector2.x, 2) + pow(vector2.y, 2))
	var angle = (vector1.x * vector2.x) + (vector1.y * vector2.y)
	angle = angle/mag
	angle = rad2deg(acos(angle))
	while angle > 360:
		angle -= 360
	return(angle)
