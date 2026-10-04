class_name Courrier
extends RefCounted
## LE COURRIER : lettres reçues par le joueur, avec ou sans récompense jointe.
## Les lettres sont gardées dans la sauvegarde (donc synchronisées avec le compte).
##
## Envoyer une lettre depuis n'importe où dans le jeu :
##   Courrier.envoyer("id_unique", "Titre", "Texte de la lettre", {"or": 5000, "gemmes": 50}, "Expéditeur")
## Une lettre avec le même identifiant n'est jamais envoyée deux fois.
##
## Lettres du jeu (LETTRES_JEU) : envoyées automatiquement à l'ouverture du menu principal.
## Pour offrir un cadeau à tous les joueurs (compensation, événement…), ajoute une entrée
## dans LETTRES_JEU avec un nouvel identifiant, puis publie la version.

const SCENE := "res://scenes/courrier.tscn"

## Nombre maximum de lettres gardées (les plus anciennes déjà lues partent en premier).
const MAX_LETTRES := 60

const LETTRES_JEU := [
	{"id": "nouveau_menu_0_37", "de": "Les Valcendre",
	"titre": "Un nouveau hall pour la lignée",
	"texte": "Le menu principal a fait peau neuve : la Lame pour combattre, le Sang pour ton armée, et le Royaume en bas de l'écran.\n\nCe courrier recevra désormais tes cadeaux, tes compensations et les récompenses spéciales. Voici un petit présent pour fêter ça.",
	"recompense": {"or": 5000, "gemmes": 50}},
]


static func _etat() -> Dictionary:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.has("courrier") or not Sauvegarde.donnees["courrier"] is Dictionary:
		Sauvegarde.donnees["courrier"] = {}
	var c: Dictionary = Sauvegarde.donnees["courrier"]
	for cle in ["lettres", "recues"]:
		if not c.has(cle) or not c[cle] is Array:
			c[cle] = []
	return c


## Envoie une lettre (une seule fois par identifiant). Renvoie true si elle vient d'arriver.
static func envoyer(id: String, titre: String, texte: String, recompense: Dictionary = {}, de := "Brothers of Legacy") -> bool:
	var c := _etat()
	if id in c["recues"]:
		return false
	c["recues"].append(id)
	c["lettres"].push_front({
		"id": id, "de": de, "titre": titre, "texte": texte,
		"recompense": recompense.duplicate(), "date": Calendrier.maintenant_local(),
		"lue": false, "reclamee": recompense.is_empty(),
	})
	_elaguer(c)
	Sauvegarde.sauvegarder()
	return true


## Distribue les lettres du jeu pas encore reçues.
static func verifier() -> void:
	for l in LETTRES_JEU:
		envoyer(l["id"], l["titre"], l["texte"], l.get("recompense", {}), l.get("de", "Brothers of Legacy"))


static func lettres() -> Array:
	return _etat()["lettres"]


## Pastille du menu : lettres non lues ou récompenses à récupérer.
static func a_lire() -> int:
	var n := 0
	for l in lettres():
		if not bool(l["lue"]) or not bool(l["reclamee"]):
			n += 1
	return n


static func marquer_lue(index: int) -> void:
	var l: Array = lettres()
	if index < 0 or index >= l.size():
		return
	if not bool(l[index]["lue"]):
		l[index]["lue"] = true
		Sauvegarde.sauvegarder()


## Récupère la pièce jointe d'une lettre. Renvoie les lignes à afficher.
static func reclamer(index: int) -> Array:
	var l: Array = lettres()
	if index < 0 or index >= l.size() or bool(l[index]["reclamee"]):
		return []
	l[index]["reclamee"] = true
	l[index]["lue"] = true
	var r := Quetes.donner(l[index]["recompense"])
	Sauvegarde.sauvegarder()
	return r


## Récupère toutes les pièces jointes en attente.
static func tout_reclamer() -> Array:
	var r: Array = []
	for i in lettres().size():
		r.append_array(reclamer(i))
	return r


## Supprime les lettres lues dont la pièce jointe a été récupérée.
static func supprimer_lues() -> int:
	var c := _etat()
	var garde: Array = []
	for l in c["lettres"]:
		if not bool(l["lue"]) or not bool(l["reclamee"]):
			garde.append(l)
	var n: int = c["lettres"].size() - garde.size()
	c["lettres"] = garde
	Sauvegarde.sauvegarder()
	return n


static func _elaguer(c: Dictionary) -> void:
	var l: Array = c["lettres"]
	while l.size() > MAX_LETTRES:
		var retire := false
		for i in range(l.size() - 1, -1, -1):
			if bool(l[i]["lue"]) and bool(l[i]["reclamee"]):
				l.remove_at(i)
				retire = true
				break
		if not retire:
			break
