class_name Marche
extends RefCounted
## LA MARCHE MAUDITE : l'expédition roguelike du jour (règles, sans interface).
##
##  - UNE marche par jour, la même carte pour tous les joueurs (classement du jour en ligne).
##  - On choisit 5 unités, puis on traverse 3 RÉGIONS (tirées des Actes) sur une carte à
##    embranchements : combats, élites, événements, feux de camp, marchands, trésors, autels.
##  - Les PV et les K.O. sont conservés toute la marche.
##  - Après chaque victoire : 1 BÉNÉDICTION au choix parmi 3 (bonus jusqu'à la fin de la marche).
##  - Aux autels : les PACTES DE SANG (une malédiction contre une grosse récompense et plus de gloire).
##  - Après une élite, elle propose parfois de REJOINDRE l'équipe pour la marche.
##  - Score final -> Sceaux de Marche (boutique des Expéditions) + classement du jour.
##
## La force des ennemis suit la puissance de l'équipe choisie au départ : ce sont les choix
## de route, de bénédictions et de pactes qui font le score.

const SCENE := "res://scenes/marche.tscn"
const REGIONS := 3
const LIGNES := 7            # 6 lignes + la ligne du boss
const TAILLE_EQUIPE := 5
## Plafond de score accepté par le serveur (voir supabase/03_marche.sql)
const SCORE_MAX := 5000

## Réglage de la difficulté (réglé par simulation, voir outils/calibrer_marche.gd).
const DIFFICULTE := 1.2
const FORCE := {"combat": 0.55, "elite": 0.6, "boss": 0.45}
## Réservé aux simulations (laisser vide).
static var force_test := {}
const PENTE_LIGNE := 0.045
const PENTE_REGION := 0.2

const TYPES := {
	"combat": {"nom": "Combat", "icone": "⚔"},
	"elite": {"nom": "Élite", "icone": "☠"},
	"boss": {"nom": "Boss", "icone": "♛"},
	"evenement": {"nom": "Événement", "icone": "?"},
	"feu": {"nom": "Feu de camp", "icone": "✧"},
	"marchand": {"nom": "Marchand", "icone": "$"},
	"tresor": {"nom": "Trésor", "icone": "◆"},
	"autel": {"nom": "Autel de Sang", "icone": "✚"},
}
## Chances de chaque type de case (lignes 1 à 4 ; la ligne 0 = combats, la ligne 5 = feu de camp)
const POIDS_TYPES := {"combat": 42, "elite": 13, "evenement": 18, "marchand": 8, "tresor": 7, "autel": 12}

const SCORE := {"combat": 10, "elite": 30, "boss": 80, "case": 3, "vivant": 15, "fin": 150}


# =====================================================================
# BÉNÉDICTIONS (bonus jusqu'à la fin de la marche)
# =====================================================================
## stats : multiplicateurs de stats ; passifs : bonus de combat ; filtre : element / roles ;
## instant : effet immédiat (soin, resurrection, or) ; gloire : bonus de score ; or_bonus : +% d'or de marche.
const BENEDICTIONS := {
	# --- Communes ---
	"lame": {"nom": "Lame Aiguisée", "rarete": "commune", "desc": "ATK +12 % pour toute l'équipe.", "stats": {"atk": 1.12}},
	"roc": {"nom": "Peau de Roc", "rarete": "commune", "desc": "DEF +15 % pour toute l'équipe.", "stats": {"def": 1.15}},
	"vigueur": {"nom": "Vigueur", "rarete": "commune", "desc": "PV max +12 % pour toute l'équipe.", "stats": {"pv": 1.12}},
	"vivacite": {"nom": "Vivacité", "rarete": "commune", "desc": "AGI +12 % pour toute l'équipe.", "stats": {"agi": 1.12}},
	"arcanes": {"nom": "Arcanes Anciennes", "rarete": "commune", "desc": "MAG +15 % pour toute l'équipe.", "stats": {"mag": 1.15}},
	"premiers_soins": {"nom": "Premiers Soins", "rarete": "commune", "desc": "Soigne tout de suite l'équipe de 25 % des PV max.", "instant": {"soin": 0.25}},
	"soif": {"nom": "Soif Écarlate", "rarete": "commune", "desc": "Vol de vie +6 % pour toute l'équipe.", "passifs": {"vol_vie": 0.06}},
	"ronces": {"nom": "Armure de Ronces", "rarete": "commune", "desc": "Renvoie 10 % des dégâts physiques reçus.", "passifs": {"epines": 0.10}},
	"rempart": {"nom": "Rempart", "rarete": "commune", "desc": "Tanks et Guerriers : DEF +20 %, PV +10 %.", "stats": {"def": 1.2, "pv": 1.1}, "filtre": {"roles": ["tank", "guerrier"]}},
	"tir_mortel": {"nom": "Tir Mortel", "rarete": "commune", "desc": "Tireurs, Mages et Assassins : ATK et MAG +18 %.", "stats": {"atk": 1.18, "mag": 1.18}, "filtre": {"roles": ["tireur", "mage", "assassin"]}},
	"ferveur_feu": {"nom": "Ferveur du Feu", "rarete": "commune", "desc": "Unités de Feu : ATK et MAG +22 %.", "stats": {"atk": 1.22, "mag": 1.22}, "filtre": {"element": "feu"}},
	"ferveur_nature": {"nom": "Ferveur de la Nature", "rarete": "commune", "desc": "Unités de Nature : ATK et MAG +22 %.", "stats": {"atk": 1.22, "mag": 1.22}, "filtre": {"element": "nature"}},
	"ferveur_eau": {"nom": "Ferveur de l'Eau", "rarete": "commune", "desc": "Unités d'Eau : ATK et MAG +22 %.", "stats": {"atk": 1.22, "mag": 1.22}, "filtre": {"element": "eau"}},
	"ferveur_tenebres": {"nom": "Ferveur des Ténèbres", "rarete": "commune", "desc": "Unités de Ténèbres : ATK et MAG +22 %.", "stats": {"atk": 1.22, "mag": 1.22}, "filtre": {"element": "tenebres"}},
	"ferveur_sacre": {"nom": "Ferveur Sacrée", "rarete": "commune", "desc": "Unités Sacrées : ATK et MAG +22 %.", "stats": {"atk": 1.22, "mag": 1.22}, "filtre": {"element": "sacre"}},
	# --- Rares ---
	"regeneration": {"nom": "Régénération", "rarete": "rare", "desc": "Toute l'équipe régénère 3 % de ses PV max à chaque tour.", "passifs": {"regen": 0.03}},
	"frenesie": {"nom": "Frénésie", "rarete": "rare", "desc": "10 % de chance d'attaquer deux fois.", "passifs": {"double": 0.10}},
	"bourreau": {"nom": "Instinct du Bourreau", "rarete": "rare", "desc": "+20 % de dégâts contre les cibles sous 50 % de PV.", "passifs": {"execution": 0.20}},
	"riposte": {"nom": "Riposte", "rarete": "rare", "desc": "15 % de chance de contre-attaquer.", "passifs": {"contre_chance": 0.15}},
	"resurrection": {"nom": "Résurrection", "rarete": "rare", "desc": "Ranime tout de suite toutes les unités K.O. avec 40 % de leurs PV.", "instant": {"ranimer": 0.4}},
	"grande_guerison": {"nom": "Grande Guérison", "rarete": "rare", "desc": "Soigne tout de suite l'équipe de 60 % des PV max.", "instant": {"soin": 0.6}},
	"gloire": {"nom": "Gloire des Anciens", "rarete": "rare", "desc": "Score final +15 %.", "gloire": 0.15},
	"fortune": {"nom": "Fortune", "rarete": "rare", "desc": "+80 or de marche tout de suite, et +25 % d'or après chaque combat.", "instant": {"or": 80}, "or_bonus": 0.25},
	"armure_sang": {"nom": "Armure de Sang", "rarete": "rare", "desc": "PV max +20 % et DEF +10 % pour toute l'équipe.", "stats": {"pv": 1.2, "def": 1.1}},
	# --- Épiques ---
	"dernier_rempart": {"nom": "Dernier Rempart", "rarete": "epique", "desc": "Chaque unité survit une fois par combat à un coup fatal (1 PV).", "passifs": {"survie": 1}},
	"colere_divine": {"nom": "Colère Divine", "rarete": "epique", "desc": "ATK et MAG +25 % pour toute l'équipe.", "stats": {"atk": 1.25, "mag": 1.25}},
	"sang_royal": {"nom": "Sang Royal", "rarete": "epique", "desc": "PV max +25 % et régénération de 4 % par tour.", "stats": {"pv": 1.25}, "passifs": {"regen": 0.04}},
	"hate": {"nom": "Hâte du Vent", "rarete": "epique", "desc": "AGI +30 % et 12 % de chance d'attaquer deux fois.", "stats": {"agi": 1.3}, "passifs": {"double": 0.12}},
	"benediction_totale": {"nom": "Bénédiction Totale", "rarete": "epique", "desc": "PV, ATK, DEF, AGI et MAG +12 % pour toute l'équipe.", "stats": {"pv": 1.12, "atk": 1.12, "def": 1.12, "agi": 1.12, "mag": 1.12}},
}
const COULEURS_RARETE := {"commune": "b8b0a8", "rare": "5aa8ff", "epique": "e0a0ff"}

