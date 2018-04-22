extends KinematicBody2D

export(float) var max_speed
export(float) var acceleration
export(float) var jump_height
export(float) var gravity
export(float) var push_speed

const UP = Vector2(0, -1)

var _motion = Vector2()
var _tilemap
var _try_jump = false

func _ready():
	set_process_input(true)
	_tilemap = $"../TileMap"

func _input(event):
	if event.is_action_pressed("ui_up"):
		_try_jump = true	

func _physics_process(delta):
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
		$Sprite.flip_h = motion_update < 0
	
	_motion.x += motion_update
	
	if is_on_floor():
		if friction:
			_motion.x = lerp(_motion.x, 0, 0.4)		
		if _try_jump:
			_motion.y -= jump_height
	else:
		if friction:
			_motion.x = lerp(_motion.x, 0, 0.05)
		if _try_jump:
			_try_jump = false
			
	_motion.x = clamp(_motion.x, -max_speed, max_speed)

	# push
	if (motion_update != 0) :
		var wall_hit = test_move(transform, Vector2(_motion.x * delta, 0))
		if wall_hit:
			var direction = Vector2(motion_update, 0)
			_tilemap.push(position, direction)

	# move
	_motion = move_and_slide(_motion, UP)
	