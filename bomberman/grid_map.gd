extends GridMap

# Référence à la scène de l'ennemi
var ennemi_scene = preload("res://ennemi.tscn")

# Configuration des niveaux : densité des caisses et nombre d'ennemis
var NIVEAUX = {
	"facile": {"densite": 0.1, "ennemis": 1},
	"moyen": {"densite": 0.15, "ennemis": 2},
	"difficile": {"densite": 0.2, "ennemis": 3}
}

var enemy_count: int = 0

# Ordre des niveaux et index courant
var LEVEL_ORDER = ["facile", "moyen", "difficile"]
var current_level_index: int = 0

# Position initiale du joueur (pour reset entre niveaux)
var initial_player_pos: Vector3 = Vector3.ZERO

func _ready():
	# Sauvegarder la position initiale du Player (si présent)
	var player = get_parent().get_node_or_null("Player")
	if player:
		initial_player_pos = player.global_position
		print("GridMap: initial_player_pos stored:", initial_player_pos)
	generer_niveau("facile")

func generer_niveau(nom_niveau: String):
	var idx = LEVEL_ORDER.find(nom_niveau)
	if idx >= 0:
		current_level_index = idx

	var config = NIVEAUX[nom_niveau]
	var densite = config["densite"]
	var nb_ennemis = config["ennemis"]
	
	# 1. Nettoyage et calcul des limites du contour existant
	var all_cells = get_used_cells()
	if all_cells.is_empty(): return
	
	var min_x = 999; var max_x = -999
	var min_z = 999; var max_z = -999
	
	for cell in all_cells:
		if cell.y == 1:
			min_x = min(min_x, cell.x)
			max_x = max(max_x, cell.x)
			min_z = min(min_z, cell.z)
			max_z = max(max_z, cell.z)

	# Supprimer les anciens ennemis
	for e in get_tree().get_nodes_in_group("ennemi"):
		e.queue_free()

	# 2. Placement des obstacles (Piliers et Caisses)
	for x in range(min_x + 1, max_x):
		for z in range(min_z + 1, max_z):
			var pos = Vector3i(x, 1, z)
			
			# Zone de sécurité joueur (Coin en bas à droite)
			if (x >= max_x - 2 and z >= max_z - 2):
				continue
				
			# On ne pose rien si un mur de contour est déjà là (Item 1)
			if get_cell_item(pos) != -1: 
				continue

			# MURS INDESTRUCTIBLES (Piliers)
			if (x - min_x) % 2 == 0 and (z - min_z) % 2 == 0:
				set_cell_item(pos, 0)
			# MURS DESTRUCTIBLES (Caisses)
			elif randf() < densite:
				set_cell_item(pos, 2)

	# --- ÉTAPE CRUCIALE ---
	# On attend la fin de la frame pour que la GridMap enregistre les set_cell_item
	await get_tree().process_frame

	# 3. Détection des cases strictement vides à l'INTÉRIEUR
	var positions_libres = []
	for x in range(min_x + 1, max_x):
		for z in range(min_z + 1, max_z):
			var pos = Vector3i(x, 1, z)
			# On vérifie si la case est TOTALEMENT vide (Item -1)
			if get_cell_item(pos) == -1:
				# On exclut aussi la zone du joueur par sécurité
				if not (x >= max_x - 2 and z >= max_z - 2):
					positions_libres.append(pos)

	# 4. Génération des ennemis
	enemy_count = 0
	positions_libres.shuffle() # On mélange pour l'aléatoire
	
	for i in range(nb_ennemis):
		if positions_libres.size() > 0:
			var pos_grid = positions_libres.pop_front()
			spawn_ennemi(pos_grid)
			enemy_count += 1
func spawn_ennemi(pos_grid: Vector3i):
	var nouvel_ennemi = ennemi_scene.instantiate()
	
	# 1. Calculer la position réelle
	var pos_3d = map_to_local(pos_grid)
	
	# 2. Assigner la position AVANT d'ajouter l'enfant
	nouvel_ennemi.global_position = pos_3d

	# Marquer l'ennemi dans un groupe pour pouvoir le supprimer facilement
	if not nouvel_ennemi.is_in_group("ennemi"):
		nouvel_ennemi.add_to_group("ennemi")
	
	# connecter le signal 'died' pour décrémenter le compteur d'ennemis
	if nouvel_ennemi.has_method("connect"):
		nouvel_ennemi.connect("died", Callable(self, "_on_enemy_died"))

	# 3. Ajouter l'ennemi à la scène
	get_tree().current_scene.add_child.call_deferred(nouvel_ennemi)


func clear_level_area():
	# Efface les cellules intérieures délimitées par le contour sur la couche 1
	var all_cells = get_used_cells()
	if all_cells.is_empty():
		return
	var min_x = 999; var max_x = -999
	var min_z = 999; var max_z = -999
	for cell in all_cells:
		if cell.y == 1:
			min_x = min(min_x, cell.x)
			max_x = max(max_x, cell.x)
			min_z = min(min_z, cell.z)
			max_z = max(max_z, cell.z)

	for x in range(min_x + 1, max_x):
		for z in range(min_z + 1, max_z):
			set_cell_item(Vector3i(x, 1, z), -1)

	# Supprimer les ennemis
	for e in get_tree().get_nodes_in_group("ennemi"):
		e.queue_free()
	enemy_count = 0


func next_level():
	current_level_index += 1
	if current_level_index >= LEVEL_ORDER.size():
		current_level_index = 0 # wrap to first or clamp as you prefer

	clear_level_area()
	generer_niveau(LEVEL_ORDER[current_level_index])

	# Remettre le joueur à la position initiale
	var player = get_parent().get_node_or_null("Player")
	if player:
		player.global_position = initial_player_pos
		print("GridMap: player reset to initial position", initial_player_pos)


func restart_level():
	# Régénère le niveau courant
	clear_level_area()
	generer_niveau(LEVEL_ORDER[current_level_index])

	# Remettre le joueur à la position initiale
	var player = get_parent().get_node_or_null("Player")
	if player:
		player.global_position = initial_player_pos
		print("GridMap: player reset to initial position", initial_player_pos)

func _on_enemy_died():
	# On attend la fin de la frame pour que l'ennemi qui vient de mourir 
	# soit bien retiré du compte ou en cours de suppression (queue_free)
	await get_tree().process_frame
	
	# On compte combien d'ennemis appartiennent encore au groupe "ennemi"
	var ennemis_vivants = get_tree().get_nodes_in_group("ennemi")
	
	# On filtre pour ne garder que ceux qui ne sont pas déjà en train d'être supprimés
	var compte_reel = 0
	for e in ennemis_vivants:
		if not e.is_queued_for_deletion():
			compte_reel += 1
	
	enemy_count = compte_reel
	print("Ennemis restants : ", enemy_count)

	if enemy_count <= 0:
		enemy_count = 0
		# Victoire : appeler le HUD pour afficher l'écran de victoire
		var hud = get_parent().get_node_or_null("HUD")
		if hud and hud.has_method("afficher_victoire"):
			hud.afficher_victoire()
