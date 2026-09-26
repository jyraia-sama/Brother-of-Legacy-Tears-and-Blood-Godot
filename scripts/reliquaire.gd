class_name Reliquaire
extends RefCounted
## LE RELIQUAIRE : les objets gagnés dans les modes de jeu et ce qu'on en fait.
##
##  - Coffres d'or        : s'ouvrent pour donner de l'or (et parfois un bonus).
##  - Élixirs de stamina  : rendent de la stamina (peuvent dépasser le maximum).
##  - Tomes d'XP          : donnent de l'XP à un héros.
##  - Pierre d'Éveil      : remplace un doublon à l'Autel de Fusion.
##  - Forge de héros      : Braises / Plumes / Fragments -> héros exclusifs.
##  - Atelier d'Échos     : Poussière d'Écho -> Écho Sanguin du set et de l'emplacement choisis ;
##                          on obtient de la Poussière en démantelant les Échos inutiles.
##
## Tous les objets sont rangés dans Sauvegarde (collection.objets).

const OBJETS := {
	"braise_infernale": {"nom": "Braise Infernale", "cat": "forge", "couleur": "ff5a2a",
		"desc": "Tombe dans la Tour de l'Enfer. Sert à forger les héros infernaux."},
	"plume_celeste": {"nom": "Plume Céleste", "cat": "forge", "couleur": "fff0b0",
		"desc": "Tombe dans la Tour du Paradis. Sert à forger les héros célestes."},
	"fragment_colossal": {"nom": "Fragment Colossal", "cat": "forge", "couleur": "d08a4a",
		"desc": "Arraché aux Boss de Monde. Sert à forger leurs rejetons."},
	"poussiere_echo": {"nom": "Poussière d'Écho", "cat": "atelier", "couleur": "d0453a",
		"desc": "Reste d'Échos Sanguins. Sert à fabriquer des Échos à l'Atelier."},
	"coffre_bronze": {"nom": "Coffre de Bronze", "cat": "coffre", "couleur": "b07a4a",
		"desc": "Contient 500 à 1 000 or."},
	"coffre_argent": {"nom": "Coffre d'Argent", "cat": "coffre", "couleur": "c8d0d8",
		"desc": "Contient 2 000 à 4 000 or, parfois un bonus."},
	"coffre_or": {"nom": "Coffre d'Or", "cat": "coffre", "couleur": "ffd060",
		"desc": "Contient 6 000 à 12 000 or et souvent un bonus."},
	"coffre_royal": {"nom": "Coffre Royal", "cat": "coffre", "couleur": "ff9a5a",
		"desc": "Contient 20 000 à 40 000 or et un bonus garanti."},
	"elixir_petit": {"nom": "Petit Élixir de Stamina", "cat": "elixir", "couleur": "7ad0ff",
		"desc": "Rend 10 points de stamina."},
	"elixir_grand": {"nom": "Grand Élixir de Stamina", "cat": "elixir", "couleur": "3a9aff",
		"desc": "Rend 30 points de stamina."},
	"tome_petit": {"nom": "Tome d'Apprenti", "cat": "tome", "couleur": "9ad08a",
		"desc": "Donne 500 XP à un héros."},
	"tome_grand": {"nom": "Tome de Vétéran", "cat": "tome", "couleur": "5ab04a",
		"desc": "Donne 2 000 XP à un héros."},
	"tome_ancien": {"nom": "Tome Ancien", "cat": "tome", "couleur": "e0c050",
		"desc": "Donne 6 000 XP à un héros."},
	"pierre_eveil": {"nom": "Pierre d'Éveil", "cat": "pierre", "couleur": "ff7ad0",
		"desc": "À l'Autel de Fusion, remplace un doublon pour faire gagner une étoile."},
	"eclat_superieur": {"nom": "Éclat de Pacte Supérieur", "cat": "pierre", "couleur": "b08aff",
		"desc": "Sert au Pacte Supérieur de l'Autel d'Invocation (SR / SSR / UR)."},
}

const ORDRE := ["braise_infernale", "plume_celeste", "fragment_colossal", "poussiere_echo",
	"coffre_bronze", "coffre_argent", "coffre_or", "coffre_royal", "elixir_petit", "elixir_grand",
	"tome_petit", "tome_grand", "tome_ancien", "pierre_eveil", "eclat_superieur"]

