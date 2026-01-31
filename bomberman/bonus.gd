extends Area3D

enum Type { BOMBE_PLUS, PORTEE_PLUS }
@export var type_bonus: Type = Type.BOMBE_PLUS

func _ready():
	# On connecte le signal quand le joueur touche le bonus
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# On supporte l'appel par le nœud Player (ou par le script player.gd)
	if body and body.is_in_group("player"):
		if type_bonus == Type.BOMBE_PLUS:
			if body.has_method("add_bomb_capacity"):
				body.add_bomb_capacity(1)
		elif type_bonus == Type.PORTEE_PLUS:
			if body.has_method("increase_explosion_range"):
				body.increase_explosion_range(1)

		queue_free() # Le bonus disparaît
