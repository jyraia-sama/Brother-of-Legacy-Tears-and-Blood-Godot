class_name Mecaniques
extends RefCounted
## MÉCANIQUES DES DONJONS (v0.67) : chaque boss, chaque mini-boss et chaque nouveau monstre
## de Donjon a une mécanique à contrer (le moteur les applique : combat_moteur.gd, « Mécaniques »).
##
##  - Boss et mini-boss : mécanique à partir du niveau NIVEAU_DEBUT du Donjon,
##    RENFORCÉE (force 2) à partir du niveau NIVEAU_RENFORCE.
##  - Nouveaux monstres : leur mécanique est toujours active (force 1).
##  - Quand le boss a sa mécanique, il entre en combat avec 2 GARDES (le monstre du Donjon).
##
## Chaque mécanique : nom, texte (ce qu'elle fait), conseil, et les « contres » qui servent à
## trouver les héros utiles du joueur (voir utiles()).

const NIVEAU_DEBUT := 4
const NIVEAU_RENFORCE := 8

## Donjon -> mécanique du boss / du mini-boss / monstre du Donjon (gardes du boss).
const BOSS := {"feu": "fournaise", "nature": "seve_eternelle", "eau": "carapace", "tenebres": "marque",
	"sacre": "jugement", "neutre": "frenesie", "savoir": "phylactere"}
const MINI := {"feu": "forge_ardente", "nature": "remede_sylvestre", "eau": "carapace_corail", "tenebres": "chaines",
	"sacre": "priere", "neutre": "faim", "savoir": "lien_ame"}
const GARDES := {"feu": "salamandre_lave", "nature": "racine_nourriciere", "eau": "crabe_bouclier",
	"tenebres": "lanterne_noire", "sacre": "acolyte_profane", "neutre": "molosse_puits", "savoir": "page_animee"}

