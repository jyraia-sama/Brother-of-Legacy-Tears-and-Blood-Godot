class_name BossMonde
extends RefCounted
## BOSS DE MONDE : un boss gigantesque par jour de la semaine.
##
##  - Ton ARMÉE de 20 unités (4 escouades de 5) affronte un seul boss aux stats démesurées.
##    Dans chaque escouade : places 1-2 = Avant, places 3-5 = Arrière.
##  - Le boss agit plusieurs fois par tour et frappe souvent toute l'armée.
##  - Le combat dure au maximum TOURS_COMBAT tours : le but est d'infliger le plus de dégâts
##    possible (et, pour les meilleures armées, de l'abattre).
##  - Seul le boss du jour est disponible. ESSAIS_PAR_JOUR tentatives par jour.
##  - Il faut des unités de haut niveau et des Échos Sanguins pour faire de gros dégâts.
##  - Récompenses selon le % de PV infligés (provisoires : à ajuster plus tard).

const ESSAIS_PAR_JOUR := 3
const TOURS_COMBAT := 15
const NIVEAU_BOSS := 30
## Débloqué quand ce chapitre est terminé
const DEBLOCAGE := Vector2i(3, 6)

## Stats du boss = stats de base niveau 30 x ces multiplicateurs (réglés par simulation :
## une armée de 20 unités niveau 27 sans Échos inflige 40 à 55 % des PV et tient ~12 tours).
const BOSS := [
	{"id": "behemoth_cendres", "titre": "Le Béhémoth des Cendres", "faiblesse": "eau", "actions": 3,
		"texte": "Une montagne de chair et de lave. Chacun de ses pas fait trembler le monde.",
		"conseil": "Il brûle toute l'armée : prévois des soigneurs et des unités d'Eau.",
		"mult": {"pv": 34.0, "atk": 1.04, "def": 1.2, "agi": 1.0, "mag": 1.04}},
	{"id": "leviathan_noir", "titre": "Le Léviathan des Abysses Noires", "faiblesse": "nature", "actions": 3,
		"texte": "Le serpent des profondeurs remonte pour engloutir les rivages.",
		"conseil": "Il gèle et dévore une unité à la fois : protège ton Arrière.",
		"mult": {"pv": 33.0, "atk": 1.28, "def": 1.2, "agi": 1.0, "mag": 1.28}},
	{"id": "yggdravor", "titre": "Yggdravor, l'Arbre-Monde Corrompu", "faiblesse": "feu", "actions": 3,
		"texte": "Ses racines étouffent des royaumes entiers. Il se régénère sans cesse.",
		"conseil": "Poison et régénération : il faut beaucoup de dégâts, vite. Le Feu brûle ses racines.",
		"mult": {"pv": 45.0, "atk": 0.70, "def": 1.1, "agi": 1.0, "mag": 0.70}},
	{"id": "golgoth", "titre": "Golgoth, Colosse de Pierre-Sang", "faiblesse": "feu", "actions": 3,
		"texte": "Une montagne vivante à la peau plus dure que l'acier.",
		"conseil": "Sa DEF est énorme : les skills (MAG) et les mages font la différence.",
		"mult": {"pv": 20.0, "atk": 1.55, "def": 1.6, "agi": 0.9, "mag": 1.55}},
	{"id": "solgard", "titre": "Solgard, le Soleil Vivant", "faiblesse": "tenebres", "actions": 3,
		"texte": "Un astre tombé du ciel, qui aveugle et consume tout ce qu'il regarde.",
		"conseil": "Il aveugle tes guerriers : les unités de Ténèbres et les mages sont précieux.",
		"mult": {"pv": 58.0, "atk": 0.49, "def": 1.2, "agi": 1.1, "mag": 0.49}},
	{"id": "nidhogr", "titre": "Nidhögr, Dévoreur d'Étoiles", "faiblesse": "sacre", "actions": 3,
		"texte": "Le dragon qui ronge les racines du ciel. Il fond sur les plus faibles.",
		"conseil": "Il vise l'Arrière et réduit au silence : des tanks résistants et du Sacré.",
		"mult": {"pv": 42.0, "atk": 0.82, "def": 1.2, "agi": 1.2, "mag": 0.82}},
	{"id": "avatar_sang", "titre": "L'Avatar du Sang Originel", "faiblesse": "sacre", "actions": 4,
		"texte": "Le premier sang jamais versé, devenu dieu. Le plus terrible de tous.",
		"conseil": "Le défi ultime : il se soigne en frappant. Seule une armée complète et bien équipée tiendra.",
		"mult": {"pv": 33.0, "atk": 0.63, "def": 1.3, "agi": 1.2, "mag": 0.63}},
]
static var mult_test := {}


