class_name UnitesData
extends RefCounted
## TOUS LES HÉROS ET MONSTRES du jeu (base reprise de la version Phaser).
##
## STATS PRINCIPALES (au niveau 1, elles augmentent avec le niveau) :
##   pv  : points de vie
##   atk : dégâts physiques de l'attaque normale
##   def : défense contre les dégâts physiques
##   agi : vitesse -> ordre d'action dans le combat
##   mag : puissance des skills
## STATS SECONDAIRES (fixes, modifiées plus tard par les Échos Sanguins et les passifs) :
##   crit        : % de chance de coup critique
##   degats_crit : % de dégâts lors d'un critique (150 = x1,5)
##   res         : résistance aux afflictions et aux dégâts des skills
##   preci       : % de chance de toucher
##
## SKILLS : débloqués aux niveaux 1, 10, 20 et 30.
##   "actif"  : se déclenche selon sa chance à chaque tour
##   "passif" : toujours actif
##   Puissance de skill = 0,6 x ATK + MAG   (voir puissance_skill())
##
## UTILISATION :
##   UnitesData.get_unite("chevalier")                 -> toutes les données
##   UnitesData.stats("chevalier", 15)                 -> stats au niveau 15
##   UnitesData.skills_debloques("chevalier", 15)      -> skills des niveaux 1 et 10
##   UnitesData.liste_invocables("SSR")                -> héros SSR invocables
##
## POUR MODIFIER UNE UNITÉ : change ses valeurs ci-dessous (les descriptions
## des skills sont du texte simple, pense à les ajuster si tu changes un chiffre).

const NIVEAU_MAX := 30
## Gain de stats par niveau : +4 % des stats de base (niveau 30 = x2,16)
const CROISSANCE_PAR_NIVEAU := 0.04
const NIVEAUX_SKILLS := [1, 10, 20, 30]

const RARETES := ["N", "R", "SR", "SSR", "UR"]
const ELEMENTS := {
	"feu": "Feu", "nature": "Nature", "eau": "Eau", "tenebres": "Ténèbres", "sacre": "Sacré",
}
const ROLES := {
	"guerrier": "Guerrier", "tank": "Tank", "assassin": "Assassin",
	"tireur": "Tireur", "mage": "Mage", "soutien": "Soutien",
}
const AFFLICTIONS := {
	"brulure": "Brûlure : perd des PV chaque tour et reçoit moins de soins",
	"gel": "Gel : AGI fortement réduite, peut perdre son tour",
	"poison": "Poison : perd un % de ses PV max chaque tour",
	"saignement": "Saignement : perd des PV à chaque action",
	"etourdi": "Étourdissement : perd son prochain tour",
	"silence": "Silence : ne peut plus lancer de skill actif",
	"aveugle": "Aveuglement : précision fortement réduite",
	"malediction": "Malédiction : RES réduite, reçoit plus de dégâts de skill",
}


static func get_unite(id: String) -> Dictionary:
	if not UNITES.has(id):
		push_warning("Unité inconnue : " + id)
		return {}
	return UNITES[id]


## Stats principales + secondaires d'une unité à un niveau donné.
static func stats(id: String, niveau: int) -> Dictionary:
	var u := get_unite(id)
	if u.is_empty():
		return {}
	var n := clampi(niveau, 1, NIVEAU_MAX)
	var facteur := 1.0 + CROISSANCE_PAR_NIVEAU * (n - 1)
	var s := {}
	for cle in u["stats"]:
		s[cle] = int(round(u["stats"][cle] * facteur))
	for cle in u["secondaires"]:
		s[cle] = u["secondaires"][cle]
	return s


static func puissance_skill(stats_unite: Dictionary) -> float:
	return 0.6 * stats_unite["atk"] + stats_unite["mag"]


## Skills débloqués à ce niveau (dans l'ordre 1, 10, 20, 30).
static func skills_debloques(id: String, niveau: int) -> Array:
	var resultat: Array = []
	for sk in get_unite(id).get("skills", []):
		if sk["niveau"] <= niveau:
			resultat.append(sk)
	return resultat


## Liste des id des héros invocables (optionnel : filtrés par rareté).
static func liste_invocables(rarete := "") -> Array:
	var l: Array = []
	for id in UNITES:
		var u: Dictionary = UNITES[id]
		if u["invocable"] and (rarete == "" or u["rarete"] == rarete):
			l.append(id)
	return l


## Liste des id par catégorie : "heros", "ennemi" ou "boss".
static func liste_categorie(categorie: String) -> Array:
	var l: Array = []
	for id in UNITES:
		if UNITES[id]["categorie"] == categorie:
			l.append(id)
	return l


## Score de puissance approximatif (utile pour équilibrer les combats).
static func puissance(id: String, niveau: int) -> int:
	var s := stats(id, niveau)
	if s.is_empty():
		return 0
	return int(s["pv"] * 0.25 + s["atk"] + s["def"] * 0.8 + s["agi"] * 0.5 + s["mag"] * 0.7)


