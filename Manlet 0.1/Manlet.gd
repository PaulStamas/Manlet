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
const AIR_FRICTION = .95
const AIR_ACCEL = 80
const AIR_MAX_SPEED = 500
const FLOOR_FRICTION = .85
const WALL_FRICTION = .75
const ACCEL = 80
const PLAYER_MAX_STOP_SPEED = ACCEL * FLOOR_FRICTION
const JUMP_VEL = -630
const WALL_JUMP_VEL = Vector2(-700, -630)
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
const FIRE_SPEED = 800
var rope_init = true
onready var hook_shot = load("res://HookShot.tscn")
var hook_fire = true

#Swing variables
var angle
var rope_length
var swing_accel
var swing_vel = 0
const MAX_SWING_VEL = 0.14
var swing_pos: Vector2
 #swing collision
var swing_col_check = true
var swing_colliding = false


var animation_finished = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$"/root/Global".register_player(self)
	respawn_position = position

func _get_inputs(delta):
	input_up = Input.is_action_pressed("ui_up")
	input_wall_jump = Input.is_action_just_pressed("ui_up")
	input_left = Input.is_action_pressed("ui_left")
	input_right = Input.is_action_pressed("ui_right")
	input_down = Input.is_action_pressed("ui_down")
	
	input_shoot = Input.is_action_just_pressed("ui_shoot")
	
	input_restart = Input.is_action_just_pressed("ui_restart")
	
	if input_restart:
		set_state(FALL, delta)
		set_state2(NONE)
		velocity *= 0
		position = respawn_position
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	_get_inputs(delta)
	state_transitions(delta)
	match state:
		IDLE:
			idle(delta)
			shoot_hook()
		RUN:
			run(delta)
			h_movement(delta)
			shoot_hook()
		JUMP:
			jump(delta)
			h_air_movement(delta)
			shoot_hook()
		FALL:
			fall(delta)
			if last_state == RUN:
				h_movement(delta)
			h_air_movement(delta)
			shoot_hook()
		ON_WALL:
			on_wall(delta)
			h_movement(delta)
		WALL_JUMP:
			wall_jump(delta)
			h_movement(delta)
			shoot_hook()
		SWING:
			swing(delta)
			
	match state2:
		NONE:
			pass
		HOOK_SHOT_ATTACHED:
			hook_shot_attached()
			
	persistant_state()
	velocity = move_and_slide(velocity, Vector2.UP)

func set_state(new_state, delta):
	last_state = state
	persistant_change_state()
	
		
	if last_state == WALL_JUMP:
		wall_jump_dir = null
		
	match new_state:
		IDLE:
			state = IDLE
			velocity.x = 0
			player_sprite.play("Idle")
			player_sprite.speed_scale = 1
			
		RUN:
			state = RUN
			player_sprite.play("Running")
		
		JUMP:
			state = JUMP
			jump_init(delta)
			player_sprite.play("JumpStart")
			#Jump_init in jump
			
		FALL:
			state = FALL
			if last_state == ON_WALL:
				float_jump_available = true
				float_jump_timer.set_wait_time(float_jump_window)
				float_jump_timer.start()
			
			if last_state == RUN:
				velocity.y = 0
				
			player_sprite.play("AirDown")
		
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
			if velocity.y > 0:
				set_state(FALL, delta)
		
		JUMP:
			if velocity.y > GRAVITY:
				set_state(FALL, delta)
			
			if is_on_ceiling():
				velocity.y = 0
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
			if !is_on_wall():
				set_state(FALL, delta)
					
			if input_wall_jump:
				set_state(WALL_JUMP, delta)
					
		WALL_JUMP:
			if velocity.y >= 0:
				set_state(FALL, delta)
				
		SWING:
			#If stuck in a corner, fall and detach rope
			if get_node("Left Check").is_colliding() and get_node("Up Check").is_colliding():
				set_state(FALL, delta)
				set_state2(NONE)
			elif get_node("Right Check").is_colliding() and get_node("Up Check").is_colliding():
				set_state(FALL, delta)
				set_state2(NONE)
				
			elif is_on_floor():
				set_state(IDLE, delta)
				
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
	
func persistant_change_state():
	pass

func idle(delta):
	pass
		
func run(delta):
	#animation rate
	var rate_scale = 40000 * delta
	if rate_scale != 0:
		player_sprite.speed_scale = abs(velocity.x)/rate_scale
	
		
func jump(delta):
	if animation_finished:
		animation_finished = false
		player_sprite.play("AirUp")
	
	
func fall(delta):
	pass
	
func on_wall(delta):
	velocity.x = 0;
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if position.x < collision.position.x:
			velocity.x += .2
			wall_jump_dir = "right"
			if input_right && velocity.y > 0:
				velocity.y *= WALL_FRICTION
		if position.x > collision.position.x:
			velocity.x -= 2
			wall_jump_dir = "left"
			if input_left && velocity.y > 0:
				velocity.y *= WALL_FRICTION
				
