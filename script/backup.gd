extends RigidBody2D

@export var explosion_force := 300

@export var fragment_x : int = 2
@export var fragment_y : int = 2

@export var fragment_scene : PackedScene



func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		explode()
		queue_free()
	

func explode():
	var sprite := get_node("Sprite2D") as Sprite2D
	var texture := sprite.texture
	var image := texture.get_image()
	var tex_size := texture.get_size()

	var fragment_size = tex_size / Vector2(fragment_x, fragment_y)
	

	for x in range(fragment_x):
		for y in range(fragment_y):

			var region = Rect2(
				x * fragment_size.x,
				y * fragment_size.y,
				fragment_size.x,
				fragment_size.y
			)

			var frag_image := Image.create(
				int(fragment_size.x),
				int(fragment_size.y),
				false,
				Image.FORMAT_RGBA8
			)

			var has_visible := false
			var is_full := true
			var visible_pixels := PackedVector2Array()
			var visible_pixels_count := 0

			for px in range(int(region.size.x)):
				for py in range(int(region.size.y)):
					
					var source_x = int(region.position.x + px)
					var source_y = int(region.position.y + py)

					var color = image.get_pixel(source_x, source_y)
					frag_image.set_pixel(px, py, color)

					if color.a > 0.1:
						has_visible = true
						visible_pixels_count += 1
						visible_pixels.append(Vector2(px, py))
					else:
						is_full = false

			if not has_visible:
				continue
			
			if visible_pixels_count < 8:
				continue

			var frag_texture := ImageTexture.create_from_image(frag_image)
			
			var frag := fragment_scene.instantiate() as RigidBody2D
			
			var frag_sprite := frag.get_node("Sprite2D") as Sprite2D
			frag_sprite.texture = frag_texture
			frag_sprite.centered = true

			var col := frag.get_node("CollisionShape2D") as CollisionShape2D

			if is_full:
				var rect := RectangleShape2D.new()
				rect.extents = fragment_size / 2.
				col.shape = rect
			else:
				var polygon := ConvexPolygonShape2D.new()
				var hull = Geometry2D.convex_hull(visible_pixels)

				for i in range(hull.size()):
					hull[i] -= fragment_size / 2
				polygon.points = hull
				col.shape = polygon
			

			var offset = Vector2(
				(x + 0.5) * fragment_size.x,
				(y + 0.5) * fragment_size.y
			) - tex_size / 2
			frag.global_position = global_position + offset

			
			
			var dir = (global_position + offset - global_position).normalized()
			
			frag.apply_impulse(dir * explosion_force)
			
			get_parent().add_child(frag)
			
			
