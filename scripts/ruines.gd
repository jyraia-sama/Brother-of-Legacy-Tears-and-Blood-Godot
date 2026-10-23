class_name Ruines
extends RefCounted
## LES RUINES OUBLIÉES (secret) — trois Légendes cachées, chacune gardée par un étage.
##
## Comment on y entre :
##  - trois FRAGMENTS DU SCEAU DE L'AUBE sont cachés dans l'histoire : la première case Mystère
##    ouverte dans l'Acte IV, l'Acte VIII et l'Acte XI en donne un (plateau.gd) ;
##  - dès le premier fragment, une stèle apparaît sur la carte du monde (au bord de la mer, à l'ouest) ;
##    avec les trois, elle s'illumine et ouvre les Ruines.
##
## Trois étages, dans l'ordre, chacun avec sa règle :
##  - « sève »  : 3 vagues d'affilée, les PV ne remontent pas entre les combats (endurance) ;
##  - « aube »  : le héros placé le plus en arrière porte la cloche d'Ombeline : les ennemis le visent
##                souvent, et s'il tombe le combat est perdu (protéger) ;
##  - « fosse » : l'obscurité réduit la précision de l'équipe ; au fond, l'Armure Creuse.
## Première victoire d'un étage : son groupe rejoint la collection + des gemmes.
## Ensuite : une fois par jour, des Cœurs (ressources d'évolution) ; sinon un peu d'or.
## La force des ennemis s'adapte à la puissance de l'équipe (comme le Sanctuaire) ; aucune stamina.
## Forces réglées par simulation (équipes réalistes des Actes VIII à XII) : environ 55-60 % de réussite par étage.

const SCENE := "res://scenes/ruines.tscn"
const FOND := "res://assets/combat3d/acte_06_fond.png"
const ACTES_FRAGMENTS := [4, 8, 11]
const ORDRE := ["seve", "aube", "fosse"]
const GEMMES := 300
const OR_REJEU := 1500
const COEURS_JOUR := 8           # Cœurs de l'élément du groupe, une fois par jour
const COEURS_SANG_JOUR := 4
const MALUS_OBSCURITE := 25.0    # précision perdue dans la Fosse

const ETAGES := {
	"seve": {
		"titre": "La Sève Rouge", "heros": "compagnie_seve", "element": "nature", "decor": "donjon_nature",
		"regle": "Endurance : 3 combats d'affilée, les PV ne remontent pas entre deux combats.",
		"vagues": [
			{"ennemis": ["loup_garou", "sanglier_sauvage", "araignee_venin"], "force": 0.84},
			{"ennemis": ["troll_marais", "loup_garou", "sorciere_bois"], "force": 1.0},
			{"ennemis": ["troll_marais", "sorciere_bois", "sanglier_sauvage", "loup_garou"], "force": 1.2, "boss": 0},
		],
		"intro": "Au premier étage, des racines rouges ont fendu les dalles. Trois silhouettes se tiennent au milieu, dos à dos, encerclées par les bêtes de la forêt.\n\nMaëlis : « Hé ! Toi, là ! Tu tombes bien. »\nVarn : « …On n'a besoin de personne. »\nYsolde : « Elles reviennent, Varn. Encore et encore. Aide-nous à tenir. »",
		"victoire": "La dernière bête s'enfuit dans les racines. Varn plante sa lame dans le sol et souffle enfin.\n\nVarn : « …Pas mal. »\nMaëlis, en riant : « Ça veut dire merci, chez lui. »\nYsolde : « La terre dit que ta route est longue. On vient avec toi. »",
		"titre_victoire": "LA COMPAGNIE DE LA SÈVE ROUGE REJOINT L'ÉQUIPE !",
		"defaite": "Les bêtes reviennent sans fin. Varn te tire en arrière : « Reviens quand tu tiendras plus longtemps. »",
	},
	"aube": {
		"titre": "Le Serment de l'Aube", "heros": "serment_aube", "element": "sacre", "decor": "donjon_sacre",
		"regle": "Protéger : ton héros le plus en arrière porte la cloche d'Ombeline. Les ennemis le visent souvent ; s'il tombe, le combat est perdu.",
		"vagues": [
			{"ennemis": ["gargouille", "exorciste_dechu", "banshee"], "force": 0.92},
			{"ennemis": ["seraphin_dechu", "exorciste_dechu", "gargouille", "spectre_glacial"], "force": 1.15, "boss": 0},
		],
		"intro": "Au deuxième étage, un sanctuaire en ruine. Une prêtresse aux cloches d'argent est enchaînée devant l'autel ; un jeune homme au bouclier se bat seul contre ceux qui la gardent.\n\nIlan ne dit rien. Il te lance une petite cloche d'argent.\nOmbeline : « Garde-la contre toi… Tant qu'elle sonne, ils ne peuvent pas m'emmener. Mais ils vont tout faire pour te la reprendre. »",
		"victoire": "Les chaînes tombent. Ombeline fait sonner toutes ses cloches à la fois, et la lumière de l'aube remplit les ruines.\n\nOmbeline : « Tu as protégé la cloche comme si c'était ta propre vie. »\nIlan pose son bouclier à tes pieds. Pour lui, c'est un serment.",
		"titre_victoire": "LE SERMENT DE L'AUBE REJOINT L'ÉQUIPE !",
		"defaite": "La cloche s'est tue. Ombeline, de loin : « Reviens… je t'attendrai. »",
	},
	"fosse": {
		"titre": "Les Oubliés de la Fosse", "heros": "oublies_fosse", "element": "tenebres", "decor": "donjon_tenebres",
		"regle": "Obscurité : l'équipe voit mal et perd de la précision. Au fond de la Fosse attend l'Armure Creuse.",
		"vagues": [
			{"ennemis": ["esprit_frappeur", "golem_pierre", "liche_mineure"], "force": 1.0},
			{"ennemis": ["chevalier_rouille_evo"], "force": 1.12, "boss": 0, "noms": {"chevalier_rouille_evo": "L'Armure Creuse"}},
		],
		"intro": "Le dernier étage descend dans le noir complet. Seule la lueur de la Larme éclaire tes pas.\n\nUne voix moqueuse tombe d'une poutre : « Tu cherches quelqu'un, toi aussi ? »\nUne chasseresse masquée se laisse glisser au bout d'une chaîne.\nRonce : « Moi, je cherche un petit chevalier. Il est descendu ici il y a très longtemps… et il n'est jamais remonté. »",
		"victoire": "L'Armure Creuse s'effondre dans un grand fracas. Dans le silence, quelque chose bouge sous le métal : deux petites lueurs bleues.\n\nRonce soulève le heaume géant. En dessous, tout petit, un chevalier dans une armure bien trop grande pour lui.\nRonce : « Je t'ai trouvé. Allez, on remonte. Et cette fois, on ne se perd plus. »",
		"titre_victoire": "LES OUBLIÉS DE LA FOSSE REJOIGNENT L'ÉQUIPE !",
		"defaite": "L'obscurité se referme. Ronce te remonte au bout de sa chaîne : « Pas encore. Reviens avec plus de lumière. »",
	},
}