func wall_jump(delta):
	pass
	
func wall_jump_init():
	if wall_jump_dir == "left":
		if last_wall_jump_dir == "left":
			velocity.x = -WALL_JUMP_VEL.x * BAD_WALL_JUMP_MULT
			velocity.y = WALL_JUMP_VEL.y * 0.25
		else:
			velocity.x = -WALL_JUMP_VEL.x
			velocity.y = WALL_JUMP_VEL.y
		last_wall_jump_dir = "left"
	elif wall_jump_dir == "right":
		if last_wall_jump_dir == "right":
			velocity.x = WALL_JUMP_VEL.x * BAD_WALL_JUMP_MULT
			velocity.y = WALL_JUMP_VEL.y * 0.25
		else:
			velocity.x = WALL_JUMP_VEL.x
			velocity.y = WALL_JUMP_VEL.y
		last_wall_jump_dir = "right"
		
func swing(delta):
	velocity *= 0
	swing_accel = GRAVITY * sin(angle) * -.01
	swing_vel += swing_accel * delta 
	swing_vel *= .999
	
	#SWING H_MOVEMENT
	if abs(swing_vel) < MAX_SWING_VEL:
		if Input.is_action_pressed("ui_right"):
			swing_vel -= abs(swing_vel/175)
			player_dir = "right"
		elif Input.is_action_pressed("ui_left"):
			player_dir = "left"
			swing_vel += abs(swing_vel/175)

	if swing_col_check:
		if swing_colliding:
			swing_vel *= -0.5
			swing_col_check = false
		
	angle += swing_vel 
	
	#GET SWING POSITION
	swing_pos.x = rope_length * sin(angle) 
	swing_pos.y = rope_length * cos(angle) 
	
	position = Vector2(hook_shot.position.x - swing_pos.x, hook_shot.position.y + swing_pos.y)
	
func swing_init(pos1, pos2):
	#conserving momentum coming into swing
	if abs(velocity.x) > abs(velocity.y):
		swing_vel = -velocity.x/6000
	else:
		swing_vel = velocity.y/6000
		
	velocity *= 0
	rope_length = sqrt(pow(pos1.x - pos2.x, 2) + pow(pos1.y - pos2.y, 2))
	var adj = pos1.y - pos2.y
	var theta = -acos(adj / rope_length)
	if pos1.x - pos2.x < 0: 
		theta *= -1
	angle = theta

func jump_init(delta):
	if last_state == SWING:
		velocity.x = swing_pos.y * delta * 4300 * -swing_vel
		velocity.y = -swing_pos.x * delta * 4300 * swing_vel
		
	else:
			velocity.y = JUMP_VEL
		
#States2
func hook_shot_attached():
	pass
		
		
#FUNCTIONS USED IN STATES
func apply_gravity():
	velocity.y += GRAVITY
	if is_on_floor():
		last_wall_jump_dir = null
		
func shoot_hook():
	if input_shoot:
		if hook_fire:
			if hook_shot.get_class() == "PackedScene":
				hook_shot = hook_shot.instance()
				get_parent().add_child(hook_shot)
			hook_shot.init(FIRE_SPEED, player_dir, position, "Show")
	
	if hook_shot.get_class() == "Area2D":
		var rope_too_long = sqrt(pow(hook_shot.position.x - position.x, 2) + pow(hook_shot.position.y - position.y, 2)) > MAX_ROPE_LENGTH
		if rope_too_long:
			hook_shot.init(0, "none", position, "Hide")
		else: 
			rope_init = true
		
func h_movement(delta):
	if input_left and !input_right:
		velocity.x -= ACCEL
		player_dir = "left"
	elif input_right and !input_left:
		velocity.x += ACCEL
		player_dir = "right"
	else: 
		#stops player for better feel, not redundant
		velocity.x *= WALL_FRICTION
		
	velocity.x *= FLOOR_FRICTION
		
func h_air_movement(delta):
	if input_left and !input_right:
		if velocity.x > -AIR_MAX_SPEED:
			velocity.x -= AIR_ACCEL
			player_dir = "left"
	elif input_right and !input_left:
		if velocity.x < AIR_MAX_SPEED:
			velocity.x += AIR_ACCEL
			player_dir = "right"
			
	velocity.x *= AIR_FRICTION


#signals
func _on_Timer_timeout():
	float_jump_available = false


func _on_AnimatedSprite_animation_finished():
	if player_sprite.animation == "JumpStart":
		animation_finished = true

#collision signals
func _on_Swing_Check_body_entered(body):
	#makes exception for player
	if body.get_name() == "Manlet":
		return
	swing_colliding = true


func _on_Swing_Check_body_exited(body):
	#makes exception for player
	if body.get_name() == "Manlet":
		return
	swing_colliding = false
	swing_col_check = true