static func est_debloque() -> bool:
	return ActesData.est_termine(DEBLOCAGE.x, DEBLOCAGE.y)


static func boss_du_jour() -> int:
	return Calendrier.jour_semaine()


static func etat() -> Dictionary:
	Sauvegarde.charger()
	var e: Dictionary = Sauvegarde.donnees["boss_monde"]
	if int(e["jour"]) != Calendrier.jour_absolu():
		e["jour"] = Calendrier.jour_absolu()
		e["essais"] = 0
		e["records_jour"] = {}
		Sauvegarde.sauvegarder()
	return e


static func essais_restants() -> int:
	return maxi(0, ESSAIS_PAR_JOUR - int(etat()["essais"]))


static func record(id: String) -> float:
	return float(etat()["records"].get(id, 0.0))


static func record_du_jour(id: String) -> float:
	return float(etat()["records_jour"].get(id, 0.0))


## L'ennemi prêt pour CombatMoteur.
static func generer(index: int) -> Array:
	var b: Dictionary = BOSS[index]
	var m: Dictionary = mult_test.get(b["id"], b["mult"])
	return [{"id": b["id"], "niveau": NIVEAU_BOSS, "boss": true, "geant": true, "actions": int(b["actions"]),
		"mult_stats": m, "nom": b["titre"]}]


static func pv_boss(index: int) -> int:
	var b: Dictionary = BOSS[index]
	var s := UnitesData.stats(b["id"], NIVEAU_BOSS)
	return int(s["pv"] * float(b["mult"]["pv"]))


## L'armée du joueur prête pour CombatMoteur (places 0-19, escouade = place / 5).
static func armee() -> Array:
	var liste: Array = []
	var esc := Sauvegarde.get_escouades()
	for i in esc.size():
		var uid: int = esc[i]
		if uid < 0:
			continue
		var h := Sauvegarde.get_heros(uid)
		liste.append({"id": h["id"], "niveau": int(h["niveau"]), "uid": uid, "place": i,
			"etoiles": Fusion.etoiles(h), "echos": Sauvegarde.bonus_echos(uid)})
	return liste


static func consommer_essai() -> bool:
	var e := etat()
	if int(e["essais"]) >= ESSAIS_PAR_JOUR:
		return false
	e["essais"] = int(e["essais"]) + 1
	Sauvegarde.sauvegarder()
	return true


## Récompenses selon le pourcentage de PV infligés (0 à 100).
static func butin(pct: float, tue: bool) -> Dictionary:
	var b := {"or": 3000 + int(pct * 400), "fragment_colossal": 1 + int(pct / 10.0) + (10 if tue else 0),
		"poussiere_echo": 10 + int(pct / 2.0)}
	if tue:
		b["coffre_royal"] = 1
		b["pierre_eveil"] = 1
	elif pct >= 60.0:
		b["coffre_or"] = 1
	elif pct >= 30.0:
		b["coffre_argent"] = 1
	else:
		b["coffre_bronze"] = 1
	if pct >= 50.0:
		b["eclat_superieur"] = 1
	return b


## Enregistre le résultat d'une tentative et donne le butin. Renvoie les lignes de texte.
static func valider(index: int, pct: float, tue: bool) -> Array:
	var id: String = BOSS[index]["id"]
	var e := etat()
	var lignes: Array = []
	lignes.append("Dégâts infligés : %.1f %% des PV%s" % [pct, "  —  BOSS ABATTU !" if tue else ""])
	if pct > float(e["records"].get(id, 0.0)):
		e["records"][id] = pct
		lignes.append("Nouveau record contre ce boss !")
	if pct > float(e["records_jour"].get(id, 0.0)):
		e["records_jour"][id] = pct
	Sauvegarde.ajouter_stat("boss_monde_tentatives")
	if tue:
		Sauvegarde.ajouter_stat("boss_monde_abattus")
	Sauvegarde.sauvegarder()
	lignes.append_array(Reliquaire.donner(butin(pct, tue)))
	return lignes