# =====================================================================
# PACTES DE SANG (malédictions)
# =====================================================================
const MALEDICTIONS := {
	"saignee": {"nom": "Saignée", "desc": "Au début de chaque combat, toute l'équipe perd 8 % de ses PV actuels."},
	"fragilite": {"nom": "Fragilité", "desc": "DEF -20 % pour toute l'équipe.", "stats": {"def": 0.8}},
	"ennemis_forts": {"nom": "Rage des Ennemis", "desc": "Les ennemis sont 12 % plus forts."},
	"sans_repos": {"nom": "Sans Repos", "desc": "Les feux de camp et les soins soignent deux fois moins."},
	"misere": {"nom": "Misère", "desc": "Or de marche gagné en combat -50 %."},
	"fatigue": {"nom": "Fatigue", "desc": "AGI -15 % pour toute l'équipe.", "stats": {"agi": 0.85}},
}
## Récompenses possibles d'un pacte
const RECOMPENSES_PACTE := {
	"epique": "Choisis une Bénédiction épique.",
	"deux_rares": "Choisis deux Bénédictions rares.",
	"tresor": "+180 or de marche et soin complet de l'équipe.",
	"gloire": "Score final +30 %.",
}
## Chaque pacte accepté ajoute aussi de la gloire (score final).
const GLOIRE_PACTE := 0.15


