extends KinematicBody2D

#Constants
const GRAVITY = 30
const GROUND_FRICTION = 0.75
const WALL_FRICTION = 0.75
const MIDAIR_FRICTION = 0.99
const FORCE_FALL = 60

const PLAYER_SPEED = 80
const PLAYER_JUMP_VEL = 630
const PLAYER_WALL_JUMP_VEL = 800
const PLAYER_MAX_STOP_SPEED = 20
const WALL_JUMP_TOUCH_DELAY = 0.175 # seconds
const BAD_WALL_JUMP_MULT = 0.75


onready var player_sprite = $AnimatedSprite

var wall_jump_dir = null
var last_wall_jump_dir = null
var wall_touch_delta = 0;
var player_dir = "right"
var state = "Idle"
var velocity: Vector2
var respawn_position: Vector2

#Inputs
var input_up
var input_wall_jump
var input_left
var input_right
var input_down 
var input_shoot
var input_restart

#Hook shot variables
const MAX_ROPE_LENGTH = 350
const MIN_ROPE_LENGTH = 75
const ROPE_STRETCH = 5
const FIRE_SPEED = 650
var rope_init = true
var grapple_point
var rope_point
var rope_angle_velocity
var rope_angle
var rope_length
onready var hook_shot = load("res://Scenes/HookShot.tscn")
var rope_point_accel
var hook_fire = true
	
var change_state

func _ready():
	$"/root/Global".register_player(self)
	respawn_position = position
	
func _physics_process(delta):
	get_inputs()
	move(delta)
	hook_shot()
	if state == "Swing":
		velocity = Vector2(0,0)
	move_and_slide(velocity, Vector2.UP)
	animate()
	print_change_state()

func get_inputs():
	input_up = Input.is_action_just_pressed("ui_up")
	input_wall_jump = Input.is_action_just_pressed("ui_up")
	input_left = Input.is_action_pressed("ui_left")
	input_right = Input.is_action_pressed("ui_right")
	input_down = Input.is_action_pressed("ui_down")
	
	input_shoot = Input.is_action_just_pressed("ui_shoot")
	
	input_restart = Input.is_action_just_pressed("ui_restart")
	
	if input_restart:
		position = respawn_position
	
func move(delta):
	
	velocity.x *= GROUND_FRICTION
	wall_touch_delta += delta
	
	on_wall()
	
	if is_on_floor():
		rope_init = true
		velocity.y = 0
		last_wall_jump_dir = "none";
		if input_up:
			velocity.y = -PLAYER_JUMP_VEL
		hook_fire = true
			
	velocity.y += GRAVITY;
	if input_down:
		velocity.y += FORCE_FALL

	if is_on_ceiling():
		if input_up:
			velocity.x *= WALL_FRICTION
			velocity.y = -1
		elif velocity.y < 0:
			velocity.y = 0
			

	if input_left and !input_right:
		velocity.x -= PLAYER_SPEED
		player_dir = "left"
	elif input_right and !input_left:
		velocity.x += PLAYER_SPEED
		player_dir = "right"
	else:
		if abs(velocity.x) < PLAYER_MAX_STOP_SPEED:
			velocity.x = 0
		state = "Idle"	
		
	if !is_on_floor():
		if hook_shot.get_class() == "Area2D":
#			print(hook_shot.attached)
			if hook_shot.attached and velocity.y >= 0:
				state = "Swing"
				hook_fire = false
				
	if input_left or input_right:
		if state != "Swing":
			state = "Running"

				
	
	
func on_wall():
	if is_on_wall():
		velocity.x = 0;
		for i in get_slide_count():
			var collision = get_slide_collision(i)
			if position.x < collision.position.x:
				wall_touch_delta = 0;
				wall_jump_dir = "left"
				if state == "Swing":
					rope_angle_velocity = 0
				elif input_right && velocity.y > 0:
					velocity.y *= WALL_FRICTION
			if position.x > collision.position.x:
				wall_touch_delta = 0
				wall_jump_dir = "right"
				if state == "Swing":
					rope_angle_velocity *= .5
				elif input_left && velocity.y > 0:
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
	
func hook_shot():
	if input_shoot and state != "swing":
		if hook_fire:
			if hook_shot.get_class() == "PackedScene":
				hook_shot = hook_shot.instance()
				get_parent().add_child(hook_shot)
			hook_shot.init(FIRE_SPEED, player_dir, position, "Show")
			
	if hook_shot.get_class() == "Area2D":
		if sqrt(pow(hook_shot.position.x - position.x, 2) + pow(hook_shot.position.y - position.y, 2)) > MAX_ROPE_LENGTH:
			hook_shot.init(0, "none", position, "Hide")
			state = "Running"
		if hook_shot.attached:
			if state == "Swing":
				swing()
		else: 
			rope_init = true

func swing():
	if rope_init:
		grapple_point = hook_shot.position
		rope_point = position
		rope_angle_velocity = -velocity.x / 150
		rope_length = sqrt(pow(grapple_point.x - position.x, 2) + pow(grapple_point.y - position.y, 2))
		rope_init = false
	
	if rope_length < MIN_ROPE_LENGTH:
		rope_length += ROPE_STRETCH
	
		
	if input_left:
		position.x -= 5
		
	if input_right:
		position.x += 5
		
	rope_angle = find_angle(hook_shot.position, position)
	var rope_angle_accel = 0.2 * cos(deg2rad(rope_angle))
	
	rope_angle_velocity += rope_angle_accel
	rope_angle += rope_angle_velocity

	rope_angle_velocity *= MIDAIR_FRICTION

	rope_point.x = grapple_point.x + (rope_length * cos(deg2rad(rope_angle)))
	rope_point.y = grapple_point.y + (rope_length * sin(deg2rad(rope_angle)))
		
	rope_point_accel = Vector2(rope_point.x - position.x, rope_point.y - position.y)
		
	position += rope_point_accel
	
	if (input_up or input_shoot) and state == "Swing":
		state = "Running"
		hook_shot.init(0, "none", position, "Hide")
		hook_shot.attached = false
		if player_dir == "right":
			velocity.x = abs(rope_point_accel.x) * 100
		elif player_dir == "left":
			velocity.x = -abs(rope_point_accel.x) * 100
		velocity.y = -abs(rope_point_accel.y) * 80
		print(velocity)
	
func animate():
	if state == "Idle":
		player_sprite.play("Idle Tired")
		player_sprite.speed_scale = 1
		player_sprite.position = Vector2(0,-2)
	
	elif state == "Running":
		player_sprite.play("Running")
		player_sprite.speed_scale = abs(velocity.x)/400
		#delete when white space is fixed
		player_sprite.position = Vector2(0,-22)
	
	elif state == "Swing":
		player_sprite.play("Running")
		player_sprite.speed_scale = 1
		#delete when white space is fixed
		player_sprite.position = Vector2(0,-21)
	
	if player_dir == "left":
		player_sprite.flip_h = true
	elif player_dir == "right":
		player_sprite.flip_h = false
	
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

func print_change_state():
	if state != change_state:
		print(state)
		change_state = state
#	if hook_shot.get_class() == "Area2D":
#		if hook_shot.attached:
#			print(hook_shot.attached)
