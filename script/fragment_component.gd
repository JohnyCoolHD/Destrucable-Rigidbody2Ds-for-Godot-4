extends Node
class_name FragmentComponent

@export_category("Nodes")
@export var body : Node2D
@export var body_sprite : Sprite2D

@export_category("Fragment Settings")
@export var min_fragment_size : int = 2
@export var fragment_size : int = 2
@export var fragment_jitter : int = 4
@export var explosion_force := 300





var fragment_scene : PackedScene

func _ready() -> void:
	fragment_scene = create_fragment_scene()
	
func create_fragment_scene():
	var root := RigidBody2D.new()
	root.name = "fragment"
	root.mass = 0.1

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	root.add_child(sprite)
	sprite.owner = root

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	root.add_child(collision)


	collision.owner = root
	var packed_scene := PackedScene.new()
	
	packed_scene.pack(root)
	root.queue_free()

	return packed_scene
	
func explode():
	var sprite := body_sprite
	var texture := sprite.texture
	var image := texture.get_image()
	
	var tex_size := texture.get_size()
	var frag_size = tex_size / Vector2(fragment_size, fragment_size)

	var grid = build_frag_grid(frag_size)

	for x in range(fragment_size):
		for y in range(fragment_size):

			var data = create_fragment_data(image, grid, x, y, frag_size)
			if data == null:
				continue

			var shape = create_collision_shape(data.visible_pixels)

			if shape == null:
				continue
			
			spawn_fragment(
				data.texture,
				shape,
				data.center,
				tex_size
			)
	body.queue_free()


func build_frag_grid(frag_size : Vector2):

	var fragment_points := []

	for x in range(fragment_size + 1):
		
		var collum = []
		
		for y in range(fragment_size + 1):
			var jitter = Vector2(
				randf_range(-fragment_jitter, fragment_jitter),
				randf_range(-fragment_jitter, fragment_jitter)
			)

			if x == 0 or x == fragment_size:
				jitter.x = 0
			if y == 0 or y == fragment_size:
				jitter.y = 0

			collum.append(
				(Vector2(x, y) * frag_size) + jitter
			)

		fragment_points.append(collum)
	
	return fragment_points

func create_fragment_data(image : Image, grid, x : int, y : int, frag_size : Vector2):
	var A = grid[x][y]
	var B = grid[x + 1][y]
	var C = grid[x + 1][y + 1]
	var D = grid[x][y + 1]
	
	var center = (A + B + C + D) / 4.0
	var region = Rect2(
		x * frag_size.x,
		y * frag_size.y,
		frag_size.x,
		frag_size.y
		)

	var local_polygon := PackedVector2Array([
		A - region.position,
		B - region.position,
		C - region.position,
		D - region.position
		])

	var frag_image := Image.create(
		int(frag_size.x),
		int(frag_size.y),
		false,
		Image.FORMAT_RGBA8
	)

	var visible_pixels := PackedVector2Array()
	var max_x = -INF
	var min_x = INF
	var max_y = -INF
	var min_y = INF

	for px in range(int(region.size.x)):
		for py in range(int(region.size.y)):
			var point := Vector2(px, py)
			if not Geometry2D.is_point_in_polygon(point, local_polygon):
				frag_image.set_pixel(px, py,  Color(0,0,0,0))
				continue
				
			var source_x := int(region.position.x + px)
			var source_y := int(region.position.y + py)
			var color := image.get_pixel(source_x, source_y)
			frag_image.set_pixel(px, py, color)

			if color.a > 0.1:
				visible_pixels.append( 
					point - (frag_size / 2.0)
				)
				max_x = max(max_x, px)
				min_x = min(min_x, px)
				max_y = max(max_y, py)
				min_y = min(min_y, py)
			
	if visible_pixels.size() < min_fragment_size:
		return null

	var width = max_x - min_x
	var height = max_y - min_y

	if width < min_fragment_size:
		return null
	if height < min_fragment_size:
		return null

	var frag_texture = ImageTexture.create_from_image(frag_image)

	return {
		"texture" : frag_texture,
		"visible_pixels" : visible_pixels,
		"center" : center
	}

func create_collision_shape(visible_pixels : PackedVector2Array):
	var hull := Geometry2D.convex_hull(visible_pixels)

	if hull.size() < 3:
		return null
	
	var polygon := ConvexPolygonShape2D.new()
	polygon.points = hull
	return polygon

func spawn_fragment(texture, shape, center : Vector2, tex_size):

	var frag := fragment_scene.instantiate() as RigidBody2D
	var sprite := frag.get_node("Sprite2D") as Sprite2D

	sprite.texture = texture
	sprite.centered = true
	sprite.position = Vector2.ZERO

	var col := frag.get_node("CollisionShape2D") as CollisionShape2D
	col.shape = shape

	frag.global_position = body.global_position + center - tex_size / 2.0
	var dir = (center - tex_size / 2.0).normalized()
	frag.apply_impulse(dir * explosion_force)
	body.get_parent().add_child(frag)