const UNITES := {

	# ============================================================
	# HÉROS DE LÉGENDE (héros de départ ; invocables mais très rares)
	# ============================================================
	"brute_noire": {
		"nom": "La Brute Noire", "rarete": "SSR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "222222",
		"legende": true, "forge": false, "race": "Gorille", "dominantes": ["pv", "atk"], "phase2": {},
		"stats": {"pv": 1400, "atk": 320, "def": 110, "agi": 60, "mag": 50},
		"secondaires": {"crit": 13, "degats_crit": 185, "res": 21, "preci": 97},
		"skills": [
			{"nom": "Frappe Brutale", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi."},
			{"nom": "Peau de Colosse", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.15}, {"effet": "rage", "stat": "atk", "valeur": 0.25}], "niveau": 10, "description": "PV +15 % ; sous 50 % de PV : ATK +25 %."},
			{"nom": "Séisme", "type": "actif", "chance": 0.25, "cible": "avant", "effets": [{"effet": "degats", "mult": 1.3}, {"effet": "affliction", "nom": "etourdi", "chance": 0.3, "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 130 % de puissance de skill aux ennemis de l'Avant ; 30 % de chance d'infliger Étourdissement (1 tour)."},
			{"nom": "Roi de la Jungle", "type": "passif", "effets": [{"effet": "execution", "valeur": 0.35}, {"effet": "vol_vie", "valeur": 0.15}], "niveau": 30, "description": "+35 % de dégâts contre les cibles sous 50 % de PV ; vol de vie de 15 % sur ses attaques."},
		],
	},
	"barbe_bleue": {
		"nom": "Barbe Bleue", "rarete": "SSR", "element": "eau", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "114488",
		"legende": true, "forge": false, "race": "Nain", "dominantes": ["def", "mag"], "phase2": {},
		"stats": {"pv": 1200, "atk": 160, "def": 240, "agi": 80, "mag": 210},
		"secondaires": {"crit": 9, "degats_crit": 175, "res": 29, "preci": 95},
		"skills": [
			{"nom": "Bouclier Magique", "type": "actif", "chance": 0.4, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.8}], "niveau": 1, "description": "(40 % de chance par tour) Soigne toute l'équipe de 80 % de puissance de skill."},
			{"nom": "Runes de Protection", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.15}, {"effet": "stat", "stat": "res", "valeur": 0.2}], "niveau": 10, "description": "DEF +15 % ; RES +20 %."},
			{"nom": "Forteresse Runique", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.15}, {"effet": "provocation", "duree": 2, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 15 % des PV max sur toute l'équipe ; attire les attaques ennemies (2 tours)."},
			{"nom": "Enclume des Abysses", "type": "passif", "effets": [{"effet": "epines", "valeur": 0.25}, {"effet": "survie", "charges": 1}], "niveau": 30, "description": "Renvoie 25 % des dégâts physiques reçus ; survit à un coup fatal avec 1 PV (1 fois par combat)."},
		],
	},
	"lance_doree": {
		"nom": "La Lance Dorée", "rarete": "SSR", "element": "sacre", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "ddaa00",
		"legende": true, "forge": false, "race": "Homme-Lézard", "dominantes": ["agi", "atk"], "phase2": {},
		"stats": {"pv": 900, "atk": 270, "def": 90, "agi": 260, "mag": 70},
		"secondaires": {"crit": 13, "degats_crit": 185, "res": 21, "preci": 97},
		"skills": [
			{"nom": "Estoc Éclair", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi."},
			{"nom": "Réflexes Écailleux", "type": "passif", "effets": [{"effet": "stat", "stat": "agi", "valeur": 0.15}, {"effet": "stat", "stat": "crit", "valeur": 8}], "niveau": 10, "description": "AGI +15 % ; Crit +8."},
			{"nom": "Tempête de Lances", "type": "actif", "chance": 0.25, "cible": "aleatoire", "effets": [{"effet": "degats", "mult": 0.8, "coups": 3}, {"effet": "affliction", "nom": "aveugle", "chance": 0.25, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Frappe 3 fois des ennemis au hasard (80 % de puissance de skill par coup) ; 25 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Premier Sang", "type": "passif", "effets": [{"effet": "premier"}, {"effet": "double_attaque", "chance": 0.2}], "niveau": 30, "description": "Agit toujours en premier au 1er tour ; 20 % de chance d'attaquer deux fois."},
		],
	},
	"nymphe": {
		"nom": "La Nymphe", "rarete": "SSR", "element": "sacre", "role": "soutien", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "22aa55",
		"legende": true, "forge": false, "race": "Elfe", "dominantes": ["mag", "def"], "phase2": {},
		"stats": {"pv": 950, "atk": 150, "def": 200, "agi": 110, "mag": 220},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 36, "preci": 100},
		"skills": [
			{"nom": "Soin Sacré", "type": "actif", "chance": 0.4, "cible": "allie_faible", "effets": [{"effet": "soin", "mult": 1.3}], "niveau": 1, "description": "(40 % de chance par tour) Soigne l'allié le plus blessé de 130 % de puissance de skill."},
			{"nom": "Chant Sylvestre", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.25}, {"effet": "aura", "stat": "res", "valeur": 0.1}], "niveau": 10, "description": "Soins prodigués +25 % ; toute l'équipe : RES +10 %."},
			{"nom": "Rosée Céleste", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.9}, {"effet": "purification"}], "niveau": 20, "description": "(25 % de chance par tour) Soigne toute l'équipe de 90 % de puissance de skill ; retire les afflictions."},
			{"nom": "Souffle de Vie", "type": "actif", "chance": 0.15, "cible": "allies", "effets": [{"effet": "ressusciter", "valeur": 0.5}, {"effet": "regen_temp", "valeur": 0.05, "duree": 3}], "niveau": 30, "description": "(15 % de chance par tour) Ranime un allié K.O. avec 50 % de ses PV ; régénère 5 % des PV par tour (3 tours)."},
		],
	},
	"mage_gris": {
		"nom": "Le Mage Gris", "rarete": "SSR", "element": "feu", "role": "mage", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "777788",
		"legende": true, "forge": false, "race": "Gobelin", "dominantes": ["mag", "agi"], "phase2": {},
		"stats": {"pv": 800, "atk": 190, "def": 70, "agi": 220, "mag": 250},
		"secondaires": {"crit": 12, "degats_crit": 185, "res": 33, "preci": 99},
		"skills": [
			{"nom": "Explosion Magique", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.1}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 110 % de puissance de skill à tous les ennemis."},
			{"nom": "Érudition Gobeline", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.18}], "niveau": 10, "description": "MAG +18 %."},
			{"nom": "Météore", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.3}, {"effet": "affliction", "nom": "brulure", "chance": 0.5, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 230 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Surcharge Arcanique", "type": "passif", "effets": [{"effet": "accumulation", "stat": "mag", "valeur": 0.12, "max": 3}, {"effet": "stat", "stat": "crit", "valeur": 10}], "niveau": 30, "description": "Chaque ennemi vaincu : MAG +12 % (max 3 fois) ; Crit +10."},
		],
	},
	"dague_violette": {
		"nom": "La Dague Violette", "rarete": "SSR", "element": "tenebres", "role": "assassin", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "660099",
		"legende": true, "forge": false, "race": "Elfe Sombre", "dominantes": ["atk", "agi"], "phase2": {},
		"stats": {"pv": 850, "atk": 290, "def": 80, "agi": 240, "mag": 90},
		"secondaires": {"crit": 23, "degats_crit": 210, "res": 17, "preci": 100},
		"skills": [
			{"nom": "Lame d'Ombre", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi."},
			{"nom": "Pas de Velours", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 12}, {"effet": "stat", "stat": "degats_crit", "valeur": 25}], "niveau": 10, "description": "Crit +12 ; Dégâts crit +25 %."},
			{"nom": "Danse des Lames", "type": "actif", "chance": 0.25, "cible": "aleatoire", "effets": [{"effet": "degats", "mult": 0.9, "coups": 3}, {"effet": "affliction", "nom": "saignement", "chance": 0.4, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Frappe 3 fois des ennemis au hasard (90 % de puissance de skill par coup) ; 40 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Exécutrice", "type": "passif", "effets": [{"effet": "execution", "valeur": 0.4}, {"effet": "bonus_arriere", "valeur": 0.2}], "niveau": 30, "description": "+40 % de dégâts contre les cibles sous 50 % de PV ; +20 % de dégâts contre les ennemis de l'Arrière."},
		],
	},
	"samourai_rouge": {
		"nom": "Le Samouraï Rouge", "rarete": "SSR", "element": "feu", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "cc1111",
		"legende": true, "forge": false, "race": "Humain", "dominantes": ["atk", "pv"], "phase2": {},
		"stats": {"pv": 1300, "atk": 280, "def": 100, "agi": 150, "mag": 60},
		"secondaires": {"crit": 13, "degats_crit": 185, "res": 21, "preci": 97},
		"skills": [
			{"nom": "Entaille Rapide", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi."},
			{"nom": "Voie du Sabre", "type": "passif", "effets": [{"effet": "contre", "chance": 0.25, "mult": 1.0}], "niveau": 10, "description": "25 % de chance de contre-attaquer (100 % d'ATK)."},
			{"nom": "Iaijutsu", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.2, "ignore_res": 0.25}, {"effet": "affliction", "nom": "saignement", "chance": 0.4, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 220 % de puissance de skill à un ennemi, en ignorant 25 % de la RES ; 40 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Bushido", "type": "passif", "effets": [{"effet": "survie", "charges": 1}, {"effet": "rage", "stat": "atk", "valeur": 0.3}], "niveau": 30, "description": "Survit à un coup fatal avec 1 PV (1 fois par combat) ; sous 50 % de PV : ATK +30 %."},
		],
	},
	"chevalier_blanc": {
		"nom": "Le Chevalier Blanc", "rarete": "SSR", "element": "sacre", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "eeeeee",
		"legende": true, "forge": false, "race": "Humain", "dominantes": ["pv", "def"], "phase2": {},
		"stats": {"pv": 1250, "atk": 190, "def": 220, "agi": 90, "mag": 100},
		"secondaires": {"crit": 9, "degats_crit": 175, "res": 29, "preci": 95},
		"skills": [
			{"nom": "Charge Sainte", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi."},
			{"nom": "Serment du Paladin", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.15}, {"effet": "immunite", "afflictions": ["malediction", "silence"]}], "niveau": 10, "description": "DEF +15 % ; immunisé à Malédiction, Silence."},
			{"nom": "Bouclier de Foi", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.12}, {"effet": "purification"}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 12 % des PV max sur toute l'équipe ; retire les afflictions."},
			{"nom": "Lumière Inébranlable", "type": "passif", "effets": [{"effet": "aura", "stat": "pv", "valeur": 0.12}, {"effet": "survie", "charges": 1}], "niveau": 30, "description": "Toute l'équipe : PV +12 % ; survit à un coup fatal avec 1 PV (1 fois par combat)."},
		],
	},

	# ============================================================
	# HÉROS INVOCABLES (Autel d'Invocation)
	# ============================================================
	"chevalier": {
		"nom": "Chevalier Noir", "rarete": "R", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "880000",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1000, "atk": 180, "def": 120, "agi": 100, "mag": 40},
		"secondaires": {"crit": 9, "degats_crit": 165, "res": 12, "preci": 93},
		"skills": [
			{"nom": "Coup Dévastateur", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}], "niveau": 10, "description": "ATK +11 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}, {"effet": "drain", "valeur": 0.35}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi ; rend au lanceur 35 % des dégâts infligés."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 14 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"archer": {
		"nom": "Elf Sylvestre", "rarete": "R", "element": "nature", "role": "tireur", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "008800",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 750, "atk": 220, "def": 80, "agi": 150, "mag": 80},
		"secondaires": {"crit": 13, "degats_crit": 175, "res": 10, "preci": 98},
		"skills": [
			{"nom": "Pluie de Flèches", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 7}], "niveau": 10, "description": "Précision +5 ; Crit +7."},
			{"nom": "Dard Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "poison", "chance": 0.55, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 55 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +14 % ; immunisé à Poison."},
		],
	},
	"mage": {
		"nom": "Sorcier Sombre", "rarete": "SR", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "440088",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 600, "atk": 280, "def": 60, "agi": 90, "mag": 200},
		"secondaires": {"crit": 9, "degats_crit": 170, "res": 26, "preci": 96},
		"skills": [
			{"nom": "Soin Obscur", "type": "actif", "chance": 0.3, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.55}], "niveau": 1, "description": "(30 % de chance par tour) Soigne toute l'équipe de 55 % de puissance de skill."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.16}], "niveau": 10, "description": "MAG +16 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "malediction", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Rituel Interdit", "type": "actif", "chance": 0.2, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.1}, {"effet": "affliction", "nom": "malediction", "chance": 0.5, "duree": 2}], "niveau": 30, "description": "(20 % de chance par tour) Inflige 110 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Malédiction (2 tours)."},
		],
	},
	"clerc": {
		"nom": "Clerc Sacré", "rarete": "SR", "element": "sacre", "role": "soutien", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "00aaff",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 700, "atk": 120, "def": 90, "agi": 110, "mag": 230},
		"secondaires": {"crit": 7, "degats_crit": 160, "res": 29, "preci": 97},
		"skills": [
			{"nom": "Soin Sacré", "type": "actif", "chance": 0.4, "cible": "allie_faible", "effets": [{"effet": "soin", "mult": 1.15}], "niveau": 1, "description": "(40 % de chance par tour) Soigne l'allié le plus blessé de 115 % de puissance de skill."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.2}, {"effet": "stat", "stat": "res", "valeur": 0.13}], "niveau": 10, "description": "Soins prodigués +20 % ; RES +13 %."},
			{"nom": "Bénédiction", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.9}, {"effet": "purification"}], "niveau": 20, "description": "(25 % de chance par tour) Soigne toute l'équipe de 90 % de puissance de skill ; retire les afflictions."},
			{"nom": "Miracle", "type": "actif", "chance": 0.15, "cible": "allies", "effets": [{"effet": "soin", "mult": 1.0}, {"effet": "ressusciter", "valeur": 0.3}], "niveau": 30, "description": "(15 % de chance par tour) Soigne toute l'équipe de 100 % de puissance de skill ; ranime un allié K.O. avec 30 % de ses PV."},
		],
	},
	"squelette": {
		"nom": "Guerrier Squelette", "rarete": "N", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "888888",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 800, "atk": 150, "def": 90, "agi": 110, "mag": 30},
		"secondaires": {"crit": 8, "degats_crit": 160, "res": 10, "preci": 92},
		"skills": [
			{"nom": "Cri d'Effroi", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 3}], "niveau": 1, "description": "(25 % de chance par tour) ATK +20 % pour toute l'équipe (3 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.1}], "niveau": 10, "description": "ATK +10 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}, {"effet": "drain", "valeur": 0.3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi ; rend au lanceur 30 % des dégâts infligés."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 12 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"demon_inf": {
		"nom": "Gardiens d'Ombre", "rarete": "SR", "element": "feu", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "660022",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1200, "atk": 240, "def": 110, "agi": 120, "mag": 100},
		"secondaires": {"crit": 6, "degats_crit": 160, "res": 22, "preci": 92},
		"skills": [
			{"nom": "Frappe Maudite", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.16}, {"effet": "epines", "valeur": 0.08}], "niveau": 10, "description": "DEF +16 % ; renvoie 8 % des dégâts physiques reçus."},
			{"nom": "Bouclier de Braise", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; ATK +20 % pour lui-même (2 tours)."},
			{"nom": "Rempart Infernal", "type": "passif", "effets": [{"effet": "epines", "valeur": 0.2}, {"effet": "stat", "stat": "def", "valeur": 0.1}], "niveau": 30, "description": "Renvoie 20 % des dégâts physiques reçus ; DEF +10 %."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"boss": {
		"nom": "Seigneur Démon", "rarete": "SSR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "aa00aa",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 2500, "atk": 350, "def": 180, "agi": 130, "mag": 180},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Cataclysme", "type": "actif", "chance": 0.4, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.2}], "niveau": 1, "description": "(40 % de chance par tour) Inflige 120 % de puissance de skill à tous les ennemis."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "drain", "valeur": 0.4}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; rend au lanceur 40 % des dégâts infligés."},
			{"nom": "Apocalypse", "type": "actif", "chance": 0.2, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "malediction", "chance": 0.6, "duree": 2}], "niveau": 30, "description": "(20 % de chance par tour) Inflige 150 % de puissance de skill à tous les ennemis ; 60 % de chance d'infliger Malédiction (2 tours)."},
		],
	},

	# ============================================================
	# HÉROS INVOCABLES (Autel d'Invocation)
	# ============================================================
	"rat_geant": {
		"nom": "Rat Géant", "rarete": "N", "element": "nature", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "5a4a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 500, "atk": 90, "def": 50, "agi": 100, "mag": 15},
		"secondaires": {"crit": 8, "degats_crit": 160, "res": 10, "preci": 92},
		"skills": [
			{"nom": "Morsure Enragée", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.4}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 140 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.1}], "niveau": 10, "description": "ATK +10 %."},
			{"nom": "Dard Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "poison", "chance": 0.5, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +12 % ; immunisé à Poison."},
		],
	},
	"gobelin": {
		"nom": "Gobelin Pillard", "rarete": "N", "element": "nature", "role": "assassin", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "3d6b2b",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 520, "atk": 105, "def": 55, "agi": 95, "mag": 20},
		"secondaires": {"crit": 18, "degats_crit": 185, "res": 6, "preci": 96},
		"skills": [
			{"nom": "Coup Sournois", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 8}, {"effet": "stat", "stat": "degats_crit", "valeur": 15}], "niveau": 10, "description": "Crit +8 ; Dégâts crit +15 %."},
			{"nom": "Morsure Vénéneuse", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "poison", "chance": 0.6, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 60 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +12 % ; immunisé à Poison."},
		],
	},
	"loup_gris": {
		"nom": "Loup Gris", "rarete": "N", "element": "nature", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "6d6d6d",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 560, "atk": 120, "def": 60, "agi": 130, "mag": 25},
		"secondaires": {"crit": 8, "degats_crit": 160, "res": 10, "preci": 92},
		"skills": [
			{"nom": "Hurlement de Meute", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 3}], "niveau": 1, "description": "(25 % de chance par tour) ATK +20 % pour toute l'équipe (3 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.1}], "niveau": 10, "description": "ATK +10 %."},
			{"nom": "Dard Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "poison", "chance": 0.5, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +12 % ; immunisé à Poison."},
		],
	},
	"zombie": {
		"nom": "Zombie Errant", "rarete": "N", "element": "tenebres", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "4a5a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 680, "atk": 95, "def": 65, "agi": 65, "mag": 15},
		"secondaires": {"crit": 4, "degats_crit": 150, "res": 18, "preci": 90},
		"skills": [
			{"nom": "Étreinte Putride", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.3}], "niveau": 1, "description": "(25 % de chance par tour) Inflige 130 % de puissance de skill à un ennemi."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.12}, {"effet": "epines", "valeur": 0.06}], "niveau": 10, "description": "DEF +12 % ; renvoie 6 % des dégâts physiques reçus."},
			{"nom": "Voile d'Effroi", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "debuff", "stat": "atk", "valeur": 0.15, "duree": 2}, {"effet": "provocation", "duree": 2, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) ATK -15 % pour tous les ennemis (2 tours) ; attire les attaques ennemies (2 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 12 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"bandit": {
		"nom": "Bandit des Routes", "rarete": "N", "element": "nature", "role": "assassin", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "704214",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 550, "atk": 115, "def": 60, "agi": 110, "mag": 30},
		"secondaires": {"crit": 18, "degats_crit": 185, "res": 6, "preci": 96},
		"skills": [
			{"nom": "Attaque Rapide", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.4}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 140 % de puissance de skill à un ennemi."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 8}, {"effet": "stat", "stat": "degats_crit", "valeur": 15}], "niveau": 10, "description": "Crit +8 ; Dégâts crit +15 %."},
			{"nom": "Morsure Vénéneuse", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "poison", "chance": 0.6, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 60 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +12 % ; immunisé à Poison."},
		],
	},
	"araignee_venin": {
		"nom": "Araignée Venimeuse", "rarete": "N", "element": "nature", "role": "mage", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "2b1a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 500, "atk": 110, "def": 45, "agi": 120, "mag": 35},
		"secondaires": {"crit": 7, "degats_crit": 160, "res": 22, "preci": 94},
		"skills": [
			{"nom": "Crachat Toxique", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.6}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 60 % de puissance de skill à tous les ennemis."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.12}], "niveau": 10, "description": "MAG +12 %."},
			{"nom": "Nuée Toxique", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.6}, {"effet": "affliction", "nom": "poison", "chance": 0.4, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 60 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +12 % ; immunisé à Poison."},
		],
	},
	"chauve_souris_vampire": {
		"nom": "Chauve-Souris Nocturne", "rarete": "N", "element": "tenebres", "role": "assassin", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "3a1a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 480, "atk": 100, "def": 40, "agi": 140, "mag": 30},
		"secondaires": {"crit": 18, "degats_crit": 185, "res": 6, "preci": 96},
		"skills": [
			{"nom": "Vol Erratique", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.3}], "niveau": 1, "description": "(25 % de chance par tour) Inflige 130 % de puissance de skill à un ennemi."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 8}, {"effet": "stat", "stat": "degats_crit", "valeur": 15}], "niveau": 10, "description": "Crit +8 ; Dégâts crit +15 %."},
			{"nom": "Lacération", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "saignement", "chance": 0.6, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 60 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 12 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"limace_acide": {
		"nom": "Limace Acide", "rarete": "N", "element": "eau", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "6bbf3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 600, "atk": 85, "def": 80, "agi": 65, "mag": 20},
		"secondaires": {"crit": 4, "degats_crit": 150, "res": 18, "preci": 90},
		"skills": [
			{"nom": "Projection Acide", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.55}], "niveau": 1, "description": "(25 % de chance par tour) Inflige 55 % de puissance de skill à tous les ennemis."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.12}, {"effet": "epines", "valeur": 0.06}], "niveau": 10, "description": "DEF +12 % ; renvoie 6 % des dégâts physiques reçus."},
			{"nom": "Carapace des Marées", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.15}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "res", "valeur": 0.2, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 15 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; RES +20 % pour lui-même (3 tours)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.04}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 4 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"corbeau_maudit": {
		"nom": "Corbeau Maudit", "rarete": "N", "element": "tenebres", "role": "tireur", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "1a1a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 490, "atk": 105, "def": 45, "agi": 135, "mag": 40},
		"secondaires": {"crit": 12, "degats_crit": 170, "res": 8, "preci": 97},
		"skills": [
			{"nom": "Bec Perçant", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.4}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 140 % de puissance de skill à un ennemi."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 6}], "niveau": 10, "description": "Précision +5 ; Crit +6."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}, {"effet": "drain", "valeur": 0.3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi ; rend au lanceur 30 % des dégâts infligés."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 12 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"sanglier_sauvage": {
		"nom": "Sanglier Sauvage", "rarete": "N", "element": "feu", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "4a2a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 650, "atk": 125, "def": 70, "agi": 80, "mag": 15},
		"secondaires": {"crit": 8, "degats_crit": 160, "res": 10, "preci": 92},
		"skills": [
			{"nom": "Charge Brutale", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.1}], "niveau": 10, "description": "ATK +10 %."},
			{"nom": "Brasier Dévorant", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.75}, {"effet": "affliction", "nom": "brulure", "chance": 0.35, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 75 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.1}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +10 % ; immunisé à Brûlure."},
		],
	},
	"brigand": {
		"nom": "Brigand Ivre", "rarete": "N", "element": "nature", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "8a5a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 570, "atk": 118, "def": 58, "agi": 105, "mag": 25},
		"secondaires": {"crit": 8, "degats_crit": 160, "res": 10, "preci": 92},
		"skills": [
			{"nom": "Coup de Gourdin", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.4}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 140 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.1}], "niveau": 10, "description": "ATK +10 %."},
			{"nom": "Dard Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "poison", "chance": 0.5, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +12 % ; immunisé à Poison."},
		],
	},
	"slime": {
		"nom": "Slime Gélatineux", "rarete": "N", "element": "eau", "role": "soutien", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "3aa8bf",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 620, "atk": 80, "def": 85, "agi": 55, "mag": 20},
		"secondaires": {"crit": 5, "degats_crit": 150, "res": 25, "preci": 95},
		"skills": [
			{"nom": "Absorption", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 1.45}], "niveau": 1, "description": "(25 % de chance par tour) Soigne toute l'équipe de 145 % de puissance de skill."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.15}, {"effet": "stat", "stat": "res", "valeur": 0.1}], "niveau": 10, "description": "Soins prodigués +15 % ; RES +10 %."},
			{"nom": "Source Apaisante", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.7}, {"effet": "purification"}], "niveau": 20, "description": "(25 % de chance par tour) Soigne toute l'équipe de 70 % de puissance de skill ; retire les afflictions."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.04}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 4 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"hyene_des_sables": {
		"nom": "Hyène des Sables", "rarete": "N", "element": "feu", "role": "assassin", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "c2a15c",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 540, "atk": 122, "def": 55, "agi": 125, "mag": 20},
		"secondaires": {"crit": 18, "degats_crit": 185, "res": 6, "preci": 96},
		"skills": [
			{"nom": "Ricanement", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "buff", "stat": "atk", "valeur": 0.15, "duree": 3}], "niveau": 1, "description": "(25 % de chance par tour) ATK +15 % pour toute l'équipe (3 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 8}, {"effet": "stat", "stat": "degats_crit", "valeur": 15}], "niveau": 10, "description": "Crit +8 ; Dégâts crit +15 %."},
			{"nom": "Lame Incandescente", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.1}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +10 % ; immunisé à Brûlure."},
		],
	},
	"serpent_crache": {
		"nom": "Serpent Cracheur", "rarete": "N", "element": "eau", "role": "tireur", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "2a7a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 500, "atk": 112, "def": 48, "agi": 115, "mag": 35},
		"secondaires": {"crit": 12, "degats_crit": 170, "res": 8, "preci": 97},
		"skills": [
			{"nom": "Jet de Venin", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.4}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 140 % de puissance de skill à un ennemi."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 6}], "niveau": 10, "description": "Précision +5 ; Crit +6."},
			{"nom": "Lame de Givre", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "gel", "chance": 0.3, "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 30 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.04}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 4 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"moine_dechu": {
		"nom": "Moine Déchu", "rarete": "N", "element": "tenebres", "role": "soutien", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "5a3a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 620, "atk": 100, "def": 75, "agi": 90, "mag": 60},
		"secondaires": {"crit": 5, "degats_crit": 150, "res": 25, "preci": 95},
		"skills": [
			{"nom": "Prière Brisée", "type": "actif", "chance": 0.25, "cible": "allie_faible", "effets": [{"effet": "soin", "mult": 1.25}], "niveau": 1, "description": "(25 % de chance par tour) Soigne l'allié le plus blessé de 125 % de puissance de skill."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.15}, {"effet": "stat", "stat": "res", "valeur": 0.1}], "niveau": 10, "description": "Soins prodigués +15 % ; RES +10 %."},
			{"nom": "Pacte de Sang", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "buff", "stat": "atk", "valeur": 0.15, "duree": 3}, {"effet": "buff", "stat": "mag", "valeur": 0.15, "duree": 3}, {"effet": "cout_pv", "valeur": 0.1}], "niveau": 20, "description": "(25 % de chance par tour) ATK +15 % pour toute l'équipe (3 tours) ; MAG +15 % pour toute l'équipe (3 tours) ; coûte 10 % de ses PV au lanceur."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 12 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"vautour_charognard": {
		"nom": "Vautour Charognard", "rarete": "N", "element": "nature", "role": "tireur", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "5a4a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 510, "atk": 108, "def": 50, "agi": 130, "mag": 25},
		"secondaires": {"crit": 12, "degats_crit": 170, "res": 8, "preci": 97},
		"skills": [
			{"nom": "Piqué Mortel", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.45}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 145 % de puissance de skill à un ennemi."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 6}], "niveau": 10, "description": "Précision +5 ; Crit +6."},
			{"nom": "Dard Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "poison", "chance": 0.5, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +12 % ; immunisé à Poison."},
		],
	},
	"esprit_frappeur": {
		"nom": "Esprit Frappeur", "rarete": "N", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "9a9aff",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 470, "atk": 115, "def": 40, "agi": 110, "mag": 65},
		"secondaires": {"crit": 7, "degats_crit": 160, "res": 22, "preci": 94},
		"skills": [
			{"nom": "Frappe Spectrale", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.45}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 145 % de puissance de skill à un ennemi."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.12}], "niveau": 10, "description": "MAG +12 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}, {"effet": "affliction", "nom": "malediction", "chance": 0.35, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 12 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"orc_guerrier": {
		"nom": "Orc Guerrier", "rarete": "R", "element": "feu", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "4a6b2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 780, "atk": 150, "def": 95, "agi": 100, "mag": 40},
		"secondaires": {"crit": 9, "degats_crit": 165, "res": 12, "preci": 93},
		"skills": [
			{"nom": "Fureur Verte", "type": "actif", "chance": 0.3, "cible": "allies", "effets": [{"effet": "buff", "stat": "atk", "valeur": 0.25, "duree": 3}], "niveau": 1, "description": "(30 % de chance par tour) ATK +25 % pour toute l'équipe (3 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}], "niveau": 10, "description": "ATK +11 %."},
			{"nom": "Brasier Dévorant", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +11 % ; immunisé à Brûlure."},
		],
	},
	"loup_garou": {
		"nom": "Loup-Garou", "rarete": "R", "element": "feu", "role": "assassin", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "3a3a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 820, "atk": 175, "def": 90, "agi": 155, "mag": 45},
		"secondaires": {"crit": 19, "degats_crit": 190, "res": 8, "preci": 97},
		"skills": [
			{"nom": "Griffes de Lune", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 9}, {"effet": "stat", "stat": "degats_crit", "valeur": 17}], "niveau": 10, "description": "Crit +9 ; Dégâts crit +17 %."},
			{"nom": "Lame Incandescente", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}, {"effet": "affliction", "nom": "brulure", "chance": 0.45, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi ; 45 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +11 % ; immunisé à Brûlure."},
		],
	},
	"spectre_glacial": {
		"nom": "Spectre Glacial", "rarete": "R", "element": "eau", "role": "mage", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "6ab8e0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 720, "atk": 165, "def": 85, "agi": 135, "mag": 90},
		"secondaires": {"crit": 8, "degats_crit": 165, "res": 24, "preci": 95},
		"skills": [
			{"nom": "Souffle Gelé", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.75}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 75 % de puissance de skill à tous les ennemis."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.14}], "niveau": 10, "description": "MAG +14 %."},
			{"nom": "Blizzard", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}, {"effet": "affliction", "nom": "gel", "chance": 0.2, "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis ; 20 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"golem_pierre": {
		"nom": "Golem de Pierre", "rarete": "R", "element": "sacre", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "7a7a6a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 900, "atk": 140, "def": 130, "agi": 60, "mag": 50},
		"secondaires": {"crit": 5, "degats_crit": 155, "res": 20, "preci": 91},
		"skills": [
			{"nom": "Poing de Roc", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.14}, {"effet": "epines", "valeur": 0.07}], "niveau": 10, "description": "DEF +14 % ; renvoie 7 % des dégâts physiques reçus."},
			{"nom": "Égide Sacrée", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.1}, {"effet": "provocation", "duree": 1, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 10 % des PV max sur toute l'équipe ; attire les attaques ennemies (1 tour)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.09}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +9 % ; immunisé à Aveuglement."},
		],
	},
	"harpie": {
		"nom": "Harpie Hurlante", "rarete": "R", "element": "nature", "role": "tireur", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "b08a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 700, "atk": 170, "def": 75, "agi": 160, "mag": 55},
		"secondaires": {"crit": 13, "degats_crit": 175, "res": 10, "preci": 98},
		"skills": [
			{"nom": "Cri Strident", "type": "actif", "chance": 0.3, "cible": "allies", "effets": [{"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 3}], "niveau": 1, "description": "(30 % de chance par tour) ATK +20 % pour toute l'équipe (3 tours)."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 7}], "niveau": 10, "description": "Précision +5 ; Crit +7."},
			{"nom": "Dard Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "poison", "chance": 0.55, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 55 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +14 % ; immunisé à Poison."},
		],
	},
	"chevalier_rouille": {
		"nom": "Chevalier Rouillé", "rarete": "R", "element": "tenebres", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "8a4a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 850, "atk": 155, "def": 120, "agi": 90, "mag": 35},
		"secondaires": {"crit": 5, "degats_crit": 155, "res": 20, "preci": 91},
		"skills": [
			{"nom": "Charge Blindée", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.65}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 165 % de puissance de skill à un ennemi."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.14}, {"effet": "epines", "valeur": 0.07}], "niveau": 10, "description": "DEF +14 % ; renvoie 7 % des dégâts physiques reçus."},
			{"nom": "Voile d'Effroi", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "debuff", "stat": "atk", "valeur": 0.15, "duree": 2}, {"effet": "provocation", "duree": 2, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) ATK -15 % pour tous les ennemis (2 tours) ; attire les attaques ennemies (2 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 14 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"sorciere_bois": {
		"nom": "Sorcière des Bois", "rarete": "R", "element": "nature", "role": "soutien", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "2a5a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 680, "atk": 160, "def": 70, "agi": 110, "mag": 130},
		"secondaires": {"crit": 6, "degats_crit": 155, "res": 27, "preci": 96},
		"skills": [
			{"nom": "Rituel Sylvestre", "type": "actif", "chance": 0.35, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.95}], "niveau": 1, "description": "(35 % de chance par tour) Soigne toute l'équipe de 95 % de puissance de skill."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.17}, {"effet": "stat", "stat": "res", "valeur": 0.11}], "niveau": 10, "description": "Soins prodigués +17 % ; RES +11 %."},
			{"nom": "Floraison", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.55}, {"effet": "regen_temp", "valeur": 0.06, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Soigne toute l'équipe de 55 % de puissance de skill ; régénère 6 % des PV par tour (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +14 % ; immunisé à Poison."},
		],
	},
	"troll_marais": {
		"nom": "Troll des Marais", "rarete": "R", "element": "eau", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "4a5a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 880, "atk": 168, "def": 110, "agi": 75, "mag": 45},
		"secondaires": {"crit": 5, "degats_crit": 155, "res": 20, "preci": 91},
		"skills": [
			{"nom": "Régénération", "type": "actif", "chance": 0.3, "cible": "allie_faible", "effets": [{"effet": "soin", "mult": 1.7}], "niveau": 1, "description": "(30 % de chance par tour) Soigne l'allié le plus blessé de 170 % de puissance de skill."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.14}, {"effet": "epines", "valeur": 0.07}], "niveau": 10, "description": "DEF +14 % ; renvoie 7 % des dégâts physiques reçus."},
			{"nom": "Carapace des Marées", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.15}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "res", "valeur": 0.2, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 15 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; RES +20 % pour lui-même (3 tours)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"gargouille": {
		"nom": "Gargouille Ailée", "rarete": "R", "element": "eau", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "5a5a5a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 790, "atk": 145, "def": 125, "agi": 100, "mag": 60},
		"secondaires": {"crit": 5, "degats_crit": 155, "res": 20, "preci": 91},
		"skills": [
			{"nom": "Plongeon de Pierre", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.14}, {"effet": "epines", "valeur": 0.07}], "niveau": 10, "description": "DEF +14 % ; renvoie 7 % des dégâts physiques reçus."},
			{"nom": "Carapace des Marées", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.15}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "res", "valeur": 0.2, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 15 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; RES +20 % pour lui-même (3 tours)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"assassin_ombre": {
		"nom": "Assassin de l'Ombre", "rarete": "R", "element": "tenebres", "role": "assassin", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "1a1a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 690, "atk": 185, "def": 70, "agi": 170, "mag": 50},
		"secondaires": {"crit": 19, "degats_crit": 190, "res": 8, "preci": 97},
		"skills": [
			{"nom": "Coup Fatal", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 9}, {"effet": "stat", "stat": "degats_crit", "valeur": 17}], "niveau": 10, "description": "Crit +9 ; Dégâts crit +17 %."},
			{"nom": "Lacération", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "saignement", "chance": 0.65, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 65 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 14 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"cyclope": {
		"nom": "Cyclope Borgne", "rarete": "R", "element": "feu", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "8a6a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 900, "atk": 175, "def": 100, "agi": 70, "mag": 30},
		"secondaires": {"crit": 9, "degats_crit": 165, "res": 12, "preci": 93},
		"skills": [
			{"nom": "Écrasement", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}], "niveau": 10, "description": "ATK +11 %."},
			{"nom": "Brasier Dévorant", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +11 % ; immunisé à Brûlure."},
		],
	},
	"minotaure_jeune": {
		"nom": "Jeune Minotaure", "rarete": "R", "element": "feu", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "6b3a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 850, "atk": 180, "def": 95, "agi": 105, "mag": 40},
		"secondaires": {"crit": 9, "degats_crit": 165, "res": 12, "preci": 93},
		"skills": [
			{"nom": "Charge du Labyrinthe", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}], "niveau": 10, "description": "ATK +11 %."},
			{"nom": "Brasier Dévorant", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +11 % ; immunisé à Brûlure."},
		],
	},
	"banshee": {
		"nom": "Banshee Pleureuse", "rarete": "R", "element": "eau", "role": "mage", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "c0c0e0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 660, "atk": 172, "def": 65, "agi": 140, "mag": 95},
		"secondaires": {"crit": 8, "degats_crit": 165, "res": 24, "preci": 95},
		"skills": [
			{"nom": "Lamento Mortel", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.14}], "niveau": 10, "description": "MAG +14 %."},
			{"nom": "Blizzard", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}, {"effet": "affliction", "nom": "gel", "chance": 0.2, "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis ; 20 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"centaure_guerrier": {
		"nom": "Centaure Guerrier", "rarete": "R", "element": "feu", "role": "tireur", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "7a5a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 820, "atk": 165, "def": 105, "agi": 150, "mag": 55},
		"secondaires": {"crit": 13, "degats_crit": 175, "res": 10, "preci": 98},
		"skills": [
			{"nom": "Tir au Galop", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.65}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 165 % de puissance de skill à un ennemi."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 7}], "niveau": 10, "description": "Précision +5 ; Crit +7."},
			{"nom": "Brasier Dévorant", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +11 % ; immunisé à Brûlure."},
		],
	},
	"golem_obsidienne": {
		"nom": "Golem d'Obsidienne", "rarete": "SR", "element": "tenebres", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "1a1a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1100, "atk": 220, "def": 170, "agi": 80, "mag": 90},
		"secondaires": {"crit": 6, "degats_crit": 160, "res": 22, "preci": 92},
		"skills": [
			{"nom": "Éclat Tranchant", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.16}, {"effet": "epines", "valeur": 0.08}], "niveau": 10, "description": "DEF +16 % ; renvoie 8 % des dégâts physiques reçus."},
			{"nom": "Voile d'Effroi", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "debuff", "stat": "atk", "valeur": 0.2, "duree": 2}, {"effet": "provocation", "duree": 2, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) ATK -20 % pour tous les ennemis (2 tours) ; attire les attaques ennemies (2 tours)."},
			{"nom": "Cœur d'Obsidienne", "type": "passif", "effets": [{"effet": "survie", "charges": 1}, {"effet": "stat", "stat": "def", "valeur": 0.1}], "niveau": 30, "description": "Survit à un coup fatal avec 1 PV (1 fois par combat) ; DEF +10 %."},
		],
	},
	"liche_mineure": {
		"nom": "Liche Mineure", "rarete": "SR", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "2a6a4a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 950, "atk": 250, "def": 120, "agi": 130, "mag": 160},
		"secondaires": {"crit": 9, "degats_crit": 170, "res": 26, "preci": 96},
		"skills": [
			{"nom": "Drain de Vie", "type": "actif", "chance": 0.35, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.85}], "niveau": 1, "description": "(35 % de chance par tour) Soigne toute l'équipe de 85 % de puissance de skill."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.16}], "niveau": 10, "description": "MAG +16 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "malediction", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Moisson d'Âmes", "type": "passif", "effets": [{"effet": "accumulation", "stat": "mag", "valeur": 0.1, "max": 3}], "niveau": 30, "description": "Chaque ennemi vaincu : MAG +10 % (max 3 fois)."},
		],
	},
	"chimere": {
		"nom": "Chimère Enragée", "rarete": "SR", "element": "nature", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "8a3a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1050, "atk": 240, "def": 140, "agi": 150, "mag": 100},
		"secondaires": {"crit": 10, "degats_crit": 170, "res": 14, "preci": 94},
		"skills": [
			{"nom": "Triple Assaut", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.95}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 95 % de puissance de skill à tous les ennemis."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.13}], "niveau": 10, "description": "ATK +13 %."},
			{"nom": "Dard Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}, {"effet": "affliction", "nom": "poison", "chance": 0.6, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi ; 60 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Trois Têtes", "type": "passif", "effets": [{"effet": "double_attaque", "chance": 0.25}], "niveau": 30, "description": "25 % de chance d'attaquer deux fois."},
		],
	},
	"seraphin_dechu": {
		"nom": "Séraphin Déchu", "rarete": "SR", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "3a1a4a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1000, "atk": 245, "def": 130, "agi": 160, "mag": 150},
		"secondaires": {"crit": 9, "degats_crit": 170, "res": 26, "preci": 96},
		"skills": [
			{"nom": "Jugement Sombre", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.16}], "niveau": 10, "description": "MAG +16 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "malediction", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Chute des Anges", "type": "actif", "chance": 0.2, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.4, "ignore_res": 0.3}, {"effet": "affliction", "nom": "silence", "chance": 0.6, "duree": 2}], "niveau": 30, "description": "(20 % de chance par tour) Inflige 240 % de puissance de skill à un ennemi, en ignorant 30 % de la RES ; 60 % de chance d'infliger Silence (2 tours)."},
		],
	},
	"hydre_jeune": {
		"nom": "Jeune Hydre", "rarete": "SR", "element": "eau", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "2a6a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1150, "atk": 230, "def": 150, "agi": 110, "mag": 90},
		"secondaires": {"crit": 6, "degats_crit": 160, "res": 22, "preci": 92},
		"skills": [
			{"nom": "Morsures Multiples", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.0}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 100 % de puissance de skill à tous les ennemis."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.16}, {"effet": "epines", "valeur": 0.08}], "niveau": 10, "description": "DEF +16 % ; renvoie 8 % des dégâts physiques reçus."},
			{"nom": "Carapace des Marées", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "res", "valeur": 0.25, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; RES +25 % pour lui-même (3 tours)."},
			{"nom": "Têtes Renaissantes", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.06}], "niveau": 30, "description": "Régénère 6 % de ses PV max à chaque tour."},
		],
	},
	"demon_flamme": {
		"nom": "Démon de Flamme", "rarete": "SR", "element": "feu", "role": "mage", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "cc4400",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 980, "atk": 260, "def": 125, "agi": 140, "mag": 110},
		"secondaires": {"crit": 9, "degats_crit": 170, "res": 26, "preci": 96},
		"skills": [
			{"nom": "Explosion Infernale", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.05}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 105 % de puissance de skill à tous les ennemis."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.16}], "niveau": 10, "description": "MAG +16 %."},
			{"nom": "Pluie de Braises", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "brulure", "chance": 0.35, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Enfer Déchaîné", "type": "actif", "chance": 0.2, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.2}, {"effet": "affliction", "nom": "brulure", "chance": 0.6, "duree": 3}], "niveau": 30, "description": "(20 % de chance par tour) Inflige 120 % de puissance de skill à tous les ennemis ; 60 % de chance d'infliger Brûlure (3 tours)."},
		],
	},
	"reine_araignee": {
		"nom": "Reine Araignée", "rarete": "SR", "element": "nature", "role": "assassin", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "4a1a5a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 920, "atk": 235, "def": 115, "agi": 155, "mag": 120},
		"secondaires": {"crit": 20, "degats_crit": 195, "res": 10, "preci": 98},
		"skills": [
			{"nom": "Toile Mortelle", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.95}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 195 % de puissance de skill à un ennemi."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 10}, {"effet": "stat", "stat": "degats_crit", "valeur": 20}], "niveau": 10, "description": "Crit +10 ; Dégâts crit +20 %."},
			{"nom": "Morsure Vénéneuse", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}, {"effet": "affliction", "nom": "poison", "chance": 0.7, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi ; 70 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Cocon Mortel", "type": "actif", "chance": 0.2, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "affliction", "nom": "etourdi", "chance": 0.4, "duree": 1}], "niveau": 30, "description": "(20 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Étourdissement (1 tour)."},
		],
	},
	"wyverne": {
		"nom": "Wyverne Sauvage", "rarete": "SR", "element": "nature", "role": "tireur", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "3a6a8a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1080, "atk": 255, "def": 145, "agi": 165, "mag": 95},
		"secondaires": {"crit": 14, "degats_crit": 180, "res": 12, "preci": 99},
		"skills": [
			{"nom": "Piqué Venimeux", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 8}], "niveau": 10, "description": "Précision +5 ; Crit +8."},
			{"nom": "Dard Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}, {"effet": "affliction", "nom": "poison", "chance": 0.6, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi ; 60 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Chasse Aérienne", "type": "passif", "effets": [{"effet": "bonus_arriere", "valeur": 0.3}], "niveau": 30, "description": "+30 % de dégâts contre les ennemis de l'Arrière."},
		],
	},
	"lapin_pyromane": {
		"nom": "Lapin Pyromane", "rarete": "SR", "element": "feu", "role": "assassin", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "ff5500",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 950, "atk": 250, "def": 120, "agi": 175, "mag": 105},
		"secondaires": {"crit": 20, "degats_crit": 195, "res": 10, "preci": 98},
		"skills": [
			{"nom": "Carotte Explosive", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.95}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 195 % de puissance de skill à un ennemi."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 10}, {"effet": "stat", "stat": "degats_crit", "valeur": 20}], "niveau": 10, "description": "Crit +10 ; Dégâts crit +20 %."},
			{"nom": "Lame Incandescente", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}, {"effet": "affliction", "nom": "brulure", "chance": 0.5, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Feu d'Artifice", "type": "actif", "chance": 0.2, "cible": "aleatoire", "effets": [{"effet": "degats", "mult": 0.7, "coups": 4}, {"effet": "affliction", "nom": "brulure", "chance": 0.25, "duree": 2}], "niveau": 30, "description": "(20 % de chance par tour) Frappe 4 fois des ennemis au hasard (70 % de puissance de skill par coup) ; 25 % de chance d'infliger Brûlure (2 tours)."},
		],
	},
	"dragon_ombre": {
		"nom": "Dragon d'Ombre", "rarete": "SSR", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "1a0a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1450, "atk": 300, "def": 190, "agi": 180, "mag": 160},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Souffle Ténébreux", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.15}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 115 % de puissance de skill à tous les ennemis."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "malediction", "chance": 0.45, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 45 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Éclipse Draconique", "type": "actif", "chance": 0.2, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "malediction", "chance": 0.5, "duree": 2}, {"effet": "affliction", "nom": "aveugle", "chance": 0.4, "duree": 2}], "niveau": 30, "description": "(20 % de chance par tour) Inflige 150 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Malédiction (2 tours) ; 40 % de chance d'infliger Aveuglement (2 tours)."},
		],
	},
	"archange_noir": {
		"nom": "Archange Noir", "rarete": "SSR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "0a0a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1300, "atk": 290, "def": 200, "agi": 200, "mag": 210},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Châtiment Céleste", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 220 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "drain", "valeur": 0.4}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; rend au lanceur 40 % des dégâts infligés."},
			{"nom": "Ailes du Jugement", "type": "passif", "effets": [{"effet": "contre", "chance": 0.25, "mult": 1.2}, {"effet": "stat", "stat": "crit", "valeur": 10}], "niveau": 30, "description": "25 % de chance de contre-attaquer (120 % d'ATK) ; Crit +10."},
		],
	},
	"titan_abysses": {
		"nom": "Titan des Abysses", "rarete": "SSR", "element": "eau", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "0a2a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1600, "atk": 280, "def": 230, "agi": 160, "mag": 140},
		"secondaires": {"crit": 7, "degats_crit": 165, "res": 24, "preci": 93},
		"skills": [
			{"nom": "Raz-de-Marée", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.1}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 110 % de puissance de skill à tous les ennemis."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.17}, {"effet": "epines", "valeur": 0.09}], "niveau": 10, "description": "DEF +17 % ; renvoie 9 % des dégâts physiques reçus."},
			{"nom": "Carapace des Marées", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "res", "valeur": 0.25, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; RES +25 % pour lui-même (3 tours)."},
			{"nom": "Marée Titanesque", "type": "actif", "chance": 0.2, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2, "cible": "soi"}], "niveau": 30, "description": "(20 % de chance par tour) Bouclier de 20 % des PV max sur toute l'équipe ; attire les attaques ennemies (2 tours)."},
		],
	},
	"reine_liches": {
		"nom": "Reine des Liches", "rarete": "SSR", "element": "tenebres", "role": "soutien", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "2a0a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1350, "atk": 310, "def": 180, "agi": 170, "mag": 220},
		"secondaires": {"crit": 8, "degats_crit": 165, "res": 31, "preci": 98},
		"skills": [
			{"nom": "Résurrection Noire", "type": "actif", "chance": 0.4, "cible": "allies", "effets": [{"effet": "soin", "mult": 1.0}], "niveau": 1, "description": "(40 % de chance par tour) Soigne toute l'équipe de 100 % de puissance de skill."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.22}, {"effet": "stat", "stat": "res", "valeur": 0.14}], "niveau": 10, "description": "Soins prodigués +22 % ; RES +14 %."},
			{"nom": "Pacte de Sang", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 3}, {"effet": "buff", "stat": "mag", "valeur": 0.2, "duree": 3}, {"effet": "cout_pv", "valeur": 0.1}], "niveau": 20, "description": "(25 % de chance par tour) ATK +20 % pour toute l'équipe (3 tours) ; MAG +20 % pour toute l'équipe (3 tours) ; coûte 10 % de ses PV au lanceur."},
			{"nom": "Armée des Morts", "type": "actif", "chance": 0.15, "cible": "allies", "effets": [{"effet": "ressusciter", "valeur": 0.5}, {"effet": "buff", "stat": "mag", "valeur": 0.2, "duree": 3}], "niveau": 30, "description": "(15 % de chance par tour) Ranime un allié K.O. avec 50 % de ses PV ; MAG +20 % pour toute l'équipe (3 tours)."},
		],
	},
	"chat_des_abysses": {
		"nom": "Chat des Abysses", "rarete": "SSR", "element": "eau", "role": "assassin", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "005588",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1320, "atk": 285, "def": 185, "agi": 220, "mag": 190},
		"secondaires": {"crit": 21, "degats_crit": 200, "res": 12, "preci": 99},
		"skills": [
			{"nom": "Griffe Glaciale", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.1}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 210 % de puissance de skill à un ennemi."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 12}, {"effet": "stat", "stat": "degats_crit", "valeur": 22}], "niveau": 10, "description": "Crit +12 ; Dégâts crit +22 %."},
			{"nom": "Estoc Glacé", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "gel", "chance": 0.3, "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 30 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Neuf Vies", "type": "passif", "effets": [{"effet": "survie", "charges": 2}, {"effet": "stat", "stat": "crit", "valeur": 15}], "niveau": 30, "description": "Survit à un coup fatal avec 1 PV (2 fois par combat) ; Crit +15."},
		],
	},
	"chien_sylvestre": {
		"nom": "Chien Sylvestre", "rarete": "SSR", "element": "nature", "role": "soutien", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "228833",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1420, "atk": 295, "def": 210, "agi": 190, "mag": 170},
		"secondaires": {"crit": 8, "degats_crit": 165, "res": 31, "preci": 98},
		"skills": [
			{"nom": "Hurlement Verdoyant", "type": "actif", "chance": 0.3, "cible": "allies", "effets": [{"effet": "soin", "mult": 1.1}], "niveau": 1, "description": "(30 % de chance par tour) Soigne toute l'équipe de 110 % de puissance de skill."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.22}, {"effet": "stat", "stat": "res", "valeur": 0.14}], "niveau": 10, "description": "Soins prodigués +22 % ; RES +14 %."},
			{"nom": "Floraison", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.6}, {"effet": "regen_temp", "valeur": 0.07, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Soigne toute l'équipe de 60 % de puissance de skill ; régénère 7 % des PV par tour (3 tours)."},
			{"nom": "Meute Protectrice", "type": "passif", "effets": [{"effet": "aura", "stat": "pv", "valeur": 0.1}, {"effet": "aura", "stat": "def", "valeur": 0.1}], "niveau": 30, "description": "Toute l'équipe : PV +10 % ; toute l'équipe : DEF +10 %."},
		],
	},
	"phenix_immortel": {
		"nom": "Phénix Immortel", "rarete": "UR", "element": "feu", "role": "soutien", "position": "arriere",
		"invocable": true, "categorie": "heros", "couleur": "ff6600",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1800, "atk": 360, "def": 230, "agi": 260, "mag": 240},
		"secondaires": {"crit": 9, "degats_crit": 170, "res": 33, "preci": 99},
		"skills": [
			{"nom": "Renaissance Ardente", "type": "actif", "chance": 0.4, "cible": "allies", "effets": [{"effet": "soin", "mult": 1.1}], "niveau": 1, "description": "(40 % de chance par tour) Soigne toute l'équipe de 110 % de puissance de skill."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.24}, {"effet": "stat", "stat": "res", "valeur": 0.16}], "niveau": 10, "description": "Soins prodigués +24 % ; RES +16 %."},
			{"nom": "Flamme Ravivante", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.75}, {"effet": "buff", "stat": "atk", "valeur": 0.15, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Soigne toute l'équipe de 75 % de puissance de skill ; ATK +15 % pour toute l'équipe (2 tours)."},
			{"nom": "Cendres Éternelles", "type": "passif", "effets": [{"effet": "renaissance", "valeur": 0.5}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "Renaît une fois par combat avec 50 % de ses PV ; immunisé à Brûlure."},
		],
	},
	"leviathan_abyssal": {
		"nom": "Léviathan Abyssal", "rarete": "UR", "element": "eau", "role": "tank", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "003355",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 2000, "atk": 380, "def": 260, "agi": 200, "mag": 220},
		"secondaires": {"crit": 8, "degats_crit": 170, "res": 26, "preci": 94},
		"skills": [
			{"nom": "Raz-de-Marée Titanesque", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 130 % de puissance de skill à tous les ennemis."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.19}, {"effet": "epines", "valeur": 0.1}], "niveau": 10, "description": "DEF +19 % ; renvoie 10 % des dégâts physiques reçus."},
			{"nom": "Carapace des Marées", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "res", "valeur": 0.3, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; RES +30 % pour lui-même (3 tours)."},
			{"nom": "Abysse Sans Fond", "type": "actif", "chance": 0.2, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.4}, {"effet": "affliction", "nom": "gel", "chance": 0.5, "duree": 1}, {"effet": "bouclier", "valeur": 0.15, "cible": "soi"}], "niveau": 30, "description": "(20 % de chance par tour) Inflige 140 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Gel (1 tour) ; bouclier de 15 % des PV max sur lui-même."},
		],
	},
	"empereur_dechu": {
		"nom": "Empereur Déchu", "rarete": "UR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "330011",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1750, "atk": 400, "def": 240, "agi": 230, "mag": 200},
		"secondaires": {"crit": 12, "degats_crit": 180, "res": 18, "preci": 96},
		"skills": [
			{"nom": "Édit de Destruction", "type": "actif", "chance": 0.4, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.5}], "niveau": 1, "description": "(40 % de chance par tour) Inflige 250 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.16}], "niveau": 10, "description": "ATK +16 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.1}, {"effet": "drain", "valeur": 0.4}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 210 % de puissance de skill à un ennemi ; rend au lanceur 40 % des dégâts infligés."},
			{"nom": "Décret Impérial", "type": "passif", "effets": [{"effet": "aura", "stat": "atk", "valeur": 0.15}, {"effet": "aura_ennemis", "stat": "def", "valeur": 0.1}], "niveau": 30, "description": "Toute l'équipe : ATK +15 % ; tous les ennemis : DEF -10 %."},
		],
	},
	"cheval_sacre": {
		"nom": "Cheval Céleste", "rarete": "UR", "element": "sacre", "role": "guerrier", "position": "avant",
		"invocable": true, "categorie": "heros", "couleur": "ffd700",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1850, "atk": 350, "def": 250, "agi": 280, "mag": 270},
		"secondaires": {"crit": 12, "degats_crit": 180, "res": 18, "preci": 96},
		"skills": [
			{"nom": "Charge Divine", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 230 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.16}], "niveau": 10, "description": "ATK +16 %."},
			{"nom": "Lance de Lumière", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "affliction", "nom": "aveugle", "chance": 0.55, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; 55 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Galop Céleste", "type": "passif", "effets": [{"effet": "premier"}, {"effet": "stat", "stat": "agi", "valeur": 0.2}], "niveau": 30, "description": "Agit toujours en premier au 1er tour ; AGI +20 %."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"gobelin_maraudeur": {
		"nom": "Gobelin Maraudeur", "rarete": "N", "element": "nature", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "3d6b2b",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 580, "atk": 110, "def": 60, "agi": 95, "mag": 25},
		"secondaires": {"crit": 18, "degats_crit": 185, "res": 6, "preci": 96},
		"skills": [
			{"nom": "Pillage Rapide", "type": "actif", "chance": 0.28, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.3}], "niveau": 1, "description": "(28 % de chance par tour) Inflige 130 % de puissance de skill à un ennemi."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 8}, {"effet": "stat", "stat": "degats_crit", "valeur": 15}], "niveau": 10, "description": "Crit +8 ; Dégâts crit +15 %."},
			{"nom": "Morsure Vénéneuse", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "poison", "chance": 0.6, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 60 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +12 % ; immunisé à Poison."},
		],
	},
	"loup_affame": {
		"nom": "Loup Affamé", "rarete": "N", "element": "nature", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "555555",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 600, "atk": 120, "def": 55, "agi": 105, "mag": 20},
		"secondaires": {"crit": 8, "degats_crit": 160, "res": 10, "preci": 92},
		"skills": [
			{"nom": "Morsure Vorace", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.35}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 135 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.1}], "niveau": 10, "description": "ATK +10 %."},
			{"nom": "Dard Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "poison", "chance": 0.5, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +12 % ; immunisé à Poison."},
		],
	},
	"rat_corrompu": {
		"nom": "Rat Corrompu", "rarete": "N", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "4a3a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 560, "atk": 100, "def": 50, "agi": 100, "mag": 20},
		"secondaires": {"crit": 7, "degats_crit": 160, "res": 22, "preci": 94},
		"skills": [
			{"nom": "Fièvre Rampante", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.5}], "niveau": 1, "description": "(25 % de chance par tour) Inflige 50 % de puissance de skill à tous les ennemis."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.12}], "niveau": 10, "description": "MAG +12 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}, {"effet": "affliction", "nom": "malediction", "chance": 0.35, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 12 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"zombie_enrage": {
		"nom": "Zombie Enragé", "rarete": "R", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "4a5a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 760, "atk": 150, "def": 95, "agi": 100, "mag": 40},
		"secondaires": {"crit": 9, "degats_crit": 165, "res": 12, "preci": 93},
		"skills": [
			{"nom": "Assaut Putride", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}], "niveau": 10, "description": "ATK +11 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}, {"effet": "drain", "valeur": 0.35}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi ; rend au lanceur 35 % des dégâts infligés."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 14 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"brigand_cagoule": {
		"nom": "Brigand Cagoulé", "rarete": "R", "element": "nature", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "333333",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 740, "atk": 160, "def": 85, "agi": 130, "mag": 50},
		"secondaires": {"crit": 19, "degats_crit": 190, "res": 8, "preci": 97},
		"skills": [
			{"nom": "Frappe Sournoise", "type": "actif", "chance": 0.32, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}], "niveau": 1, "description": "(32 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 9}, {"effet": "stat", "stat": "degats_crit", "valeur": 17}], "niveau": 10, "description": "Crit +9 ; Dégâts crit +17 %."},
			{"nom": "Morsure Vénéneuse", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "poison", "chance": 0.65, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 65 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +14 % ; immunisé à Poison."},
		],
	},
	"araignee_geante": {
		"nom": "Araignée Géante", "rarete": "R", "element": "nature", "role": "tireur", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "2a1a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 780, "atk": 155, "def": 90, "agi": 120, "mag": 60},
		"secondaires": {"crit": 13, "degats_crit": 175, "res": 10, "preci": 98},
		"skills": [
			{"nom": "Toile Empoisonnée", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 7}], "niveau": 10, "description": "Précision +5 ; Crit +7."},
			{"nom": "Dard Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "poison", "chance": 0.55, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 55 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +14 % ; immunisé à Poison."},
		],
	},
	"golem_fissure": {
		"nom": "Golem Fissuré", "rarete": "SR", "element": "nature", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "6a6a5a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 960, "atk": 190, "def": 150, "agi": 70, "mag": 70},
		"secondaires": {"crit": 6, "degats_crit": 160, "res": 22, "preci": 92},
		"skills": [
			{"nom": "Éclat de Pierre", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.16}, {"effet": "epines", "valeur": 0.08}], "niveau": 10, "description": "DEF +16 % ; renvoie 8 % des dégâts physiques reçus."},
			{"nom": "Écorce Ancestrale", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "buff", "stat": "def", "valeur": 0.2, "duree": 3}, {"effet": "provocation", "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) DEF +20 % pour toute l'équipe (3 tours) ; attire les attaques ennemies (1 tour)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.16}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +16 % ; immunisé à Poison."},
		],
	},
	"harpie_sanglante": {
		"nom": "Harpie Sanglante", "rarete": "SR", "element": "tenebres", "role": "tireur", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "9a2a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 920, "atk": 210, "def": 110, "agi": 160, "mag": 80},
		"secondaires": {"crit": 14, "degats_crit": 180, "res": 12, "preci": 99},
		"skills": [
			{"nom": "Plongeon Sanglant", "type": "actif", "chance": 0.32, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.85}], "niveau": 1, "description": "(32 % de chance par tour) Inflige 185 % de puissance de skill à un ennemi."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 8}], "niveau": 10, "description": "Précision +5 ; Crit +8."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "drain", "valeur": 0.35}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; rend au lanceur 35 % des dégâts infligés."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.16}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 16 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"ombre_rampante": {
		"nom": "Ombre Rampante", "rarete": "SR", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "1a1a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 900, "atk": 200, "def": 100, "agi": 150, "mag": 100},
		"secondaires": {"crit": 9, "degats_crit": 170, "res": 26, "preci": 96},
		"skills": [
			{"nom": "Étreinte des Ténèbres", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.9}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 90 % de puissance de skill à tous les ennemis."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.16}], "niveau": 10, "description": "MAG +16 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "malediction", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.16}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 16 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"spectre_vengeur": {
		"nom": "Spectre Vengeur", "rarete": "SR", "element": "tenebres", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "5a7a9a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1100, "atk": 230, "def": 150, "agi": 180, "mag": 130},
		"secondaires": {"crit": 20, "degats_crit": 195, "res": 10, "preci": 98},
		"skills": [
			{"nom": "Vengeance Spectrale", "type": "actif", "chance": 0.32, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.95}], "niveau": 1, "description": "(32 % de chance par tour) Inflige 195 % de puissance de skill à un ennemi."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 10}, {"effet": "stat", "stat": "degats_crit", "valeur": 20}], "niveau": 10, "description": "Crit +10 ; Dégâts crit +20 %."},
			{"nom": "Lacération", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}, {"effet": "affliction", "nom": "saignement", "chance": 0.7, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi ; 70 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.16}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 16 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"troll_cavernes": {
		"nom": "Troll des Cavernes", "rarete": "SR", "element": "eau", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "4a5a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1200, "atk": 220, "def": 180, "agi": 90, "mag": 90},
		"secondaires": {"crit": 6, "degats_crit": 160, "res": 22, "preci": 92},
		"skills": [
			{"nom": "Régénération Souterraine", "type": "actif", "chance": 0.3, "cible": "allies", "effets": [{"effet": "soin", "mult": 1.0}], "niveau": 1, "description": "(30 % de chance par tour) Soigne toute l'équipe de 100 % de puissance de skill."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.16}, {"effet": "epines", "valeur": 0.08}], "niveau": 10, "description": "DEF +16 % ; renvoie 8 % des dégâts physiques reçus."},
			{"nom": "Carapace des Marées", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "res", "valeur": 0.25, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; RES +25 % pour lui-même (3 tours)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"cyclope_furieux": {
		"nom": "Cyclope Furieux", "rarete": "SR", "element": "feu", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "7a5a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1150, "atk": 245, "def": 165, "agi": 100, "mag": 60},
		"secondaires": {"crit": 10, "degats_crit": 170, "res": 14, "preci": 94},
		"skills": [
			{"nom": "Écrasement Rageur", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.95}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 95 % de puissance de skill à tous les ennemis."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.13}], "niveau": 10, "description": "ATK +13 %."},
			{"nom": "Brasier Dévorant", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.13}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +13 % ; immunisé à Brûlure."},
		],
	},
	"demon_mineur": {
		"nom": "Démon Mineur", "rarete": "SSR", "element": "feu", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "8a1a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1300, "atk": 270, "def": 190, "agi": 190, "mag": 150},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Flammes Infernales", "type": "actif", "chance": 0.32, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.05}], "niveau": 1, "description": "(32 % de chance par tour) Inflige 105 % de puissance de skill à tous les ennemis."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Pluie de Braises", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +14 % ; immunisé à Brûlure."},
		],
	},
	"liche_novice": {
		"nom": "Liche Novice", "rarete": "SSR", "element": "tenebres", "role": "soutien", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "2a6a5a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1280, "atk": 265, "def": 175, "agi": 170, "mag": 200},
		"secondaires": {"crit": 8, "degats_crit": 165, "res": 31, "preci": 98},
		"skills": [
			{"nom": "Malédiction Drainante", "type": "actif", "chance": 0.35, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.8}], "niveau": 1, "description": "(35 % de chance par tour) Soigne toute l'équipe de 80 % de puissance de skill."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.22}, {"effet": "stat", "stat": "res", "valeur": 0.14}], "niveau": 10, "description": "Soins prodigués +22 % ; RES +14 %."},
			{"nom": "Pacte de Sang", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 3}, {"effet": "buff", "stat": "mag", "valeur": 0.2, "duree": 3}, {"effet": "cout_pv", "valeur": 0.1}], "niveau": 20, "description": "(25 % de chance par tour) ATK +20 % pour toute l'équipe (3 tours) ; MAG +20 % pour toute l'équipe (3 tours) ; coûte 10 % de ses PV au lanceur."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.17}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 17 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"gargouille_jade": {
		"nom": "Gargouille de Jade", "rarete": "SSR", "element": "sacre", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "2a8a5a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1350, "atk": 255, "def": 210, "agi": 160, "mag": 120},
		"secondaires": {"crit": 7, "degats_crit": 165, "res": 24, "preci": 93},
		"skills": [
			{"nom": "Éclat de Jade", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.17}, {"effet": "epines", "valeur": 0.09}], "niveau": 10, "description": "DEF +17 % ; renvoie 9 % des dégâts physiques reçus."},
			{"nom": "Égide Sacrée", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.15}, {"effet": "provocation", "duree": 1, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 15 % des PV max sur toute l'équipe ; attire les attaques ennemies (1 tour)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +12 % ; immunisé à Aveuglement."},
		],
	},
	"chevalier_dechu": {
		"nom": "Chevalier Déchu", "rarete": "SSR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "3a1a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1500, "atk": 300, "def": 220, "agi": 170, "mag": 110},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Serment Brisé", "type": "actif", "chance": 0.32, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.1}], "niveau": 1, "description": "(32 % de chance par tour) Inflige 210 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "drain", "valeur": 0.4}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; rend au lanceur 40 % des dégâts infligés."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.17}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 17 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"hydre_bicephale": {
		"nom": "Hydre Bicéphale", "rarete": "SSR", "element": "eau", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "1a5a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1600, "atk": 310, "def": 210, "agi": 150, "mag": 130},
		"secondaires": {"crit": 7, "degats_crit": 165, "res": 24, "preci": 93},
		"skills": [
			{"nom": "Double Morsure", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.1}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 110 % de puissance de skill à tous les ennemis."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.17}, {"effet": "epines", "valeur": 0.09}], "niveau": 10, "description": "DEF +17 % ; renvoie 9 % des dégâts physiques reçus."},
			{"nom": "Carapace des Marées", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "res", "valeur": 0.25, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; RES +25 % pour lui-même (3 tours)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.06}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 6 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"vouivre_ecarlate": {
		"nom": "Vouivre Écarlate", "rarete": "SSR", "element": "feu", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "aa1a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1550, "atk": 320, "def": 200, "agi": 220, "mag": 140},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Souffle Écarlate", "type": "actif", "chance": 0.32, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.15}], "niveau": 1, "description": "(32 % de chance par tour) Inflige 115 % de puissance de skill à tous les ennemis."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Pluie de Braises", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +14 % ; immunisé à Brûlure."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"gardien_foret": {
		"nom": "Gardien de la Forêt Maudite", "rarete": "SR", "element": "sacre", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "114411",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1450, "atk": 260, "def": 170, "agi": 120, "mag": 110},
		"secondaires": {"crit": 6, "degats_crit": 160, "res": 22, "preci": 92},
		"skills": [
			{"nom": "Racines Étrangleuses", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.0}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 100 % de puissance de skill à tous les ennemis."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.16}, {"effet": "epines", "valeur": 0.08}], "niveau": 10, "description": "DEF +16 % ; renvoie 8 % des dégâts physiques reçus."},
			{"nom": "Égide Sacrée", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.1}, {"effet": "provocation", "duree": 1, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 10 % des PV max sur toute l'équipe ; attire les attaques ennemies (1 tour)."},
			{"nom": "Forêt Éternelle", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "epines", "valeur": 0.15}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; renvoie 15 % des dégâts physiques reçus."},
		],
	},
	"seigneur_donjon": {
		"nom": "Seigneur du Donjon Maudit", "rarete": "SSR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "441144",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Réveil du Gardien", "texte": "Le Seigneur du Donjon puise dans la puissance du sépulcre."},
		"stats": {"pv": 1950, "atk": 310, "def": 210, "agi": 150, "mag": 150},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Jugement du Donjon", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 220 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "drain", "valeur": 0.4}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; rend au lanceur 40 % des dégâts infligés."},
			{"nom": "Tyrannie", "type": "passif", "effets": [{"effet": "execution", "valeur": 0.3}, {"effet": "rage", "stat": "atk", "valeur": 0.2}], "niveau": 30, "description": "+30 % de dégâts contre les cibles sous 50 % de PV ; sous 50 % de PV : ATK +20 %."},
		],
	},
	"seigneur_des_cendres": {
		"nom": "Seigneur des Cendres", "rarete": "SSR", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "552200",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Le Brasier Renaît", "texte": "Les cendres s'embrasent : le Seigneur des Cendres entre en fureur !"},
		"stats": {"pv": 2100, "atk": 330, "def": 230, "agi": 160, "mag": 170},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Cendres Ardentes", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 120 % de puissance de skill à tous les ennemis."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "malediction", "chance": 0.45, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 45 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Pluie de Cendres", "type": "actif", "chance": 0.2, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.4}, {"effet": "affliction", "nom": "brulure", "chance": 0.7, "duree": 3}], "niveau": 30, "description": "(20 % de chance par tour) Inflige 140 % de puissance de skill à tous les ennemis ; 70 % de chance d'infliger Brûlure (3 tours)."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"pillard_incendiaire": {
		"nom": "Pillard Incendiaire", "rarete": "N", "element": "feu", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "aa4411",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 560, "atk": 120, "def": 60, "agi": 100, "mag": 20},
		"secondaires": {"crit": 8, "degats_crit": 160, "res": 10, "preci": 92},
		"skills": [
			{"nom": "Torche Enflammée", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.4}, {"effet": "affliction", "nom": "brulure", "chance": 0.3, "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 140 % de puissance de skill à un ennemi ; 30 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.1}], "niveau": 10, "description": "ATK +10 %."},
			{"nom": "Brasier Dévorant", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.75}, {"effet": "affliction", "nom": "brulure", "chance": 0.35, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 75 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.1}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +10 % ; immunisé à Brûlure."},
		],
	},
	"patrouilleur_vautour": {
		"nom": "Patrouilleur Vautour", "rarete": "N", "element": "nature", "role": "tireur", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "6a5a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 475, "atk": 125, "def": 45, "agi": 120, "mag": 30},
		"secondaires": {"crit": 12, "degats_crit": 170, "res": 8, "preci": 97},
		"skills": [
			{"nom": "Carreau Vicieux", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 6}], "niveau": 10, "description": "Précision +5 ; Crit +6."},
			{"nom": "Dard Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "poison", "chance": 0.5, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +12 % ; immunisé à Poison."},
		],
	},
	"profanateur_tombes": {
		"nom": "Profanateur de Tombes", "rarete": "N", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "3a2a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 450, "atk": 100, "def": 40, "agi": 100, "mag": 65},
		"secondaires": {"crit": 7, "degats_crit": 160, "res": 22, "preci": 94},
		"skills": [
			{"nom": "Poussière Maudite", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.55}, {"effet": "affliction", "nom": "malediction", "chance": 0.25, "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 55 % de puissance de skill à tous les ennemis ; 25 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.12}], "niveau": 10, "description": "MAG +12 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}, {"effet": "affliction", "nom": "malediction", "chance": 0.35, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 12 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"pestifere_errant": {
		"nom": "Pestiféré Errant", "rarete": "N", "element": "nature", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "5a6a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 730, "atk": 90, "def": 85, "agi": 70, "mag": 25},
		"secondaires": {"crit": 4, "degats_crit": 150, "res": 18, "preci": 90},
		"skills": [
			{"nom": "Toux Contagieuse", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.45}, {"effet": "affliction", "nom": "poison", "chance": 0.35, "duree": 3}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 45 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.12}, {"effet": "epines", "valeur": 0.06}], "niveau": 10, "description": "DEF +12 % ; renvoie 6 % des dégâts physiques reçus."},
			{"nom": "Écorce Ancestrale", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "buff", "stat": "def", "valeur": 0.15, "duree": 3}, {"effet": "provocation", "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) DEF +15 % pour toute l'équipe (3 tours) ; attire les attaques ennemies (1 tour)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +12 % ; immunisé à Poison."},
		],
	},
	"porteur_lanterne": {
		"nom": "Porteur de Lanterne Noire", "rarete": "R", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "1a1a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 640, "atk": 145, "def": 65, "agi": 120, "mag": 110},
		"secondaires": {"crit": 8, "degats_crit": 165, "res": 24, "preci": 95},
		"skills": [
			{"nom": "Flamme Funèbre", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}, {"effet": "affliction", "nom": "malediction", "chance": 0.3, "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis ; 30 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.14}], "niveau": 10, "description": "MAG +14 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.75}, {"effet": "affliction", "nom": "malediction", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 75 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 14 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"souvenir_spectral": {
		"nom": "Souvenir Spectral", "rarete": "R", "element": "eau", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "8ab0d0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 680, "atk": 190, "def": 65, "agi": 170, "mag": 40},
		"secondaires": {"crit": 19, "degats_crit": 190, "res": 8, "preci": 97},
		"skills": [
			{"nom": "Étreinte du Passé", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "gel", "chance": 0.25, "duree": 1}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 25 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 9}, {"effet": "stat", "stat": "degats_crit", "valeur": 17}], "niveau": 10, "description": "Crit +9 ; Dégâts crit +17 %."},
			{"nom": "Estoc Glacé", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}, {"effet": "affliction", "nom": "gel", "chance": 0.3, "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi ; 30 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"veuve_lanternes": {
		"nom": "La Veuve aux Lanternes", "rarete": "SR", "element": "eau", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "2a3a5a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Deuil Éternel", "texte": "Les lanternes noires s'allument toutes à la fois."},
		"stats": {"pv": 1020, "atk": 210, "def": 100, "agi": 140, "mag": 190},
		"secondaires": {"crit": 9, "degats_crit": 170, "res": 26, "preci": 96},
		"skills": [
			{"nom": "Lamentation", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.9}, {"effet": "affliction", "nom": "gel", "chance": 0.3, "duree": 1}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 90 % de puissance de skill à tous les ennemis ; 30 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.16}], "niveau": 10, "description": "MAG +16 %."},
			{"nom": "Blizzard", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.75}, {"effet": "affliction", "nom": "gel", "chance": 0.25, "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 75 % de puissance de skill à tous les ennemis ; 25 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Nuit des Lanternes Noires", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.2}, {"effet": "affliction", "nom": "malediction", "chance": 0.5, "duree": 2}], "niveau": 30, "description": "(25 % de chance par tour) Inflige 120 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Malédiction (2 tours)."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"mercenaire_balafre": {
		"nom": "Mercenaire Balafré", "rarete": "R", "element": "feu", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "8a3a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 800, "atk": 175, "def": 95, "agi": 120, "mag": 35},
		"secondaires": {"crit": 9, "degats_crit": 165, "res": 12, "preci": 93},
		"skills": [
			{"nom": "Taille Sauvage", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "saignement", "chance": 0.3, "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 30 % de chance d'infliger Saignement (2 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}], "niveau": 10, "description": "ATK +11 %."},
			{"nom": "Brasier Dévorant", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +11 % ; immunisé à Brûlure."},
		],
	},
	"arbaletrier_noir": {
		"nom": "Arbalétrier Noir", "rarete": "R", "element": "tenebres", "role": "tireur", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "2a2a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 680, "atk": 185, "def": 70, "agi": 145, "mag": 50},
		"secondaires": {"crit": 13, "degats_crit": 175, "res": 10, "preci": 98},
		"skills": [
			{"nom": "Salve Perforante", "type": "actif", "chance": 0.3, "cible": "arriere", "effets": [{"effet": "degats", "mult": 1.1}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 110 % de puissance de skill aux ennemis de l'Arrière."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 7}], "niveau": 10, "description": "Précision +5 ; Crit +7."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}, {"effet": "drain", "valeur": 0.35}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi ; rend au lanceur 35 % des dégâts infligés."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 14 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"receleur_ombre": {
		"nom": "Receleur de l'Ombre", "rarete": "R", "element": "nature", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "3a4a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 680, "atk": 190, "def": 65, "agi": 170, "mag": 40},
		"secondaires": {"crit": 19, "degats_crit": 190, "res": 8, "preci": 97},
		"skills": [
			{"nom": "Lame Empoisonnée", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "poison", "chance": 0.45, "duree": 3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 45 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 9}, {"effet": "stat", "stat": "degats_crit", "valeur": 17}], "niveau": 10, "description": "Crit +9 ; Dégâts crit +17 %."},
			{"nom": "Morsure Vénéneuse", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "poison", "chance": 0.65, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 65 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +14 % ; immunisé à Poison."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"capitaine_drapeau_noir": {
		"nom": "Capitaine au Drapeau Noir", "rarete": "SR", "element": "feu", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "5a1a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Dernier Carré", "texte": "Le Capitaine lève son étendard : ses hommes se déchaînent."},
		"stats": {"pv": 1275, "atk": 260, "def": 140, "agi": 140, "mag": 60},
		"secondaires": {"crit": 10, "degats_crit": 170, "res": 14, "preci": 94},
		"skills": [
			{"nom": "Loi du Plus Fort", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.13}], "niveau": 10, "description": "ATK +13 %."},
			{"nom": "Brasier Dévorant", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Tyran des Routes", "type": "passif", "effets": [{"effet": "aura", "stat": "atk", "valeur": 0.15}, {"effet": "contre", "chance": 0.25, "mult": 1.0}], "niveau": 30, "description": "Toute l'équipe : ATK +15 % ; 25 % de chance de contre-attaquer (100 % d'ATK)."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"garde_os": {
		"nom": "Garde d'Os", "rarete": "R", "element": "tenebres", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "c8c0a8",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1040, "atk": 130, "def": 135, "agi": 85, "mag": 40},
		"secondaires": {"crit": 5, "degats_crit": 155, "res": 20, "preci": 91},
		"skills": [
			{"nom": "Rempart Osseux", "type": "actif", "chance": 0.3, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.15}, {"effet": "provocation", "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Bouclier de 15 % des PV max sur lui-même ; attire les attaques ennemies (2 tours)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.14}, {"effet": "epines", "valeur": 0.07}], "niveau": 10, "description": "DEF +14 % ; renvoie 7 % des dégâts physiques reçus."},
			{"nom": "Voile d'Effroi", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "debuff", "stat": "atk", "valeur": 0.15, "duree": 2}, {"effet": "provocation", "duree": 2, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) ATK -15 % pour tous les ennemis (2 tours) ; attire les attaques ennemies (2 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 14 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"pretre_autel": {
		"nom": "Prêtre de l'Autel", "rarete": "SR", "element": "tenebres", "role": "soutien", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "4a1a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 920, "atk": 165, "def": 125, "agi": 125, "mag": 180},
		"secondaires": {"crit": 7, "degats_crit": 160, "res": 29, "preci": 97},
		"skills": [
			{"nom": "Offrande de Sang", "type": "actif", "chance": 0.3, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.6}, {"effet": "buff", "stat": "atk", "valeur": 0.15, "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Soigne toute l'équipe de 60 % de puissance de skill ; ATK +15 % pour toute l'équipe (2 tours)."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.2}, {"effet": "stat", "stat": "res", "valeur": 0.13}], "niveau": 10, "description": "Soins prodigués +20 % ; RES +13 %."},
			{"nom": "Pacte de Sang", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 3}, {"effet": "buff", "stat": "mag", "valeur": 0.2, "duree": 3}, {"effet": "cout_pv", "valeur": 0.1}], "niveau": 20, "description": "(25 % de chance par tour) ATK +20 % pour toute l'équipe (3 tours) ; MAG +20 % pour toute l'équipe (3 tours) ; coûte 10 % de ses PV au lanceur."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.16}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 16 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"mirage_vaincu": {
		"nom": "Mirage des Vaincus", "rarete": "SR", "element": "sacre", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "d8c890",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 815, "atk": 210, "def": 100, "agi": 140, "mag": 190},
		"secondaires": {"crit": 9, "degats_crit": 170, "res": 26, "preci": 96},
		"skills": [
			{"nom": "Hallucination", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.75}, {"effet": "affliction", "nom": "aveugle", "chance": 0.35, "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 75 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.16}], "niveau": 10, "description": "MAG +16 %."},
			{"nom": "Rayon Sacré", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "aveugle", "chance": 0.3, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 30 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.1}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +10 % ; immunisé à Aveuglement."},
		],
	},
	"fanatique_zelote": {
		"nom": "Zélote Fanatique", "rarete": "R", "element": "sacre", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "c8a060",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 800, "atk": 175, "def": 95, "agi": 120, "mag": 35},
		"secondaires": {"crit": 9, "degats_crit": 165, "res": 12, "preci": 93},
		"skills": [
			{"nom": "Châtiment Aveugle", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "silence", "chance": 0.25, "duree": 1}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 25 % de chance d'infliger Silence (1 tour)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}], "niveau": 10, "description": "ATK +11 %."},
			{"nom": "Lance de Lumière", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}, {"effet": "affliction", "nom": "aveugle", "chance": 0.45, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi ; 45 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.09}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +9 % ; immunisé à Aveuglement."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"inquisiteur_implacable": {
		"nom": "L'Inquisiteur Implacable", "rarete": "SSR", "element": "sacre", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "e0d0a0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Ferveur Aveugle", "texte": "L'Inquisiteur entre en transe : rien ne l'arrêtera."},
		"stats": {"pv": 1750, "atk": 325, "def": 200, "agi": 175, "mag": 85},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Bûcher Purificateur", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "brulure", "chance": 0.5, "duree": 3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Brûlure (3 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lance de Lumière", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "aveugle", "chance": 0.5, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Jugement Final", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.3}, {"effet": "affliction", "nom": "silence", "chance": 0.4, "duree": 2}], "niveau": 30, "description": "(25 % de chance par tour) Inflige 130 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Silence (2 tours)."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"statue_hurlante": {
		"nom": "Statue Hurlante", "rarete": "SR", "element": "sacre", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "9a9aa8",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1325, "atk": 190, "def": 195, "agi": 100, "mag": 70},
		"secondaires": {"crit": 6, "degats_crit": 160, "res": 22, "preci": 92},
		"skills": [
			{"nom": "Cri Pétrifiant", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.5}, {"effet": "affliction", "nom": "etourdi", "chance": 0.2, "duree": 1}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 50 % de puissance de skill à tous les ennemis ; 20 % de chance d'infliger Étourdissement (1 tour)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.16}, {"effet": "epines", "valeur": 0.08}], "niveau": 10, "description": "DEF +16 % ; renvoie 8 % des dégâts physiques reçus."},
			{"nom": "Égide Sacrée", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.1}, {"effet": "provocation", "duree": 1, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 10 % des PV max sur toute l'équipe ; attire les attaques ennemies (1 tour)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.1}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +10 % ; immunisé à Aveuglement."},
		],
	},
	"aberration_cristal": {
		"nom": "Aberration Cristalline", "rarete": "SR", "element": "eau", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "9a7ad0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 865, "atk": 280, "def": 100, "agi": 195, "mag": 70},
		"secondaires": {"crit": 20, "degats_crit": 195, "res": 10, "preci": 98},
		"skills": [
			{"nom": "Éclat Tranchant", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}, {"effet": "affliction", "nom": "saignement", "chance": 0.35, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi ; 35 % de chance d'infliger Saignement (2 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 10}, {"effet": "stat", "stat": "degats_crit", "valeur": 20}], "niveau": 10, "description": "Crit +10 ; Dégâts crit +20 %."},
			{"nom": "Estoc Glacé", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}, {"effet": "affliction", "nom": "gel", "chance": 0.3, "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi ; 30 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"reflet_ame": {
		"nom": "Le Reflet de l'Âme", "rarete": "SSR", "element": "tenebres", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "1a1a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Âme Brisée", "texte": "Le Reflet se fissure… et devient plus féroce encore."},
		"stats": {"pv": 1490, "atk": 355, "def": 140, "agi": 245, "mag": 100},
		"secondaires": {"crit": 21, "degats_crit": 200, "res": 12, "preci": 99},
		"skills": [
			{"nom": "Miroir Noir", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.1}, {"effet": "drain", "valeur": 0.3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 210 % de puissance de skill à un ennemi ; rend au lanceur 30 % des dégâts infligés."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 12}, {"effet": "stat", "stat": "degats_crit", "valeur": 22}], "niveau": 10, "description": "Crit +12 ; Dégâts crit +22 %."},
			{"nom": "Lacération", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.75}, {"effet": "affliction", "nom": "saignement", "chance": 0.8, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 175 % de puissance de skill à un ennemi ; 80 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Double Maléfique", "type": "passif", "effets": [{"effet": "double_attaque", "chance": 0.3}, {"effet": "survie", "charges": 1}], "niveau": 30, "description": "30 % de chance d'attaquer deux fois ; survit à un coup fatal avec 1 PV (1 fois par combat)."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"liane_venimeuse": {
		"nom": "Liane Vénéneuse", "rarete": "SR", "element": "nature", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "2a5a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 815, "atk": 210, "def": 100, "agi": 140, "mag": 190},
		"secondaires": {"crit": 9, "degats_crit": 170, "res": 26, "preci": 96},
		"skills": [
			{"nom": "Étreinte Épineuse", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}, {"effet": "affliction", "nom": "poison", "chance": 0.4, "duree": 3}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.16}], "niveau": 10, "description": "MAG +16 %."},
			{"nom": "Nuée Toxique", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.65}, {"effet": "affliction", "nom": "poison", "chance": 0.5, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 65 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.16}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +16 % ; immunisé à Poison."},
		],
	},
	"bete_tourbieres": {
		"nom": "Bête des Tourbières", "rarete": "SR", "element": "eau", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "3a4a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1325, "atk": 190, "def": 195, "agi": 100, "mag": 70},
		"secondaires": {"crit": 6, "degats_crit": 160, "res": 22, "preci": 92},
		"skills": [
			{"nom": "Engloutissement", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "gel", "chance": 0.3, "duree": 1}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 30 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.16}, {"effet": "epines", "valeur": 0.08}], "niveau": 10, "description": "DEF +16 % ; renvoie 8 % des dégâts physiques reçus."},
			{"nom": "Carapace des Marées", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "res", "valeur": 0.25, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; RES +25 % pour lui-même (3 tours)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"dame_ronciers": {
		"nom": "La Dame des Ronciers", "rarete": "SSR", "element": "nature", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "3a1a3a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Floraison Maudite", "texte": "Des ronces jaillissent de partout autour de la Dame."},
		"stats": {"pv": 1400, "atk": 265, "def": 140, "agi": 175, "mag": 270},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Pacte Épineux", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.0}, {"effet": "affliction", "nom": "poison", "chance": 0.5, "duree": 3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 100 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Nuée Toxique", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}, {"effet": "affliction", "nom": "poison", "chance": 0.5, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Corrompue", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.9}, {"effet": "regen_temp", "valeur": 0.06, "duree": 3}], "niveau": 30, "description": "(25 % de chance par tour) Soigne toute l'équipe de 90 % de puissance de skill ; régénère 6 % des PV par tour (3 tours)."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"rodeur_eclipse": {
		"nom": "Rôdeur de l'Éclipse", "rarete": "SSR", "element": "tenebres", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "4a0a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1190, "atk": 355, "def": 140, "agi": 245, "mag": 100},
		"secondaires": {"crit": 21, "degats_crit": 200, "res": 12, "preci": 99},
		"skills": [
			{"nom": "Griffe Sanglante", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "saignement", "chance": 0.4, "duree": 3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 12}, {"effet": "stat", "stat": "degats_crit", "valeur": 22}], "niveau": 10, "description": "Crit +12 ; Dégâts crit +22 %."},
			{"nom": "Lacération", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.75}, {"effet": "affliction", "nom": "saignement", "chance": 0.8, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 175 % de puissance de skill à un ennemi ; 80 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.17}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 17 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"demon_siege": {
		"nom": "Démon de Siège", "rarete": "SSR", "element": "feu", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "6a2a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1820, "atk": 235, "def": 280, "agi": 120, "mag": 100},
		"secondaires": {"crit": 7, "degats_crit": 165, "res": 24, "preci": 93},
		"skills": [
			{"nom": "Bélier Infernal", "type": "actif", "chance": 0.3, "cible": "avant", "effets": [{"effet": "degats", "mult": 1.2}, {"effet": "affliction", "nom": "etourdi", "chance": 0.25, "duree": 1}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 120 % de puissance de skill aux ennemis de l'Avant ; 25 % de chance d'infliger Étourdissement (1 tour)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.17}, {"effet": "epines", "valeur": 0.09}], "niveau": 10, "description": "DEF +17 % ; renvoie 9 % des dégâts physiques reçus."},
			{"nom": "Bouclier de Braise", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; ATK +20 % pour lui-même (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +14 % ; immunisé à Brûlure."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"avatar_eclipse": {
		"nom": "Avatar de l'Éclipse", "rarete": "SSR", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "2a0000",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Totalité", "texte": "L'éclipse est totale : l'Avatar déborde d'énergie ténébreuse."},
		"stats": {"pv": 1400, "atk": 265, "def": 140, "agi": 175, "mag": 270},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Soleil Noir", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.1}, {"effet": "affliction", "nom": "malediction", "chance": 0.45, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 110 % de puissance de skill à tous les ennemis ; 45 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "malediction", "chance": 0.45, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 45 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Éclipse Totale", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.4}, {"effet": "affliction", "nom": "aveugle", "chance": 0.5, "duree": 2}], "niveau": 30, "description": "(25 % de chance par tour) Inflige 140 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Aveuglement (2 tours)."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"champion_dechu": {
		"nom": "Champion Déchu", "rarete": "SSR", "element": "sacre", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "b09060",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1400, "atk": 325, "def": 200, "agi": 175, "mag": 85},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Lame Oubliée", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lance de Lumière", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "aveugle", "chance": 0.5, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +12 % ; immunisé à Aveuglement."},
		],
	},
	"pilleur_royal": {
		"nom": "Pilleur de Tombes Royales", "rarete": "SR", "element": "tenebres", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "3a2a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 865, "atk": 280, "def": 100, "agi": 195, "mag": 70},
		"secondaires": {"crit": 20, "degats_crit": 195, "res": 10, "preci": 98},
		"skills": [
			{"nom": "Vol de Relique", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}, {"effet": "debuff", "stat": "atk", "valeur": 0.15, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi ; ATK -15 % pour un ennemi (2 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 10}, {"effet": "stat", "stat": "degats_crit", "valeur": 20}], "niveau": 10, "description": "Crit +10 ; Dégâts crit +20 %."},
			{"nom": "Lacération", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.7}, {"effet": "affliction", "nom": "saignement", "chance": 0.7, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 170 % de puissance de skill à un ennemi ; 70 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.16}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 16 % sur ses attaques ; immunisé à Malédiction."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"ombre_premier_roi": {
		"nom": "L'Ombre du Premier Roi", "rarete": "SSR", "element": "tenebres", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "1a1a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Couronne de l'Oubli", "texte": "Le Premier Roi se souvient de sa gloire passée."},
		"stats": {"pv": 2275, "atk": 235, "def": 280, "agi": 120, "mag": 100},
		"secondaires": {"crit": 7, "degats_crit": 165, "res": 24, "preci": 93},
		"skills": [
			{"nom": "Couronne Maudite", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.95}, {"effet": "debuff", "stat": "def", "valeur": 0.2, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 95 % de puissance de skill à tous les ennemis ; DEF -20 % pour tous les ennemis (2 tours)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.17}, {"effet": "epines", "valeur": 0.09}], "niveau": 10, "description": "DEF +17 % ; renvoie 9 % des dégâts physiques reçus."},
			{"nom": "Voile d'Effroi", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "debuff", "stat": "atk", "valeur": 0.2, "duree": 2}, {"effet": "provocation", "duree": 2, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) ATK -20 % pour tous les ennemis (2 tours) ; attire les attaques ennemies (2 tours)."},
			{"nom": "Malédiction des Rois", "type": "passif", "effets": [{"effet": "aura_ennemis", "stat": "atk", "valeur": 0.12}, {"effet": "regen", "valeur": 0.04}], "niveau": 30, "description": "Tous les ennemis : ATK -12 % ; régénère 4 % de ses PV max à chaque tour."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"tortionnaire": {
		"nom": "Tortionnaire", "rarete": "SSR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "3a0a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1400, "atk": 325, "def": 200, "agi": 175, "mag": 85},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Crochets de Fer", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "saignement", "chance": 0.5, "duree": 3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "drain", "valeur": 0.4}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; rend au lanceur 40 % des dégâts infligés."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.17}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 17 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"abomination": {
		"nom": "Abomination de Laboratoire", "rarete": "SSR", "element": "nature", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "4a6a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1820, "atk": 235, "def": 280, "agi": 120, "mag": 100},
		"secondaires": {"crit": 7, "degats_crit": 165, "res": 24, "preci": 93},
		"skills": [
			{"nom": "Chair Mutante", "type": "actif", "chance": 0.3, "cible": "soi", "effets": [{"effet": "regen_temp", "valeur": 0.08, "duree": 3}, {"effet": "provocation", "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Régénère 8 % des PV par tour (3 tours) ; attire les attaques ennemies (2 tours)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.17}, {"effet": "epines", "valeur": 0.09}], "niveau": 10, "description": "DEF +17 % ; renvoie 9 % des dégâts physiques reçus."},
			{"nom": "Écorce Ancestrale", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "buff", "stat": "def", "valeur": 0.2, "duree": 3}, {"effet": "provocation", "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) DEF +20 % pour toute l'équipe (3 tours) ; attire les attaques ennemies (1 tour)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.17}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +17 % ; immunisé à Poison."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"maitre_supplices": {
		"nom": "Le Maître des Supplices", "rarete": "SSR", "element": "feu", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "5a0a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Salle Ultime", "texte": "Le Maître des Supplices ouvre sa dernière salle de tourments."},
		"stats": {"pv": 1400, "atk": 265, "def": 140, "agi": 175, "mag": 270},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Chambre de Tourments", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.1}, {"effet": "affliction", "nom": "brulure", "chance": 0.5, "duree": 3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 110 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Brûlure (3 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Pluie de Braises", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Supplice Éternel", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.5}, {"effet": "affliction", "nom": "etourdi", "chance": 0.4, "duree": 1}], "niveau": 30, "description": "(25 % de chance par tour) Inflige 250 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Étourdissement (1 tour)."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"garde_fratricide": {
		"nom": "Garde Fratricide", "rarete": "SSR", "element": "tenebres", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "2a1a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1820, "atk": 235, "def": 280, "agi": 120, "mag": 100},
		"secondaires": {"crit": 7, "degats_crit": 165, "res": 24, "preci": 93},
		"skills": [
			{"nom": "Serment Brisé", "type": "actif", "chance": 0.3, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.12}], "niveau": 1, "description": "(30 % de chance par tour) Bouclier de 12 % des PV max sur toute l'équipe."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.17}, {"effet": "epines", "valeur": 0.09}], "niveau": 10, "description": "DEF +17 % ; renvoie 9 % des dégâts physiques reçus."},
			{"nom": "Voile d'Effroi", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "debuff", "stat": "atk", "valeur": 0.2, "duree": 2}, {"effet": "provocation", "duree": 2, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) ATK -20 % pour tous les ennemis (2 tours) ; attire les attaques ennemies (2 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.17}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 17 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"compagnon_traitre": {
		"nom": "Compagnon Traître", "rarete": "SSR", "element": "feu", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "6a1a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1190, "atk": 355, "def": 140, "agi": 245, "mag": 100},
		"secondaires": {"crit": 21, "degats_crit": 200, "res": 12, "preci": 99},
		"skills": [
			{"nom": "Poignard dans le Dos", "type": "actif", "chance": 0.35, "cible": "arriere", "effets": [{"effet": "degats", "mult": 1.8}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 180 % de puissance de skill aux ennemis de l'Arrière."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 12}, {"effet": "stat", "stat": "degats_crit", "valeur": 22}], "niveau": 10, "description": "Crit +12 ; Dégâts crit +22 %."},
			{"nom": "Lame Incandescente", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "brulure", "chance": 0.5, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +14 % ; immunisé à Brûlure."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"frere_masque": {
		"nom": "Le Frère Masqué", "rarete": "SSR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "1a0a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Le Masque Tombe", "texte": "Le masque se brise : ton propre sang se dresse contre toi."},
		"stats": {"pv": 1750, "atk": 325, "def": 200, "agi": 175, "mag": 85},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Lame du Sang Partagé", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.2}, {"effet": "drain", "valeur": 0.35}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 220 % de puissance de skill à un ennemi ; rend au lanceur 35 % des dégâts infligés."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "drain", "valeur": 0.4}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; rend au lanceur 40 % des dégâts infligés."},
			{"nom": "Le Dernier Regard", "type": "passif", "effets": [{"effet": "execution", "valeur": 0.35}, {"effet": "survie", "charges": 1}], "niveau": 30, "description": "+35 % de dégâts contre les cibles sous 50 % de PV ; survit à un coup fatal avec 1 PV (1 fois par combat)."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"garde_cendres": {
		"nom": "Garde des Cendres Éternelles", "rarete": "SSR", "element": "sacre", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "d0b070",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1820, "atk": 235, "def": 280, "agi": 120, "mag": 100},
		"secondaires": {"crit": 7, "degats_crit": 165, "res": 24, "preci": 93},
		"skills": [
			{"nom": "Mur de Cendres", "type": "actif", "chance": 0.3, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.12}, {"effet": "buff", "stat": "def", "valeur": 0.15, "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Bouclier de 12 % des PV max sur toute l'équipe ; DEF +15 % pour toute l'équipe (2 tours)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.17}, {"effet": "epines", "valeur": 0.09}], "niveau": 10, "description": "DEF +17 % ; renvoie 9 % des dégâts physiques reçus."},
			{"nom": "Égide Sacrée", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.15}, {"effet": "provocation", "duree": 1, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 15 % des PV max sur toute l'équipe ; attire les attaques ennemies (1 tour)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +12 % ; immunisé à Aveuglement."},
		],
	},
	"heraut_apocalypse": {
		"nom": "Héraut de l'Apocalypse", "rarete": "SSR", "element": "feu", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "8a1a00",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1120, "atk": 265, "def": 140, "agi": 175, "mag": 270},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Trompette du Jugement", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.1}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 110 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Pluie de Braises", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +14 % ; immunisé à Brûlure."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"heritier_maudit": {
		"nom": "L'Héritier Maudit", "rarete": "UR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "2a002a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Métamorphose du Mal", "texte": "L'Héritier se transforme en une monstruosité cauchemardesque !"},
		"stats": {"pv": 2310, "atk": 405, "def": 245, "agi": 240, "mag": 115},
		"secondaires": {"crit": 12, "degats_crit": 180, "res": 18, "preci": 96},
		"skills": [
			{"nom": "Héritage Maudit", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.3}, {"effet": "affliction", "nom": "malediction", "chance": 0.5, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 230 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.16}], "niveau": 10, "description": "ATK +16 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.1}, {"effet": "drain", "valeur": 0.4}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 210 % de puissance de skill à un ennemi ; rend au lanceur 40 % des dégâts infligés."},
			{"nom": "Crépuscule des Frères", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "malediction", "chance": 0.6, "duree": 2}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 30, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à tous les ennemis ; 60 % de chance d'infliger Malédiction (2 tours) ; 40 % de chance d'infliger Brûlure (2 tours)."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"diablotin_soufre": {
		"nom": "Diablotin de Soufre", "rarete": "N", "element": "feu", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "c0401a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 475, "atk": 130, "def": 40, "agi": 140, "mag": 25},
		"secondaires": {"crit": 18, "degats_crit": 185, "res": 6, "preci": 96},
		"skills": [
			{"nom": "Griffes Brûlantes", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "brulure", "chance": 0.3, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 30 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 8}, {"effet": "stat", "stat": "degats_crit", "valeur": 15}], "niveau": 10, "description": "Crit +8 ; Dégâts crit +15 %."},
			{"nom": "Lame Incandescente", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.1}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +10 % ; immunisé à Brûlure."},
		],
	},
	"ame_damnee": {
		"nom": "Âme Damnée", "rarete": "N", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "4a3a5a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 450, "atk": 100, "def": 40, "agi": 100, "mag": 65},
		"secondaires": {"crit": 7, "degats_crit": 160, "res": 22, "preci": 94},
		"skills": [
			{"nom": "Plainte Éternelle", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.55}, {"effet": "affliction", "nom": "malediction", "chance": 0.25, "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 55 % de puissance de skill à tous les ennemis ; 25 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.12}], "niveau": 10, "description": "MAG +12 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}, {"effet": "affliction", "nom": "malediction", "chance": 0.35, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 12 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"molosse_enfers": {
		"nom": "Molosse des Enfers", "rarete": "R", "element": "feu", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "6a1a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 800, "atk": 175, "def": 95, "agi": 120, "mag": 35},
		"secondaires": {"crit": 9, "degats_crit": 165, "res": 12, "preci": 93},
		"skills": [
			{"nom": "Morsure de Braise", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "saignement", "chance": 0.3, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 30 % de chance d'infliger Saignement (2 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}], "niveau": 10, "description": "ATK +11 %."},
			{"nom": "Brasier Dévorant", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.11}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +11 % ; immunisé à Brûlure."},
		],
	},
	"passeur_styx": {
		"nom": "Passeur du Fleuve Rouge", "rarete": "R", "element": "eau", "role": "soutien", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "5a1a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 720, "atk": 110, "def": 85, "agi": 110, "mag": 105},
		"secondaires": {"crit": 6, "degats_crit": 155, "res": 27, "preci": 96},
		"skills": [
			{"nom": "Obole de Sang", "type": "actif", "chance": 0.3, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.55}, {"effet": "buff", "stat": "def", "valeur": 0.12, "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Soigne toute l'équipe de 55 % de puissance de skill ; DEF +12 % pour toute l'équipe (2 tours)."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.17}, {"effet": "stat", "stat": "res", "valeur": 0.11}], "niveau": 10, "description": "Soins prodigués +17 % ; RES +11 %."},
			{"nom": "Source Apaisante", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.75}, {"effet": "purification"}], "niveau": 20, "description": "(25 % de chance par tour) Soigne toute l'équipe de 75 % de puissance de skill ; retire les afflictions."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"bourreau_cornu": {
		"nom": "Bourreau Cornu", "rarete": "SR", "element": "feu", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "7a2a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1020, "atk": 260, "def": 140, "agi": 140, "mag": 60},
		"secondaires": {"crit": 10, "degats_crit": 170, "res": 14, "preci": 94},
		"skills": [
			{"nom": "Hache du Supplice", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}, {"effet": "affliction", "nom": "saignement", "chance": 0.4, "duree": 3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.13}], "niveau": 10, "description": "ATK +13 %."},
			{"nom": "Brasier Dévorant", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.13}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +13 % ; immunisé à Brûlure."},
		],
	},
	"sangsue_abyssale": {
		"nom": "Sangsue Abyssale", "rarete": "SR", "element": "eau", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "3a0a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1325, "atk": 190, "def": 195, "agi": 100, "mag": 70},
		"secondaires": {"crit": 6, "degats_crit": 160, "res": 22, "preci": 92},
		"skills": [
			{"nom": "Succion", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.3}, {"effet": "drain", "valeur": 0.5}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 130 % de puissance de skill à un ennemi ; rend au lanceur 50 % des dégâts infligés."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.16}, {"effet": "epines", "valeur": 0.08}], "niveau": 10, "description": "DEF +16 % ; renvoie 8 % des dégâts physiques reçus."},
			{"nom": "Carapace des Marées", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "res", "valeur": 0.25, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; RES +25 % pour lui-même (3 tours)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"forgeron_abime": {
		"nom": "Forgeron de l'Abîme", "rarete": "SR", "element": "feu", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "8a3a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1325, "atk": 190, "def": 195, "agi": 100, "mag": 70},
		"secondaires": {"crit": 6, "degats_crit": 160, "res": 22, "preci": 92},
		"skills": [
			{"nom": "Enclume Rougie", "type": "actif", "chance": 0.3, "cible": "avant", "effets": [{"effet": "degats", "mult": 1.1}, {"effet": "affliction", "nom": "etourdi", "chance": 0.2, "duree": 1}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 110 % de puissance de skill aux ennemis de l'Avant ; 20 % de chance d'infliger Étourdissement (1 tour)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.16}, {"effet": "epines", "valeur": 0.08}], "niveau": 10, "description": "DEF +16 % ; renvoie 8 % des dégâts physiques reçus."},
			{"nom": "Bouclier de Braise", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; ATK +20 % pour lui-même (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.13}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +13 % ; immunisé à Brûlure."},
		],
	},
	"succube": {
		"nom": "Succube Tentatrice", "rarete": "SSR", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "8a1a4a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1120, "atk": 265, "def": 140, "agi": 175, "mag": 270},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Baiser Mortel", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}, {"effet": "affliction", "nom": "silence", "chance": 0.35, "duree": 2}, {"effet": "drain", "valeur": 0.25}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi ; 35 % de chance d'infliger Silence (2 tours) ; rend au lanceur 25 % des dégâts infligés."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "malediction", "chance": 0.45, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 45 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.17}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 17 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"cerbere": {
		"nom": "Cerbère", "rarete": "SSR", "element": "feu", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "5a0a00",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1190, "atk": 355, "def": 140, "agi": 245, "mag": 100},
		"secondaires": {"crit": 21, "degats_crit": 200, "res": 12, "preci": 99},
		"skills": [
			{"nom": "Triple Morsure", "type": "actif", "chance": 0.35, "cible": "aleatoire", "effets": [{"effet": "degats", "mult": 0.8, "coups": 3}, {"effet": "affliction", "nom": "brulure", "chance": 0.3, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Frappe 3 fois des ennemis au hasard (80 % de puissance de skill par coup) ; 30 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 12}, {"effet": "stat", "stat": "degats_crit", "valeur": 22}], "niveau": 10, "description": "Crit +12 ; Dégâts crit +22 %."},
			{"nom": "Lame Incandescente", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "brulure", "chance": 0.5, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +14 % ; immunisé à Brûlure."},
		],
	},
	"chevalier_infernal": {
		"nom": "Chevalier Infernal", "rarete": "SSR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "2a0a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1400, "atk": 325, "def": 200, "agi": 175, "mag": 85},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Lame Damnée", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "affliction", "nom": "malediction", "chance": 0.4, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "drain", "valeur": 0.4}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; rend au lanceur 40 % des dégâts infligés."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.17}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 17 % sur ses attaques ; immunisé à Malédiction."},
		],
	},
	"archidemon": {
		"nom": "Archidémon du Néant", "rarete": "UR", "element": "feu", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "6a0000",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1480, "atk": 335, "def": 170, "agi": 240, "mag": 370},
		"secondaires": {"crit": 11, "degats_crit": 180, "res": 30, "preci": 98},
		"skills": [
			{"nom": "Pluie de Soufre", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.0}, {"effet": "affliction", "nom": "brulure", "chance": 0.45, "duree": 3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 100 % de puissance de skill à tous les ennemis ; 45 % de chance d'infliger Brûlure (3 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.19}], "niveau": 10, "description": "MAG +19 %."},
			{"nom": "Pluie de Braises", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.16}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +16 % ; immunisé à Brûlure."},
		],
	},
	"tourmenteur_ames": {
		"nom": "Tourmenteur des Âmes", "rarete": "UR", "element": "tenebres", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "1a001a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1570, "atk": 445, "def": 170, "agi": 335, "mag": 140},
		"secondaires": {"crit": 22, "degats_crit": 205, "res": 14, "preci": 100},
		"skills": [
			{"nom": "Arrache-Âme", "type": "actif", "chance": 0.35, "cible": "arriere", "effets": [{"effet": "degats", "mult": 1.7}, {"effet": "affliction", "nom": "malediction", "chance": 0.4, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 170 % de puissance de skill aux ennemis de l'Arrière ; 40 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 13}, {"effet": "stat", "stat": "degats_crit", "valeur": 24}], "niveau": 10, "description": "Crit +13 ; Dégâts crit +24 %."},
			{"nom": "Lacération", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.85}, {"effet": "affliction", "nom": "saignement", "chance": 0.85, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 185 % de puissance de skill à un ennemi ; 85 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Soif de Sang", "type": "passif", "effets": [{"effet": "vol_vie", "valeur": 0.19}, {"effet": "immunite", "afflictions": ["malediction"]}], "niveau": 30, "description": "Vol de vie de 19 % sur ses attaques ; immunisé à Malédiction."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"gardien_soufre": {
		"nom": "Gardien des Portes de Soufre", "rarete": "SR", "element": "feu", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "9a4a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Portes Ouvertes", "texte": "Les portes de soufre s'embrasent derrière le Gardien !"},
		"stats": {"pv": 1660, "atk": 190, "def": 195, "agi": 100, "mag": 70},
		"secondaires": {"crit": 6, "degats_crit": 160, "res": 22, "preci": 92},
		"skills": [
			{"nom": "Mur de Soufre", "type": "actif", "chance": 0.35, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.15}, {"effet": "buff", "stat": "def", "valeur": 0.2, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Bouclier de 15 % des PV max sur toute l'équipe ; DEF +20 % pour toute l'équipe (2 tours)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.16}, {"effet": "epines", "valeur": 0.08}], "niveau": 10, "description": "DEF +16 % ; renvoie 8 % des dégâts physiques reçus."},
			{"nom": "Bouclier de Braise", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; ATK +20 % pour lui-même (2 tours)."},
			{"nom": "Cœur de Soufre", "type": "passif", "effets": [{"effet": "epines", "valeur": 0.2}, {"effet": "stat", "stat": "def", "valeur": 0.15}], "niveau": 30, "description": "Renvoie 20 % des dégâts physiques reçus ; DEF +15 %."},
		],
	},
	"avarex": {
		"nom": "Avarex, Prince de l'Avidité", "rarete": "SR", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "4a3a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Avidité Sans Fin", "texte": "Avarex dévore son propre trésor et grandit encore."},
		"stats": {"pv": 1020, "atk": 210, "def": 100, "agi": 140, "mag": 190},
		"secondaires": {"crit": 9, "degats_crit": 170, "res": 26, "preci": 96},
		"skills": [
			{"nom": "Or Maudit", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.9}, {"effet": "debuff", "stat": "atk", "valeur": 0.15, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 90 % de puissance de skill à tous les ennemis ; ATK -15 % pour tous les ennemis (2 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.16}], "niveau": 10, "description": "MAG +16 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "malediction", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Trésor Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.1}, {"effet": "affliction", "nom": "malediction", "chance": 0.5, "duree": 2}], "niveau": 30, "description": "(25 % de chance par tour) Inflige 110 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Malédiction (2 tours)."},
		],
	},
	"nocher_rouge": {
		"nom": "Nautre, Nocher du Fleuve Rouge", "rarete": "SSR", "element": "eau", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "4a0a1a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Crue Sanglante", "texte": "Le fleuve rouge déborde autour du Nocher."},
		"stats": {"pv": 1750, "atk": 325, "def": 200, "agi": 175, "mag": 85},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Rame du Trépas", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "affliction", "nom": "gel", "chance": 0.35, "duree": 1}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; 35 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lame de Givre", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "gel", "chance": 0.4, "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Le Fleuve Réclame", "type": "passif", "effets": [{"effet": "execution", "valeur": 0.3}, {"effet": "vol_vie", "valeur": 0.15}], "niveau": 30, "description": "+30 % de dégâts contre les cibles sous 50 % de PV ; vol de vie de 15 % sur ses attaques."},
		],
	},
	"vorhka": {
		"nom": "Vorhka, Mère des Tourments", "rarete": "SSR", "element": "nature", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "3a4a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Éclosion", "texte": "Des milliers de larves jaillissent autour de Vorhka."},
		"stats": {"pv": 1490, "atk": 355, "def": 140, "agi": 245, "mag": 100},
		"secondaires": {"crit": 21, "degats_crit": 200, "res": 12, "preci": 99},
		"skills": [
			{"nom": "Dards Pestilentiels", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.9}, {"effet": "affliction", "nom": "poison", "chance": 0.55, "duree": 3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 90 % de puissance de skill à tous les ennemis ; 55 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 12}, {"effet": "stat", "stat": "degats_crit", "valeur": 22}], "niveau": 10, "description": "Crit +12 ; Dégâts crit +22 %."},
			{"nom": "Morsure Vénéneuse", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.75}, {"effet": "affliction", "nom": "poison", "chance": 0.8, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 175 % de puissance de skill à un ennemi ; 80 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Couvée Infinie", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; immunisé à Poison."},
		],
	},
	"grand_forgeron": {
		"nom": "Le Grand Forgeron Infernal", "rarete": "SSR", "element": "feu", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "aa3a00",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Forge Ultime", "texte": "Le Grand Forgeron plonge ses bras dans la lave."},
		"stats": {"pv": 2275, "atk": 235, "def": 280, "agi": 120, "mag": 100},
		"secondaires": {"crit": 7, "degats_crit": 165, "res": 24, "preci": 93},
		"skills": [
			{"nom": "Marteau de l'Abîme", "type": "actif", "chance": 0.35, "cible": "avant", "effets": [{"effet": "degats", "mult": 1.4}, {"effet": "affliction", "nom": "etourdi", "chance": 0.35, "duree": 1}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 140 % de puissance de skill aux ennemis de l'Avant ; 35 % de chance d'infliger Étourdissement (1 tour)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.17}, {"effet": "epines", "valeur": 0.09}], "niveau": 10, "description": "DEF +17 % ; renvoie 9 % des dégâts physiques reçus."},
			{"nom": "Bouclier de Braise", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; ATK +20 % pour lui-même (2 tours)."},
			{"nom": "Armure Forgée", "type": "passif", "effets": [{"effet": "survie", "charges": 1}, {"effet": "stat", "stat": "def", "valeur": 0.2}], "niveau": 30, "description": "Survit à un coup fatal avec 1 PV (1 fois par combat) ; DEF +20 %."},
		],
	},
	"lilithra": {
		"nom": "Lilithra, Reine des Succubes", "rarete": "SSR", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "9a0a5a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Masque Tombé", "texte": "La beauté de Lilithra se déchire : sa vraie forme apparaît."},
		"stats": {"pv": 1400, "atk": 265, "def": 140, "agi": 175, "mag": 270},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Charme Fatal", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.0}, {"effet": "affliction", "nom": "silence", "chance": 0.4, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 100 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Silence (2 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "malediction", "chance": 0.45, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 45 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Nuit des Succubes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.3}, {"effet": "drain", "valeur": 0.3}], "niveau": 30, "description": "(25 % de chance par tour) Inflige 130 % de puissance de skill à tous les ennemis ; rend au lanceur 30 % des dégâts infligés."},
		],
	},
	"cerberus": {
		"nom": "Cerbérus Tricéphale", "rarete": "UR", "element": "feu", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "7a0a00",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Rage des Trois Têtes", "texte": "Les trois gueules hurlent ensemble !"},
		"stats": {"pv": 1965, "atk": 445, "def": 170, "agi": 335, "mag": 140},
		"secondaires": {"crit": 22, "degats_crit": 205, "res": 14, "preci": 100},
		"skills": [
			{"nom": "Trois Gueules", "type": "actif", "chance": 0.35, "cible": "aleatoire", "effets": [{"effet": "degats", "mult": 1.0, "coups": 3}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Frappe 3 fois des ennemis au hasard (100 % de puissance de skill par coup) ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 13}, {"effet": "stat", "stat": "degats_crit", "valeur": 24}], "niveau": 10, "description": "Crit +13 ; Dégâts crit +24 %."},
			{"nom": "Lame Incandescente", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "affliction", "nom": "brulure", "chance": 0.55, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; 55 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Gardien des Enfers", "type": "passif", "effets": [{"effet": "double_attaque", "chance": 0.3}, {"effet": "premier"}], "niveau": 30, "description": "30 % de chance d'attaquer deux fois ; agit toujours en premier au 1er tour."},
		],
	},
	"baalzeth": {
		"nom": "Baal'Zeth, Général des Légions", "rarete": "UR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "3a000a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Cor de Guerre", "texte": "Baal'Zeth sonne la charge de toutes ses légions."},
		"stats": {"pv": 2310, "atk": 405, "def": 245, "agi": 240, "mag": 115},
		"secondaires": {"crit": 12, "degats_crit": 180, "res": 18, "preci": 96},
		"skills": [
			{"nom": "Ordre de Massacre", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.3}, {"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 2, "cible": "allies"}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 230 % de puissance de skill à un ennemi ; ATK +20 % pour toute l'équipe (2 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.16}], "niveau": 10, "description": "ATK +16 %."},
			{"nom": "Lame du Néant", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.1}, {"effet": "drain", "valeur": 0.4}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 210 % de puissance de skill à un ennemi ; rend au lanceur 40 % des dégâts infligés."},
			{"nom": "Légions Infinies", "type": "passif", "effets": [{"effet": "aura", "stat": "atk", "valeur": 0.18}, {"effet": "contre", "chance": 0.25, "mult": 1.0}], "niveau": 30, "description": "Toute l'équipe : ATK +18 % ; 25 % de chance de contre-attaquer (100 % d'ATK)."},
		],
	},
	"archidiable": {
		"nom": "L'Archidiable Écarlate", "rarete": "UR", "element": "feu", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "cc0000",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Enfer Déchaîné", "texte": "L'Archidiable embrase tout l'étage."},
		"stats": {"pv": 1850, "atk": 335, "def": 170, "agi": 240, "mag": 370},
		"secondaires": {"crit": 11, "degats_crit": 180, "res": 30, "preci": 98},
		"skills": [
			{"nom": "Brasier Écarlate", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.2}, {"effet": "affliction", "nom": "brulure", "chance": 0.55, "duree": 3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 120 % de puissance de skill à tous les ennemis ; 55 % de chance d'infliger Brûlure (3 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.19}], "niveau": 10, "description": "MAG +19 %."},
			{"nom": "Pluie de Braises", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Apocalypse Écarlate", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "brulure", "chance": 0.7, "duree": 3}], "niveau": 30, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à tous les ennemis ; 70 % de chance d'infliger Brûlure (3 tours)."},
		],
	},
	"abaddor": {
		"nom": "Abaddor, le Diable Primordial", "rarete": "UR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "1a0000",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Le Neuvième Cercle", "texte": "Abaddor déploie ses ailes : l'Enfer tout entier tremble !"},
		"stats": {"pv": 2310, "atk": 405, "def": 245, "agi": 240, "mag": 115},
		"secondaires": {"crit": 14, "degats_crit": 190, "res": 23, "preci": 98},
		"skills": [
			{"nom": "Sentence Infernale", "type": "actif", "chance": 0.4, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.2}, {"effet": "affliction", "nom": "malediction", "chance": 0.5, "duree": 2}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 1, "description": "(40 % de chance par tour) Inflige 120 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Malédiction (2 tours) ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Seigneur des Neuf Cercles", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.2}, {"effet": "immunite", "afflictions": ["etourdi", "silence", "brulure"]}], "niveau": 10, "description": "ATK +20 % ; immunisé à Étourdissement, Silence, Brûlure."},
			{"nom": "Chaînes de Damnation", "type": "actif", "chance": 0.3, "cible": "arriere", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "etourdi", "chance": 0.35, "duree": 1}], "niveau": 20, "description": "(30 % de chance par tour) Inflige 150 % de puissance de skill aux ennemis de l'Arrière ; 35 % de chance d'infliger Étourdissement (1 tour)."},
			{"nom": "Immortel", "type": "passif", "effets": [{"effet": "survie", "charges": 1}, {"effet": "vol_vie", "valeur": 0.15}], "niveau": 30, "description": "Survit à un coup fatal avec 1 PV (1 fois par combat) ; vol de vie de 15 % sur ses attaques."},
		],
	},

	# ============================================================
	# ENNEMIS (non invocables)
	# ============================================================
	"cherubin": {
		"nom": "Chérubin Espiègle", "rarete": "N", "element": "sacre", "role": "soutien", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "f0d0a0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 505, "atk": 75, "def": 55, "agi": 90, "mag": 60},
		"secondaires": {"crit": 5, "degats_crit": 150, "res": 25, "preci": 95},
		"skills": [
			{"nom": "Petite Grâce", "type": "actif", "chance": 0.3, "cible": "allie_faible", "effets": [{"effet": "soin", "mult": 0.8}], "niveau": 1, "description": "(30 % de chance par tour) Soigne l'allié le plus blessé de 80 % de puissance de skill."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.15}, {"effet": "stat", "stat": "res", "valeur": 0.1}], "niveau": 10, "description": "Soins prodigués +15 % ; RES +10 %."},
			{"nom": "Bénédiction", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.8}, {"effet": "purification"}], "niveau": 20, "description": "(25 % de chance par tour) Soigne toute l'équipe de 80 % de puissance de skill ; retire les afflictions."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.08}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +8 % ; immunisé à Aveuglement."},
		],
	},
	"faucon_celeste": {
		"nom": "Faucon Céleste", "rarete": "N", "element": "sacre", "role": "tireur", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "e0c070",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 475, "atk": 125, "def": 45, "agi": 120, "mag": 30},
		"secondaires": {"crit": 12, "degats_crit": 170, "res": 8, "preci": 97},
		"skills": [
			{"nom": "Serres de Lumière", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "aveugle", "chance": 0.25, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 150 % de puissance de skill à un ennemi ; 25 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 6}], "niveau": 10, "description": "Précision +5 ; Crit +6."},
			{"nom": "Lance de Lumière", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "affliction", "nom": "aveugle", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 160 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.08}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +8 % ; immunisé à Aveuglement."},
		],
	},
	"nuee_vivante": {
		"nom": "Nuée Vivante", "rarete": "R", "element": "eau", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "b0c8e0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 640, "atk": 145, "def": 65, "agi": 120, "mag": 110},
		"secondaires": {"crit": 8, "degats_crit": 165, "res": 24, "preci": 95},
		"skills": [
			{"nom": "Averse Glacée", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.6}, {"effet": "affliction", "nom": "gel", "chance": 0.25, "duree": 1}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 60 % de puissance de skill à tous les ennemis ; 25 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.14}], "niveau": 10, "description": "MAG +14 %."},
			{"nom": "Blizzard", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}, {"effet": "affliction", "nom": "gel", "chance": 0.2, "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis ; 20 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.05}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 5 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"gardien_albatre": {
		"nom": "Gardien d'Albâtre", "rarete": "R", "element": "sacre", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "e8e0d0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1040, "atk": 130, "def": 135, "agi": 85, "mag": 40},
		"secondaires": {"crit": 5, "degats_crit": 155, "res": 20, "preci": 91},
		"skills": [
			{"nom": "Égide Blanche", "type": "actif", "chance": 0.3, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.14}, {"effet": "epines", "valeur": 0.07}], "niveau": 10, "description": "DEF +14 % ; renvoie 7 % des dégâts physiques reçus."},
			{"nom": "Égide Sacrée", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.1}, {"effet": "provocation", "duree": 1, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 10 % des PV max sur toute l'équipe ; attire les attaques ennemies (1 tour)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.09}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +9 % ; immunisé à Aveuglement."},
		],
	},
	"archer_cieux": {
		"nom": "Archer des Cieux", "rarete": "SR", "element": "sacre", "role": "tireur", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "d8c080",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 865, "atk": 270, "def": 105, "agi": 170, "mag": 85},
		"secondaires": {"crit": 14, "degats_crit": 180, "res": 12, "preci": 99},
		"skills": [
			{"nom": "Flèche Solaire", "type": "actif", "chance": 0.35, "cible": "arriere", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "aveugle", "chance": 0.3, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 150 % de puissance de skill aux ennemis de l'Arrière ; 30 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 8}], "niveau": 10, "description": "Précision +5 ; Crit +8."},
			{"nom": "Lance de Lumière", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}, {"effet": "affliction", "nom": "aveugle", "chance": 0.5, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.1}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +10 % ; immunisé à Aveuglement."},
		],
	},
	"pretresse_aube": {
		"nom": "Prêtresse de l'Aube", "rarete": "SR", "element": "sacre", "role": "soutien", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "f8e8c0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 920, "atk": 165, "def": 125, "agi": 125, "mag": 180},
		"secondaires": {"crit": 7, "degats_crit": 160, "res": 29, "preci": 97},
		"skills": [
			{"nom": "Hymne Matinal", "type": "actif", "chance": 0.3, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.6}, {"effet": "purification"}], "niveau": 1, "description": "(30 % de chance par tour) Soigne toute l'équipe de 60 % de puissance de skill ; retire les afflictions."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.2}, {"effet": "stat", "stat": "res", "valeur": 0.13}], "niveau": 10, "description": "Soins prodigués +20 % ; RES +13 %."},
			{"nom": "Bénédiction", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.9}, {"effet": "purification"}], "niveau": 20, "description": "(25 % de chance par tour) Soigne toute l'équipe de 90 % de puissance de skill ; retire les afflictions."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.1}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +10 % ; immunisé à Aveuglement."},
		],
	},
	"seraphin_ardent": {
		"nom": "Séraphin Ardent", "rarete": "SSR", "element": "feu", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "ffb040",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1120, "atk": 265, "def": 140, "agi": 175, "mag": 270},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Six Ailes de Feu", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.95}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 95 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Pluie de Braises", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cœur Ardent", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "ATK +14 % ; immunisé à Brûlure."},
		],
	},
	"valkyrie_celeste": {
		"nom": "Valkyrie Céleste", "rarete": "SSR", "element": "sacre", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "c8b890",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1400, "atk": 325, "def": 200, "agi": 175, "mag": 85},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Lance du Walhalla", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "affliction", "nom": "etourdi", "chance": 0.2, "duree": 1}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; 20 % de chance d'infliger Étourdissement (1 tour)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lance de Lumière", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "aveugle", "chance": 0.5, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +12 % ; immunisé à Aveuglement."},
		],
	},
	"dominion": {
		"nom": "Dominion Couronné", "rarete": "SSR", "element": "eau", "role": "soutien", "position": "arriere",
		"invocable": false, "categorie": "ennemi", "couleur": "90b0e0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1260, "atk": 205, "def": 180, "agi": 160, "mag": 255},
		"secondaires": {"crit": 8, "degats_crit": 165, "res": 31, "preci": 98},
		"skills": [
			{"nom": "Loi Céleste", "type": "actif", "chance": 0.3, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.12}, {"effet": "buff", "stat": "mag", "valeur": 0.15, "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Bouclier de 12 % des PV max sur toute l'équipe ; MAG +15 % pour toute l'équipe (2 tours)."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.22}, {"effet": "stat", "stat": "res", "valeur": 0.14}], "niveau": 10, "description": "Soins prodigués +22 % ; RES +14 %."},
			{"nom": "Source Apaisante", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.85}, {"effet": "purification"}], "niveau": 20, "description": "(25 % de chance par tour) Soigne toute l'équipe de 85 % de puissance de skill ; retire les afflictions."},
			{"nom": "Flux Vital", "type": "passif", "effets": [{"effet": "regen", "valeur": 0.06}, {"effet": "immunite", "afflictions": ["gel"]}], "niveau": 30, "description": "Régénère 6 % de ses PV max à chaque tour ; immunisé à Gel."},
		],
	},
	"trone_vivant": {
		"nom": "Trône Vivant", "rarete": "SSR", "element": "sacre", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "fff0b0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1820, "atk": 235, "def": 280, "agi": 120, "mag": 100},
		"secondaires": {"crit": 7, "degats_crit": 165, "res": 24, "preci": 93},
		"skills": [
			{"nom": "Roue de Mille Yeux", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.7}, {"effet": "affliction", "nom": "aveugle", "chance": 0.4, "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Inflige 70 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.17}, {"effet": "epines", "valeur": 0.09}], "niveau": 10, "description": "DEF +17 % ; renvoie 9 % des dégâts physiques reçus."},
			{"nom": "Égide Sacrée", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.15}, {"effet": "provocation", "duree": 1, "cible": "soi"}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 15 % des PV max sur toute l'équipe ; attire les attaques ennemies (1 tour)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.12}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +12 % ; immunisé à Aveuglement."},
		],
	},
	"archange_justicier": {
		"nom": "Archange Justicier", "rarete": "UR", "element": "sacre", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "ffe080",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1570, "atk": 445, "def": 170, "agi": 335, "mag": 140},
		"secondaires": {"crit": 22, "degats_crit": 205, "res": 14, "preci": 100},
		"skills": [
			{"nom": "Sentence Divine", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 220 % de puissance de skill à un ennemi."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 13}, {"effet": "stat", "stat": "degats_crit", "valeur": 24}], "niveau": 10, "description": "Crit +13 ; Dégâts crit +24 %."},
			{"nom": "Frappe Purificatrice", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "affliction", "nom": "silence", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Silence (2 tours)."},
			{"nom": "Aura Bénie", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.13}, {"effet": "immunite", "afflictions": ["aveugle"]}], "niveau": 30, "description": "Toute l'équipe : DEF +13 % ; immunisé à Aveuglement."},
		],
	},
	"puissance_celeste": {
		"nom": "Puissance Céleste", "rarete": "UR", "element": "nature", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "ennemi", "couleur": "a0d080",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1850, "atk": 405, "def": 245, "agi": 240, "mag": 115},
		"secondaires": {"crit": 12, "degats_crit": 180, "res": 18, "preci": 96},
		"skills": [
			{"nom": "Glaive des Vertus", "type": "actif", "chance": 0.35, "cible": "avant", "effets": [{"effet": "degats", "mult": 1.4}, {"effet": "debuff", "stat": "def", "valeur": 0.2, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 140 % de puissance de skill aux ennemis de l'Avant ; DEF -20 % pour les ennemis de l'Avant (2 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.16}], "niveau": 10, "description": "ATK +16 %."},
			{"nom": "Dard Empoisonné", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.85}, {"effet": "affliction", "nom": "poison", "chance": 0.7, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 185 % de puissance de skill à un ennemi ; 70 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Tenace", "type": "passif", "effets": [{"effet": "stat", "stat": "pv", "valeur": 0.19}, {"effet": "immunite", "afflictions": ["poison"]}], "niveau": 30, "description": "PV +19 % ; immunisé à Poison."},
		],
	},

	# ============================================================
	# BOSS (non invocables)
	# ============================================================
	"gardien_nuees": {
		"nom": "Gardien des Nuées", "rarete": "SR", "element": "eau", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "a0c0e0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Tempête Céleste", "texte": "Les nuées se changent en tempête."},
		"stats": {"pv": 1660, "atk": 190, "def": 195, "agi": 100, "mag": 70},
		"secondaires": {"crit": 6, "degats_crit": 160, "res": 22, "preci": 92},
		"skills": [
			{"nom": "Voile de Brume", "type": "actif", "chance": 0.35, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.15}], "niveau": 1, "description": "(35 % de chance par tour) Bouclier de 15 % des PV max sur toute l'équipe."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.16}, {"effet": "epines", "valeur": 0.08}], "niveau": 10, "description": "DEF +16 % ; renvoie 8 % des dégâts physiques reçus."},
			{"nom": "Carapace des Marées", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "res", "valeur": 0.25, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; RES +25 % pour lui-même (3 tours)."},
			{"nom": "Brume Protectrice", "type": "passif", "effets": [{"effet": "aura", "stat": "def", "valeur": 0.12}, {"effet": "regen", "valeur": 0.04}], "niveau": 30, "description": "Toute l'équipe : DEF +12 % ; régénère 4 % de ses PV max à chaque tour."},
		],
	},
	"aethel": {
		"nom": "Aethel, Héraut Doré", "rarete": "SR", "element": "sacre", "role": "tireur", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "ffd060",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Fanfare Dorée", "texte": "Aethel sonne l'appel des cieux."},
		"stats": {"pv": 1085, "atk": 270, "def": 105, "agi": 170, "mag": 85},
		"secondaires": {"crit": 14, "degats_crit": 180, "res": 12, "preci": 99},
		"skills": [
			{"nom": "Trompe du Matin", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.9}, {"effet": "affliction", "nom": "aveugle", "chance": 0.35, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 90 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Œil de Faucon", "type": "passif", "effets": [{"effet": "stat", "stat": "preci", "valeur": 5}, {"effet": "stat", "stat": "crit", "valeur": 8}], "niveau": 10, "description": "Précision +5 ; Crit +8."},
			{"nom": "Lance de Lumière", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}, {"effet": "affliction", "nom": "aveugle", "chance": 0.5, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Premier Rayon", "type": "passif", "effets": [{"effet": "premier"}, {"effet": "stat", "stat": "crit", "valeur": 15}], "niveau": 30, "description": "Agit toujours en premier au 1er tour ; Crit +15."},
		],
	},
	"dame_albatre": {
		"nom": "La Dame d'Albâtre", "rarete": "SSR", "element": "sacre", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "f0f0e8",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Albâtre Brisé", "texte": "La Dame se fissure et libère une lumière aveuglante."},
		"stats": {"pv": 1400, "atk": 265, "def": 140, "agi": 175, "mag": 270},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Pétrification Sainte", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.95}, {"effet": "affliction", "nom": "etourdi", "chance": 0.2, "duree": 1}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 95 % de puissance de skill à tous les ennemis ; 20 % de chance d'infliger Étourdissement (1 tour)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Rayon Sacré", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "aveugle", "chance": 0.3, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 30 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Beauté de Marbre", "type": "passif", "effets": [{"effet": "survie", "charges": 1}, {"effet": "immunite", "afflictions": ["etourdi", "silence"]}], "niveau": 30, "description": "Survit à un coup fatal avec 1 PV (1 fois par combat) ; immunisé à Étourdissement, Silence."},
		],
	},
	"oriel": {
		"nom": "Oriel, Lame de l'Aube", "rarete": "SSR", "element": "sacre", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "ffe0a0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Midi Éternel", "texte": "Le soleil s'arrête au-dessus d'Oriel."},
		"stats": {"pv": 1750, "atk": 325, "def": 200, "agi": 175, "mag": 85},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Aube Tranchante", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.1}, {"effet": "affliction", "nom": "aveugle", "chance": 0.4, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 210 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lance de Lumière", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "aveugle", "chance": 0.5, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Zénith", "type": "passif", "effets": [{"effet": "execution", "valeur": 0.3}, {"effet": "stat", "stat": "atk", "valeur": 0.15}], "niveau": 30, "description": "+30 % de dégâts contre les cibles sous 50 % de PV ; ATK +15 %."},
		],
	},
	"choeur_incarne": {
		"nom": "Le Chœur Incarné", "rarete": "SSR", "element": "eau", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "c0d8ff",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Crescendo", "texte": "Le chant devient insoutenable."},
		"stats": {"pv": 1400, "atk": 265, "def": 140, "agi": 175, "mag": 270},
		"secondaires": {"crit": 10, "degats_crit": 175, "res": 28, "preci": 97},
		"skills": [
			{"nom": "Cantique Assourdissant", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.0}, {"effet": "affliction", "nom": "silence", "chance": 0.4, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 100 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Silence (2 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.17}], "niveau": 10, "description": "MAG +17 %."},
			{"nom": "Blizzard", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.75}, {"effet": "affliction", "nom": "gel", "chance": 0.25, "duree": 1}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 75 % de puissance de skill à tous les ennemis ; 25 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Grand Cantique", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 1.0}, {"effet": "buff", "stat": "mag", "valeur": 0.2, "duree": 3}], "niveau": 30, "description": "(25 % de chance par tour) Soigne toute l'équipe de 100 % de puissance de skill ; MAG +20 % pour toute l'équipe (3 tours)."},
		],
	},
	"ophanim": {
		"nom": "Ophanim, la Roue Ardente", "rarete": "SSR", "element": "feu", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "ffa020",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Roue Enflammée", "texte": "Les roues d'Ophanim s'embrasent et tournent de plus en plus vite."},
		"stats": {"pv": 2275, "atk": 235, "def": 280, "agi": 120, "mag": 100},
		"secondaires": {"crit": 7, "degats_crit": 165, "res": 24, "preci": 93},
		"skills": [
			{"nom": "Roues de Feu", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.9}, {"effet": "affliction", "nom": "brulure", "chance": 0.45, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 90 % de puissance de skill à tous les ennemis ; 45 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.17}, {"effet": "epines", "valeur": 0.09}], "niveau": 10, "description": "DEF +17 % ; renvoie 9 % des dégâts physiques reçus."},
			{"nom": "Bouclier de Braise", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; ATK +20 % pour lui-même (2 tours)."},
			{"nom": "Mille Yeux", "type": "passif", "effets": [{"effet": "epines", "valeur": 0.25}, {"effet": "immunite", "afflictions": ["aveugle", "etourdi"]}], "niveau": 30, "description": "Renvoie 25 % des dégâts physiques reçus ; immunisé à Aveuglement, Étourdissement."},
		],
	},
	"valkaria": {
		"nom": "Valkaria, Reine des Valkyries", "rarete": "UR", "element": "sacre", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "e0c060",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Dernière Chevauchée", "texte": "Valkaria appelle les âmes des braves."},
		"stats": {"pv": 2310, "atk": 405, "def": 245, "agi": 240, "mag": 115},
		"secondaires": {"crit": 12, "degats_crit": 180, "res": 18, "preci": 96},
		"skills": [
			{"nom": "Charge des Élues", "type": "actif", "chance": 0.35, "cible": "avant", "effets": [{"effet": "degats", "mult": 1.6}, {"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 2, "cible": "allies"}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 160 % de puissance de skill aux ennemis de l'Avant ; ATK +20 % pour toute l'équipe (2 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.16}], "niveau": 10, "description": "ATK +16 %."},
			{"nom": "Lance de Lumière", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "affliction", "nom": "aveugle", "chance": 0.55, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; 55 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Chevauchée des Valkyries", "type": "passif", "effets": [{"effet": "aura", "stat": "agi", "valeur": 0.15}, {"effet": "double_attaque", "chance": 0.2}], "niveau": 30, "description": "Toute l'équipe : AGI +15 % ; 20 % de chance d'attaquer deux fois."},
		],
	},
	"serapheon": {
		"nom": "Sérapheon, Flamme Divine", "rarete": "UR", "element": "feu", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "ff8000",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Flamme Divine", "texte": "Sérapheon devient un brasier de lumière pure."},
		"stats": {"pv": 1850, "atk": 335, "def": 170, "agi": 240, "mag": 370},
		"secondaires": {"crit": 11, "degats_crit": 180, "res": 30, "preci": 98},
		"skills": [
			{"nom": "Feu Purificateur", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.2}, {"effet": "affliction", "nom": "brulure", "chance": 0.5, "duree": 3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 120 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Brûlure (3 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.19}], "niveau": 10, "description": "MAG +19 %."},
			{"nom": "Pluie de Braises", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Soleil de Justice", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "brulure", "chance": 0.6, "duree": 3}], "niveau": 30, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à tous les ennemis ; 60 % de chance d'infliger Brûlure (3 tours)."},
		],
	},
	"azarel": {
		"nom": "Azarel, Archange du Jugement", "rarete": "UR", "element": "sacre", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "boss", "couleur": "fff8d0",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Verdict", "texte": "Azarel lève son glaive : le jugement est rendu."},
		"stats": {"pv": 1965, "atk": 445, "def": 170, "agi": 335, "mag": 140},
		"secondaires": {"crit": 22, "degats_crit": 205, "res": 14, "preci": 100},
		"skills": [
			{"nom": "Balance du Jugement", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.4}, {"effet": "affliction", "nom": "silence", "chance": 0.4, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 240 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Silence (2 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 13}, {"effet": "stat", "stat": "degats_crit", "valeur": 24}], "niveau": 10, "description": "Crit +13 ; Dégâts crit +24 %."},
			{"nom": "Frappe Purificatrice", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.0}, {"effet": "affliction", "nom": "silence", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 200 % de puissance de skill à un ennemi ; 40 % de chance d'infliger Silence (2 tours)."},
			{"nom": "Glaive du Jugement", "type": "passif", "effets": [{"effet": "execution", "valeur": 0.4}, {"effet": "survie", "charges": 1}], "niveau": 30, "description": "+40 % de dégâts contre les cibles sous 50 % de PV ; survit à un coup fatal avec 1 PV (1 fois par combat)."},
		],
	},
	"aurelys": {
		"nom": "Aurelys, la Lumière Primordiale", "rarete": "UR", "element": "sacre", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss", "couleur": "ffffff",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "La Première Aube", "texte": "Aurelys révèle sa lumière véritable : les cieux s'ouvrent !"},
		"stats": {"pv": 1850, "atk": 335, "def": 170, "agi": 240, "mag": 370},
		"secondaires": {"crit": 13, "degats_crit": 190, "res": 35, "preci": 100},
		"skills": [
			{"nom": "Genèse", "type": "actif", "chance": 0.4, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.2}, {"effet": "affliction", "nom": "aveugle", "chance": 0.5, "duree": 2}, {"effet": "affliction", "nom": "etourdi", "chance": 0.15, "duree": 1}], "niveau": 1, "description": "(40 % de chance par tour) Inflige 120 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Aveuglement (2 tours) ; 15 % de chance d'infliger Étourdissement (1 tour)."},
			{"nom": "Lumière Incréée", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.2}, {"effet": "immunite", "afflictions": ["etourdi", "silence", "aveugle"]}], "niveau": 10, "description": "MAG +20 % ; immunisé à Étourdissement, Silence, Aveuglement."},
			{"nom": "Rayon Primordial", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 2.6}, {"effet": "degats", "mult": 0.0}], "niveau": 20, "description": "(30 % de chance par tour) Inflige 260 % de puissance de skill à un ennemi ; inflige 0 % de puissance de skill à un ennemi."},
			{"nom": "Résurrection Céleste", "type": "actif", "chance": 0.2, "cible": "allies", "effets": [{"effet": "ressusciter", "valeur": 0.5}, {"effet": "soin", "mult": 0.8}], "niveau": 30, "description": "(20 % de chance par tour) Ranime un allié K.O. avec 50 % de ses PV ; soigne toute l'équipe de 80 % de puissance de skill."},
		],
	},

	# ============================================================
	# BOSS DE MONDE (un par jour de la semaine)
	# ============================================================
	"behemoth_cendres": {
		"nom": "Béhémoth des Cendres", "rarete": "UR", "element": "feu", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "boss_monde", "couleur": "8a2a00",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Cœur de Volcan", "texte": "Le Béhémoth s'embrase : la terre entière se fend !"},
		"stats": {"pv": 2405, "atk": 295, "def": 345, "agi": 170, "mag": 140},
		"secondaires": {"crit": 10, "degats_crit": 180, "res": 31, "preci": 96},
		"skills": [
			{"nom": "Souffle de Magma", "type": "actif", "chance": 0.45, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "brulure", "chance": 0.5, "duree": 2}], "niveau": 1, "description": "(45 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Cuir de Lave", "type": "passif", "effets": [{"effet": "immunite", "afflictions": ["etourdi", "gel", "silence"]}, {"effet": "epines", "valeur": 0.1}], "niveau": 10, "description": "Immunisé à Étourdissement, Gel, Silence ; renvoie 10 % des dégâts physiques reçus."},
			{"nom": "Piétinement", "type": "actif", "chance": 0.35, "cible": "avant", "effets": [{"effet": "degats", "mult": 1.3}, {"effet": "affliction", "nom": "etourdi", "chance": 0.3, "duree": 1}], "niveau": 20, "description": "(35 % de chance par tour) Inflige 130 % de puissance de skill aux ennemis de l'Avant ; 30 % de chance d'infliger Étourdissement (1 tour)."},
			{"nom": "Éruption", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.1}, {"effet": "affliction", "nom": "brulure", "chance": 0.6, "duree": 3}], "niveau": 30, "description": "(30 % de chance par tour) Inflige 110 % de puissance de skill à tous les ennemis ; 60 % de chance d'infliger Brûlure (3 tours)."},
		],
	},
	"leviathan_noir": {
		"nom": "Léviathan des Abysses Noires", "rarete": "UR", "element": "eau", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss_monde", "couleur": "0a2a4a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Abysse Sans Fond", "texte": "Le Léviathan entraîne le champ de bataille sous les flots."},
		"stats": {"pv": 1850, "atk": 405, "def": 245, "agi": 240, "mag": 115},
		"secondaires": {"crit": 14, "degats_crit": 190, "res": 23, "preci": 98},
		"skills": [
			{"nom": "Raz-de-Marée", "type": "actif", "chance": 0.45, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.8}, {"effet": "affliction", "nom": "gel", "chance": 0.35, "duree": 1}], "niveau": 1, "description": "(45 % de chance par tour) Inflige 80 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Gel (1 tour)."},
			{"nom": "Écailles Abyssales", "type": "passif", "effets": [{"effet": "immunite", "afflictions": ["etourdi", "gel", "silence"]}, {"effet": "stat", "stat": "def", "valeur": 0.15}], "niveau": 10, "description": "Immunisé à Étourdissement, Gel, Silence ; DEF +15 %."},
			{"nom": "Tourbillon", "type": "actif", "chance": 0.35, "cible": "arriere", "effets": [{"effet": "degats", "mult": 1.3}, {"effet": "debuff", "stat": "agi", "valeur": 0.25, "duree": 2}], "niveau": 20, "description": "(35 % de chance par tour) Inflige 130 % de puissance de skill aux ennemis de l'Arrière ; AGI -25 % pour les ennemis de l'Arrière (2 tours)."},
			{"nom": "Engloutissement", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 3.0}, {"effet": "drain", "valeur": 0.3}], "niveau": 30, "description": "(30 % de chance par tour) Inflige 300 % de puissance de skill à un ennemi ; rend au lanceur 30 % des dégâts infligés."},
		],
	},
	"yggdravor": {
		"nom": "Yggdravor, l'Arbre-Monde Corrompu", "rarete": "UR", "element": "nature", "role": "soutien", "position": "arriere",
		"invocable": false, "categorie": "boss_monde", "couleur": "2a4a0a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Racines du Monde", "texte": "L'Arbre-Monde réveille chacune de ses racines."},
		"stats": {"pv": 1665, "atk": 260, "def": 220, "agi": 215, "mag": 345},
		"secondaires": {"crit": 11, "degats_crit": 180, "res": 38, "preci": 100},
		"skills": [
			{"nom": "Racines Voraces", "type": "actif", "chance": 0.45, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.75}, {"effet": "affliction", "nom": "poison", "chance": 0.5, "duree": 3}], "niveau": 1, "description": "(45 % de chance par tour) Inflige 75 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Poison (3 tours)."},
			{"nom": "Sève Éternelle", "type": "passif", "effets": [{"effet": "immunite", "afflictions": ["etourdi", "gel", "silence"]}, {"effet": "regen", "valeur": 0.02}], "niveau": 10, "description": "Immunisé à Étourdissement, Gel, Silence ; régénère 2 % de ses PV max à chaque tour."},
			{"nom": "Ronces du Monde", "type": "actif", "chance": 0.35, "cible": "avant", "effets": [{"effet": "degats", "mult": 1.2}, {"effet": "affliction", "nom": "saignement", "chance": 0.5, "duree": 3}], "niveau": 20, "description": "(35 % de chance par tour) Inflige 120 % de puissance de skill aux ennemis de l'Avant ; 50 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Floraison Toxique", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.9}, {"effet": "affliction", "nom": "poison", "chance": 0.6, "duree": 3}, {"effet": "debuff", "stat": "res", "valeur": 0.2, "duree": 2}], "niveau": 30, "description": "(30 % de chance par tour) Inflige 90 % de puissance de skill à tous les ennemis ; 60 % de chance d'infliger Poison (3 tours) ; RES -20 % pour tous les ennemis (2 tours)."},
		],
	},
	"golgoth": {
		"nom": "Golgoth, Colosse de Pierre-Sang", "rarete": "UR", "element": "nature", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "boss_monde", "couleur": "5a3a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Montagne Vivante", "texte": "Golgoth arrache la montagne sur laquelle il se tient."},
		"stats": {"pv": 2405, "atk": 295, "def": 345, "agi": 170, "mag": 140},
		"secondaires": {"crit": 10, "degats_crit": 180, "res": 31, "preci": 96},
		"skills": [
			{"nom": "Éboulement", "type": "actif", "chance": 0.45, "cible": "avant", "effets": [{"effet": "degats", "mult": 1.3}, {"effet": "affliction", "nom": "etourdi", "chance": 0.3, "duree": 1}], "niveau": 1, "description": "(45 % de chance par tour) Inflige 130 % de puissance de skill aux ennemis de l'Avant ; 30 % de chance d'infliger Étourdissement (1 tour)."},
			{"nom": "Corps de Pierre-Sang", "type": "passif", "effets": [{"effet": "immunite", "afflictions": ["etourdi", "gel", "silence"]}, {"effet": "stat", "stat": "def", "valeur": 0.35}, {"effet": "epines", "valeur": 0.15}], "niveau": 10, "description": "Immunisé à Étourdissement, Gel, Silence ; DEF +35 % ; renvoie 15 % des dégâts physiques reçus."},
			{"nom": "Séisme", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.9}, {"effet": "affliction", "nom": "etourdi", "chance": 0.2, "duree": 1}], "niveau": 20, "description": "(35 % de chance par tour) Inflige 90 % de puissance de skill à tous les ennemis ; 20 % de chance d'infliger Étourdissement (1 tour)."},
			{"nom": "Poing de la Montagne", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 3.2}], "niveau": 30, "description": "(30 % de chance par tour) Inflige 320 % de puissance de skill à un ennemi."},
		],
	},
	"solgard": {
		"nom": "Solgard, le Soleil Vivant", "rarete": "UR", "element": "sacre", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "boss_monde", "couleur": "ffcc33",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Zénith Absolu", "texte": "Solgard brille comme mille soleils."},
		"stats": {"pv": 1480, "atk": 335, "def": 170, "agi": 240, "mag": 370},
		"secondaires": {"crit": 13, "degats_crit": 190, "res": 35, "preci": 100},
		"skills": [
			{"nom": "Éruption Solaire", "type": "actif", "chance": 0.45, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "aveugle", "chance": 0.45, "duree": 2}], "niveau": 1, "description": "(45 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 45 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Couronne Solaire", "type": "passif", "effets": [{"effet": "immunite", "afflictions": ["etourdi", "gel", "silence"]}, {"effet": "immunite", "afflictions": ["aveugle", "brulure"]}], "niveau": 10, "description": "Immunisé à Étourdissement, Gel, Silence ; immunisé à Aveuglement, Brûlure."},
			{"nom": "Rayon Brûlant", "type": "actif", "chance": 0.35, "cible": "arriere", "effets": [{"effet": "degats", "mult": 1.3}, {"effet": "affliction", "nom": "brulure", "chance": 0.4, "duree": 2}], "niveau": 20, "description": "(35 % de chance par tour) Inflige 130 % de puissance de skill aux ennemis de l'Arrière ; 40 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Supernova", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.3}, {"effet": "affliction", "nom": "aveugle", "chance": 0.5, "duree": 2}], "niveau": 30, "description": "(25 % de chance par tour) Inflige 130 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Aveuglement (2 tours)."},
		],
	},
	"nidhogr": {
		"nom": "Nidhögr, Dévoreur d'Étoiles", "rarete": "UR", "element": "tenebres", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "boss_monde", "couleur": "1a0a2a",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Dévoreur de Mondes", "texte": "Nidhögr ouvre sa gueule sur les étoiles elles-mêmes."},
		"stats": {"pv": 1570, "atk": 445, "def": 170, "agi": 335, "mag": 140},
		"secondaires": {"crit": 24, "degats_crit": 215, "res": 19, "preci": 100},
		"skills": [
			{"nom": "Gueule du Vide", "type": "actif", "chance": 0.45, "cible": "arriere", "effets": [{"effet": "degats", "mult": 1.3}, {"effet": "affliction", "nom": "malediction", "chance": 0.5, "duree": 2}], "niveau": 1, "description": "(45 % de chance par tour) Inflige 130 % de puissance de skill aux ennemis de l'Arrière ; 50 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Écailles d'Étoiles", "type": "passif", "effets": [{"effet": "immunite", "afflictions": ["etourdi", "gel", "silence"]}, {"effet": "immunite", "afflictions": ["malediction"]}, {"effet": "stat", "stat": "crit", "valeur": 15}], "niveau": 10, "description": "Immunisé à Étourdissement, Gel, Silence ; immunisé à Malédiction ; Crit +15."},
			{"nom": "Ailes du Néant", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.9}, {"effet": "affliction", "nom": "silence", "chance": 0.35, "duree": 2}], "niveau": 20, "description": "(35 % de chance par tour) Inflige 90 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Silence (2 tours)."},
			{"nom": "Dévorer", "type": "actif", "chance": 0.3, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 3.0}, {"effet": "drain", "valeur": 0.4}], "niveau": 30, "description": "(30 % de chance par tour) Inflige 300 % de puissance de skill à un ennemi ; rend au lanceur 40 % des dégâts infligés."},
		],
	},
	"avatar_sang": {
		"nom": "L'Avatar du Sang Originel", "rarete": "UR", "element": "tenebres", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "boss_monde", "couleur": "6a0000",
		"legende": false, "forge": false, "race": "", "dominantes": [], "phase2": {"nom": "Le Premier Sang", "texte": "L'Avatar absorbe tout le sang versé sur le champ de bataille !"},
		"stats": {"pv": 1850, "atk": 405, "def": 245, "agi": 240, "mag": 115},
		"secondaires": {"crit": 14, "degats_crit": 190, "res": 23, "preci": 98},
		"skills": [
			{"nom": "Marée de Sang", "type": "actif", "chance": 0.45, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "saignement", "chance": 0.5, "duree": 3}, {"effet": "drain", "valeur": 0.15}], "niveau": 1, "description": "(45 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Saignement (3 tours) ; rend au lanceur 15 % des dégâts infligés."},
			{"nom": "Sang Originel", "type": "passif", "effets": [{"effet": "immunite", "afflictions": ["etourdi", "gel", "silence"]}, {"effet": "vol_vie", "valeur": 0.1}, {"effet": "rage", "stat": "atk", "valeur": 0.3}], "niveau": 10, "description": "Immunisé à Étourdissement, Gel, Silence ; vol de vie de 10 % sur ses attaques ; sous 50 % de PV : ATK +30 %."},
			{"nom": "Fléau Écarlate", "type": "actif", "chance": 0.35, "cible": "arriere", "effets": [{"effet": "degats", "mult": 1.3}, {"effet": "affliction", "nom": "saignement", "chance": 0.5, "duree": 3}], "niveau": 20, "description": "(35 % de chance par tour) Inflige 130 % de puissance de skill aux ennemis de l'Arrière ; 50 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Éclipse de Sang", "type": "actif", "chance": 0.3, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.2}, {"effet": "affliction", "nom": "malediction", "chance": 0.5, "duree": 2}, {"effet": "drain", "valeur": 0.2}], "niveau": 30, "description": "(30 % de chance par tour) Inflige 120 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Malédiction (2 tours) ; rend au lanceur 20 % des dégâts infligés."},
		],
	},

	# ============================================================
	# HÉROS DE FORGE (créés au Reliquaire, non invocables)
	# ============================================================
	"belzaroth": {
		"nom": "Belzaroth, Prince des Braises", "rarete": "SSR", "element": "feu", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "heros", "couleur": "b02000",
		"legende": false, "forge": true, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1485, "atk": 345, "def": 210, "agi": 185, "mag": 90},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Épée de Braise", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "brulure", "chance": 0.45, "duree": 3}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 45 % de chance d'infliger Brûlure (3 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Brasier Dévorant", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.9}, {"effet": "affliction", "nom": "brulure", "chance": 0.45, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 90 % de puissance de skill à tous les ennemis ; 45 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Couronne de Braises", "type": "passif", "effets": [{"effet": "rage", "stat": "atk", "valeur": 0.35}, {"effet": "immunite", "afflictions": ["brulure"]}], "niveau": 30, "description": "Sous 50 % de PV : ATK +35 % ; immunisé à Brûlure."},
		],
	},
	"nyxara": {
		"nom": "Nyxara la Succube", "rarete": "SSR", "element": "tenebres", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "heros", "couleur": "8a0a6a",
		"legende": false, "forge": true, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1260, "atk": 375, "def": 150, "agi": 260, "mag": 110},
		"secondaires": {"crit": 21, "degats_crit": 200, "res": 12, "preci": 99},
		"skills": [
			{"nom": "Étreinte Fatale", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.8}, {"effet": "drain", "valeur": 0.35}, {"effet": "affliction", "nom": "silence", "chance": 0.3, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 180 % de puissance de skill à un ennemi ; rend au lanceur 35 % des dégâts infligés ; 30 % de chance d'infliger Silence (2 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 12}, {"effet": "stat", "stat": "degats_crit", "valeur": 22}], "niveau": 10, "description": "Crit +12 ; Dégâts crit +22 %."},
			{"nom": "Lacération", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.75}, {"effet": "affliction", "nom": "saignement", "chance": 0.8, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 175 % de puissance de skill à un ennemi ; 80 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Charme Irrésistible", "type": "passif", "effets": [{"effet": "aura_ennemis", "stat": "atk", "valeur": 0.1}, {"effet": "vol_vie", "valeur": 0.18}], "niveau": 30, "description": "Tous les ennemis : ATK -10 % ; vol de vie de 18 % sur ses attaques."},
		],
	},
	"mephistar": {
		"nom": "Méphistar, Seigneur de l'Abîme", "rarete": "UR", "element": "tenebres", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "heros", "couleur": "2a0010",
		"legende": false, "forge": true, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1570, "atk": 355, "def": 180, "agi": 255, "mag": 390},
		"secondaires": {"crit": 11, "degats_crit": 180, "res": 30, "preci": 98},
		"skills": [
			{"nom": "Pacte de l'Abîme", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.1}, {"effet": "affliction", "nom": "malediction", "chance": 0.5, "duree": 2}, {"effet": "affliction", "nom": "brulure", "chance": 0.3, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 110 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Malédiction (2 tours) ; 30 % de chance d'infliger Brûlure (2 tours)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.19}], "niveau": 10, "description": "MAG +19 %."},
			{"nom": "Ombres Dévorantes", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "malediction", "chance": 0.5, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 50 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Portes de l'Abîme", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.5}, {"effet": "affliction", "nom": "malediction", "chance": 0.6, "duree": 2}, {"effet": "debuff", "stat": "res", "valeur": 0.2, "duree": 2}], "niveau": 30, "description": "(25 % de chance par tour) Inflige 150 % de puissance de skill à tous les ennemis ; 60 % de chance d'infliger Malédiction (2 tours) ; RES -20 % pour tous les ennemis (2 tours)."},
		],
	},
	"seraphine_aube": {
		"nom": "Séraphine d'Aube", "rarete": "SSR", "element": "sacre", "role": "soutien", "position": "arriere",
		"invocable": false, "categorie": "heros", "couleur": "fff0c0",
		"legende": false, "forge": true, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1335, "atk": 220, "def": 190, "agi": 165, "mag": 270},
		"secondaires": {"crit": 8, "degats_crit": 165, "res": 31, "preci": 98},
		"skills": [
			{"nom": "Lumière Salvatrice", "type": "actif", "chance": 0.35, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.75}, {"effet": "purification"}], "niveau": 1, "description": "(35 % de chance par tour) Soigne toute l'équipe de 75 % de puissance de skill ; retire les afflictions."},
			{"nom": "Grâce Protectrice", "type": "passif", "effets": [{"effet": "soin_bonus", "valeur": 0.22}, {"effet": "stat", "stat": "res", "valeur": 0.14}], "niveau": 10, "description": "Soins prodigués +22 % ; RES +14 %."},
			{"nom": "Bénédiction", "type": "actif", "chance": 0.25, "cible": "allies", "effets": [{"effet": "soin", "mult": 0.95}, {"effet": "purification"}], "niveau": 20, "description": "(25 % de chance par tour) Soigne toute l'équipe de 95 % de puissance de skill ; retire les afflictions."},
			{"nom": "Aube Nouvelle", "type": "actif", "chance": 0.15, "cible": "allies", "effets": [{"effet": "ressusciter", "valeur": 0.6}, {"effet": "soin", "mult": 0.6}], "niveau": 30, "description": "(15 % de chance par tour) Ranime un allié K.O. avec 60 % de ses PV ; soigne toute l'équipe de 60 % de puissance de skill."},
		],
	},
	"solarius": {
		"nom": "Solarius, l'Archange Solaire", "rarete": "SSR", "element": "sacre", "role": "guerrier", "position": "avant",
		"invocable": false, "categorie": "heros", "couleur": "ffd040",
		"legende": false, "forge": true, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1485, "atk": 345, "def": 210, "agi": 185, "mag": 90},
		"secondaires": {"crit": 11, "degats_crit": 175, "res": 16, "preci": 95},
		"skills": [
			{"nom": "Lame du Zénith", "type": "actif", "chance": 0.35, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "aveugle", "chance": 0.45, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 45 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Maîtrise des Armes", "type": "passif", "effets": [{"effet": "stat", "stat": "atk", "valeur": 0.14}], "niveau": 10, "description": "ATK +14 %."},
			{"nom": "Lance de Lumière", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "aveugle", "chance": 0.5, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 190 % de puissance de skill à un ennemi ; 50 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Aile Solaire", "type": "passif", "effets": [{"effet": "aura", "stat": "atk", "valeur": 0.12}, {"effet": "survie", "charges": 1}], "niveau": 30, "description": "Toute l'équipe : ATK +12 % ; survit à un coup fatal avec 1 PV (1 fois par combat)."},
		],
	},
	"aurelion": {
		"nom": "Aurelion, Premier Séraphin", "rarete": "UR", "element": "sacre", "role": "mage", "position": "arriere",
		"invocable": false, "categorie": "heros", "couleur": "fffae0",
		"legende": false, "forge": true, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1570, "atk": 355, "def": 180, "agi": 255, "mag": 390},
		"secondaires": {"crit": 11, "degats_crit": 180, "res": 30, "preci": 98},
		"skills": [
			{"nom": "Jugement Céleste", "type": "actif", "chance": 0.35, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 1.1}, {"effet": "affliction", "nom": "aveugle", "chance": 0.4, "duree": 2}, {"effet": "affliction", "nom": "silence", "chance": 0.2, "duree": 1}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 110 % de puissance de skill à tous les ennemis ; 40 % de chance d'infliger Aveuglement (2 tours) ; 20 % de chance d'infliger Silence (1 tour)."},
			{"nom": "Flux Arcanique", "type": "passif", "effets": [{"effet": "stat", "stat": "mag", "valeur": 0.19}], "niveau": 10, "description": "MAG +19 %."},
			{"nom": "Rayon Sacré", "type": "actif", "chance": 0.25, "cible": "ennemis", "effets": [{"effet": "degats", "mult": 0.85}, {"effet": "affliction", "nom": "aveugle", "chance": 0.35, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 85 % de puissance de skill à tous les ennemis ; 35 % de chance d'infliger Aveuglement (2 tours)."},
			{"nom": "Chœur Éternel", "type": "actif", "chance": 0.2, "cible": "allies", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "regen_temp", "valeur": 0.06, "duree": 3}, {"effet": "buff", "stat": "mag", "valeur": 0.2, "duree": 3}], "niveau": 30, "description": "(20 % de chance par tour) Bouclier de 20 % des PV max sur toute l'équipe ; régénère 6 % des PV par tour (3 tours) ; MAG +20 % pour toute l'équipe (3 tours)."},
		],
	},
	"rejeton_behemoth": {
		"nom": "Rejeton du Béhémoth", "rarete": "SSR", "element": "feu", "role": "tank", "position": "avant",
		"invocable": false, "categorie": "heros", "couleur": "a03a10",
		"legende": false, "forge": true, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1930, "atk": 250, "def": 295, "agi": 130, "mag": 110},
		"secondaires": {"crit": 7, "degats_crit": 165, "res": 24, "preci": 93},
		"skills": [
			{"nom": "Carapace de Lave", "type": "actif", "chance": 0.3, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.22}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "def", "valeur": 0.2, "duree": 2}], "niveau": 1, "description": "(30 % de chance par tour) Bouclier de 22 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; DEF +20 % pour lui-même (2 tours)."},
			{"nom": "Peau de Fer", "type": "passif", "effets": [{"effet": "stat", "stat": "def", "valeur": 0.17}, {"effet": "epines", "valeur": 0.09}], "niveau": 10, "description": "DEF +17 % ; renvoie 9 % des dégâts physiques reçus."},
			{"nom": "Bouclier de Braise", "type": "actif", "chance": 0.25, "cible": "soi", "effets": [{"effet": "bouclier", "valeur": 0.2}, {"effet": "provocation", "duree": 2}, {"effet": "buff", "stat": "atk", "valeur": 0.2, "duree": 2}], "niveau": 20, "description": "(25 % de chance par tour) Bouclier de 20 % des PV max sur lui-même ; attire les attaques ennemies (2 tours) ; ATK +20 % pour lui-même (2 tours)."},
			{"nom": "Sang de Magma", "type": "passif", "effets": [{"effet": "epines", "valeur": 0.25}, {"effet": "aura", "stat": "def", "valeur": 0.12}], "niveau": 30, "description": "Renvoie 25 % des dégâts physiques reçus ; toute l'équipe : DEF +12 %."},
		],
	},
	"enfant_nidhogr": {
		"nom": "Enfant de Nidhögr", "rarete": "UR", "element": "tenebres", "role": "assassin", "position": "avant",
		"invocable": false, "categorie": "heros", "couleur": "2a0a3a",
		"legende": false, "forge": true, "race": "", "dominantes": [], "phase2": {},
		"stats": {"pv": 1665, "atk": 470, "def": 180, "agi": 355, "mag": 145},
		"secondaires": {"crit": 22, "degats_crit": 205, "res": 14, "preci": 100},
		"skills": [
			{"nom": "Croc Stellaire", "type": "actif", "chance": 0.35, "cible": "arriere", "effets": [{"effet": "degats", "mult": 1.9}, {"effet": "affliction", "nom": "malediction", "chance": 0.45, "duree": 2}], "niveau": 1, "description": "(35 % de chance par tour) Inflige 190 % de puissance de skill aux ennemis de l'Arrière ; 45 % de chance d'infliger Malédiction (2 tours)."},
			{"nom": "Instinct du Prédateur", "type": "passif", "effets": [{"effet": "stat", "stat": "crit", "valeur": 13}, {"effet": "stat", "stat": "degats_crit", "valeur": 24}], "niveau": 10, "description": "Crit +13 ; Dégâts crit +24 %."},
			{"nom": "Lacération", "type": "actif", "chance": 0.25, "cible": "ennemi", "effets": [{"effet": "degats", "mult": 1.85}, {"effet": "affliction", "nom": "saignement", "chance": 0.85, "duree": 3}], "niveau": 20, "description": "(25 % de chance par tour) Inflige 185 % de puissance de skill à un ennemi ; 85 % de chance d'infliger Saignement (3 tours)."},
			{"nom": "Faim du Vide", "type": "passif", "effets": [{"effet": "accumulation", "stat": "atk", "valeur": 0.15, "max": 4}, {"effet": "bonus_arriere", "valeur": 0.25}], "niveau": 30, "description": "Chaque ennemi vaincu : ATK +15 % (max 4 fois) ; +25 % de dégâts contre les ennemis de l'Arrière."},
		],
	},
}
