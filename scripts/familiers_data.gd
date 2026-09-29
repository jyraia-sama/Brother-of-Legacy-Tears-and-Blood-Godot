class_name FamiliersData
extends RefCounted
## FAMILIERS : les 40 compagnons de la Ménagerie (non combattants).
##
## Un familier part en chasse avec un héros N ou R (voir menagerie.gd) et rapporte du butin
## en temps réel. Ses STATS DE FARMING :
##   - RÉCOLTE   : multiplie la quantité de chaque butin (x1,00 pour un N ... x1,60 pour un UR).
##   - CÉLÉRITÉ  : minutes entre deux butins (plus c'est bas, plus il rapporte souvent).
##   - FORTUNE   : augmente les chances de butin RARE et ÉPIQUE.
##   - TERRAIN   : zone de chasse préférée (+25 % de récolte sur cette zone).
##   - TALENT    : capacité spéciale (voir TALENTS).
## Niveau (monte en chassant) et étoiles (Éveil avec un doublon) renforcent Récolte et Fortune.
## Pour ajouter un familier : ajoute une ligne dans LISTE (l'id doit être unique).
## Illustration facultative : res://assets/familiers/<id>.png (sinon un médaillon coloré).

## Valeurs de base par rareté
const RARETES := {
	"N":   {"recolte": 1.00, "fortune": 0.0,  "celerite": 30.0, "niveau_max": 10, "talent": 1.0},
	"R":   {"recolte": 1.10, "fortune": 3.0,  "celerite": 27.0, "niveau_max": 15, "talent": 1.4},
	"SR":  {"recolte": 1.25, "fortune": 6.0,  "celerite": 24.0, "niveau_max": 20, "talent": 1.9},
	"SSR": {"recolte": 1.40, "fortune": 10.0, "celerite": 21.0, "niveau_max": 25, "talent": 2.5},
	"UR":  {"recolte": 1.60, "fortune": 15.0, "celerite": 18.0, "niveau_max": 30, "talent": 3.2},
}
const ORDRE_RARETE := ["N", "R", "SR", "SSR", "UR"]
const ETOILES_MAX := 5

## Talents : valeur de base (multipliée par le coefficient « talent » de la rareté).
const TALENTS := {
	"double":   {"nom": "Double prise",   "base": 4.0,  "texte": "%s %% de chance de doubler un butin."},
	"sceau":    {"nom": "Flair sauvage",  "base": 1.5,  "texte": "%s %% de chance de trouver en plus un Sceau Sauvage."},
	"or":       {"nom": "Pie voleuse",    "base": 6.0,  "texte": "+%s %% d'or aux Plaines Cendrées, et un peu d'or dans les autres zones."},
	"chance":   {"nom": "Porte-bonheur",  "base": 3.0,  "texte": "Fortune +%s."},
	"rapide":   {"nom": "Pas léger",      "base": 4.0,  "texte": "Célérité : %s %% de temps en moins entre deux butins."},
	"mentor":   {"nom": "Mentor",         "base": 12.0, "texte": "Le héros qui l'accompagne gagne +%s %% d'XP."},
	"nomade":   {"nom": "Nomade",         "base": 6.0,  "texte": "+%s %% de récolte dans toutes les zones."},
}