const STAMINA := {"elixir_petit": 10, "elixir_grand": 30}
const XP_TOME := {"tome_petit": 500, "tome_grand": 2000, "tome_ancien": 6000}
const OR_COFFRE := {"coffre_bronze": [500, 1000], "coffre_argent": [2000, 4000],
	"coffre_or": [6000, 12000], "coffre_royal": [20000, 40000]}
## Chance d'un bonus dans le coffre, et bonus possibles
const BONUS_COFFRE := {"coffre_bronze": 0.0, "coffre_argent": 0.25, "coffre_or": 0.6, "coffre_royal": 1.0}
const BONUS_POSSIBLES := ["elixir_petit", "tome_petit", "poussiere_echo", "elixir_grand", "tome_grand", "pierre_eveil"]

# ---------------------------------------------------------------------
# Forge
# ---------------------------------------------------------------------
## Recettes de la Forge : héros exclusifs (non invocables).
const FORGE := [
	{"id": "belzaroth", "cout": {"braise_infernale": 150}, "or": 20000, "origine": "Tour de l'Enfer"},
	{"id": "nyxara", "cout": {"braise_infernale": 150}, "or": 20000, "origine": "Tour de l'Enfer"},
	{"id": "mephistar", "cout": {"braise_infernale": 400}, "or": 60000, "origine": "Tour de l'Enfer"},
	{"id": "seraphine_aube", "cout": {"plume_celeste": 150}, "or": 20000, "origine": "Tour du Paradis"},
	{"id": "solarius", "cout": {"plume_celeste": 150}, "or": 20000, "origine": "Tour du Paradis"},
	{"id": "aurelion", "cout": {"plume_celeste": 400}, "or": 60000, "origine": "Tour du Paradis"},
	{"id": "rejeton_behemoth", "cout": {"fragment_colossal": 120}, "or": 25000, "origine": "Boss de Monde"},
	{"id": "enfant_nidhogr", "cout": {"fragment_colossal": 300}, "or": 60000, "origine": "Boss de Monde"},
]
## Échanges de la Forge (monnaie -> objet utile)
const ECHANGES := [
	{"cout": {"braise_infernale": 40}, "donne": {"eclat_superieur": 1}},
	{"cout": {"plume_celeste": 40}, "donne": {"eclat_superieur": 1}},
	{"cout": {"fragment_colossal": 30}, "donne": {"pierre_eveil": 1}},
	{"cout": {"braise_infernale": 20, "plume_celeste": 20}, "donne": {"coffre_or": 1}},
]

# ---------------------------------------------------------------------
# Atelier d'Échos
# ---------------------------------------------------------------------
## Fabrication : Poussière + or -> Écho du set et de l'emplacement choisis.
const ATELIER := {
	"simple": {"nom": "Fabrication", "poussiere": 60, "or": 2000,
		"raretes": [0, 30, 45, 20, 5], "etoiles": [3, 4]},
	"superieure": {"nom": "Fabrication supérieure", "poussiere": 180, "or": 8000,
		"raretes": [0, 0, 40, 45, 15], "etoiles": [4, 6]},
}


static func nom(objet: String) -> String:
	return OBJETS.get(objet, {}).get("nom", objet)


static func texte_cout(cout: Dictionary, or_requis := 0) -> String:
	var morceaux: Array = []
	for o in cout:
		morceaux.append("%d %s" % [int(cout[o]), nom(o)])
	if or_requis > 0:
		morceaux.append("%d or" % or_requis)
	return " + ".join(morceaux)


static func peut_payer(cout: Dictionary, or_requis := 0) -> bool:
	for o in cout:
		if Sauvegarde.get_objet(o) < int(cout[o]):
			return false
	return Sauvegarde.get_or() >= or_requis


static func payer(cout: Dictionary, or_requis := 0) -> bool:
	if not peut_payer(cout, or_requis):
		return false
	for o in cout:
		Sauvegarde.retirer_objet(o, int(cout[o]))
	if or_requis > 0:
		Sauvegarde.depenser_or(or_requis)
	return true


## Donne des objets (et de l'or avec la clé "or"). Renvoie les lignes de texte du butin.
static func donner(butin: Dictionary) -> Array:
	var lignes: Array = []
	for o in butin:
		var n := int(butin[o])
		if n <= 0:
			continue
		if o == "or":
			Sauvegarde.ajouter_or(n)
			lignes.append("Or : +%d" % n)
		else:
			Sauvegarde.ajouter_objet(o, n)
			lignes.append("%s : +%d" % [nom(o), n])
	return lignes


