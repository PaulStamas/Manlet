extends KinematicBody2D

#Player states
enum {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ON_WALL,
	WALL_JUMP,
	SWING,
	
	#States2
	NONE,
	HOOK_SHOT_SHOOT,
	HOOK_SHOT_ATTACHED
}

var state = FALL
var state2 = NONE
var last_state = null
var last_state2 = null

const GRAVITY = 30
const AMBIENT_FRICTION = .85
const WALL_FRICTION = .75
const ACCEL = 80
const PLAYER_MAX_STOP_SPEED = 20
const JUMP_VEL = -630
const WALL_JUMP_VEL = -800
const BAD_WALL_JUMP_MULT = 0.75

var velocity = Vector2(0, 0)
var player_dir = "right"
var wall_jump_dir = null
var last_wall_jump_dir = null

#Inputs
var input_up = false
var input_wall_jump = false
var input_left = false
var input_right = false
var input_down = false
var input_shoot = false
var input_restart = false

#Timer
var respawn_position: Vector2
onready var player_sprite = get_node("AnimatedSprite")
onready var float_jump_timer = get_node("WallJumpTimer")
const float_jump_window = .18#seconds
var float_jump_available = true

#Hook shot variables
const MAX_ROPE_LENGTH = 350
const MIN_ROPE_LENGTH = 75
const ROPE_STRETCH = 5
const FIRE_SPEED = 650
var rope_init = true
var grapple_point
onready var hook_shot = load("res://HookShot.tscn")
var rope_point_accel
var hook_fire = true

#Swing variable
var angle
var rope_length
var swing_accel
var swing_vel = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$"/root/Global".register_player(self)
	respawn_position = position

func _get_inputs():
	input_up = Input.is_action_pressed("ui_up")
	input_wall_jump = Input.is_action_just_pressed("ui_up")
	input_left = Input.is_action_pressed("ui_left")
	input_right = Input.is_action_pressed("ui_right")
	input_down = Input.is_action_pressed("ui_down")
	
	input_shoot = Input.is_action_just_pressed("ui_shoot")
	
	input_restart = Input.is_action_just_pressed("ui_restart")
	
	if input_restart:
		position = respawn_position
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	persistant_state()
	_get_inputs()
	state_transitions(delta)
	shoot_hook()
	match state:
		IDLE:
			idle(delta)
		RUN:
			run(delta)
		JUMP:
			jump(delta)
		FALL:
			fall(delta)
		ON_WALL:
			on_wall(delta)
		WALL_JUMP:
			wall_jump(delta)
		SWING:
			swing(delta)
			
	match state2:
		NONE:
			pass
		HOOK_SHOT_ATTACHED:
			hook_shot_attached()

	move_and_slide(velocity, Vector2.UP)

func set_state(new_state, delta):
	last_state = state
	persistant_change_state()
	if last_state == WALL_JUMP:
		wall_jump_dir = null
		
	match new_state:
		IDLE:
			state = IDLE
			velocity.x = 0
			velocity.y = 0
			player_sprite.play("Idle")
			player_sprite.speed_scale = 1
			
		RUN:
			state = RUN
			player_sprite.play("Running")
		
		JUMP:
			state = JUMP
			jump_init()
			
		FALL:
			state = FALL
			if last_state == ON_WALL:
				float_jump_available = true
				float_jump_timer.set_wait_time(float_jump_window)
				float_jump_timer.start()
		
		ON_WALL:
			state = ON_WALL
		
		WALL_JUMP:
			state = WALL_JUMP
			wall_jump_init()
			
		SWING:
			if hook_shot.attached:
				swing_init(position, hook_shot.position)
				state = SWING
		
func set_state2(new_state):
	last_state2 = state2
	if last_state2 == HOOK_SHOT_ATTACHED:
		hook_shot.init(0, "none", position, "Hide")
		hook_shot.attached = false
	match new_state:
		NONE:
			state2 = NONE
			
		HOOK_SHOT_ATTACHED:
			state2 = HOOK_SHOT_ATTACHED
		
		
func state_transitions(delta):
	if state2 != HOOK_SHOT_ATTACHED:
		if hook_shot.get_class() == "Area2D":
			if hook_shot.attached:
				set_state2(HOOK_SHOT_ATTACHED)
				return
		
	if state == IDLE or state == RUN:
		if input_up:
			set_state(JUMP, delta)
			return
			
	if state == JUMP or state == FALL:
		if is_on_wall():
			set_state(ON_WALL, delta)
			return
			
	match state:
		IDLE:
			if input_left or input_right:
				set_state(RUN, delta)
			
		RUN:
			#To IDLE
			if abs(velocity.x) < PLAYER_MAX_STOP_SPEED:
				set_state(IDLE, delta)
			#To FALL
			if velocity.y >= 0:
				set_state(FALL, delta)
		
		JUMP:
			if velocity.y >= 0:
				set_state(FALL, delta)
			
		FALL:
			if is_on_floor():
				if abs(velocity.x) > 0:
					set_state(RUN, delta)
				else:
					set_state(IDLE, delta)
			
			elif last_state == ON_WALL:
				if input_up and float_jump_available:
					set_state(WALL_JUMP, delta)
			
			elif state2 == HOOK_SHOT_ATTACHED:
				set_state(SWING, delta)
			
		
		ON_WALL:
			if !(player_dir == "left" and input_left):
				if !is_on_wall():
					set_state(FALL, delta)
					
			elif !(player_dir == "right" and input_right):
				if !is_on_wall():
					set_state(FALL, delta)
					
			if input_wall_jump:
				set_state(WALL_JUMP, delta)
					
		WALL_JUMP:
			if velocity.y >= 0:
				set_state(FALL, delta)
				
		SWING:
			if is_on_floor():
				set_state(IDLE, delta)
			
			elif is_on_ceiling():
				set_state(FALL, delta)
				set_state2(NONE)
			
			elif is_on_wall():
				set_state(ON_WALL, delta)
				set_state2(NONE)
				
			elif input_up:
				set_state(JUMP, delta)
				set_state2(NONE)
				
	match state2:
		NONE:
			pass
			
		HOOK_SHOT_ATTACHED:
			if !hook_shot.attached:
				set_state2(NONE)
		
