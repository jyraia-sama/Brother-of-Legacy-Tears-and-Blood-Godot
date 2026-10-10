class_name Deblocages
extends RefCounted
## DÉBLOCAGES : les modes de jeu et les places d'équipe s'ouvrent au fil de l'histoire,
## pour ne pas noyer un nouveau joueur sous tous les menus dès la première minute.
##
## Chaque mode s'ouvre quand un chapitre précis est TERMINÉ : [acte, chapitre].
## Les joueurs déjà avancés ont tout de suite ce qui correspond à leur progression.
## Pour changer le calendrier : modifie MODES et PLACES ci-dessous.

## id du bouton du menu -> [acte, chapitre à terminer]. Absent = ouvert dès le début.
const MODES := {
	"echos":      [1, 2],    # s'ouvre en arrivant au chapitre 3 de l'Acte I
	"fusion":     [1, 6],
	"reliquaire": [1, 6],
	"arene":      [2, 6],
	"donjon":     [2, 6],
	"boss_monde": [3, 6],
	"tours":      [3, 6],
	"guilde":     [3, 6],
	"expedition": [4, 6],
	"menagerie":  [4, 6],
}

## Noms et présentation affichés à l'ouverture d'un mode.
const PRESENTATIONS := {
	"echos": ["Échos Sanguins", "Les fragments de souvenirs que lâchent tes ennemis peuvent maintenant être portés par tes héros. Six emplacements par héros, des sets à compléter et des améliorations à tenter."],
	"fusion": ["Autel de Fusion", "Éveille tes héros avec leurs doubles, absorbe les unités en trop pour les faire grandir, et fais évoluer les plus puissants."],
	"reliquaire": ["Le Reliquaire", "Ton inventaire : ouvre tes coffres, bois tes élixirs de stamina, lis tes tomes d'XP. La Forge et l'Atelier y créent des héros exclusifs et des Échos choisis."],
	"arene": ["Arène", "Affronte les défenses des autres joueurs, grimpe dans le classement de la saison et défie tes amis en Arène classée."],
	"donjon": ["Donjons", "Six donjons élémentaires, des vagues de monstres et un boss : c'est là que se trouvent les ressources d'évolution."],
	"boss_monde": ["Boss de Monde", "Chaque jour un titan différent. Ton armée de 20 unités l'attaque pour lui arracher le plus de PV possible."],
	"tours": ["Tours infinies", "La Tour de l'Enfer et la Tour du Paradis : cent étages chacune, de plus en plus durs, remises à zéro chaque semaine."],
	"guilde": ["Guilde", "Rejoins ou crée une guilde : dons quotidiens, discussion, Boss de guilde, bénédictions et boutique de guilde."],
	"expedition": ["Expédition", "La Marche Maudite, une traversée périlleuse avec tes héros, et la Compagnie, qui part en mission pendant que tu joues ailleurs."],
	"menagerie": ["Ménagerie", "Tes héros N et R partent chasser avec des familiers et rapportent du butin, même jeu fermé."],
}

## Places d'équipe : 3 au début, puis [acte, chapitre à terminer] pour chaque place en plus.
const PLACES_DEPART := 3
const PLACES := [[1, 6], [3, 6]]


static func _fait(cond: Array) -> bool:
	return ActesData.est_termine(int(cond[0]), int(cond[1]))


## Le mode est-il ouvert ? (le menu Admin « tout débloquer » ouvre tout)
static func est_ouvert(id: String) -> bool:
	if not MODES.has(id) or Sauvegarde.admin("tout_debloque"):
		return true
	return _fait(MODES[id])


## « Se débloque à la fin de l'Acte II » / « … au chapitre 3 de l'Acte I ».
static func texte_condition(id: String) -> String:
	if not MODES.has(id):
		return ""
	return _texte(MODES[id])


static func _texte(cond: Array) -> String:
	var a := int(cond[0])
	var c := int(cond[1])
	var romain := str(ActesData.get_acte(a).get("romain", str(a)))
	if c >= 6:
		return UiCommun.t("Se débloque à la fin de l'Acte %s") % romain
	return UiCommun.t("Se débloque au chapitre %d de l'Acte %s") % [c + 1, romain]


## Nombre de places d'équipe ouvertes (3 à 5).
static func places_equipe() -> int:
	if Sauvegarde.admin("tout_debloque"):
		return Sauvegarde.TAILLE_EQUIPE_MAX
	var n := PLACES_DEPART
	for cond in PLACES:
		if _fait(cond):
			n += 1
	return mini(n, Sauvegarde.TAILLE_EQUIPE_MAX)


## Condition d'ouverture d'une place d'équipe (index 0 à 4), "" si elle est ouverte.
static func condition_place(place: int) -> String:
	if place < places_equipe():
		return ""
	var i := place - PLACES_DEPART
	if i < 0 or i >= PLACES.size():
		return ""
	return _texte(PLACES[i])


## Nouveautés pas encore annoncées au joueur : [{titre, texte}]. Les marque comme vues.
## Au premier appel (joueurs qui avaient déjà avancé), tout ce qui est déjà ouvert est
## marqué comme vu sans être annoncé.
static func nouveautes() -> Array:
	Sauvegarde.charger()
	var premier := not Sauvegarde.donnees.has("deblocages_vus")
	if premier or not Sauvegarde.donnees["deblocages_vus"] is Array:
		Sauvegarde.donnees["deblocages_vus"] = []
	var vus: Array = Sauvegarde.donnees["deblocages_vus"]
	var l: Array = []
	for id in MODES:
		if est_ouvert(id) and not id in vus:
			vus.append(id)
			if not premier:
				l.append({"titre": "Nouveau : " + PRESENTATIONS[id][0], "texte": PRESENTATIONS[id][1]})
	var cle := "places_%d" % places_equipe()
	if places_equipe() > PLACES_DEPART and not cle in vus:
		vus.append(cle)
		if not premier:
			l.append({"titre": "Nouvelle place d'équipe !", "texte": UiCommun.t("Un nouveau compagnon peut rejoindre ton équipe : tu peux maintenant aligner %d héros. Va dans Deck & Équipe pour l'y placer.") % places_equipe()})
	if premier or not l.is_empty():
		Sauvegarde.sauvegarder()
	return l
