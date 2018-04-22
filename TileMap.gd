extends TileMap

class CellGroup:
	var _cell_coords_array = []
	var _tilemap
	var _cell_group_map
	var _is_on_floor = true
	var _falling_time = 0
	var _falling_delay = 0.5
	
	func update(delta):
		var down = Vector2(0, 1)
		if _is_on_floor:
			if (_check_if_can_move(down)):
				_is_on_floor = false
				_falling_time = 0
		else:
			_falling_time += delta
			if _falling_time > _falling_delay:
				_falling_time = 0
				if (_check_if_can_move(down)):
					_move(down)
				else:
					_is_on_floor = true
	
	func try_move(direction):			
		if _check_if_can_move(direction):
			_move(direction)

	func _check_if_can_move(direction):
		var direction_map_coords = Vector2(sign(direction.x), sign(direction.y))
		var first_cell = _tilemap.get_cellv(_cell_coords_array[0])
		
		for cell_coords in _cell_coords_array:
			var cell_coords_to = cell_coords + direction_map_coords
			if _cell_coords_array.has(cell_coords_to):
				continue
				
			var cell_to = _tilemap.get_cellv(cell_coords_to)			
			if cell_to != _tilemap.NONE:
				return false
				
		return true
		
	func _move(direction):
		var direction_map_coords = Vector2(sign(direction.x), sign(direction.y))
		var first_cell = _tilemap.get_cellv(_cell_coords_array[0])

		# move player if necessary	
		var space_state = _tilemap.get_world_2d().direct_space_state

		for cell_coords in _cell_coords_array:
			var cell_size = _tilemap.get_cell_size()
				
			var world_coords = _tilemap.map_to_world(cell_coords + direction_map_coords)
			world_coords += cell_size / 2
				
			# prepare overlap query parameters 			
			var param = Physics2DShapeQueryParameters.new()
			param.transform.origin = world_coords
	
			var shape = RectangleShape2D.new()
			shape.set_extents(cell_size / 2)
			param.set_shape(shape)
	
			# check overlaps
			var overlaps = space_state.intersect_shape(param)
	
			for overlap in overlaps:
				if overlap.collider.name == "Player":
					overlap.collider.position.y = world_coords.y + cell_size.y
					# check if player should die
					var player_new_coords_map_space = _tilemap.world_to_map(overlap.collider.position)
					var overlapping_cell = _tilemap.get_cellv(player_new_coords_map_space)
					if overlapping_cell != _tilemap.NONE:
						_tilemap.get_tree().reload_current_scene()

		# remove cells from tilemap and cell group map
		for cell_coords in _cell_coords_array:
			_tilemap.set_cellv(cell_coords, _tilemap.NONE)
			_cell_group_map.set_group(cell_coords, null)
			
		# update cell_coords and add cells to tilemap and cell group map
		for i in range(0, _cell_coords_array.size()):
			var cell_coords = _cell_coords_array[i]
			cell_coords += direction_map_coords
			_cell_coords_array[i] = cell_coords
			_tilemap.set_cellv(cell_coords, first_cell)
			_cell_group_map.set_group(cell_coords, self)

	func _move_player_if_necessary(cell_coords, space_state):
		var cell_size = _tilemap.get_cell_size()
			
		var world_coords = _tilemap.map_to_world(cell_coords)
		world_coords += cell_size / 2
			
		# prepare overlap query parameters 			
		var param = Physics2DShapeQueryParameters.new()
		param.transform.origin = world_coords

		var shape = RectangleShape2D.new()
		shape.set_extents(cell_size / 2)
		param.set_shape(shape)

		# check overlaps
		var overlaps = space_state.intersect_shape(param)

		for overlap in overlaps:
			if overlap.collider.name == "Player":
				overlap.collider.position.y = world_coords.y + cell_size.y

	func is_on_floor():
		return _is_on_floor
	
	func get_cell_coords_array():
		return _cell_coords_array
	
	func _init(tilemap, cell_group_map, first_cell_coords):
		_tilemap = tilemap
		_cell_group_map = cell_group_map
		
		var cell_type = _tilemap.get_cellv(first_cell_coords)
		_init_recursion(first_cell_coords, cell_type, _cell_coords_array)

		for cell_coords in _cell_coords_array:	
			_cell_group_map.set_group(cell_coords, self)
					
	func _init_recursion(map_coords, cell_type, result_array):
		var current_cell_type = _tilemap.get_cellv(map_coords)
		
		if current_cell_type != cell_type:
			return
		
		for cell_coords in result_array:
			if map_coords == cell_coords: # if already visited
				return
		
		result_array.push_back(map_coords)
		
		_init_recursion(map_coords + Vector2(-1, 0), cell_type, result_array)
		_init_recursion(map_coords + Vector2(1, 0), cell_type, result_array)
		_init_recursion(map_coords + Vector2(0, -1), cell_type, result_array)
		_init_recursion(map_coords + Vector2(0, 1), cell_type, result_array);
	