## Contres possibles (clés de _tags) :
##   brulure, poison, purification, controle (étourdir / geler / silence), silence, zone, multi,
##   bouclier, epines, provocation, debuff_atk, brise (DEF -), malediction, execution,
##   immunite_brulure, immunite_malediction, soin
const INFOS := {
	# --- Boss ---
	"fournaise": {"nom": "Fournaise", "type": "boss",
		"texte": "Chaque tour où un héros reste brûlé, sa Brûlure s'aggrave. Tous les 4 tours, ÉRUPTION : de gros dégâts sur toute l'équipe.",
		"conseil": "Purifie les brûlures, aligne des héros immunisés à la Brûlure et des boucliers pour l'Éruption. L'Eau est forte contre le Feu.",
		"contres": ["purification", "immunite_brulure", "bouclier", "soin"]},
	"seve_eternelle": {"nom": "Sève Éternelle", "type": "boss",
		"texte": "Régénère une grosse part de ses PV à chaque tour et soigne ses gardes. Brûlée, elle ne récupère que la moitié.",
		"conseil": "Garde-la sous Brûlure (le Feu est fort contre la Nature) ou abats-la très vite avec de l'exécution. Tue les Racines Nourricières en premier.",
		"contres": ["brulure", "execution", "zone"]},
	"carapace": {"nom": "Carapace des Abysses", "type": "boss",
		"texte": "Une carapace réduit de 80 % les dégâts reçus. Elle se brise après 18 coups, puis se reforme au tour suivant.",
		"conseil": "Frappe souvent : attaques multiples et sorts de zone brisent la carapace. Le Poison l'ignore (la Nature est forte contre l'Eau).",
		"contres": ["multi", "zone", "poison", "brise", "malediction"]},
	"marque": {"nom": "Marque du Trépas", "type": "boss",
		"texte": "Tous les 2 tours, marque un héros. Si la marque n'est pas retirée dans les 2 tours, le héros tombe K.O.",
		"conseil": "Une Purification retire la marque. Les héros immunisés à la Malédiction ne peuvent pas être marqués. Le Sacré est fort contre elle.",
		"contres": ["purification", "immunite_malediction"]},
	"jugement": {"nom": "Jugement", "type": "boss",
		"texte": "Tous les 3 tours, entre en incantation. S'il n'est pas interrompu, il soigne tout son camp et frappe très fort toute l'équipe.",
		"conseil": "Étourdis-le, gèle-le ou réduis-le au silence pendant l'incantation. En combat manuel, garde ton contrôle pour ce moment.",
		"contres": ["controle", "silence"]},
	"frenesie": {"nom": "Frénésie Sanglante", "type": "boss",
		"texte": "Gagne de l'ATK à chaque tour et s'acharne sur le héros le plus blessé.",
		"conseil": "Un tank qui provoque attire ses coups ; les Épines le blessent quand il frappe. Baisse son ATK, et fais vite.",
		"contres": ["provocation", "epines", "debuff_atk", "bouclier"]},
	"phylactere": {"nom": "Phylactère", "type": "boss",
		"texte": "Tant qu'un de ses gardes est debout, elle subit 50 % de dégâts en moins et ne peut pas tomber sous 1 PV. Ranime un garde tombé tous les 2 tours.",
		"conseil": "Tue les gardes ensemble avec des sorts de zone. Le Silence l'empêche de ranimer.",
		"contres": ["zone", "silence", "brulure"]},
	# --- Mini-boss ---
	"forge_ardente": {"nom": "Forge Ardente", "type": "mini",
		"texte": "Ses Brûlures s'aggravent à chaque tour tant qu'elles ne sont pas purifiées.",
		"conseil": "Une Purification ou une immunité à la Brûlure suffit.", "contres": ["purification", "immunite_brulure"]},
	"remede_sylvestre": {"nom": "Remède Sylvestre", "type": "mini",
		"texte": "Se soigne à chaque tour, sauf si elle est brûlée.",
		"conseil": "Brûle-la !", "contres": ["brulure", "execution"]},
	"carapace_corail": {"nom": "Carapace de Corail", "type": "mini",
		"texte": "Réduit de 60 % les dégâts reçus jusqu'à ce qu'elle encaisse 6 coups ; se reforme au tour suivant.",
		"conseil": "Multiplie les coups ; le Poison passe à travers.", "contres": ["multi", "zone", "poison"]},
	"chaines": {"nom": "Chaînes", "type": "mini",
		"texte": "Tous les 3 tours, enchaîne un héros : il ne peut plus agir pendant 2 tours.",
		"conseil": "Une Purification libère le héros enchaîné.", "contres": ["purification"]},
	"priere": {"nom": "Prière", "type": "mini",
		"texte": "Incantation de 2 tours : si elle aboutit, un gros bouclier protège tout son camp.",
		"conseil": "Interromps-le : étourdir, geler ou réduire au silence.", "contres": ["controle", "silence"]},
	"faim": {"nom": "Faim", "type": "mini",
		"texte": "Gagne de l'ATK à chaque tour.",
		"conseil": "Va vite, et protège-toi avec des tanks à Épines.", "contres": ["epines", "provocation", "debuff_atk"]},
	"lien_ame": {"nom": "Lien d'Âme", "type": "mini",
		"texte": "Ne peut pas tomber sous 1 PV tant qu'un de ses gardes est debout.",
		"conseil": "Abats d'abord les gardes.", "contres": ["zone"]},
	# --- Monstres ---
	"salamandre": {"nom": "Brûlure Vive", "type": "monstre", "texte": "Ses Brûlures s'aggravent à chaque tour.",
		"conseil": "Purifie ou immunise.", "contres": ["purification", "immunite_brulure"]},
	"racine": {"nom": "Sève Nourricière", "type": "monstre", "texte": "Soigne tous ses alliés à chaque tour.",
		"conseil": "Abats-la en premier.", "contres": ["zone", "brulure"]},
	"crabe": {"nom": "Petite Carapace", "type": "monstre", "texte": "Réduit de 50 % les dégâts reçus jusqu'à encaisser 3 coups.",
		"conseil": "Frappe-le plusieurs fois.", "contres": ["multi", "zone", "poison"]},
	"lanterne": {"nom": "Marque Faible", "type": "monstre",
		"texte": "Tous les 3 tours, marque un héros : à la fin de la marque, il perd 35 % de ses PV.",
		"conseil": "Purifie la marque ou abats la Lanterne.", "contres": ["purification", "immunite_malediction"]},
	"acolyte": {"nom": "Soin Incanté", "type": "monstre",
		"texte": "Incantation de 2 tours qui soigne tout son camp, sauf si on l'interrompt.",
		"conseil": "Étourdis-le ou tue-le avant la fin.", "contres": ["controle", "silence"]},
	"molosse": {"nom": "Frénésie", "type": "monstre", "texte": "Gagne de l'ATK à chaque tour.",
		"conseil": "Abats-le vite.", "contres": ["epines", "provocation"]},
	"page": {"nom": "Pages Volantes", "type": "monstre",
		"texte": "Revient une fois à la vie, sauf si elle tombe sous un sort de zone.",
		"conseil": "Achève-la avec un sort de zone.", "contres": ["zone"]},
}

