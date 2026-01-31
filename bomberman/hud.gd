extends CanvasLayer

@onready var label_vies = $Control/vies
@onready var bomb_label = $Control/bombes
@onready var score_label = $Control/score
@onready var panel_game_over = $GameOverPanel
@onready var panel_victoire = $Victoire

func _ready():
	print("HUD: _ready() start")
	if panel_game_over:
		panel_game_over.hide()

	# Masquer le panneau Victoire
	if panel_victoire:
		panel_victoire.hide()
	
	# Connexion du bouton Rejouer (US21)
	# Assurez-vous que le nom du bouton correspond à votre scène (ex: "RetryButton")
	# Bouton Rejouer du GameOver
	var btn = get_node_or_null("GameOverPanel/VBoxContainer/rejouer")
	if btn:
		btn.connect("pressed", Callable(self, "_on_rejouer_pressed"))
		print("HUD: connected GameOver/rejouer")

	# Bouton Recommencer du Control
	var btn_control = get_node_or_null("Control/Button")
	if btn_control:
		btn_control.connect("pressed", Callable(self, "_on_rejouer_pressed"))
		print("HUD: connected Control/Button (rejouer)")

	# Victoire panel buttons
	var btn_v_rejouer = get_node_or_null("Victoire/VBoxContainer/Rejouer")
	if btn_v_rejouer:
		btn_v_rejouer.connect("pressed", Callable(self, "_on_rejouer_pressed"))
		print("HUD: connected Victoire/Rejouer")
	var btn_levelup = get_node_or_null("Victoire/VBoxContainer/LevelUp")
	if btn_levelup:
		btn_levelup.connect("pressed", Callable(self, "_on_level_up_pressed"))
		print("HUD: connected Victoire/LevelUp")

	# Nous n'utilisons pas pause_mode ici car il n'est pas disponible
	# sur cette version/type de nœud : nous gardons l'UI non-pausée.

# Dans votre script HUD
func update_vies(v: int):
	# On cherche le nœud dynamiquement si label_vies est null
	if not label_vies:
		label_vies = find_child("vies", true, false)
	
	if label_vies:
		label_vies.text = "Vies : " + str(v)
	else:
		print("ERREUR : Le Label 'vies' est introuvable dans la scène.")

func add_score(points: int):
	# Initialise si nécessaire
	if not score_label:
		score_label = find_child("score", true, false)
	if score_label:
		var current = 0
		if score_label.text != "":
			# Texte attendu : "Score : N"
			var parts = score_label.text.split(":")
			if parts.size() >= 2:
				current = int(parts[1].strip_edges())
		current += points
		score_label.text = "Score : " + str(current)
	else:
		print("ERREUR : Le Label 'score' est introuvable")

func afficher_game_over():
	if panel_game_over:
		panel_game_over.show()
	# NOTE: ne pas mettre l'arbre en pause ici pour garantir que
	# les boutons UI restent interactifs sur toutes les versions de Godot.
	# Si vous souhaitez figer la logique du jeu, utilisez un drapeau
	# de pause dans vos scripts de gameplay.
	get_tree().paused = false

func afficher_victoire():
	if panel_victoire:
		panel_victoire.show() # Affiche le menu de victoire
	# Voir note ci-dessus — ne pas pauser l'arbre pour garantir l'interaction
	get_tree().paused = false

func update_bombes(count: int):
	# On s'assure que le nœud est bien récupéré
	if not bomb_label:
		bomb_label = find_child("bombes", true, false)
	
	if bomb_label:
		bomb_label.text = "Bombes : " + str(count)
	else:
		print("ERREUR : Le Label 'bombes' est introuvable")
func _on_rejouer_pressed():
	print("HUD: _on_rejouer_pressed() called")
	# 1. TRÈS IMPORTANT : Enlever la pause AVANT de relancer
	get_tree().paused = false

	# Cacher les panneaux UI avant de relancer
	if panel_game_over:
		panel_game_over.hide()
	if panel_victoire:
		panel_victoire.hide()

	# 2. Si GridMap propose restart_level(), l'utiliser pour garder le niveau courant
	# Réinitialiser le joueur (vies et stock de bombes) si présent
	var player = get_parent().get_node_or_null("Player")
	if player:
		if player.has_method("actualiser_hud"):
			player.vies = player.max_vies
			# réinitialiser le stock de bombes à la valeur initiale
			player.bomb_stock = player.initial_bomb_stock
			player.actualiser_hud()

	var grid = get_parent().get_node_or_null("GridMap")
	if grid and grid.has_method("restart_level"):
		print("HUD: calling GridMap.restart_level()")
		grid.restart_level()
	else:
		# fallback: recharger la scène
		get_tree().reload_current_scene()

func _on_level_up_pressed():
	print("HUD: _on_level_up_pressed() called")
	# Débloquer la pause, cacher le panneau et demander au GridMap de générer le niveau suivant
	get_tree().paused = false
	if panel_victoire:
		panel_victoire.hide()

	var grid = get_parent().get_node_or_null("GridMap")
	if grid and grid.has_method("next_level"):
		grid.next_level()
	else:
		# Si pas de méthode, on recharge simplement la scène
		get_tree().reload_current_scene()
