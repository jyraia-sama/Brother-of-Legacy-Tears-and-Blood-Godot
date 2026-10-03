class_name Sanctuaire
extends RefCounted
## LE SANCTUAIRE DU BÉLIER (secret) — la famille du créateur du jeu, tous les trois nés sous le signe du Bélier.
##
## Accès secret : toucher 3 fois de suite le blason au centre de la barre du haut du menu principal
## (ou taper B-E-L-I-E-R au clavier sur le menu).
##
## Quatre épreuves, dans l'ordre : Alysse, puis Loucas, puis Anaïs, puis les trois réunis.
## - La difficulté s'adapte à TON ÉQUIPE (sa puissance réelle : niveaux, étoiles, Échos) : le Sanctuaire
##   se joue à n'importe quel moment de l'aventure.
## - Première victoire : le membre de la famille rejoint ta collection (héros UR non invocable),
##   plus des gemmes ; l'épreuve finale donne un titre, des gemmes et un Coffre Royal.
## - Les épreuves restent rejouables (un peu d'or), sans stamina.

const SCENE := "res://scenes/sanctuaire.tscn"
const FOND := "res://assets/sanctuaire/fond.png"
const ORDRE := ["alysse", "loucas", "anais", "famille"]
const TITRE_FINAL := "Cœur du Bélier"
const OR_REJEU := 2000

## force : puissance de la famille par rapport à celle de ton équipe (réglée par simulation avec
## outils/calibrer_sanctuaire.gd : environ 70 %, 60 %, 55 % et 45 % de victoires pour une équipe moyenne).
const EPREUVES := {
	"alysse": {
		"titre": "Alysse, l'Étoile du Bélier", "boss": ["alysse_etoile"], "force": 0.65,
		"gemmes": 150,
		"intro": "Une pluie d'étoiles tombe sur le Sanctuaire. Une jeune fille agile se pose sur une corne de pierre, le sourire en coin.\n\n« Alors c'est toi qui veux entrer chez le Bélier ? Il faudra d'abord m'attraper… et je suis la plus rapide de la famille ! »",
		"victoire": "Alysse éclate de rire et retombe sur ses pieds.\n« D'accord, d'accord, tu as gagné… Mais je viens avec toi ! Mon frère, lui, ne va pas te laisser passer aussi facilement. »",
		"titre_victoire": "ALYSSE REJOINT L'ÉQUIPE !",
		"defaite": "Alysse file entre les étoiles en riant : « Trop lent ! Reviens quand tu seras prêt. »",
	},
	"loucas": {
		"titre": "Loucas, le Bélier Ardent", "boss": ["loucas_belier"], "force": 0.72,
		"gemmes": 200,
		"intro": "Le sol tremble. Un garçon aux cornes de braise frappe trois fois du pied, comme un bélier avant la charge.\n\n« Ma sœur t'a laissé passer ? Pas moi. Personne ne bat Loucas… enfin, presque personne. En garde ! »",
		"victoire": "Loucas se relève en se frottant la tête.\n« Aïe… Tu cognes fort ! OK, tu as le droit de voir Maman. Mais je te préviens : elle, c'est la cheffe. »",
		"titre_victoire": "LOUCAS REJOINT L'ÉQUIPE !",
		"defaite": "Loucas croise les bras, fier comme un bélier : « Je t'avais dit que j'étais le plus fort ! »",
	},
	"anais": {
		"titre": "Anaïs, Reine de la Toison d'Or", "boss": ["anais_toison"], "force": 0.91,
		"gemmes": 250,
		"intro": "Au cœur du Sanctuaire, une femme vêtue de la Toison d'Or veille sur le foyer. Sa lumière est douce… et redoutable.\n\n« Tu as battu mes deux enfants. Impressionnant. Mais une mère ne s'incline pas si facilement. Montre-moi que ton cœur est digne du Bélier. »",
		"victoire": "La Toison d'Or s'apaise. Anaïs pose la main sur ton épaule.\n« Tu as du courage, et du cœur. Je veillerai sur toi aussi. »\n\nAu fond du Sanctuaire, une porte d'or s'entrouvre : les trois Béliers t'attendent ensemble…",
		"titre_victoire": "ANAÏS REJOINT L'ÉQUIPE !",
		"defaite": "Anaïs sourit doucement : « Repose-toi, et reviens. Le foyer t'attendra. »",
	},
	"famille": {
		"titre": "La Famille du Bélier", "boss": ["loucas_belier", "alysse_etoile", "anais_toison"], "force": 0.81,
		"gemmes": 500,
		"intro": "Les trois Béliers se tiennent côte à côte, plus forts ensemble que jamais.\n\nAlysse : « Cette fois, on joue en équipe ! »\nLoucas : « Trois contre… euh… ton équipe. C'est équitable. »\nAnaïs : « Quand la famille est unie, rien ne lui résiste. Prouve-nous le contraire ! »",
		"victoire": "Les trois Béliers baissent les armes et éclatent de rire ensemble.\n\nAnaïs : « Tu fais partie de la famille, maintenant. »\nLoucas : « Mais la prochaine fois, je gagne ! »\nAlysse : « Moi aussi ! »",
		"titre_victoire": "LA FAMILLE DU BÉLIER EST VAINCUE !",
		"defaite": "Alysse, Loucas et Anaïs, main dans la main : « Ensemble, on est imbattables ! Reviens nous défier. »",
	},
}