const NOMS_CONTRES := {"brulure": "Brûlure", "poison": "Poison", "purification": "Purification",
	"controle": "Contrôle", "silence": "Silence", "zone": "Sorts de zone", "multi": "Coups multiples",
	"bouclier": "Boucliers", "epines": "Épines", "provocation": "Provocation", "debuff_atk": "Baisse d'ATK",
	"brise": "Brise-armure", "malediction": "Malédiction", "execution": "Exécution",
	"immunite_brulure": "Immunité Brûlure", "immunite_malediction": "Immunité Malédiction", "soin": "Soins"}


static func infos(meca: String) -> Dictionary:
	return INFOS.get(meca, {})


## Force de la mécanique d'un boss / mini-boss à ce niveau de Donjon (0 = pas de mécanique).
static var desactive_test := false     # outils de calibrage : Donjons sans mécanique

static func force(niveau: int) -> int:
	if desactive_test:
		return 0
	if niveau >= NIVEAU_RENFORCE:
		return 2
	return 1 if niveau >= NIVEAU_DEBUT else 0


static func boss(donjon: String) -> String:
	return str(BOSS.get(donjon, ""))


static func mini(donjon: String) -> String:
	return str(MINI.get(donjon, ""))


static func garde(donjon: String) -> String:
	return str(GARDES.get(donjon, ""))


# ---------------------------------------------------------------------
# Héros utiles
# ---------------------------------------------------------------------

static var _cache_tags := {}


## Ce que sait faire une unité (selon ses sorts appris jusqu'au niveau `niveau`).
static func tags(id: String, niveau := 99) -> Dictionary:
	var cle := "%s-%d" % [id, niveau]
	if _cache_tags.has(cle):
		return _cache_tags[cle]
	var t := {}
	for sk in UnitesData.get_unite(id).get("skills", []):
		if int(sk["niveau"]) > niveau:
			continue
		var cible := str(sk.get("cible", ""))
		var degats := false
		for e in sk.get("effets", []):
			match str(e["effet"]):
				"affliction":
					var n := str(e["nom"])
					if n in ["brulure", "poison", "malediction", "silence"]:
						t[n] = true
					if n in ["etourdi", "gel", "silence"]:
						t["controle"] = true
				"purification": t["purification"] = true
				"bouclier": t["bouclier"] = true
				"epines": t["epines"] = true
				"provocation": t["provocation"] = true
				"execution": t["execution"] = true
				"double_attaque": t["multi"] = true
				"soin":
					if cible in ["allies", "allie_faible"]:
						t["soin"] = true
				"debuff":
					if str(e.get("stat", "")) == "atk":
						t["debuff_atk"] = true
					elif str(e.get("stat", "")) == "def":
						t["brise"] = true
				"immunite":
					for a in e.get("afflictions", []):
						if a in ["brulure", "malediction"]:
							t["immunite_" + str(a)] = true
				"degats":
					degats = true
					if int(e.get("coups", 1)) > 1:
						t["multi"] = true
		if degats and cible in ["ennemis", "avant", "arriere"]:
			t["zone"] = true
	_cache_tags[cle] = t
	return t


## Héros de la collection du joueur utiles contre cette mécanique :
## [{uid, id, nom, niveau, raisons: [noms des contres], element: bool (fort contre le donjon)}],
## les plus utiles d'abord (plus de contres, puis niveau).
static func utiles(meca: String, element_donjon := "") -> Array:
	var contres: Array = infos(meca).get("contres", [])
	var l: Array = []
	for h in Sauvegarde.liste_heros():
		var t := tags(str(h["id"]), Fusion.niveau_record(h))
		var raisons: Array = []
		for c in contres:
			if t.has(c):
				raisons.append(NOMS_CONTRES.get(c, c))
		var u := UnitesData.get_unite(h["id"])
		var fort: bool = element_donjon != "" and CombatMoteur.FORT_CONTRE.get(str(u.get("element", "")), "") == element_donjon
		if raisons.is_empty():
			continue
		l.append({"uid": int(h["uid"]), "id": str(h["id"]), "nom": str(u["nom"]), "niveau": int(h["niveau"]),
			"raisons": raisons, "element": fort})
	l.sort_custom(func(a, b):
		if a["raisons"].size() != b["raisons"].size():
			return a["raisons"].size() > b["raisons"].size()
		return a["niveau"] > b["niveau"])
	return l