#WHAT HAPPENS IN STATES			
func persistant_state():
	apply_gravity()
	if player_dir == "left":
		player_sprite.flip_h = true
	elif player_dir == "right":
		player_sprite.flip_h = false
	
	velocity.x *= AMBIENT_FRICTION
	
func persistant_change_state():
	pass

func idle(delta):
	pass
		
func run(delta):
	h_movement(delta)
	#animation rate
	var rate_scale = 30000 * delta
	player_sprite.speed_scale = abs(velocity.x)/rate_scale
		
func jump(delta):
	h_movement(delta)
	
func fall(delta):
	h_movement(delta)
	
func on_wall(delta):
	h_movement(delta)
	velocity.x = 0;
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if position.x < collision.position.x:
			velocity.x += 2
			wall_jump_dir = "right"
			if input_right && velocity.y > 0:
				velocity.y *= WALL_FRICTION
		if position.x > collision.position.x:
			velocity.x -= 2
			wall_jump_dir = "left"
			if input_left && velocity.y > 0:
				velocity.y *= WALL_FRICTION
				
func wall_jump(delta):
	h_movement(delta)
	
func wall_jump_init():
	if wall_jump_dir == "left":
		if last_wall_jump_dir == "left":
			velocity.x = -WALL_JUMP_VEL * BAD_WALL_JUMP_MULT
			velocity.y = JUMP_VEL * 0.25
		else:
			velocity.x = -WALL_JUMP_VEL
			velocity.y = JUMP_VEL
		last_wall_jump_dir = "left"
	elif wall_jump_dir == "right":
		if last_wall_jump_dir == "right":
			velocity.x = WALL_JUMP_VEL * BAD_WALL_JUMP_MULT
			velocity.y = JUMP_VEL * 0.25
		else:
			velocity.x = WALL_JUMP_VEL
			velocity.y = JUMP_VEL
		last_wall_jump_dir = "right"
		
func swing(delta):
	velocity *= 0
	swing_accel = GRAVITY * sin(angle) * -.01
	swing_vel += swing_accel * delta 
	swing_vel *= .999
	
	#SWING H_MOVEMENT
	if Input.is_action_pressed("ui_right"):
		swing_vel -= abs(swing_vel/400)
		player_dir = "right"
	elif Input.is_action_pressed("ui_left"):
		player_dir = "left"
		swing_vel += abs(swing_vel/400)

	angle += swing_vel 
	
	#GET SWING POSITION
	var pos: Vector2
	pos.x = hook_shot.position.x - rope_length * sin(angle) 
	pos.y = hook_shot.position.y + rope_length * cos(angle) 
	
	position = pos
	
func swing_init(pos1, pos2):
	swing_vel = -velocity.x/6000
	velocity *= 0
	rope_length = sqrt(pow(pos1.x - pos2.x, 2) + pow(pos1.y - pos2.y, 2))
	var adj = pos1.y - pos2.y
	var theta = acos(adj / rope_length)
	if pos1.x - pos2.x < 0: 
		print("yes")
		theta *= -1
	angle = theta

func jump_init():
	if last_state == SWING:
		if player_dir == "left":
			velocity.x = WALL_JUMP_VEL * abs(swing_vel) * 10
		if player_dir == "right":
			velocity.x = -WALL_JUMP_VEL * abs(swing_vel) * 10
		
		velocity.y = JUMP_VEL * abs(swing_vel) * 10
	else:
		velocity.y = JUMP_VEL
		
#States2
func hook_shot_attached():
	if hook_shot.get_class() == "Area2D":
		var rope_too_long = sqrt(pow(hook_shot.position.x - position.x, 2) + pow(hook_shot.position.y - position.y, 2)) > MAX_ROPE_LENGTH
		if rope_too_long:
			hook_shot.init(0, "none", position, "Hide")
		else: 
			rope_init = true
		
		
#FUNCTIONS USED IN STATES
func apply_gravity():
	velocity.y += GRAVITY
	if is_on_floor():
		last_wall_jump_dir = null
		velocity.y = 0
	if is_on_ceiling():
		velocity.y = 0
		
func shoot_hook():
	if input_shoot:
		if hook_fire:
			if hook_shot.get_class() == "PackedScene":
				hook_shot = hook_shot.instance()
				get_parent().add_child(hook_shot)
			hook_shot.init(FIRE_SPEED, player_dir, position, "Show")
		
func h_movement(delta):
	if input_left and !input_right:
		velocity.x -= ACCEL
		player_dir = "left"
	elif input_right and !input_left:
		velocity.x += ACCEL
		player_dir = "right"
	else:
		velocity.x *= AMBIENT_FRICTION


func _on_Timer_timeout():
	float_jump_available = false