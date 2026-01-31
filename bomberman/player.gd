extends CharacterBody3D

# --- Variables de Déplacement ---
@export var speed : float = 0.25
var tile_size : float = 1.0
var is_moving : bool = false
@export var max_vies : int = 3
var vies : int = 3
var spawn_position : Vector3

# --- Références aux Nœuds ---
@onready var ray = $RayCast3D
@onready var model = $king
@export var bomb_stock : int = 5
@export var explosion_range : int = 1

# Valeurs initiales sauvegardées
var initial_bomb_stock: int = 0

# --- Scène de la Bombe ---
@export var bombe_scene : PackedScene = preload("res://bombe.tscn")

func _ready():
	vies = max_vies
	spawn_position = global_position
	# Sauvegarder le stock de bombs initial
	initial_bomb_stock = bomb_stock
	# ajouter le joueur au groupe 'player' pour détections globales
	add_to_group("player")
	
	# On attend la fin de la frame pour être sûr que le HUD est prêt
	await get_tree().process_frame
	actualiser_hud()

# --- Ajoutez ces variables au début de player.gd ---
var is_invulnerable : bool = false

func take_damage():
	# Sécurité 1 : Ne rien faire si déjà mort (US11)
	if vies <= 0:
		return
		
	# Sécurité 2 : Ne rien faire si invulnérable (évite les dégâts multiples)
	if is_invulnerable:
		return

	# Application des dégâts
	vies -= 1
	is_invulnerable = true # On devient invulnérable
	print("Aïe ! Vies restantes : ", vies)
	actualiser_hud()
	
	if vies <= 0:
		mourir()
	else:
		respawn()
		# On attend 1 seconde avant de redevenir vulnérable
		await get_tree().create_timer(1.0).timeout
		is_invulnerable = false

func respawn():
	# US12 : Réapparaître au départ
	is_moving = false
	global_position = spawn_position
	
	# --- RESET DE L'ORIENTATION ---
	# On remet la rotation du modèle à zéro
	model.quaternion = Quaternion.IDENTITY 
	# On applique le correctif de 180° que tu utilises pour ton modèle
	model.rotate_y(PI)

func mourir():
	# US11 : Fin de partie
	print("Game Over")
	# On peut appeler le HUD ici pour afficher l'écran de défaite
	get_parent().get_node("HUD").afficher_game_over()
func actualiser_hud():
	var hud = get_parent().get_node_or_null("HUD")
	if hud:
		hud.update_vies(vies)
		hud.update_bombes(bomb_stock) # Ajout de la mise à jour des bombes
func _physics_process(_delta):
	# Si le personnage est en train de se déplacer, on ignore les entrées
	if is_moving:
		return

	# Détection des directions
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("haut"): input_dir = Vector3.FORWARD
	elif Input.is_action_pressed("bas"): input_dir = Vector3.BACK
	elif Input.is_action_pressed("gauche"): input_dir = Vector3.LEFT
	elif Input.is_action_pressed("droite"): input_dir = Vector3.RIGHT

	# Si une touche est pressée, on lance le mouvement
	if input_dir != Vector3.ZERO:
		move_on_grid(input_dir)
		
	# Action de poser une bombe
	if Input.is_action_just_pressed("bombe"):
		drop_bomb()

func move_on_grid(direction: Vector3):
	# On règle la cible du RayCast pour vérifier les obstacles
	ray.target_position = direction * tile_size
	ray.force_raycast_update()
	
	# Oriente le modèle (le rig de Julian) vers la direction
	model.look_at(global_position + direction, Vector3.UP)
	# On ajoute 180 degrés (PI) pour compenser l'orientation initiale du modèle
	model.rotate_y(PI)

	# Si le RayCast ne touche rien, on avance
	if not ray.is_colliding():
		is_moving = true
		var target_pos = global_position + (direction * tile_size)
		
		# Création d'une transition fluide (Tween)
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_pos, speed)
		# Une fois arrivé, on autorise un nouveau mouvement
		tween.finished.connect(Callable(self, "_on_move_finished"))
		
func drop_bomb():
	# US05 : Vérifier si on a encore des bombes
	if bomb_stock <= 0:
		return

	bomb_stock -= 1
	actualiser_hud() # On met à jour l'affichage immédiatement
	
	var b = bombe_scene.instantiate()
	get_parent().add_child(b)
	# Transmettre la portée actuelle du joueur à la bombe
	if b.has_method("set_explosion_range"):
		b.set_explosion_range(explosion_range)
	
	var bomb_pos = Vector3(floor(global_position.x) + 0.5, 1.0, floor(global_position.z) + 0.5)
	b.global_position = bomb_pos
	
	# Optionnel : Récupérer la bombe après l'explosion (US17)
	# Vous pouvez connecter un signal ici ou gérer cela dans bombe.gd

func _on_move_finished():
	is_moving = false

func add_bomb_capacity(amount: int = 1):
	bomb_stock += amount
	actualiser_hud()

func increase_explosion_range(amount: int = 1):
	explosion_range += amount
	actualiser_hud()