# =====================================================================
# ÉVÉNEMENTS
# =====================================================================
## Chaque choix : {texte, cout_or?, effets} ou {texte, cout_or?, chance, succes, echec}
## Effets : soin, degats (% PV max), or, benediction (rareté), malediction ("hasard"), ranimer,
##          score, gloire, recrue ("mercenaire"), combat ("elite").
const EVENEMENTS := {
	"pretre": {"titre": "Le Prêtre Blessé", "texte": "Un prêtre gît au bord du chemin, une flèche dans l'épaule. Il serre contre lui une bourse et un reliquaire.",
		"choix": [
			{"texte": "Le soigner et prier avec lui (−40 or)", "cout_or": 40, "effets": {"benediction": "commune", "score": 10}},
			{"texte": "Lui prendre sa bourse", "effets": {"or": 70, "score": -10}},
			{"texte": "Passer ton chemin", "effets": {}},
		]},
	"coffre": {"titre": "Le Coffre Runique", "texte": "Un coffre couvert de runes palpite comme un cœur. Quelque chose gratte à l'intérieur.",
		"choix": [
			{"texte": "L'ouvrir (60 % : Bénédiction rare, sinon piège)", "chance": 0.6, "succes": {"benediction": "rare"}, "echec": {"degats": 0.2}},
			{"texte": "Le laisser où il est", "effets": {}},
		]},
	"fontaine": {"titre": "La Fontaine Tiède", "texte": "Une fontaine de pierre noire laisse couler un sang tiède qui sent le fer et les roses.",
		"choix": [
			{"texte": "Boire", "effets": {"soin": 0.45}},
			{"texte": "Y tremper tes armes", "effets": {"benediction": "commune", "degats": 0.1}},
		]},
	"mercenaire": {"titre": "Le Mercenaire sans Maître", "texte": "Un guerrier couvert de cicatrices propose ses services. Il ne demande ni nom, ni gloire : seulement de l'or.",
		"choix": [
			{"texte": "L'engager (−90 or) : il remplace une unité", "cout_or": 90, "effets": {"recrue": "mercenaire"}},
			{"texte": "Refuser", "effets": {}},
		]},
	"autel_oublie": {"titre": "L'Autel Oublié", "texte": "Des offrandes s'entassent devant une idole sans visage. Des pièces, des bijoux… et des os.",
		"choix": [
			{"texte": "Prier", "effets": {"benediction": "commune"}},
			{"texte": "Piller les offrandes", "effets": {"or": 120, "malediction": "hasard"}},
		]},
	"ombres": {"titre": "Les Ombres dans la Brume", "texte": "Des silhouettes armées barrent la route. Leurs yeux brillent comme des braises.",
		"choix": [
			{"texte": "Les affronter (combat d'élite, Bénédiction rare en plus)", "effets": {"combat": "elite"}},
			{"texte": "Les contourner par les ronces", "effets": {"degats": 0.12}},
		]},
	"puits": {"titre": "Le Puits aux Souhaits", "texte": "Un vieux puits. Tout au fond, des pièces brillent sous l'eau noire.",
		"choix": [
			{"texte": "Jeter 50 or (50 % : Bénédiction rare)", "cout_or": 50, "chance": 0.5, "succes": {"benediction": "rare"}, "echec": {}},
			{"texte": "Passer", "effets": {}},
		]},
	"campement": {"titre": "Le Campement Abandonné", "texte": "Les feux sont encore tièdes. Les occupants sont partis en hâte… ou ne sont jamais partis.",
		"choix": [
			{"texte": "Fouiller les tentes", "effets": {"or": 60}},
			{"texte": "Se reposer un peu", "effets": {"soin": 0.25}},
		]},
	"voix": {"titre": "La Voix dans la Brume", "texte": "Une voix familière t'appelle par ton nom depuis le brouillard. Elle promet la puissance.",
		"choix": [
			{"texte": "La suivre (35 % : Bénédiction épique, sinon blessures)", "chance": 0.35, "succes": {"benediction": "epique"}, "echec": {"degats": 0.25}},
			{"texte": "Se boucher les oreilles", "effets": {}},
		]},
	"marchand_ames": {"titre": "Le Marchand d'Âmes", "texte": "Un homme sans ombre sourit : « Un peu de ton âme contre beaucoup d'or. Et de gloire. »",
		"choix": [
			{"texte": "Accepter le marché", "effets": {"or": 100, "gloire": 0.1, "malediction": "hasard"}},
			{"texte": "Refuser", "effets": {}},
		]},
	"caravane": {"titre": "Les Survivants", "texte": "Quelques survivants d'une caravane attaquée te regardent passer, affamés.",
		"choix": [
			{"texte": "Partager tes provisions (−30 or)", "cout_or": 30, "effets": {"score": 25, "soin": 0.15}},
			{"texte": "Continuer ta route", "effets": {}},
		]},
	"tombe": {"titre": "La Tombe du Héros", "texte": "Une épée rouillée plantée dans une tombe. La légende dit que son porteur n'a jamais connu la défaite.",
		"choix": [
			{"texte": "Retirer l'épée (50 % : ATK +12 %, sinon malédiction)", "chance": 0.5, "succes": {"benediction_id": "lame"}, "echec": {"malediction": "hasard"}},
			{"texte": "Se recueillir", "effets": {"soin": 0.15, "score": 5}},
		]},
}

## Marchand : prix
const PRIX := {"commune": 70, "rare": 140, "soin": 60, "ranimer": 100, "purifier": 120}


# =====================================================================
# Carte du jour
# =====================================================================

static func jour() -> int:
	return Calendrier.jour_absolu()


