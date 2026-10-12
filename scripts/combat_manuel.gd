class_name CombatManuel
extends Node
## COMBAT MANUEL contre l'ordinateur (Aventure, Tours, Donjons, Marche Maudite, Sanctuaire).
## Ajouté par l'écran de combat quand le joueur a choisi « Manuel » (choix mémorisé).
##
## À chaque tour d'une de MES unités, la barre d'icônes attend mon choix (sans minuteur) ;
## les ennemis jouent seuls (meilleur sort disponible, sinon attaque).
## Bouton « Auto » pendant le combat : mes unités jouent seules jusqu'à ce que je repasse en manuel.
## « Passer » : le reste du combat se joue en automatique, sans animation.
## À la fin, le résultat est transmis à l'écran de combat comme un combat automatique.

var ecran: EcranCombat
var moteur: CombatMoteur
var _barre: BarreActions
var _passe := false


func _ready() -> void:
	_barre = BarreActions.new(ecran)
	ecran.add_child(_barre)
	moteur.demarrer_manuel()
	_boucle()


## Le joueur repasse en automatique pendant que la barre attend.
func auto_maintenant() -> void:
	_barre.forcer_auto()


func passer() -> void:
	_passe = true
	_barre.forcer_auto()


func _boucle() -> void:
	await _jouer_evenements()
	while true:
		var c := moteur.prochain_acteur()
		await _jouer_evenements()
		if c.is_empty():
			break
		var action := {"type": "auto"}
		if int(c["camp"]) == 0 and ecran.manuel_actif() and not _passe:
			action = await _barre.choisir(c, moteur.actions_possibles(c))
			if action.is_empty():
				action = {"type": "auto"}
		moteur.jouer_action(c, action)
		await _jouer_evenements()
	ecran._res = moteur._resultat()
	await _jouer_evenements()
	_barre.fermer()
	ecran._fin()


func _jouer_evenements() -> void:
	for ev in moteur.nouveaux_evenements():
		if ecran._passer:
			ecran._appliquer_sans_animation(ev)
		else:
			await ecran._jouer(ev)
