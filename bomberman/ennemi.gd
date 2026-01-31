extends CharacterBody3D

signal died

@export var speed : float = 0.75
var tile_size : float = 1.0
var is_moving : bool = false
var current_dir : Vector3 = Vector3.FORWARD

@onready var ray = $RayCast3D
@onready var detecteur = $DetecteurJoueur

func _ready():
	randomize()
	choose_new_direction()

func _physics_process(_delta):
	if is_moving:
		return

	# Essaye d'aller dans la direction courante, sinon choisit une nouvelle direction
	if current_dir != Vector3.ZERO:
		ray.target_position = current_dir * tile_size
		ray.force_raycast_update()
		if not ray.is_colliding():
			move_in_direction(current_dir)
			return

	choose_new_direction()

func choose_new_direction():
	var dirs = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	dirs.shuffle()
	for d in dirs:
		ray.target_position = d * tile_size
		ray.force_raycast_update()
		if not ray.is_colliding():
			current_dir = d
			move_in_direction(d)
			return

	# Si bloqué dans toutes les directions, on reste sur place
	current_dir = Vector3.ZERO

func move_in_direction(direction: Vector3):
	if direction == Vector3.ZERO:
		return

	is_moving = true
	var target_pos = global_position + (direction * tile_size)
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, speed)
	tween.finished.connect(Callable(self, "_on_move_finished"))

func _on_detecteur_joueur_body_entered(body):
	# US14 : Le joueur perd une vie s'il touche un ennemi
	if body is CharacterBody3D and body.has_method("take_damage"):
		body.take_damage()

func die():
	# émet un signal avant de se supprimer pour prévenir le spawner
	emit_signal("died")
	queue_free()
	# On attend la fin de la frame pour que le compte du groupe soit juste
	await get_tree().process_frame
				
func _on_move_finished():
	is_moving = false