## [id, nom, rareté, élément, terrain, talent, couleur, description]
const LISTE := [
	# --- N (12) ---
	["rat_cryptes", "Rat des Cryptes", "N", "tenebres", "cimetiere", "double", "6a5a50", "Il se faufile entre les ossements et ne revient jamais les pattes vides."],
	["corbeau_charognard", "Corbeau Charognard", "N", "tenebres", "plaines", "or", "2a2a33", "Attiré par tout ce qui brille, surtout sur les champs de bataille."],
	["crapaud_tourbes", "Crapaud des Tourbes", "N", "nature", "sources", "rapide", "5a7a3a", "Il sait toujours où l'eau est la plus pure."],
	["chauve_souris_cendree", "Chauve-souris Cendrée", "N", "feu", "nids", "sceau", "7a5a5a", "Elle niche près des brasiers et flaire les créatures sauvages."],
	["furet_voleur", "Furet Voleur", "N", "nature", "plaines", "or", "b08a5a", "Rien n'échappe à ses petites pattes. Rien."],
	["scarabee_dore", "Scarabée Doré", "N", "sacre", "veines", "chance", "d0b040", "Les mineurs le considèrent comme un présage de filon."],
	["limace_luisante", "Limace Luisante", "N", "eau", "bibliotheque", "mentor", "7ad0c0", "Elle éclaire les pages des livres oubliés."],
	["chat_noir_errant", "Chat Noir Errant", "N", "tenebres", "cimetiere", "chance", "1a1a1a", "Porte-malheur pour les autres, porte-bonheur pour son maître."],
	["hibou_borgne", "Hibou Borgne", "N", "sacre", "bibliotheque", "mentor", "a08a6a", "Un œil suffit pour lire dans le noir."],
	["lezard_braises", "Lézard des Braises", "N", "feu", "veines", "rapide", "d05a2a", "Il court sur les roches brûlantes sans jamais s'arrêter."],
	["araignee_tisseuse", "Araignée Tisseuse", "N", "tenebres", "nids", "double", "4a3a4a", "Ses toiles attrapent bien plus que des mouches."],
	["chien_galeux", "Chien Galeux", "N", "neutre", "plaines", "nomade", "8a7a6a", "Fidèle, affamé, et prêt à suivre n'importe qui n'importe où."],
	# --- R (11) ---
	["loup_cendres", "Loup des Cendres", "R", "feu", "plaines", "double", "5a4a4a", "Il chasse en silence dans les plaines calcinées."],
	["renard_fantome", "Renard Fantôme", "R", "tenebres", "cimetiere", "sceau", "c0c0d0", "Mi-renard, mi-souvenir. Il guide vers les échos perdus."],
	["serpent_onyx", "Serpent d'Onyx", "R", "tenebres", "veines", "chance", "20202a", "Sa peau reflète les veines de minerai qu'il traverse."],
	["faucon_sanglant", "Faucon Sanglant", "R", "feu", "nids", "rapide", "a02a2a", "Il repère une proie à des lieues."],
	["sanglier_balafre", "Sanglier Balafré", "R", "nature", "plaines", "nomade", "6a4a2a", "Il fouille la terre et déterre des trésors enfouis."],
	["blaireau_fouisseur", "Blaireau Fouisseur", "R", "nature", "veines", "double", "5a5a4a", "Il creuse plus vite qu'une équipe de nains."],
	["lynx_neiges_noires", "Lynx des Neiges Noires", "R", "eau", "nids", "chance", "3a4a5a", "Ses yeux voient l'invisible dans la tempête."],
	["tortue_moussue", "Tortue Moussue", "R", "eau", "sources", "mentor", "4a7a4a", "Lente, sage, et d'une patience infinie."],
	["mouette_spectrale", "Mouette Spectrale", "R", "eau", "sources", "rapide", "d0e0f0", "Elle survole les sources et plonge sur les plus pures."],
	["belette_sang", "Belette de Sang", "R", "tenebres", "cimetiere", "or", "8a1a1a", "Elle dérobe les offrandes laissées aux morts."],
	["bouc_maudit", "Bouc Maudit", "R", "tenebres", "bibliotheque", "nomade", "4a2a3a", "Il a mangé tant de grimoires qu'il en récite des pages."],
	# --- SR (9) ---
	["chouette_sepulcrale", "Chouette Sépulcrale", "SR", "tenebres", "bibliotheque", "mentor", "5a4a6a", "Gardienne des archives des morts, elle enseigne à qui l'écoute."],
	["salamandre_ardente", "Salamandre Ardente", "SR", "feu", "veines", "double", "ff6a2a", "Elle nage dans la lave et en ressort chargée de braises."],
	["golem_poche", "Golem de Poche", "SR", "neutre", "veines", "nomade", "8a8a7a", "Taillé dans une pierre d'éveil ratée. Infatigable."],
	["feu_follet", "Feu Follet", "SR", "sacre", "cimetiere", "chance", "a0e0ff", "Il mène les voyageurs perdus... vers les trésors, pour une fois."],
	["kelpie_marais", "Kelpie des Marais", "SR", "eau", "sources", "rapide", "2a6a6a", "Un cheval d'eau qui connaît chaque source cachée."],
	["corneille_prophetesse", "Corneille Prophétesse", "SR", "tenebres", "nids", "sceau", "3a1a3a", "Elle croasse le nom des bêtes avant même qu'elles n'apparaissent."],
	["mimic_apprivoise", "Mimic Apprivoisé", "SR", "neutre", "plaines", "or", "8a5a1a", "Un Mimic qui a choisi son camp. Il avale l'or... et le rend (presque tout)."],
	["chat_sphinx", "Chat-Sphinx", "SR", "sacre", "bibliotheque", "chance", "e0c070", "Il pose des énigmes. Ceux qui répondent juste repartent plus sages."],
	["ours_mort_vivant", "Ours Mort-Vivant", "SR", "tenebres", "plaines", "double", "4a4a3a", "Même la mort n'a pas calmé son appétit."],
	# --- SSR (5) ---
	["wyverneau_ecarlate", "Wyverneau Écarlate", "SSR", "feu", "nids", "sceau", "c0202a", "Un jeune wyverne qui reconnaît l'odeur des bêtes sauvages."],
	["licorne_dechue", "Licorne Déchue", "SSR", "tenebres", "sources", "mentor", "6a4a8a", "Sa corne noircie purifie encore les eaux qu'elle touche."],
	["cerbere_nain", "Cerbère Nain", "SSR", "feu", "cimetiere", "double", "8a2a1a", "Trois têtes, trois fois plus de butin."],
	["phenix_cendre", "Phénix Cendré", "SSR", "feu", "veines", "rapide", "ff9a3a", "Il renaît de ses cendres... et des vôtres, s'il le faut."],
	["basilic_cristal", "Basilic de Cristal", "SSR", "sacre", "bibliotheque", "chance", "a0f0f0", "Son regard ne pétrifie plus : il révèle les trésors."],
	# --- UR (3) ---
	["dragonnet_primordial", "Dragonnet Primordial", "UR", "feu", "plaines", "or", "ffb030", "Le dernier-né des premiers dragons. Il dort sur une montagne d'or."],
	["kirin_crepuscule", "Kirin du Crépuscule", "UR", "sacre", "nids", "nomade", "ffe0a0", "Là où il passe, la chance fleurit."],
	["ombre_leviathan", "Ombre de Léviathan", "UR", "eau", "sources", "double", "1a3a6a", "Une infime part du grand serpent des abysses. Même infime, elle est immense."],
]