static func _etat() -> Dictionary:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.get("sanctuaire") is Dictionary:
		Sauvegarde.donnees["sanctuaire"] = {"vaincus": []}
	return Sauvegarde.donnees["sanctuaire"]


static func est_vaincue(ep: String) -> bool:
	return ep in _etat()["vaincus"]


## Une épreuve s'ouvre quand la précédente est vaincue.
static func est_ouverte(ep: String) -> bool:
	var i := ORDRE.find(ep)
	return i == 0 or est_vaincue(ORDRE[i - 1])


# ---------------------------------------------------------------------
# Difficulté : adaptée à la puissance réelle de l'équipe
# ---------------------------------------------------------------------

## Puissance d'une unité telle qu'elle combat (niveau, étoiles, Échos).
static func puissance_unite(e: Dictionary) -> float:
	var s := UnitesData.stats(e["id"], int(e.get("niveau", 1)))
	if e.has("etoiles"):
		s = Fusion.appliquer_etoiles(s, int(e["etoiles"]))
	if e.get("echos", {}) is Dictionary and not (e.get("echos", {}) as Dictionary).is_empty():
		s = Echos.appliquer(s, e["echos"])
	return s["pv"] * 0.25 + s["atk"] + s["def"] * 0.8 + s["agi"] * 0.5 + s["mag"] * 0.7


static func equipe_joueur() -> Array:
	var equipe: Array = []
	for uid in Sauvegarde.get_equipe():
		var h := Sauvegarde.get_heros(uid)
		if h.is_empty():
			continue
		equipe.append({"id": h["id"], "niveau": int(h["niveau"]), "uid": uid, "place": Sauvegarde.place_de(uid),
			"etoiles": Fusion.etoiles(h), "echos": Sauvegarde.bonus_echos(uid)})
	return equipe


## Ennemis d'une épreuve pour cette équipe.
static func generer(ep: String, equipe: Array) -> Array:
	var info: Dictionary = EPREUVES[ep]
	var total := 0.0
	var niv := 0.0
	for e in equipe:
		total += puissance_unite(e)
		niv += int(e["niveau"])
	var niveau := clampi(int(round(niv / maxf(1, equipe.size()))) + 2, 1, UnitesData.NIVEAU_MAX)
	var boss: Array = info["boss"]
	var force: float = float(calibrage_test.get(ep, info["force"]))
	var cible := total * force / boss.size()
	var liste: Array = []
	for id in boss:
		var base := puissance_unite({"id": id, "niveau": niveau})
		liste.append({"id": id, "niveau": niveau, "mult": cible / maxf(1.0, base), "boss": true,
			"nom": UnitesData.get_unite(id)["nom"]})
	liste.sort_custom(func(a, b): return Rencontres._ordre_place(a["id"]) < Rencontres._ordre_place(b["id"]))
	for i in liste.size():
		liste[i]["place"] = i
	return liste

## Réservé aux tests d'équilibrage (laisser vide).
static var calibrage_test := {}


## XP de chaque héros après une victoire.
static func xp(niveau_heros: int) -> int:
	return int(Sauvegarde.xp_heros_pour_niveau(niveau_heros) * 0.6)


# ---------------------------------------------------------------------
# Récompenses
# ---------------------------------------------------------------------

## Applique la victoire. Renvoie les lignes à afficher.
static func valider_victoire(ep: String) -> Array:
	var e := _etat()
	var info: Dictionary = EPREUVES[ep]
	var l: Array = []
	if ep in e["vaincus"]:
		Sauvegarde.ajouter_or(OR_REJEU)
		l.append("Or : +%d" % OR_REJEU)
		return l
	e["vaincus"].append(ep)
	if ep == "famille":
		Succes.ajouter_titre(TITRE_FINAL)
		l.append("Nouveau titre : « %s »" % TITRE_FINAL)
		Sauvegarde.ajouter_objet("coffre_royal", 1)
		l.append("Coffre Royal x1")
	else:
		var id: String = info["boss"][0]
		Sauvegarde.ajouter_heros(id)
		Sauvegarde.decouvrir(id)
		l.append("%s rejoint ta collection (héros UR) !" % UnitesData.get_unite(id)["nom"])
	Sauvegarde.ajouter_gemmes(int(info["gemmes"]))
	l.append("Gemmes : +%d" % int(info["gemmes"]))
	Sauvegarde.sauvegarder()
	return l