# ---------------------------------------------------------------------
# Utilisation des objets
# ---------------------------------------------------------------------

## Ouvre un coffre. Renvoie le butin {"or": n, objet: n}  ({} si pas de coffre).
static func ouvrir_coffre(coffre: String) -> Dictionary:
	if not OR_COFFRE.has(coffre) or not Sauvegarde.retirer_objet(coffre, 1):
		return {}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var bornes: Array = OR_COFFRE[coffre]
	var butin := {"or": int(round(rng.randi_range(bornes[0], bornes[1]) / 10.0)) * 10}
	if rng.randf() < float(BONUS_COFFRE[coffre]):
		var max_i := 2 if coffre == "coffre_argent" else (4 if coffre == "coffre_or" else BONUS_POSSIBLES.size() - 1)
		var bonus: String = BONUS_POSSIBLES[rng.randi_range(0, max_i)]
		butin[bonus] = 20 if bonus == "poussiere_echo" else 1
	donner(butin)
	Sauvegarde.ajouter_stat("coffres_ouverts")
	return butin


static func utiliser_elixir(elixir: String) -> int:
	if not STAMINA.has(elixir) or not Sauvegarde.retirer_objet(elixir, 1):
		return 0
	Sauvegarde.ajouter_stamina(int(STAMINA[elixir]))
	return int(STAMINA[elixir])


## Utilise un tome sur un héros. Renvoie les niveaux gagnés (-1 si impossible).
static func utiliser_tome(tome: String, uid: int) -> int:
	var h := Sauvegarde.get_heros(uid)
	if h.is_empty() or not XP_TOME.has(tome) or int(h["niveau"]) >= UnitesData.NIVEAU_MAX:
		return -1
	if not Sauvegarde.retirer_objet(tome, 1):
		return -1
	return Sauvegarde.ajouter_xp_heros(uid, int(XP_TOME[tome]))


# ---------------------------------------------------------------------
# Forge
# ---------------------------------------------------------------------

## Crée le héros d'une recette. Renvoie son uid (-1 si impossible).
static func forger(recette: Dictionary) -> int:
	if not payer(recette["cout"], int(recette["or"])):
		return -1
	Sauvegarde.ajouter_stat("heros_forges")
	return Sauvegarde.ajouter_heros(recette["id"])


static func echanger(echange: Dictionary) -> bool:
	if not payer(echange["cout"]):
		return false
	donner(echange["donne"])
	return true


# ---------------------------------------------------------------------
# Atelier d'Échos
# ---------------------------------------------------------------------

static func fabriquer_echo(type: String, set_id: String, emplacement: int, principale: String) -> Dictionary:
	var a: Dictionary = ATELIER[type]
	if not payer({"poussiere_echo": int(a["poussiere"])}, int(a["or"])):
		return {}
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var poids: Array = a["raretes"]
	var total := 0
	for w in poids:
		total += int(w)
	var r := rng.randi_range(1, total)
	var rarete := 0
	for i in poids.size():
		r -= int(poids[i])
		if r <= 0:
			rarete = i
			break
	var etoiles := rng.randi_range(int(a["etoiles"][0]), int(a["etoiles"][1]))
	var principales: Array = Echos.EMPLACEMENTS[emplacement]["principales"]
	if not principale in principales:
		principale = principales[rng.randi_range(0, principales.size() - 1)]
	var echo := Echos.creer(set_id, emplacement, rarete, etoiles, principale, rng)
	Sauvegarde.ajouter_echo(echo)
	return echo


## Poussière rendue en démantelant un Écho.
static func poussiere_demantelement(echo: Dictionary) -> int:
	return 2 + int(echo["rarete"]) * 4 + int(echo["etoiles"]) * 2 + int(echo.get("niveau", 0))


## Démantèle des Échos (ni équipés, ni verrouillés). Renvoie la poussière gagnée.
static func demanteler(uids: Array) -> int:
	var total := 0
	var ok: Array = []
	for uid in uids:
		var e := Sauvegarde.get_echo(int(uid))
		if e.is_empty() or e.get("verrou", false) or int(e["porteur"]) >= 0:
			continue
		total += poussiere_demantelement(e)
		ok.append(int(uid))
	if ok.is_empty():
		return 0
	Sauvegarde.supprimer_echos(ok)
	Sauvegarde.ajouter_objet("poussiere_echo", total)
	return total
