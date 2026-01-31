extends Area3D


func _ready():
	for child in get_children():
		if child is GPUParticles3D:
			child.emitting = true
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_body_entered(body):
	
	# --- GESTION DES DEGATS (Joueur et Ennemis) ---
	if body is CharacterBody3D and body.has_method("take_damage"):
		body.take_damage()
		
	if body.has_method("die") and body.is_in_group("ennemis"):
		body.die()
	# explosion_effect ne gère plus la destruction des briques ni le score
