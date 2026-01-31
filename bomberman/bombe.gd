extends Area3D

@export var explosion_scene : PackedScene = preload("res://explosion_effect.tscn")
@export var bonus_scene : PackedScene = preload("res://bonus.tscn")
var explosion_range = 2
var rng := RandomNumberGenerator.new()

const BONUS_CHANCE := 0.70 # chance qu'une caisse lâche un bonus

func set_explosion_range(r: int):
	explosion_range = r

func _ready():
	$ExplosionTimer.timeout.connect(_on_explosion_timeout)
	rng.randomize()

func _on_explosion_timeout():
	explode()

# Dans bomberman/bombe.gd

func explode():
	var gridmap = get_parent().get_node_or_null("GridMap")

	# Exploser au centre
	spawn_explosion(global_position)
	# On arrête l'explosion si la case centrale est un mur indestructible ou une caisse
	if _process_cell(global_position, gridmap):
		# si c'était une caisse, on a déjà placé la flamme, on s'arrête
		var player = get_tree().get_first_node_in_group("player")
		queue_free()
		return

	var directions = [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
	for dir in directions:
		for i in range(1, explosion_range + 1):
			var target_pos = global_position + (dir * i)
			var stop = false
			if gridmap:
				stop = _process_cell(target_pos, gridmap)

			spawn_explosion(target_pos)

			if stop:
				break
	var player = get_tree().get_first_node_in_group("player")
	queue_free()

func spawn_explosion(pos):
	var e = explosion_scene.instantiate()
	get_parent().add_child(e)
	# On aligne l'effet sur la grille
	e.global_position = Vector3(floor(pos.x) + 0.5, 1.0, floor(pos.z) + 0.5)

func _process_cell(pos: Vector3, gridmap) -> bool:
	# Retourne true si l'explosion doit s'arrêter (mur indestructible ou caisse)
	if not gridmap:
		return false
	var local_pos = gridmap.to_local(pos)
	var map_pos = gridmap.local_to_map(local_pos)
	var item = gridmap.get_cell_item(map_pos)

	print_debug("[bombe] explosion at global:", pos, "local:", local_pos, "map:", map_pos, "item:", item)
	if item == 0:
		return true

	# Si c'est une caisse destructible, on la détruit et on récompense le joueur
	if item == 2:
		gridmap.set_cell_item(map_pos, -1)
		print_debug("[bombe] destroyed crate at", map_pos)
		var hud = get_parent().get_node_or_null("HUD")
		if hud and hud.has_method("add_score"):
			hud.add_score(10)

		# Spawn bonus aléatoire au-dessus de la case détruite
		if rng.randf() < BONUS_CHANCE and bonus_scene:
			var b = bonus_scene.instantiate()
			get_parent().add_child(b)
			# placer le bonus centré sur la case: convertir map -> local -> global
			var map_local_pos = gridmap.map_to_local(map_pos)
			var global_pos = gridmap.to_global(map_local_pos)
			b.global_position = Vector3(floor(global_pos.x) + 0.5, 1.0, floor(global_pos.z) + 0.5)
			# choisir aléatoirement le type
			if b.has_method("set"):
				# si c'est un Node, on accède à la variable exportée
				b.type_bonus = rng.randi_range(0, 1)

		return true

	# --- fallback : vérifier les 4 voisins si la map_pos n'était pas une caisse
	var neighs = [Vector3i(map_pos.x+1, map_pos.y, map_pos.z), Vector3i(map_pos.x-1, map_pos.y, map_pos.z), Vector3i(map_pos.x, map_pos.y, map_pos.z+1), Vector3i(map_pos.x, map_pos.y, map_pos.z-1)]
	for nmp in neighs:
		# vérifie que la position est dans les bornes
		if gridmap and nmp.y == map_pos.y:
			# get_cell_item peut retourner -1, 0, 2
			var it2 = gridmap.get_cell_item(nmp)
			if it2 == 2:
				gridmap.set_cell_item(nmp, -1)
				print_debug("[bombe] fallback destroyed crate at", nmp)
				# porte présélectionnée

	# Rien trouvé
	return false
