extends Area2D

export(String, FILE, "*.tscn") var scene_to_load

func _physics_process(delta):
	
	Area2D
	
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.name == "Player":
			$"/root/AudioManager".play("Win")
			get_tree().change_scene(scene_to_load)