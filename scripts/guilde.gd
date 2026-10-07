class_name Guilde
extends RefCounted
## VIE DE GUILDE (côté jeu). Le serveur (supabase/05_guildes_vie.sql) garde tout : niveau, trésor,
## Sceaux, bénédictions, Boss de guilde, journal et discussion. Le jeu garde seulement une copie
## des BÉNÉDICTIONS dans la sauvegarde, pour les appliquer en combat même hors ligne.

## Bénédictions : bonus par rang (5 rangs max), pour tous les membres.
const BENEDICTIONS := {
	"force":    {"nom": "Force",    "icone": "⚔", "texte": "ATK de tes héros +%d %%",           "par_rang": 3},
	"vitalite": {"nom": "Vitalité", "icone": "❤", "texte": "PV de tes héros +%d %%",            "par_rang": 3},
	"rempart":  {"nom": "Rempart",  "icone": "⛨", "texte": "DEF de tes héros +%d %%",           "par_rang": 3},
	"fortune":  {"nom": "Fortune",  "icone": "●", "texte": "Or gagné en combat +%d %%",         "par_rang": 5},
	"savoir":   {"nom": "Savoir",   "icone": "✎", "texte": "XP de héros gagnée en combat +%d %%", "par_rang": 5},
}
const RANG_MAX := 5

## Dons quotidiens (les coûts sont vérifiés par le serveur, qui les renvoie).
const DONS := [
	{"id": "salut",  "nom": "Salut",       "texte": "Gratuit"},
	{"id": "or",     "nom": "Don d'or",    "texte": "20 000 or"},
	{"id": "gemmes", "nom": "Don royal",   "texte": "50 gemmes"},
]


## Rangs des bénédictions de la guilde du joueur ({} sans guilde).
static func benedictions() -> Dictionary:
	Sauvegarde.charger()
	var b = Sauvegarde.donnees.get("guilde_benedictions", {})
	return b if b is Dictionary else {}


static func rang(id: String) -> int:
	return int(benedictions().get(id, 0))


## Bonus en % d'une bénédiction (0 sans guilde).
static func bonus(id: String) -> float:
	if not BENEDICTIONS.has(id):
		return 0.0
	return float(rang(id) * int(BENEDICTIONS[id]["par_rang"]))


## Ajoute Force / Vitalité / Rempart aux bonus d'Échos d'un héros (appelé par Sauvegarde.bonus_echos).
static func appliquer_aux_stats(b: Dictionary) -> Dictionary:
	var f := bonus("force")
	var v := bonus("vitalite")
	var r := bonus("rempart")
	if f == 0.0 and v == 0.0 and r == 0.0:
		return b
	var res := b.duplicate()
	var p: Dictionary = (b.get("pourcent", {}) as Dictionary).duplicate()
	p["atk"] = float(p.get("atk", 0.0)) + f
	p["pv"] = float(p.get("pv", 0.0)) + v
	p["def"] = float(p.get("def", 0.0)) + r
	res["pourcent"] = p
	return res


static func memoriser(benedic: Variant) -> void:
	Sauvegarde.charger()
	Sauvegarde.donnees["guilde_benedictions"] = benedic if benedic is Dictionary else {}
	Sauvegarde.sauvegarder()


## Met à jour la copie locale des bénédictions (au menu principal). Silencieux en cas d'échec.
static func rafraichir() -> void:
	if not EnLigne.est_connecte():
		return
	var r := await EnLigne.appeler("guilde_vie")
	if not r.ok:
		return
	memoriser(r.data.get("benedictions", {}) if r.data is Dictionary else {})


## Titan affronté par la guilde cette semaine (un des 7 Boss de Monde, en rotation).
static func index_boss() -> int:
	return int(Calendrier.jour_absolu() / 7) % BossMonde.BOSS.size()
