extends Control
class_name GECanvas
tool

export var pixel_size: int = 16 setget set_pixel_size
export(int, 1, 2500) var canvas_width = 48 setget set_canvas_width # == pixels
export(int, 1, 2500) var canvas_height = 28 setget set_canvas_height # == pixels
export var grid_size = 16 setget set_grid_size
export var big_grid_size = 10 setget set_big_grid_size
export var can_draw = true

var mouse_in_region
var mouse_on_top

var layers : Array = [] # Key: layer_name, val: GELayer
var active_layer: GELayer
var preview_layer: GELayer

var canvas
var grid
var big_grid
var selected_pixels = []



func _enter_tree():
	#-------------------------------
	# Set nodes
	#-------------------------------
	canvas = find_node("Canvas")
	grid = find_node("Grid")
	big_grid = find_node("BigGrid")
	
	#-------------------------------
	# setup layers and canvas
	#-------------------------------
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	
	#-------------------------------
	# setup layers and canvas
	#-------------------------------
	#canvas_size = Vector2(int(rect_size.x / grid_size), int(rect_size.y / grid_size))
	#pixel_size = canvas_size
	
	active_layer = add_new_layer("Layer1")
	preview_layer = add_new_layer("Preview")
	
	set_process(true)


func _process(delta):
	if active_layer == null:
		return
	var mouse_position = get_local_mouse_position()
	var rect = Rect2(Vector2(0, 0), rect_size)
	mouse_in_region = rect.has_point(mouse_position)
	update()


func _draw():
	for layer in layers:
		if not layer.visible:
			continue
		var idx = 0
		for color in layer.pixels:
			var p = GEUtils.to_2D(idx, canvas_width)
			draw_rect(Rect2(p.x * pixel_size, p.y * pixel_size, pixel_size, pixel_size), color)
			idx += 1
	
	var idx = 0
	for color in preview_layer.pixels:
		var p = GEUtils.to_2D(idx, canvas_width)
		draw_rect(Rect2(p.x * pixel_size, p.y * pixel_size, pixel_size, pixel_size), color)
		idx += 1
	


#-------------------------------
# Export
#-------------------------------

func set_pixel_size(size: int):
	pixel_size = size
	set_grid_size(grid_size)
	set_big_grid_size(big_grid_size)
	set_canvas_width(canvas_width)
	set_canvas_height(canvas_height)


func set_grid_size(size):
	grid_size = size
	if not find_node("Grid"):
		return
	find_node("Grid").size = size * pixel_size


func set_big_grid_size(size):
	big_grid_size = size
	if not find_node("BigGrid"):
		return
	find_node("BigGrid").size = size * pixel_size


func set_canvas_width(val: int):
	canvas_width = val
	rect_size.x = canvas_width * pixel_size


func set_canvas_height(val: int):
	canvas_height = val
	rect_size.y = canvas_height * pixel_size


#-------------------------------
# Layer
#-------------------------------

func get_active_layer():
	return active_layer


func get_preview_layer():
	return preview_layer


func clear_active_layer():
	active_layer.clear()


func clear_preview_layer():
	preview_layer.clear()


func clear_layer(layer_name: String):
	for layer in layers:
		if layer.name == layer_name:
			layer.clear()
			break


func remove_layer(layer_name: String):
	# change current layer if the active layer is removed
	var del_layer = find_layer_by_name(layer_name)
	del_layer.clear()
	if del_layer == active_layer:
		for layer in layers:
			if layer == preview_layer or layer == active_layer:
				continue
			active_layer = layer
			break
	layers.erase(del_layer)
	return active_layer


func add_new_layer(layer_name: String):
	for layer in layers:
		if layer.name == layer_name:
			return
	var layer = GELayer.new()
	layer.name = layer_name
	layer.resize(canvas_width, canvas_height)
	if layer_name != "Preview":
		layers.append(layer)
	return layer


func duplicate_layer(layer_name: String, new_layer_name: String):
	for layer in layers:
		if layer.name == new_layer_name:
			return
	
	var dup_layer
	for layer in layers:
		if layer.name == layer_name:
			dup_layer = layer
			break
	
	var layer :GELayer = add_new_layer(new_layer_name)
	layer.pixels = dup_layer.pixels.duplicate()
	layer.name = new_layer_name
	return layer


func toggle_layer_visibility(layer_name: String):
	for layer in layers:
		if layer.name == layer_name:
			layer.visible = not layer.visible


func find_layer_by_name(layer_name: String):
	for layer in layers:
		if layer.name == layer_name:
			return layer
	return null


