extends Node
## POLICES : ajoute une police de symboles (DejaVu Sans, sous-ensemble) en secours de la
## police du jeu. Sans elle, les symboles ★ ⚔ ☠ ✦ ← → ✔… s'affichent en petits carrés
## sur certains ordinateurs et sur la version web (pas de polices du système dans le navigateur).
## Chargé automatiquement au démarrage (Projet > Paramètres > Autoload : « Polices »).

const SYMBOLES := "res://assets/polices/symboles.ttf"


func _init() -> void:
	var symboles := load(SYMBOLES) as Font
	if symboles == null:
		push_warning("Police de symboles introuvable : " + SYMBOLES)
		return
	var principale := ThemeDB.fallback_font
	if principale != null and not symboles in principale.fallbacks:
		var f := principale.fallbacks.duplicate()
		f.append(symboles)
		principale.fallbacks = f