class CellGroupMap:
	var _array2d
	var _width
	var _height
	
	func _init(width, height):
		_array2d = []
		_width = width
		_height = height
		
		for x in range(0, width):
			for y in range(0, height):
				_array2d.push_back(null)
		
	func get_group(map_coords):
		return _array2d[map_coords.y * _width + map_coords.x]
	
	func set_group(map_coords, group):
		_array2d[map_coords.y * _width + map_coords.x] = group

enum CellTypes {
	WALL = 0,
	NONE = -1
}

const WIDTH = 50
const HEIGHT = 50
var _cell_group_map
var _cell_groups = []

func _ready():
	_cell_group_map = CellGroupMap.new(WIDTH, HEIGHT)

	for y in range(0, HEIGHT):
		for x in range(0, WIDTH):
			var map_coords = Vector2(x, y)
			var cell = get_cellv(map_coords)
			if _cell_group_map.get_group(map_coords) == null && cell != WALL && cell != NONE:
				var cell_group = CellGroup.new(self, _cell_group_map, map_coords)
				_cell_groups.push_back(cell_group)

func push(from, direction, is_on_floor):
	var map_coords = world_to_map(from)
	var cell_group = _cell_group_map.get_group(map_coords + Vector2(sign(direction.x), sign(direction.y)))
	if cell_group:
		# if player is standing on cell_group to be pushed AND cell_group is on floor, cancel
		if is_on_floor && cell_group.is_on_floor():
			var cell_type_floor = get_cellv(map_coords + Vector2(0, 1))
			var cell_type_cell_group = get_cellv(cell_group.get_cell_coords_array()[0])
			if cell_type_floor == cell_type_cell_group:
				return
		
		cell_group.try_move(direction)

func _process(delta):
	for cell_group in _cell_groups:
		cell_group.update(delta)

	# destroy tiles if necessary
	for y in range(HEIGHT - 1, -1, -1): # HEIGHT, HEIGHT - 1, ..., 0	
		var start_x = 0
		var scanning = false

		for x in range(0, WIDTH):
			var map_coords = Vector2(x, y)
			var cell = get_cellv(map_coords) 
			
			var cell_group_is_on_floor = true
			var cell_group = _cell_group_map.get_group(map_coords)
			if cell_group:
				cell_group_is_on_floor = cell_group.is_on_floor()
				
			if cell == NONE || !cell_group_is_on_floor:
				scanning = false
			elif cell == WALL:
				if !scanning:					
					scanning = true
				else:
					remove_vertical_line_segment(start_x + 1, x - 1, y)
				
				start_x = x

func remove_vertical_line_segment(x_first, x_last, y):
	for x in range(x_first, x_last + 1):
		var destroyable_map_coords = Vector2(x, y)
		set_cellv(destroyable_map_coords, NONE)
	
	for x in range(x_first, x_last + 1):
		var destroyable_map_coords = Vector2(x, y)
		
		var modifiable_cell_group = _cell_group_map.get_group(destroyable_map_coords)
		
		if modifiable_cell_group:
			# remove from _cell_groups
			var modifiable_cell_group_index = _cell_groups.find(modifiable_cell_group)
			_cell_groups.remove(modifiable_cell_group_index)
		
			var cell_coords_array = modifiable_cell_group.get_cell_coords_array()
			
			# remove from _cell_group_map			
			for cell_coords in cell_coords_array:
				_cell_group_map.set_group(cell_coords, null)
			
			# analyze coords and create new groups if necessary
			for cell_coords in cell_coords_array:				
				var current_cell = get_cellv(cell_coords)
				
				if current_cell != WALL && current_cell != NONE:
					if _cell_group_map.get_group(cell_coords) == null:
						var new_cell_group = CellGroup.new(self, _cell_group_map, cell_coords)
						_cell_groups.push_back(new_cell_group)