static func _etat() -> Dictionary:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.get("ruines") is Dictionary:
		Sauvegarde.donnees["ruines"] = {}
	var e: Dictionary = Sauvegarde.donnees["ruines"]
	for k in ["fragments", "vaincus"]:
		if not e.get(k) is Array:
			e[k] = []
	if not e.get("jours") is Dictionary:
		e["jours"] = {}
	if not e.get("en_cours") is Dictionary:
		e["en_cours"] = {}
	return e


# ---------------------------------------------------------------------
# Fragments et accès
# ---------------------------------------------------------------------

static func nb_fragments() -> int:
	if Sauvegarde.admin("ruines_ouvertes"):
		return ACTES_FRAGMENTS.size()
	return (_etat()["fragments"] as Array).size()


static func a_fragment(acte: int) -> bool:
	return acte in _etat()["fragments"]


## Le plateau de cet Acte cache-t-il encore un fragment ?
static func fragment_a_trouver(acte: int) -> bool:
	return acte in ACTES_FRAGMENTS and not a_fragment(acte) and not Sauvegarde.admin("ruines_ouvertes")


static func donner_fragment(acte: int) -> void:
	var e := _etat()
	if not acte in e["fragments"]:
		e["fragments"].append(acte)
		Sauvegarde.sauvegarder()


static func stele_visible() -> bool:
	return nb_fragments() >= 1


static func ouvertes() -> bool:
	return nb_fragments() >= ACTES_FRAGMENTS.size()


static func est_vaincu(et: String) -> bool:
	return et in _etat()["vaincus"]


static func est_ouvert(et: String) -> bool:
	var i := ORDRE.find(et)
	return ouvertes() and (i == 0 or est_vaincu(ORDRE[i - 1]))


static func recompense_du_jour_dispo(et: String) -> bool:
	return int(_etat()["jours"].get(et, -1)) != Calendrier.jour_absolu()


# ---------------------------------------------------------------------
# Progression dans un étage (plusieurs vagues)
# ---------------------------------------------------------------------

## {"etage", "vague", "pv": {uid: ratio}} ou {} si aucun étage en cours.
static func en_cours() -> Dictionary:
	return _etat()["en_cours"]


static func commencer(et: String) -> void:
	_etat()["en_cours"] = {"etage": et, "vague": 0, "pv": {}}
	Sauvegarde.sauvegarder()


static func abandonner() -> void:
	_etat()["en_cours"] = {}
	Sauvegarde.sauvegarder()


static func nb_vagues(et: String) -> int:
	return (ETAGES[et]["vagues"] as Array).size()


