extends Label

func _process(delta):
	text = str(1.0 / delta)
	text += "\n" + str(Engine.get_frames_per_second())