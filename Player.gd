extends KinematicBody2D

export(float) var max_speed
export(float) var acceleration
export(float) var jump_height
export(float) var gravity
export(float) var push_speed

var _player_jump_cancellation_delay = 0.1

const UP = Vector2(0, -1)

var _motion = Vector2()
var _tilemap
var _jump_delay_timer

func _ready():
	set_process_input(true)
	_tilemap = $"../TileMap"
	
	_jump_delay_timer = Timer.new()
	_jump_delay_timer.wait_time = _player_jump_cancellation_delay
	_jump_delay_timer.one_shot = true
	add_child(_jump_delay_timer)

func _input(event):
	if event.is_action_pressed("ui_up"):
		_jump_delay_timer.start()

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_pressed("ui_accept"):
		$"/root/AudioManager".play("Death")
		get_tree().reload_current_scene()
	
	# update _motion based on gravity and input
	_motion.y += gravity
	
	var motion_update = 0
	if Input.is_action_pressed("ui_left"):
		motion_update -= acceleration;
	if Input.is_action_pressed("ui_right"):
		motion_update += acceleration;

	var friction = true
	if motion_update != 0:
		friction = false
		$AnimatedSprite.flip_h = motion_update < 0
		$AnimatedSprite.animation = "run"
	else:
		$AnimatedSprite.animation = "idle"
	
	_motion.x += motion_update
	
	if is_on_floor():
		if friction:
			_motion.x = lerp(_motion.x, 0, 0.4)		
		if !_jump_delay_timer.is_stopped():
			_jump_delay_timer.stop()
			$"/root/AudioManager".play("Jump")
			_motion.y -= jump_height
	else:
		if friction:
			_motion.x = lerp(_motion.x, 0, 0.05)
			
	_motion.x = clamp(_motion.x, -max_speed, max_speed)

	# push
	if (motion_update != 0) :
		var wall_hit = test_move(transform, Vector2(_motion.x * delta, 0))
		if wall_hit:			
			var direction = Vector2(motion_update, 0)
			_tilemap.push(position, direction, is_on_floor())

	# move
	_motion = move_and_slide(_motion, UP)
	