## Équipe du joueur pour la vague en cours (PV gardés, cloche, obscurité).
static func equipe(et: String) -> Array:
	var eq := Sanctuaire.equipe_joueur()
	var pv: Dictionary = en_cours().get("pv", {})
	var porteur := -1
	if et == "aube":
		var place_max := -1
		for i in eq.size():
			if int(eq[i]["place"]) > place_max:
				place_max = int(eq[i]["place"])
				porteur = i
	var vivants: Array = []
	for i in eq.size():
		var e: Dictionary = eq[i]
		e["pv_ratio"] = float(pv.get(str(e["uid"]), 1.0))
		if e["pv_ratio"] <= 0.0:
			continue
		if i == porteur:
			e["prioritaire"] = true
			e["vital"] = true
		if et == "fosse":
			e["malus_preci"] = MALUS_OBSCURITE
		vivants.append(e)
	return vivants


## Héros qui porte la cloche (étage de l'Aube) : son uid, ou -1.
static func porteur_cloche(eq: Array) -> int:
	for e in eq:
		if e.get("vital", false):
			return int(e["uid"])
	return -1


static func generer(et: String, vague: int, eq: Array) -> Array:
	var v: Dictionary = ETAGES[et]["vagues"][vague]
	var total := 0.0
	var niv := 0.0
	for e in Sanctuaire.equipe_joueur():
		total += Sanctuaire.puissance_unite(e)
		niv += int(e["niveau"])
	var nb := maxi(1, Sanctuaire.equipe_joueur().size())
	var niveau := clampi(int(round(niv / nb)) + 1, 1, UnitesData.NIVEAU_MAX)
	var ids: Array = v["ennemis"]
	var noms: Dictionary = v.get("noms", {})
	var liste: Array = []
	for k in ids.size():
		var id: String = ids[k]
		var boss := int(v.get("boss", -1)) == k
		var poids := 1.6 if (boss and ids.size() > 1) else 1.0
		var somme := float(ids.size()) + (0.6 if v.has("boss") and ids.size() > 1 else 0.0)
		var cible := total * float(v["force"]) * poids / somme
		var base := Sanctuaire.puissance_unite({"id": id, "niveau": niveau})
		var e := {"id": id, "niveau": niveau, "mult": cible / maxf(1.0, base), "boss": boss,
			"nom": str(noms.get(id, UnitesData.get_unite(id)["nom"]))}
		liste.append(e)
	liste.sort_custom(func(a, b): return Rencontres._ordre_place(a["id"]) < Rencontres._ordre_place(b["id"]))
	for i in liste.size():
		liste[i]["place"] = i
	return liste


## Fin d'un combat. Renvoie {"lignes", "fini" (étage terminé), "titre"}.
static func apres_combat(victoire: bool, eq: Array, pv_final: Array) -> Dictionary:
	var c := en_cours()
	var et: String = c.get("etage", "")
	var r := {"lignes": [], "fini": false, "titre": ""}
	if et == "":
		return r
	var info: Dictionary = ETAGES[et]
	if not victoire:
		r["lignes"].append(info["defaite"])
		abandonner()
		return r
	for i in mini(eq.size(), pv_final.size()):
		if eq[i].has("uid"):
			c["pv"][str(eq[i]["uid"])] = maxf(0.0, float(pv_final[i]))
	c["vague"] = int(c["vague"]) + 1
	if int(c["vague"]) < nb_vagues(et):
		r["lignes"].append(UiCommun.t("Vague %d / %d repoussée ! La suivante arrive…") % [int(c["vague"]), nb_vagues(et)])
		Sauvegarde.sauvegarder()
		return r
	r["fini"] = true
	var premiere := not est_vaincu(et)
	r["lignes"].append_array(valider(et))
	r["titre"] = info["titre_victoire"] if premiere else "ÉTAGE TERMINÉ !"
	abandonner()
	return r


static func valider(et: String) -> Array:
	var e := _etat()
	var info: Dictionary = ETAGES[et]
	var l: Array = []
	if not et in e["vaincus"]:
		e["vaincus"].append(et)
		var id: String = info["heros"]
		Sauvegarde.ajouter_heros(id)
		Sauvegarde.decouvrir(id)
		l.append(UiCommun.t("%s rejoint ta collection (Légende cachée) !") % UnitesData.get_unite(id)["nom"])
		Sauvegarde.ajouter_gemmes(GEMMES)
		l.append(UiCommun.t("Gemmes : +%d") % GEMMES)
		e["jours"][et] = Calendrier.jour_absolu()
	elif recompense_du_jour_dispo(et):
		e["jours"][et] = Calendrier.jour_absolu()
		var r_el := Evolution.ressource(str(info["element"]), "coeur")
		var r_sang := Evolution.ressource("neutre", "coeur")
		Sauvegarde.ajouter_objet(r_el, COEURS_JOUR)
		Sauvegarde.ajouter_objet(r_sang, COEURS_SANG_JOUR)
		l.append(UiCommun.t("Récompense du jour : %s x%d, %s x%d") % [Reliquaire.nom(r_el), COEURS_JOUR, Reliquaire.nom(r_sang), COEURS_SANG_JOUR])
	else:
		Sauvegarde.ajouter_or(OR_REJEU)
		l.append(UiCommun.t("Or : +%d  (récompense du jour déjà prise)") % OR_REJEU)
	Sauvegarde.sauvegarder()
	return l