static func _rng(sel: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash("BoL-marche-%d-%s" % [jour(), sel])
	return r


## Les 3 Actes dont viennent les régions du jour (un dans chaque tiers de l'histoire).
static func actes_du_jour() -> Array:
	var r := _rng("actes")
	return [r.randi_range(1, 4), r.randi_range(5, 8), r.randi_range(9, 12)]


static func nom_region(region: int) -> String:
	var a: Dictionary = ActesData.get_acte(int(actes_du_jour()[region]))
	return str(a.get("titre", a.get("nom", "Région %d" % (region + 1))))


static var _cache_cartes := {}

## Carte d'une région : [lignes] de [{type, x, liens: [index dans la ligne suivante]}]
static func carte(region: int) -> Array:
	var cle := "%d-%d" % [jour(), region]
	if _cache_cartes.has(cle):
		return _cache_cartes[cle]
	var r := _rng("carte-%d" % region)
	var lignes: Array = []
	for k in LIGNES:
		var n := 1 if k == LIGNES - 1 else (3 if k == 0 else r.randi_range(2, 4))
		var ligne: Array = []
		for i in n:
			var t := "combat"
			if k == LIGNES - 1:
				t = "boss"
			elif k == LIGNES - 2:
				t = "feu"
			elif k > 0:
				t = _tirer_type(r, k)
			ligne.append({"type": t, "x": (i + 0.5) / n, "liens": []})
		lignes.append(ligne)
	# Liens : chaque case va vers la case la plus proche de la ligne suivante (+ parfois une 2e),
	# et chaque case de la ligne suivante doit être atteignable.
	for k in LIGNES - 1:
		var a: Array = lignes[k]
		var b: Array = lignes[k + 1]
		for i in a.size():
			var proches := range(b.size())
			proches.sort_custom(func(p, q): return absf(b[p]["x"] - a[i]["x"]) < absf(b[q]["x"] - a[i]["x"]))
			a[i]["liens"].append(proches[0])
			if proches.size() > 1 and r.randf() < 0.55 and absf(b[proches[1]]["x"] - a[i]["x"]) < 0.45:
				a[i]["liens"].append(proches[1])
		for j in b.size():
			var atteint := false
			for i in a.size():
				if j in a[i]["liens"]:
					atteint = true
			if not atteint:
				var meilleur := 0
				for i in a.size():
					if absf(a[i]["x"] - b[j]["x"]) < absf(a[meilleur]["x"] - b[j]["x"]):
						meilleur = i
				a[meilleur]["liens"].append(j)
		for i in a.size():
			a[i]["liens"].sort()
	_cache_cartes[cle] = lignes
	return lignes


static func _tirer_type(r: RandomNumberGenerator, ligne: int) -> String:
	var total := 0
	for t in POIDS_TYPES:
		if t == "elite" and ligne < 2:
			continue
		total += int(POIDS_TYPES[t])
	var x := r.randi_range(1, total)
	for t in POIDS_TYPES:
		if t == "elite" and ligne < 2:
			continue
		x -= int(POIDS_TYPES[t])
		if x <= 0:
			return t
	return "combat"


# =====================================================================
# État (sauvegarde)
# =====================================================================

static func _donnees() -> Dictionary:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.has("marche") or not Sauvegarde.donnees["marche"] is Dictionary:
		Sauvegarde.donnees["marche"] = {}
	var d: Dictionary = Sauvegarde.donnees["marche"]
	for cle in ["partie", "boutique"]:
		if not d.has(cle):
			d[cle] = {}
	if not d.has("record"):
		d["record"] = 0
	return d


## Partie du jour ({} si aucune aujourd'hui).
static func partie() -> Dictionary:
	var p: Dictionary = _donnees()["partie"]
	if p.is_empty() or int(p.get("jour", -1)) != jour():
		# Une marche d'un jour passé encore en cours est terminée d'office
		if not p.is_empty() and p.get("etat", "") == "en_cours":
			p["etat"] = "finie"
		return {}
	return p


static func en_cours() -> bool:
	return partie().get("etat", "") == "en_cours"


static func deja_jouee() -> bool:
	return partie().get("etat", "") == "finie" and not Sauvegarde.admin("marche_illimitee")


static func record() -> int:
	return int(_donnees()["record"])


# =====================================================================
# Départ
# =====================================================================

static func puissance_unite(m: Dictionary) -> float:
	var s: Dictionary
	if int(m.get("uid", -1)) >= 0:
		s = Sauvegarde.stats_heros(int(m["uid"]))
	else:
		s = UnitesData.stats(m["id"], int(m["niveau"]))
		var mult := float(m.get("mult", 1.0))
		s["pv"] *= mult
		s["atk"] *= 1.0 + (mult - 1.0) * 0.5
		s["mag"] *= 1.0 + (mult - 1.0) * 0.5
	return s["pv"] * 0.25 + s["atk"] + s["def"] * 0.8 + s["agi"] * 0.5 + s["mag"] * 0.7


## Commence la marche avec ces unités (uids). Renvoie "" ou la raison.
static func commencer(uids: Array, classee: bool) -> String:
	if deja_jouee():
		return "Tu as déjà fait la Marche du jour. Reviens demain !"
	if uids.is_empty() or uids.size() > TAILLE_EQUIPE:
		return "Choisis de 1 à %d unités." % TAILLE_EQUIPE
	for uid in uids:
		if Sauvegarde.get_heros(int(uid)).is_empty():
			return "Unité introuvable."
		if Sauvegarde.est_occupe(int(uid)):
			return "Une des unités est partie en mission avec la Compagnie."
	var equipe: Array = []
	for uid in uids:
		var h := Sauvegarde.get_heros(int(uid))
		equipe.append({"uid": int(uid), "id": h["id"], "niveau": int(h["niveau"]), "pv": 1.0})
	equipe.sort_custom(func(a, b): return Rencontres._ordre_place(a["id"]) < Rencontres._ordre_place(b["id"]))
	var puissance := 0.0
	var niveaux := 0
	for m in equipe:
		puissance += puissance_unite(m)
		niveaux += int(m["niveau"])
	var d := _donnees()
	d["partie"] = {
		"jour": jour(), "etat": "en_cours", "classee": classee and not Sauvegarde.admin("marche_illimitee"),
		"equipe": equipe, "puissance": maxf(puissance, 1.0) * TAILLE_EQUIPE / float(equipe.size()),
		"niveau": clampi(int(round(float(niveaux) / equipe.size())), 1, UnitesData.NIVEAU_MAX),
		"region": 0, "ligne": -1, "case": -1,
		"benedictions": [], "maledictions": [], "or": 50, "score": 0, "gloire": 0.0,
		"attente": {}, "achats": {}, "chemin": [], "combats": 0, "elites": 0, "boss": 0, "pactes": 0,
		"journal": ["La Marche commence : %s." % nom_region(0)],
		"resultat": {},
	}
	Sauvegarde.ajouter_stat("marches")
	Sauvegarde.sauvegarder()
	return ""


# =====================================================================
# Déplacement sur la carte
# =====================================================================

## Index des cases atteignables sur la prochaine ligne.
static func cases_atteignables() -> Array:
	var p := partie()
	if p.is_empty() or p["etat"] != "en_cours" or not p["attente"].is_empty():
		return []
	var ligne := int(p["ligne"])
	if ligne < 0:
		return range(carte(int(p["region"]))[0].size())
	if ligne >= LIGNES - 1:
		return []
	return carte(int(p["region"]))[ligne][int(p["case"])]["liens"]


static func case_actuelle() -> Dictionary:
	var p := partie()
	if int(p.get("ligne", -1)) < 0:
		return {}
	return carte(int(p["region"]))[int(p["ligne"])][int(p["case"])]


## Avance sur une case de la ligne suivante. Renvoie le type de la case.
static func avancer(index: int) -> String:
	var p := partie()
	if not index in cases_atteignables():
		return ""
	p["ligne"] = int(p["ligne"]) + 1
	p["case"] = index
	p["chemin"].append([int(p["region"]), int(p["ligne"]), index])
	var c: Dictionary = carte(int(p["region"]))[int(p["ligne"])][index]
	var t: String = c["type"]
	if not t in ["combat", "elite", "boss"]:
		p["score"] = int(p["score"]) + SCORE["case"]
	match t:
		"evenement":
			var ids := EVENEMENTS.keys()
			var r := _rng("evt-%d-%d-%d" % [int(p["region"]), int(p["ligne"]), index])
			p["attente"] = {"type": "evenement", "id": ids[r.randi_range(0, ids.size() - 1)]}
		"feu":
			p["attente"] = {"type": "feu"}
		"marchand":
			p["attente"] = {"type": "marchand", "offres": _offres_marchand(), "achetes": []}
		"tresor":
			var r := _rng("tresor-%d-%d-%d" % [int(p["region"]), int(p["ligne"]), index])
			var gain := r.randi_range(50, 90)
			p["or"] = int(p["or"]) + gain
			journal("Trésor : +%d or." % gain)
			_proposer_benedictions("commune", "tresor")
		"autel":
			p["attente"] = {"type": "autel", "pactes": _tirer_pactes()}
		_:
			p["attente"] = {"type": "combat", "combat": t}
	Sauvegarde.sauvegarder()
	return t


static func journal(t: String) -> void:
	var p := partie()
	p["journal"].append(t)
	if p["journal"].size() > 40:
		p["journal"].pop_front()


# =====================================================================
# Combats
# =====================================================================

## Ennemis du combat de la case actuelle (type "combat", "elite" ou "boss").
static func ennemis(type: String) -> Array:
	var p := partie()
	var region := int(p["region"])
	var ligne := maxi(0, int(p["ligne"]))
	var acte: int = actes_du_jour()[region]
	var pool: Dictionary = Rencontres.POOLS[acte]
	var r := _rng("ennemis-%d-%d-%d-%s" % [region, ligne, int(p["case"]), type])
	var niv := clampi(int(p["niveau"]) + {"combat": 0, "elite": 1, "boss": 2}[type] + region, 1, UnitesData.NIVEAU_MAX)
	var membres: Array = []       # [id, poids, nom, boss, elite]
	match type:
		"combat":
			var nb := 3 if ligne < 2 and region == 0 else (4 if region < 2 else 5)
			for i in nb:
				membres.append([pool["monstres"][r.randi_range(0, pool["monstres"].size() - 1)], 1.0, "", false, false])
		"elite":
			var chef: String = pool["gardiens"][r.randi_range(0, pool["gardiens"].size() - 1)]
			membres.append([chef, 1.5, "Élite : " + UnitesData.get_unite(chef)["nom"], false, true])
			for i in 2:
				membres.append([pool["monstres"][r.randi_range(0, pool["monstres"].size() - 1)], 1.0, "", false, false])
		"boss":
			membres.append([pool["boss"], 2.2, "", true, false])
			for i in 2:
				var g: String = pool["gardiens"][r.randi_range(0, pool["gardiens"].size() - 1)]
				membres.append([g, 1.0, "Garde : " + UnitesData.get_unite(g)["nom"], false, false])
	# Les jeunes équipes (peu de sorts débloqués) affrontent des ennemis un peu plus doux
	var ajust_niveau := 0.62 + 0.38 * clampf((int(p["niveau"]) - 5) / 24.0, 0.0, 1.0)
	var cible: float = float(p["puissance"]) * DIFFICULTE * ajust_niveau * float(force_test.get(type, FORCE[type])) \
		* (1.0 + PENTE_LIGNE * ligne + PENTE_REGION * region) * (1.12 if "ennemis_forts" in p["maledictions"] else 1.0)
	var brut := 0.0
	for m in membres:
		brut += UnitesData.puissance(m[0], niv) * m[1]
	var facteur: float = cible / maxf(1.0, brut)
	membres.sort_custom(func(a, b): return Rencontres._ordre_place(a[0]) < Rencontres._ordre_place(b[0]))
	var equipe: Array = []
	for m in membres:
		var e := {"id": m[0], "niveau": niv, "mult": facteur * m[1], "boss": m[3], "elite": m[4]}
		if m[2] != "":
			e["nom"] = m[2]
		equipe.append(e)
	return equipe


## Bonus cumulés (bénédictions + malédictions) pour une unité.
static func bonus_unite(id_unite: String) -> Dictionary:
	var p := partie()
	var u := UnitesData.get_unite(id_unite)
	var stats := {}
	var passifs := {}
	var sources: Array = []
	for b in p["benedictions"]:
		sources.append(BENEDICTIONS.get(b, {}))
	for m in p["maledictions"]:
		sources.append(MALEDICTIONS.get(m, {}))
	for s in sources:
		var f: Dictionary = s.get("filtre", {})
		if f.has("element") and u["element"] != f["element"]:
			continue
		if f.has("roles") and not u["role"] in f["roles"]:
			continue
		for st in s.get("stats", {}):
			stats[st] = float(stats.get(st, 1.0)) * float(s["stats"][st])
		for pa in s.get("passifs", {}):
			passifs[pa] = passifs.get(pa, 0) + s["passifs"][pa]
	return {"stats": stats, "passifs": passifs}


## L'équipe prête pour le moteur de combat (PV, bonus, recrues).
static func combattants() -> Array:
	var p := partie()
	var l: Array = []
	for i in p["equipe"].size():
		var m: Dictionary = p["equipe"][i]
		var e := {"id": m["id"], "niveau": int(m["niveau"]), "place": i, "pv_ratio": float(m["pv"])}
		if int(m.get("uid", -1)) >= 0:
			var h := Sauvegarde.get_heros(int(m["uid"]))
			e["uid"] = int(m["uid"])
			e["etoiles"] = Fusion.etoiles(h)
			e["echos"] = Sauvegarde.bonus_echos(int(m["uid"]))
		else:
			e["mult"] = float(m.get("mult", 1.0))
		var b := bonus_unite(m["id"])
		if not b["stats"].is_empty():
			e["mult_stats"] = b["stats"]
		if not b["passifs"].is_empty():
			e["passifs_sup"] = b["passifs"]
		l.append(e)
	return l


## Demande de combat pour EcranCombat (case actuelle, ou élite d'un événement).
static func demande_combat() -> Dictionary:
	var p := partie()
	var type: String = p["attente"].get("combat", "combat")
	# Saignée : l'équipe perd des PV avant chaque combat
	if "saignee" in p["maledictions"]:
		for m in p["equipe"]:
			if float(m["pv"]) > 0.0:
				m["pv"] = maxf(0.01, float(m["pv"]) * 0.92)
	return {"mode": "marche", "type": type, "region": int(p["region"]), "equipe": combattants(),
		"ennemis": ennemis(type), "retour": SCENE}


## Résultat d'un combat. Renvoie les lignes à afficher.
static func apres_combat(res: Dictionary) -> Array:
	var p := partie()
	var lignes: Array = []
	var type: String = p["attente"].get("combat", "combat")
	var bonus_evt: bool = p["attente"].get("bonus", false)
	for i in p["equipe"].size():
		if i < res["pv_final"].size():
			p["equipe"][i]["pv"] = float(res["pv_final"][i])
	p["attente"] = {}
	if not res["victoire"]:
		journal("Défaite face au %s." % TYPES[type]["nom"].to_lower())
		lignes.append("Ton équipe est tombée. La Marche s'arrête ici.")
		lignes.append_array(terminer(false))
		return lignes
	var region := int(p["region"])
	var pts := int(SCORE[type] * (1.0 + 0.5 * region if type != "boss" else region + 1))
	p["score"] = int(p["score"]) + pts
	var gain := int({"combat": 25, "elite": 50, "boss": 90}[type] * (1.0 + _or_bonus()) * (0.5 if "misere" in p["maledictions"] else 1.0))
	p["or"] = int(p["or"]) + gain
	lignes.append("Score +%d   ·   Or de marche +%d" % [pts, gain])
	match type:
		"combat":
			p["combats"] = int(p["combats"]) + 1
		"elite":
			p["elites"] = int(p["elites"]) + 1
		"boss":
			p["boss"] = int(p["boss"]) + 1
	journal("%s gagné (+%d points)." % [TYPES[type]["nom"], pts])
	if type == "boss":
		if region >= REGIONS - 1:
			lignes.append("Le dernier boss est tombé : la Marche est accomplie !")
			lignes.append_array(terminer(true))
			return lignes
		# Région suivante : un peu de repos
		p["region"] = region + 1
		p["ligne"] = -1
		p["case"] = -1
		_soigner(0.3)
		journal("Nouvelle région : %s. L'équipe reprend son souffle (+30 %% PV)." % nom_region(region + 1))
		lignes.append("Région suivante : %s. Ton équipe reprend son souffle (+30 %% PV)." % nom_region(region + 1))
		_proposer_benedictions("epique", "boss")
	elif type == "elite":
		_proposer_benedictions("rare" if not bonus_evt else "rare", "elite")
		# L'élite vaincue propose parfois de rejoindre l'équipe
		var r := _rng("recrue-%d-%d-%d" % [region, int(p["ligne"]), int(p["case"])])
		if r.randf() < 0.5:
			var chef: Dictionary = ennemis("elite")[0]
			for e in ennemis("elite"):
				if e.get("elite", false):
					chef = e
			p["attente"]["recrue"] = {"id": chef["id"], "niveau": int(chef["niveau"]), "mult": float(chef["mult"]) * 0.75}
	else:
		_proposer_benedictions("commune" if not bonus_evt else "rare", "combat")
	Sauvegarde.sauvegarder()
	return lignes


static func _or_bonus() -> float:
	var b := 0.0
	for id in partie()["benedictions"]:
		b += float(BENEDICTIONS.get(id, {}).get("or_bonus", 0.0))
	return b


# =====================================================================
# Bénédictions : choix
# =====================================================================

## Propose 3 bénédictions (une case d'attente "benediction").
static func _proposer_benedictions(rarete: String, source: String, nombre_choix := 1) -> void:
	var p := partie()
	var r := _rng("bene-%d-%d-%d-%s-%d" % [int(p["region"]), int(p["ligne"]), int(p["case"]), source, p["benedictions"].size()])
	var possibles: Array = []
	for id in BENEDICTIONS:
		if BENEDICTIONS[id]["rarete"] == rarete:
			possibles.append(id)
	var offres: Array = []
	while offres.size() < 3 and not possibles.is_empty():
		offres.append(possibles.pop_at(r.randi_range(0, possibles.size() - 1)))
	var recrue = p["attente"].get("recrue", null)
	p["attente"] = {"type": "benediction", "offres": offres, "rarete": rarete, "restants": nombre_choix}
	if recrue != null:
		p["attente"]["recrue"] = recrue


## Choisit une bénédiction proposée (index dans les offres, -1 = aucune).
static func choisir_benediction(index: int) -> void:
	var p := partie()
	var a: Dictionary = p["attente"]
	if a.get("type", "") != "benediction":
		return
	if index >= 0 and index < a["offres"].size():
		var id: String = a["offres"][index]
		_appliquer_benediction(id)
		a["offres"].remove_at(index)
	a["restants"] = int(a["restants"]) - 1
	if int(a["restants"]) <= 0 or a["offres"].is_empty() or index < 0:
		var recrue = a.get("recrue", null)
		p["attente"] = {}
		if recrue != null:
			p["attente"] = {"type": "recrue", "unite": recrue}
	Sauvegarde.sauvegarder()


static func _appliquer_benediction(id: String) -> void:
	var p := partie()
	var b: Dictionary = BENEDICTIONS[id]
	var inst: Dictionary = b.get("instant", {})
	if inst.has("soin"):
		_soigner(float(inst["soin"]))
	if inst.has("ranimer"):
		_ranimer(float(inst["ranimer"]))
	if inst.has("or"):
		p["or"] = int(p["or"]) + int(inst["or"])
	if b.has("gloire"):
		p["gloire"] = float(p["gloire"]) + float(b["gloire"])
	if b.has("stats") or b.has("passifs") or b.has("or_bonus"):
		p["benedictions"].append(id)
	journal("Bénédiction : %s." % b["nom"])


static func _soigner(pct: float) -> void:
	var p := partie()
	if "sans_repos" in p["maledictions"]:
		pct *= 0.5
	for m in p["equipe"]:
		if float(m["pv"]) > 0.0:
			m["pv"] = minf(1.0, float(m["pv"]) + pct)


static func _ranimer(pct: float) -> void:
	for m in partie()["equipe"]:
		if float(m["pv"]) <= 0.0:
			m["pv"] = pct


static func _blesser(pct: float) -> void:
	for m in partie()["equipe"]:
		if float(m["pv"]) > 0.0:
			m["pv"] = maxf(0.05, float(m["pv"]) - pct)


# =====================================================================
# Recrues (élite vaincue, mercenaire)
# =====================================================================

## Accepte la recrue à la place de l'unité n° index (-1 = refuser).
static func recruter(index: int) -> void:
	var p := partie()
	var a: Dictionary = p["attente"]
	if a.get("type", "") != "recrue":
		return
	if index >= 0 and index < p["equipe"].size():
		var u: Dictionary = a["unite"]
		var ancien: String = UnitesData.get_unite(p["equipe"][index]["id"])["nom"]
		p["equipe"][index] = {"uid": -1, "id": u["id"], "niveau": int(u["niveau"]), "mult": float(u["mult"]), "pv": 1.0, "recrue": true}
		Sauvegarde.decouvrir(u["id"])
		journal("%s rejoint la marche (à la place de %s)." % [UnitesData.get_unite(u["id"])["nom"], ancien])
	p["attente"] = {}
	Sauvegarde.sauvegarder()


static func _mercenaire() -> Dictionary:
	var p := partie()
	var r := _rng("mercenaire-%d-%d" % [int(p["region"]), int(p["ligne"])])
	var liste := UnitesData.liste_invocables("SR") + UnitesData.liste_invocables("SSR")
	var id: String = liste[r.randi_range(0, liste.size() - 1)]
	var niv := int(p["niveau"])
	# Force d'un membre moyen de l'équipe de départ
	var cible := float(p["puissance"]) / TAILLE_EQUIPE
	return {"id": id, "niveau": niv, "mult": clampf(cible / maxf(1.0, UnitesData.puissance(id, niv)), 0.5, 3.0)}


# =====================================================================
# Événements, feu de camp, marchand, autel
# =====================================================================

## Applique un choix d'événement. Renvoie les lignes de résultat.
static func choisir_evenement(index: int) -> Array:
	var p := partie()
	var a: Dictionary = p["attente"]
	if a.get("type", "") != "evenement":
		return []
	var evt: Dictionary = EVENEMENTS[a["id"]]
	var c: Dictionary = evt["choix"][index]
	if int(c.get("cout_or", 0)) > int(p["or"]):
		return ["Pas assez d'or de marche."]
	p["or"] = int(p["or"]) - int(c.get("cout_or", 0))
	p["attente"] = {}
	var effets: Dictionary = c.get("effets", {})
	var lignes: Array = []
	if c.has("chance"):
		var r := _rng("evt-choix-%d-%d-%d" % [int(p["region"]), int(p["ligne"]), index])
		if r.randf() < float(c["chance"]):
			effets = c["succes"]
			lignes.append("Réussite !")
		else:
			effets = c["echec"]
			lignes.append("Échec…")
	lignes.append_array(_appliquer_effets(effets))
	journal("%s : %s" % [evt["titre"], c["texte"]])
	Sauvegarde.sauvegarder()
	return lignes


static func _appliquer_effets(e: Dictionary) -> Array:
	var p := partie()
	var l: Array = []
	if e.has("soin"):
		_soigner(float(e["soin"]))
		l.append("L'équipe récupère %d %% de ses PV." % int(float(e["soin"]) * 100))
	if e.has("degats"):
		_blesser(float(e["degats"]))
		l.append("L'équipe perd %d %% de ses PV." % int(float(e["degats"]) * 100))
	if e.has("or"):
		p["or"] = int(p["or"]) + int(e["or"])
		l.append("Or de marche +%d." % int(e["or"]))
	if e.has("score"):
		p["score"] = int(p["score"]) + int(e["score"])
		l.append("Score %s%d." % ["+" if int(e["score"]) >= 0 else "", int(e["score"])])
	if e.has("gloire"):
		p["gloire"] = float(p["gloire"]) + float(e["gloire"])
		l.append("Gloire +%d %% (score final)." % int(float(e["gloire"]) * 100))
	if e.has("ranimer"):
		_ranimer(float(e["ranimer"]))
	if e.has("malediction"):
		var m := _malediction_au_hasard()
		if m != "":
			p["maledictions"].append(m)
			l.append("Malédiction : %s — %s" % [MALEDICTIONS[m]["nom"], MALEDICTIONS[m]["desc"]])
	if e.has("benediction_id"):
		_appliquer_benediction(e["benediction_id"])
		l.append("Bénédiction : %s." % BENEDICTIONS[e["benediction_id"]]["nom"])
	# Ces effets ouvrent un nouveau choix (le dernier gagne)
	if e.has("benediction"):
		_proposer_benedictions(e["benediction"], "evt")
	if e.has("recrue"):
		p["attente"] = {"type": "recrue", "unite": _mercenaire()}
	if e.has("combat"):
		p["attente"] = {"type": "combat", "combat": e["combat"], "bonus": true}
		l.append("Le combat s'engage !")
	return l


static func _malediction_au_hasard() -> String:
	var p := partie()
	var libres: Array = []
	for m in MALEDICTIONS:
		if not m in p["maledictions"]:
			libres.append(m)
	if libres.is_empty():
		return ""
	var r := _rng("maudit-%d-%d-%d" % [int(p["region"]), int(p["ligne"]), p["maledictions"].size()])
	return libres[r.randi_range(0, libres.size() - 1)]


## Feu de camp : "repos", "entrainement" ou "rite".
static func feu_de_camp(choix: String) -> Array:
	var p := partie()
	if p["attente"].get("type", "") != "feu":
		return []
	p["attente"] = {}
	var l: Array = []
	match choix:
		"repos":
			_soigner(0.35)
			l.append("L'équipe se repose (+%d %% PV)." % (17 if "sans_repos" in p["maledictions"] else 35))
		"entrainement":
			_proposer_benedictions("commune", "feu")
		"rite":
			_blesser(0.2)
			_proposer_benedictions("rare", "rite")
			l.append("Le rite coûte 20 % des PV de l'équipe.")
	journal("Feu de camp : " + {"repos": "repos", "entrainement": "entraînement", "rite": "rite de sang"}[choix] + ".")
	Sauvegarde.sauvegarder()
	return l


static func _offres_marchand() -> Array:
	var p := partie()
	var r := _rng("marchand-%d-%d-%d" % [int(p["region"]), int(p["ligne"]), int(p["case"])])
	var communes: Array = []
	var rares: Array = []
	for id in BENEDICTIONS:
		if BENEDICTIONS[id]["rarete"] == "commune" and not BENEDICTIONS[id].has("instant"):
			communes.append(id)
		elif BENEDICTIONS[id]["rarete"] == "rare" and not BENEDICTIONS[id].has("instant"):
			rares.append(id)
	var o: Array = []
	for k in 2:
		o.append({"type": "benediction", "id": communes.pop_at(r.randi_range(0, communes.size() - 1)), "prix": PRIX["commune"]})
	o.append({"type": "benediction", "id": rares[r.randi_range(0, rares.size() - 1)], "prix": PRIX["rare"]})
	o.append({"type": "soin", "prix": PRIX["soin"]})
	o.append({"type": "ranimer", "prix": PRIX["ranimer"]})
	o.append({"type": "purifier", "prix": PRIX["purifier"]})
	return o


static func texte_offre(o: Dictionary) -> String:
	match str(o["type"]):
		"benediction":
			var b: Dictionary = BENEDICTIONS[o["id"]]
			return "%s — %s" % [b["nom"], b["desc"]]
		"soin":
			return "Soins — l'équipe récupère 35 % de ses PV."
		"ranimer":
			return "Résurrection — ranime les unités K.O. avec 40 % de leurs PV."
		"purifier":
			return "Purification — retire ta dernière malédiction."
	return ""


## Achète l'offre n° index chez le marchand. Renvoie "" ou la raison.
static func acheter(index: int) -> String:
	var p := partie()
	var a: Dictionary = p["attente"]
	if a.get("type", "") != "marchand" or index in a["achetes"]:
		return "Déjà acheté."
	var o: Dictionary = a["offres"][index]
	if int(p["or"]) < int(o["prix"]):
		return "Pas assez d'or de marche."
	if o["type"] == "purifier" and p["maledictions"].is_empty():
		return "Tu n'as aucune malédiction."
	if o["type"] == "ranimer" and not p["equipe"].any(func(m): return float(m["pv"]) <= 0.0):
		return "Aucune unité K.O."
	p["or"] = int(p["or"]) - int(o["prix"])
	a["achetes"].append(index)
	match str(o["type"]):
		"benediction":
			_appliquer_benediction(o["id"])
		"soin":
			_soigner(0.35)
		"ranimer":
			_ranimer(0.4)
		"purifier":
			var m: String = p["maledictions"].pop_back()
			journal("Malédiction levée : %s." % MALEDICTIONS[m]["nom"])
	Sauvegarde.sauvegarder()
	return ""


static func quitter_lieu() -> void:
	var p := partie()
	if p["attente"].get("type", "") in ["marchand"]:
		p["attente"] = {}
		Sauvegarde.sauvegarder()


static func _tirer_pactes() -> Array:
	var p := partie()
	var r := _rng("pacte-%d-%d-%d" % [int(p["region"]), int(p["ligne"]), int(p["case"])])
	var maudits: Array = []
	for m in MALEDICTIONS:
		if not m in p["maledictions"]:
			maudits.append(m)
	var recomp := RECOMPENSES_PACTE.keys()
	var l: Array = []
	for k in 2:
		if maudits.is_empty():
			break
		l.append({"malediction": maudits.pop_at(r.randi_range(0, maudits.size() - 1)),
			"recompense": recomp.pop_at(r.randi_range(0, recomp.size() - 1))})
	return l


## Accepte le pacte n° index (-1 = refuser). Renvoie les lignes de résultat.
static func pacte(index: int) -> Array:
	var p := partie()
	var a: Dictionary = p["attente"]
	if a.get("type", "") != "autel":
		return []
	p["attente"] = {}
	if index < 0 or index >= a["pactes"].size():
		journal("Autel de Sang : pacte refusé.")
		Sauvegarde.sauvegarder()
		return ["Tu refuses le pacte. L'autel se tait."]
	var pa: Dictionary = a["pactes"][index]
	var l: Array = []
	p["maledictions"].append(pa["malediction"])
	p["pactes"] = int(p["pactes"]) + 1
	p["gloire"] = float(p["gloire"]) + GLOIRE_PACTE
	l.append("Malédiction : %s — %s" % [MALEDICTIONS[pa["malediction"]]["nom"], MALEDICTIONS[pa["malediction"]]["desc"]])
	l.append("Gloire +%d %% (score final)." % int(GLOIRE_PACTE * 100))
	match str(pa["recompense"]):
		"epique":
			_proposer_benedictions("epique", "pacte")
		"deux_rares":
			_proposer_benedictions("rare", "pacte", 2)
		"tresor":
			p["or"] = int(p["or"]) + 180
			for m in p["equipe"]:
				if float(m["pv"]) > 0.0:
					m["pv"] = 1.0
			l.append("+180 or de marche, équipe soignée.")
		"gloire":
			p["gloire"] = float(p["gloire"]) + 0.3
			l.append("Gloire +30 %.")
	journal("Pacte de Sang : %s." % MALEDICTIONS[pa["malediction"]]["nom"])
	Sauvegarde.sauvegarder()
	return l


# =====================================================================
# Fin de la marche
# =====================================================================

static func score_final(p: Dictionary, complete: bool) -> int:
	var s := int(p["score"])
	s += int(int(p["or"]) / 5.0)
	for m in p["equipe"]:
		if float(m["pv"]) > 0.0:
			s += SCORE["vivant"]
	if complete:
		s += SCORE["fin"]
	return mini(SCORE_MAX, int(round(s * (1.0 + float(p["gloire"])))))


static func sceaux(score: int) -> int:
	return int(round(score / 10.0))


## Termine la marche : score, Sceaux, XP. Renvoie les lignes de récompense.
static func terminer(complete: bool) -> Array:
	var p := partie()
	var score := score_final(p, complete)
	var s := sceaux(score)
	p["etat"] = "finie"
	p["attente"] = {}
	p["resultat"] = {"score": score, "sceaux": s, "complete": complete, "envoye": false}
	var d := _donnees()
	var l: Array = []
	if score > int(d["record"]):
		d["record"] = score
		l.append("Nouveau record personnel !")
	l.append("SCORE FINAL : %d%s" % [score, ("   (gloire +%d %%)" % int(float(p["gloire"]) * 100)) if float(p["gloire"]) > 0 else ""])
	l.append_array(Reliquaire.donner({"sceau_marche": s}))
	# XP pour les unités du joueur : selon les combats gagnés
	var victoires := int(p["combats"]) + 2 * int(p["elites"]) + 4 * int(p["boss"])
	var xp := 40 * victoires
	if xp > 0:
		for m in p["equipe"]:
			if int(m.get("uid", -1)) >= 0 and not Sauvegarde.get_heros(int(m["uid"])).is_empty():
				Sauvegarde.ajouter_xp_heros(int(m["uid"]), xp)
		l.append("Tes unités : +%d XP chacune." % xp)
	Sauvegarde.ajouter_stat("marches_terminees" if complete else "marches_perdues")
	Sauvegarde.sauvegarder()
	return l


## Abandon volontaire (le score accumulé compte quand même).
static func abandonner() -> Array:
	if not en_cours():
		return []
	journal("La Marche est abandonnée.")
	return terminer(false)


# =====================================================================
# Boutique des Expéditions (Sceaux de Marche)
# =====================================================================
## limite : achats par semaine
const BOUTIQUE := [
	{"id": "poussiere_echo", "quantite": 20, "prix": 30, "limite": 10},
	{"id": "elixir_grand", "quantite": 1, "prix": 45, "limite": 5},
	{"id": "tome_grand", "quantite": 1, "prix": 50, "limite": 5},
	{"id": "larme_sang", "quantite": 3, "prix": 60, "limite": 5},
	{"id": "coffre_or", "quantite": 1, "prix": 90, "limite": 3},
	{"id": "eclat_superieur", "quantite": 1, "prix": 110, "limite": 3},
	{"id": "coeur_sang", "quantite": 1, "prix": 150, "limite": 2},
	{"id": "pierre_eveil", "quantite": 1, "prix": 300, "limite": 1},
]


static func _achats_semaine() -> Dictionary:
	var b: Dictionary = _donnees()["boutique"]
	if int(b.get("semaine", -1)) != Calendrier.semaine():
		b["semaine"] = Calendrier.semaine()
		b["achats"] = {}
	return b["achats"]


static func achats_restants(article: Dictionary) -> int:
	return int(article["limite"]) - int(_achats_semaine().get(article["id"], 0))


static func acheter_boutique(index: int) -> String:
	var a: Dictionary = BOUTIQUE[index]
	if achats_restants(a) <= 0:
		return "Limite de la semaine atteinte."
	if not Sauvegarde.retirer_objet("sceau_marche", int(a["prix"])):
		return "Pas assez de Sceaux de Marche."
	var ach := _achats_semaine()
	ach[a["id"]] = int(ach.get(a["id"], 0)) + 1
	Sauvegarde.ajouter_objet(a["id"], int(a["quantite"]))
	Sauvegarde.sauvegarder()
	return ""