static var _index := {}


static func _construire() -> void:
	if not _index.is_empty():
		return
	for l in LISTE:
		var r: Dictionary = RARETES[l[2]]
		# Petite variation par familier (stable) pour qu'ils ne soient pas tous identiques
		var h := absi(hash(l[0]))
		var var_rec := 1.0 + ((h % 7) - 3) * 0.01
		var var_cel := 1.0 + (((h / 7) % 5) - 2) * 0.02
		_index[l[0]] = {"id": l[0], "nom": l[1], "rarete": l[2], "element": l[3], "terrain": l[4],
			"talent": l[5], "couleur": l[6], "description": l[7],
			"recolte": snappedf(float(r["recolte"]) * var_rec, 0.01),
			"fortune": float(r["fortune"]),
			"celerite": snappedf(float(r["celerite"]) * var_cel, 0.1),
			"niveau_max": int(r["niveau_max"]),
			"talent_valeur": snappedf(float(TALENTS[l[5]]["base"]) * float(r["talent"]), 0.1)}


static func get_familier(id: String) -> Dictionary:
	_construire()
	return _index.get(id, {})


static func existe(id: String) -> bool:
	_construire()
	return _index.has(id)


static func ids(rarete := "") -> Array:
	var l: Array = []
	for f in LISTE:
		if rarete == "" or f[2] == rarete:
			l.append(f[0])
	return l


static func texte_talent(id: String, etoiles := 1) -> String:
	var f := get_familier(id)
	var t: Dictionary = TALENTS[f["talent"]]
	return "%s : %s" % [t["nom"], str(t["texte"]) % _n(valeur_talent(id, etoiles))]


static func valeur_talent(id: String, etoiles := 1) -> float:
	return float(get_familier(id)["talent_valeur"]) * (1.0 + 0.1 * (etoiles - 1))


static func chemin_image(id: String) -> String:
	var p := "res://assets/familiers/%s.png" % id
	return p if ResourceLoader.exists(p) else ""


static func _n(x: float) -> String:
	return str(int(x)) if is_equal_approx(x, round(x)) else str(snappedf(x, 0.1))
