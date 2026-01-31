# Bomberman
Jeu type Bomberman développé avec Godot.

**Présentation**
- **Projet**: Jeu d'explosion et de stratégie en grille inspiré de Bomberman.
- **Moteur**: Godot (ouvrir le fichier project.godot pour charger le projet).

**Prérequis**
- Godot Engine installé sur votre machine.

**Démarrage rapide**
- Ouvrir le projet dans Godot en sélectionnant le dossier contenant project.godot.
- Ouvrir la scène principale: [bomberman/main.tscn](bomberman/main.tscn).
- Lancer la scène depuis l'éditeur (bouton Play).

**Commandes (actions d'entrée)**
- Haut : action "haut"
- Bas : action "bas"
- Gauche : action "gauche"
- Droite : action "droite"
- Poser une bombe : action "bombe"

**Structure du projet (repères)**
- Scènes et scripts principaux: [bomberman/player.gd](bomberman/player.gd), [bomberman/bombe.gd](bomberman/bombe.gd), [bomberman/ennemi.gd](bomberman/ennemi.gd), [bomberman/grid_map.gd](bomberman/grid_map.gd), [bomberman/hud.gd](bomberman/hud.gd).
- Scène principale: [bomberman/main.tscn](bomberman/main.tscn).
- Ressources graphiques et autres: dossier [bomberman/assets/](bomberman/assets/).
- Configuration d'export: [bomberman/export_presets.cfg](bomberman/export_presets.cfg).

**Fonctionnalités connues**
- Déplacement sur grille avec interpolation fluide.
- Poser des bombes et gérer leur portée.
- Système de vies, réapparition et HUD.
