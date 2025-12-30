extends RigidBody2D

##### The Rigidbody needs to be a rectangle or a square with this code !!!
# Don't scale the Sprite2D

@export var explosion_force := 300

@export_range(2, 32) #bigger numbers would definitly cause performance issues 
var fragment_x := 8

@export_range(2, 32)
var fragment_y := 8

@export var fragment_scene : PackedScene

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		explode()
		queue_free()

func explode():
	var sprite := get_node("Sprite2D") as Sprite2D
	var texture := sprite.texture
	var tex_size := texture.get_size()

	var fragment_size = tex_size / Vector2(fragment_x, fragment_y)

	for x in range(fragment_x):
		for y in range(fragment_y):
			var frag := fragment_scene.instantiate() as RigidBody2D

			var frag_sprite := frag.get_node("Sprite2D") as Sprite2D
			frag_sprite.texture = texture
			frag_sprite.region_enabled = true
			frag_sprite.region_rect = Rect2(
				x * fragment_size.x,
				y * fragment_size.y,
				fragment_size.x,
				fragment_size.y
			)

			var offset = Vector2(
				(x + 0.5) * fragment_size.x,
				(y + 0.5) * fragment_size.y
			) - tex_size / 2

			frag.global_position = global_position + offset
			var dir = (global_position + offset - global_position).normalized()
			frag.apply_impulse(dir * explosion_force)
			frag.get_node("CollisionShape2D").shape.extents = fragment_size / 2
			get_parent().add_child(frag)
