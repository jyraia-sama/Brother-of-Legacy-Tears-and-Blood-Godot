class_name Invocation
extends RefCounted
## AUTEL D'INVOCATION : règles et tirages.
##
##   Pacte Doré      : payé en or           -> N, R, SR
##   Pacte Supérieur : payé en Éclats de Pacte Supérieur (lâchés par les boss) -> SR, SSR, UR, Légende
##
## Taux, prix et garanties modifiables ci-dessous.

const PACTES := {
	"dore": {
		"nom": "Pacte Doré",
		"monnaie": "or", "prix_x1": 500, "prix_x10": 4500,
		"taux": [["N", 0.60], ["R", 0.30], ["SR", 0.10]],
	},
	"superieur": {
		"nom": "Pacte Supérieur",
		"monnaie": "eclat", "prix_x1": 1, "prix_x10": 10,
		"taux": [["SR", 0.752], ["SSR", 0.22], ["UR", 0.025], ["LEG", 0.003]],
	},
}

## Pacte Doré x10 : au moins un SR garanti.
const X10_DORE_SR_GARANTI := true
## Pacte Supérieur : SSR (ou mieux) garanti si aucun n'est sorti depuis ce nombre d'invocations.
const GARANTIE_SUPERIEUR := 20

const NOMS_RARETE := {"N": "N", "R": "R", "SR": "SR", "SSR": "SSR", "UR": "UR", "LEG": "Légende"}


static func prix(pacte: String, nombre: int) -> int:
	return PACTES[pacte]["prix_x10"] if nombre >= 10 else PACTES[pacte]["prix_x1"] * nombre


static func peut_payer(pacte: String, nombre: int) -> bool:
	var p := prix(pacte, nombre)
	if PACTES[pacte]["monnaie"] == "or":
		return Sauvegarde.get_or() >= p
	return Sauvegarde.get_objet(Sauvegarde.ECLAT) >= p


## Invocations restantes avant le SSR garanti du Pacte Supérieur.
static func avant_garantie() -> int:
	Sauvegarde.charger()
	return GARANTIE_SUPERIEUR - int(Sauvegarde.donnees["invocation"]["pity_superieur"])


## Effectue l'invocation (paiement compris). Renvoie la liste des héros obtenus :
## [{ "uid", "id", "rarete", "nouveau": bool }]  -  ou [] si le joueur ne peut pas payer.
static func invoquer(pacte: String, nombre: int, rng: RandomNumberGenerator = null) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	if not peut_payer(pacte, nombre):
		return []
	var p := prix(pacte, nombre)
	if PACTES[pacte]["monnaie"] == "or":
		Sauvegarde.depenser_or(p)
	else:
		Sauvegarde.retirer_objet(Sauvegarde.ECLAT, p)

	var raretes: Array = []
	var inv: Dictionary = Sauvegarde.donnees["invocation"]
	for i in nombre:
		var r := _tirer_rarete(pacte, rng)
		if pacte == "superieur":
			if r == "SR":
				inv["pity_superieur"] = int(inv["pity_superieur"]) + 1
				if int(inv["pity_superieur"]) >= GARANTIE_SUPERIEUR:
					r = "SSR"
			if r != "SR":
				inv["pity_superieur"] = 0
		raretes.append(r)
	# Garantie du x10 doré : au moins un SR
	if pacte == "dore" and nombre >= 10 and X10_DORE_SR_GARANTI and not "SR" in raretes:
		raretes[rng.randi_range(0, raretes.size() - 1)] = "SR"
	inv["total_" + pacte] = int(inv.get("total_" + pacte, 0)) + nombre

	var resultat: Array = []
	for r in raretes:
		var id := _tirer_unite(r, rng)
		var nouveau := _nb_possedes(id) == 0
		var uid := Sauvegarde.ajouter_heros(id)
		resultat.append({"uid": uid, "id": id, "rarete": r, "nouveau": nouveau})
	Sauvegarde.sauvegarder()
	return resultat


static func _tirer_rarete(pacte: String, rng: RandomNumberGenerator) -> String:
	var x := rng.randf()
	var cumul := 0.0
	for t in PACTES[pacte]["taux"]:
		cumul += t[1]
		if x < cumul:
			return t[0]
	return PACTES[pacte]["taux"][0][0]


## Tous les héros invocables d'une rareté ("LEG" = Héros de Légende).
static func pool(rarete: String) -> Array:
	var l: Array = []
	for id in UnitesData.UNITES:
		var u: Dictionary = UnitesData.UNITES[id]
		if not u["invocable"]:
			continue
		var leg: bool = u.get("legende", false)
		if (rarete == "LEG" and leg) or (rarete != "LEG" and not leg and u["rarete"] == rarete):
			l.append(id)
	return l


static func _tirer_unite(rarete: String, rng: RandomNumberGenerator) -> String:
	var l := pool(rarete)
	return l[rng.randi_range(0, l.size() - 1)]


static func _nb_possedes(id: String) -> int:
	var n := 0
	for h in Sauvegarde.liste_heros():
		if h["id"] == id:
			n += 1
	return n