func move_layer_forward(layer_name: String):
	var remove_pos = -1
	var layer
	for i in range(layers.size()):
		if layers[i].name == layer_name:
			remove_pos = i
			layer = layers[i]
			print("from: ", i)
			break
	layers.erase(layer)
	print("forw to: ", max(remove_pos - 1, 0))
	layers.insert(max(remove_pos - 1, 0), layer)


func move_layer_back(layer_name: String):
	var remove_pos = -1
	var layer
	for i in range(layers.size()):
		if layers[i].name == layer_name:
			remove_pos = i
			layer = layers[i]
			print("from: ", i)
			break
	layers.erase(layer)
	print("back to: ", min(remove_pos + 1, layers.size()))
	layers.insert(min(remove_pos + 1, layers.size()), layer)


func select_layer(layer_name: String):
	active_layer = find_layer_by_name(layer_name)


#-------------------------------
# Check 
#-------------------------------

func _on_mouse_entered():
	mouse_on_top = true


func _on_mouse_exited():
	mouse_on_top = false


func is_inside_canvas(x, y):
	if x < 0 or y < 0:
		return false
	if x >= canvas_width or y >= canvas_height:
		return false
	return true



#-------------------------------
# Basic pixel-layer options
#-------------------------------


#Note: Arrays are always passed by reference. To get a copy of an array which 
#      can be modified independently of the original array, use duplicate.
# (https://docs.godotengine.org/en/stable/classes/class_array.html)
func set_pixel_arr(pixels: Array, color: Color):
	for pixel in pixels:
		_set_pixel(active_layer, pixel.x, pixel.y, color)


func set_pixel_v(pos: Vector2, color: Color):
	set_pixel(pos.x, pos.y, color)


func set_pixel(x: int, y: int, color: Color):
	_set_pixel(active_layer, x, y, color)


func _set_pixel(layer: GELayer, x: int, y: int, color: Color):
	if not is_inside_canvas(x, y):
		return
	layer.set_pixel(x, y, color)


func get_pixel_v(pos: Vector2):
	return get_pixel(pos.x, pos.y)


func get_pixel(x: int, y: int):
	var idx = GEUtils.to_1D(x, y, canvas_width)
	if active_layer:
		if active_layer.pixels.size() <= idx:
			return null
		return active_layer.pixels[idx]
	return null


func set_preview_pixel_v(pos: Vector2, color: Color):
	set_preview_pixel(pos.x, pos.y, color)


func set_preview_pixel(x:int, y: int, color: Color):
	if not is_inside_canvas(x, y):
		return
	preview_layer.set_pixel(x, y, color)


func get_preview_pixel_v(pos: Vector2):
	return get_preview_pixel(pos.x, pos.y)


func get_preview_pixel(x: int, y: int):
	var idx = GEUtils.to_1D(x, y, canvas_width)
	if preview_layer:
		if preview_layer.pixels.size() <= idx:
			return null
	return preview_layer.pixels[idx]


#-------------------------------
# Handy tools
#-------------------------------


func select_color(x, y):
	var same_color_pixels = []
	var color = get_pixel(x, y)
	for pixel_color in active_layer.pixels:
		if pixel_color == color:
			same_color_pixels.append(color)
	return same_color_pixels


func select_same_color(x, y):
	return get_neighbouring_pixels(x, y)


# returns array of Vector2
# yoinked from 
# https://www.geeksforgeeks.org/flood-fill-algorithm-implement-fill-paint/
func get_neighbouring_pixels(pos_x: int, pos_y: int) -> Array:
	var pixels = []
	
	var to_check_queue = []
	var checked_queue = []
	
	to_check_queue.append(GEUtils.to_1D(pos_x, pos_y, canvas_width))
	
	var color = get_pixel(pos_x, pos_y)
	
	while not to_check_queue.empty():
		var idx = to_check_queue.pop_front()
		var p = GEUtils.to_2D(idx, canvas_width)
		
		if idx in checked_queue:
			continue
		
		checked_queue.append(idx)
		
		if get_pixel(p.x, p.y) != color:
			continue
		
		# add to result
		pixels.append(p)
		
		# check neighbours
		var x = p.x - 1
		var y = p.y
		if is_inside_canvas(x, y):
			idx = GEUtils.to_1D(x, y, canvas_width)
			to_check_queue.append(idx)
		
		x = p.x + 1
		if is_inside_canvas(x, y):
			idx = GEUtils.to_1D(x, y, canvas_width)
			to_check_queue.append(idx)
		
		x = p.x
		y = p.y - 1
		if is_inside_canvas(x, y):
			idx = GEUtils.to_1D(x, y, canvas_width)
			to_check_queue.append(idx)
		
		y = p.y + 1
		if is_inside_canvas(x, y):
			idx = GEUtils.to_1D(x, y, canvas_width)
			to_check_queue.append(idx)
	
	return pixels

