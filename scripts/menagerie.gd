class_name Menagerie
extends RefCounted
## LA MÉNAGERIE : les familiers et les TERRAINS DE CHASSE (farming en temps réel).
##
##  - Une ÉQUIPE DE CHASSE = 1 héros de rareté N ou R (hors équipe de combat) + 1 familier,
##    envoyés sur une zone. Ils rapportent un butin à intervalle régulier (Célérité),
##    même jeu fermé, jusqu'à 12 h de stock : au-delà, il faut venir RÉCOLTER.
##  - Places : 2 au départ, +1 aux niveaux de compte 10, 20 et 30 (5 au maximum).
##  - Zones débloquées avec le niveau de compte ; chacune a son butin et ses rôles favoris.
##  - Quantité = Récolte du familier x bonus du héros (rareté R, niveau, étoiles, rôle favori)
##    x terrain préféré du familier. La Fortune augmente les chances de butin rare / épique.
##  - En chassant, le familier gagne des niveaux et le héros de l'XP.
##  - Les familiers s'obtiennent au PACTE SAUVAGE (Autel d'Invocation) avec des Sceaux Sauvages
##    (coffres et Mimics de l'Aventure, zone des Nids Sauvages, Marché du jour).
##  - Doublon d'un familier : ÉVEIL (+1 étoile, jusqu'à 5). Un familier inutile peut être libéré (or).

const SCENE := "res://scenes/menagerie.tscn"
const SCEAU := "sceau_sauvage"
const PLAFOND_SECONDES := 12 * 3600
const PLACES_DEPART := 2
const PALIERS_PLACES := [10, 20, 30]
const RARETES_HEROS := ["N", "R"]

## Butin : "commun" / "rare" / "epique" -> [objet, min, max]. « {e} » = élément du familier.
const ZONES := {
	"plaines": {"nom": "Plaines Cendrées", "niveau": 1, "facteur": 1.0, "roles": ["guerrier", "tank"],
		"desc": "Des champs de bataille calcinés : or abandonné et coffres enfouis.",
		"butin": {"commun": ["or", 120, 200], "rare": ["coffre_bronze", 1, 1], "epique": ["coffre_argent", 1, 1]}},
	"bibliotheque": {"nom": "Bibliothèque Engloutie", "niveau": 4, "facteur": 3.0, "roles": ["mage", "soutien"],
		"desc": "Des rayonnages noyés où dorment des tomes de savoir.",
		"butin": {"commun": ["tome_petit", 1, 1], "rare": ["tome_grand", 1, 1], "epique": ["tome_ancien", 1, 1]}},
	"sources": {"nom": "Sources Vives", "niveau": 8, "facteur": 3.0, "roles": ["soutien", "tank"],
		"desc": "Des eaux claires qui redonnent des forces : élixirs de stamina.",
		"butin": {"commun": ["elixir_petit", 1, 1], "rare": ["elixir_grand", 1, 1], "epique": ["elixir_grand", 2, 2]}},
	"cimetiere": {"nom": "Cimetière des Échos", "niveau": 12, "facteur": 1.2, "roles": ["assassin", "tireur"],
		"desc": "Des tombes où résonnent encore les Échos Sanguins : Poussière d'Écho.",
		"butin": {"commun": ["poussiere_echo", 2, 4], "rare": ["poussiere_echo", 8, 12], "epique": ["poussiere_echo", 20, 30]}},
	"veines": {"nom": "Veines Élémentaires", "niveau": 16, "facteur": 2.0, "roles": ["guerrier", "mage"],
		"desc": "Des failles gorgées d'énergie : ressources d'évolution de l'élément du familier (neutre = Sang).",
		"butin": {"commun": ["goutte_{e}", 1, 1], "rare": ["larme_{e}", 1, 1], "epique": ["coeur_{e}", 1, 1]}},
	"nids": {"nom": "Nids Sauvages", "niveau": 20, "facteur": 4.0, "roles": ["tireur", "assassin"],
		"desc": "Le repaire des bêtes : Sceaux Sauvages, et parfois un Éclat de Pacte Supérieur.",
		"butin": {"commun": ["sceau_sauvage", 1, 1], "rare": ["sceau_sauvage", 2, 3], "epique": ["eclat_superieur", 1, 1]}},
}
const ORDRE_ZONES := ["plaines", "bibliotheque", "sources", "cimetiere", "veines", "nids"]
const RESSOURCE_ELEMENT := {"feu": "braise", "nature": "seve", "eau": "abysse", "tenebres": "ombre", "sacre": "aube", "neutre": "sang"}
const POIDS_BUTIN := {"commun": 80.0, "rare": 17.0, "epique": 3.0}

## PACTE SAUVAGE (Autel d'Invocation)
const PACTE := {"nom": "Pacte Sauvage", "prix_x1": 1, "prix_x10": 10,
	"taux": [["N", 0.52], ["R", 0.32], ["SR", 0.12], ["SSR", 0.035], ["UR", 0.005]]}
## Garantie : un SSR (ou mieux) au plus tard après ce nombre d'invocations sans SSR/UR.
const GARANTIE := 40
## Or rendu en libérant un familier
const OR_LIBERATION := {"N": 150, "R": 400, "SR": 1200, "SSR": 3500, "UR": 9000}


# ---------------------------------------------------------------------
# État
# ---------------------------------------------------------------------

static func _etat() -> Dictionary:
	Sauvegarde.charger()
	if not Sauvegarde.donnees.has("menagerie") or not Sauvegarde.donnees["menagerie"] is Dictionary:
		Sauvegarde.donnees["menagerie"] = {}
	var m: Dictionary = Sauvegarde.donnees["menagerie"]
	for cle in ["familiers", "equipes", "decouverts"]:
		if not m.has(cle):
			m[cle] = []
	if not m.has("prochain_uid"):
		m["prochain_uid"] = 1
	if not m.has("pity"):
		m["pity"] = 0
	return m


static func maintenant() -> int:
	return int(Time.get_unix_time_from_system())


## Premier passage : un familier et quelques Sceaux offerts. Renvoie les lignes (ou []).
static func accueil() -> Array:
	var m := _etat()
	if m.get("accueil", false):
		return []
	m["accueil"] = true
	var f := ajouter_familier("chien_galeux")
	Sauvegarde.ajouter_objet(SCEAU, 5)
	Sauvegarde.sauvegarder()
	return ["Familier offert : %s" % FamiliersData.get_familier(f["id"])["nom"], "Sceaux Sauvages : +5"]


# ---------------------------------------------------------------------
# Familiers possédés
# ---------------------------------------------------------------------

static func familiers() -> Array:
	return _etat()["familiers"]


static func get_fam(uid: int) -> Dictionary:
	for f in familiers():
		if int(f["uid"]) == uid:
			return f
	return {}


static func ajouter_familier(id: String) -> Dictionary:
	var m := _etat()
	var f := {"uid": int(m["prochain_uid"]), "id": id, "niveau": 1, "xp": 0, "etoiles": 1}
	m["prochain_uid"] = int(m["prochain_uid"]) + 1
	m["familiers"].append(f)
	if not id in m["decouverts"]:
		m["decouverts"].append(id)
	return f


static func est_decouvert(id: String) -> bool:
	return id in _etat()["decouverts"]


static func xp_niveau(niveau: int) -> int:
	return 4 + 2 * niveau


static func recolte(f: Dictionary) -> float:
	var d := FamiliersData.get_familier(f["id"])
	return float(d["recolte"]) * (1.0 + 0.01 * (int(f["niveau"]) - 1)) * (1.0 + 0.05 * (int(f["etoiles"]) - 1))


static func fortune(f: Dictionary) -> float:
	var d := FamiliersData.get_familier(f["id"])
	var v := float(d["fortune"]) + 0.3 * (int(f["niveau"]) - 1) + 1.0 * (int(f["etoiles"]) - 1)
	if d["talent"] == "chance":
		v += FamiliersData.valeur_talent(f["id"], int(f["etoiles"]))
	return v


## Minutes entre deux butins sur une zone (Célérité x facteur de la zone).
static func minutes(f: Dictionary, zone: String) -> float:
	var d := FamiliersData.get_familier(f["id"])
	var m := float(d["celerite"]) * float(ZONES[zone]["facteur"])
	if d["talent"] == "rapide":
		m *= 1.0 - FamiliersData.valeur_talent(f["id"], int(f["etoiles"])) / 100.0
	return m


static func occupe_fam(uid: int) -> bool:
	for e in _etat()["equipes"]:
		if int(e["familier"]) == uid:
			return true
	return false


## Éveil : sacrifie un doublon (même familier) pour +1 étoile. Renvoie "" si OK, sinon la raison.
static func eveiller(uid: int, sacrifie: int) -> String:
	var f := get_fam(uid)
	var s := get_fam(sacrifie)
	if f.is_empty() or s.is_empty() or uid == sacrifie:
		return "Choisis un doublon."
	if f["id"] != s["id"]:
		return "Il faut un doublon du même familier."
	if int(f["etoiles"]) >= FamiliersData.ETOILES_MAX:
		return "Ce familier a déjà %d étoiles." % FamiliersData.ETOILES_MAX
	if occupe_fam(sacrifie):
		return "Le doublon est parti en chasse."
	f["etoiles"] = int(f["etoiles"]) + 1
	# Le doublon transmet une partie de son expérience
	f["xp"] = int(f["xp"]) + int(s["xp"])
	_monter(f)
	_etat()["familiers"].erase(s)
	Sauvegarde._stat("eveils_familiers")
	Sauvegarde.sauvegarder()
	return ""


## Libère un familier contre de l'or. Renvoie l'or gagné (0 si impossible).
static func liberer(uid: int) -> int:
	var f := get_fam(uid)
	if f.is_empty() or occupe_fam(uid):
		return 0
	var gain: int = OR_LIBERATION[FamiliersData.get_familier(f["id"])["rarete"]] * int(f["etoiles"])
	_etat()["familiers"].erase(f)
	Sauvegarde.ajouter_or(gain)
	Sauvegarde.sauvegarder()
	return gain


static func _monter(f: Dictionary) -> int:
	var nmax := int(FamiliersData.get_familier(f["id"])["niveau_max"])
	var n := 0
	while int(f["niveau"]) < nmax and int(f["xp"]) >= xp_niveau(int(f["niveau"])):
		f["xp"] = int(f["xp"]) - xp_niveau(int(f["niveau"]))
		f["niveau"] = int(f["niveau"]) + 1
		n += 1
	if int(f["niveau"]) >= nmax:
		f["xp"] = 0
	return n


# ---------------------------------------------------------------------
# Pacte Sauvage
# ---------------------------------------------------------------------

static func prix(nombre: int) -> int:
	return int(PACTE["prix_x10"]) if nombre >= 10 else int(PACTE["prix_x1"]) * nombre


static func peut_invoquer(nombre: int) -> bool:
	return Sauvegarde.get_objet(SCEAU) >= prix(nombre)


static func avant_garantie() -> int:
	return GARANTIE - int(_etat()["pity"])


## Renvoie [{uid, id, rarete, nouveau}] ou [] si pas assez de Sceaux.
static func invoquer(nombre: int, rng: RandomNumberGenerator = null) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	if not peut_invoquer(nombre):
		return []
	Sauvegarde.retirer_objet(SCEAU, prix(nombre))
	var m := _etat()
	var raretes: Array = []
	for i in nombre:
		var x := rng.randf()
		var cumul := 0.0
		var r := "N"
		for t in PACTE["taux"]:
			cumul += float(t[1])
			if x < cumul:
				r = t[0]
				break
		m["pity"] = int(m["pity"]) + 1
		if int(m["pity"]) >= GARANTIE and not r in ["SSR", "UR"]:
			r = "SSR"
		if r in ["SSR", "UR"]:
			m["pity"] = 0
		raretes.append(r)
	# x10 : au moins un SR garanti
	if nombre >= 10 and not ("SR" in raretes or "SSR" in raretes or "UR" in raretes):
		raretes[rng.randi_range(0, raretes.size() - 1)] = "SR"
	var res: Array = []
	for r in raretes:
		var l := FamiliersData.ids(r)
		var id: String = l[rng.randi_range(0, l.size() - 1)]
		var nouveau := not est_decouvert(id)
		var f := ajouter_familier(id)
		res.append({"uid": f["uid"], "id": id, "rarete": r, "nouveau": nouveau})
	Sauvegarde._stat("invocations_familiers", nombre)
	Sauvegarde.sauvegarder()
	return res


# ---------------------------------------------------------------------
# Terrains de chasse
# ---------------------------------------------------------------------

static func places() -> int:
	var n := PLACES_DEPART
	for p in PALIERS_PLACES:
		if Sauvegarde.get_niveau_compte() >= p:
			n += 1
	return n


static func zone_ouverte(zone: String) -> bool:
	return Sauvegarde.get_niveau_compte() >= int(ZONES[zone]["niveau"])


static func equipes() -> Array:
	return _etat()["equipes"]


static func heros_en_chasse(uid: int) -> bool:
	Sauvegarde.charger()
	var m = Sauvegarde.donnees.get("menagerie", {})
	if not m is Dictionary:
		return false
	for e in m.get("equipes", []):
		if int(e["heros"]) == uid:
			return true
	return false


## Pourquoi ce héros ne peut pas chasser ("" = il peut).
static func raison_heros(uid: int) -> String:
	var h := Sauvegarde.get_heros(uid)
	if h.is_empty():
		return "Introuvable."
	if not UnitesData.get_unite(h["id"])["rarete"] in RARETES_HEROS or h.get("depart", false) \
			or UnitesData.get_unite(h["id"]).get("legende", false):
		return "Seuls les héros N et R partent en chasse."
	if Sauvegarde.place_de(uid) >= 0:
		return "Ce héros est dans l'équipe de combat."
	if Sauvegarde.est_occupe(uid):
		return "Ce héros est déjà occupé."
	return ""


## Multiplicateur de récolte apporté par le héros sur une zone.
static func bonus_heros(uid: int, zone: String) -> float:
	var h := Sauvegarde.get_heros(uid)
	if h.is_empty():
		return 1.0
	var u := UnitesData.get_unite(h["id"])
	var b := 1.0 + 0.005 * (int(h["niveau"]) - 1) + 0.04 * (Fusion.etoiles(h) - 1)
	if u["rarete"] == "R":
		b += 0.10
	if u["role"] in ZONES[zone]["roles"]:
		b += 0.20
	return b


## Multiplicateur total de récolte d'une équipe (héros x familier x terrain).
static func multiplicateur(heros_uid: int, fam: Dictionary, zone: String) -> float:
	var d := FamiliersData.get_familier(fam["id"])
	var m := recolte(fam) * bonus_heros(heros_uid, zone)
	if d["terrain"] == zone:
		m *= 1.25
	if d["talent"] == "nomade":
		m *= 1.0 + FamiliersData.valeur_talent(fam["id"], int(fam["etoiles"])) / 100.0
	return m


## Envoie une équipe. Renvoie "" si OK, sinon la raison.
static func partir(heros_uid: int, fam_uid: int, zone: String) -> String:
	if equipes().size() >= places():
		return "Toutes les places de chasse sont prises."
	if not ZONES.has(zone) or not zone_ouverte(zone):
		return "Zone pas encore débloquée."
	var r := raison_heros(heros_uid)
	if r != "":
		return r
	if get_fam(fam_uid).is_empty():
		return "Choisis un familier."
	if occupe_fam(fam_uid):
		return "Ce familier est déjà en chasse."
	var t := maintenant()
	equipes().append({"heros": heros_uid, "familier": fam_uid, "zone": zone, "debut": t, "dernier": t,
		"butins": 0, "stock": {}, "graine": randi()})
	Sauvegarde._stat("chasses_lancees")
	Sauvegarde.sauvegarder()
	return ""


## Nombre maximum de butins stockés (12 h de chasse).
static func plafond(e: Dictionary) -> int:
	var f := get_fam(int(e["familier"]))
	if f.is_empty():
		return 0
	return maxi(1, int(PLAFOND_SECONDES / (minutes(f, e["zone"]) * 60.0)))


## Fait avancer toutes les chasses jusqu'à maintenant (appelé à l'ouverture de l'écran et chaque seconde).
static func maj() -> bool:
	var change := false
	var t := maintenant()
	for e in equipes():
		var f := get_fam(int(e["familier"]))
		if f.is_empty():
			continue
		var intervalle := int(minutes(f, e["zone"]) * 60.0)
		var n := int((t - int(e["dernier"])) / intervalle)
		if n <= 0:
			continue
		var place := plafond(e) - int(e["butins"])
		var k := mini(n, maxi(0, place))
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%d-%d" % [int(e.get("graine", 0)), int(e["dernier"])])
		for i in k:
			_ajouter_butin(e, f, rng)
		e["butins"] = int(e["butins"]) + k
		# Stock plein : le temps ne s'accumule plus
		e["dernier"] = t if int(e["butins"]) >= plafond(e) else int(e["dernier"]) + n * intervalle
		change = true
	if change:
		Sauvegarde.sauvegarder()
	return change


static func _ajouter_butin(e: Dictionary, f: Dictionary, rng: RandomNumberGenerator) -> void:
	var zone: String = e["zone"]
	var d := FamiliersData.get_familier(f["id"])
	var fo := fortune(f)
	var poids := {"commun": POIDS_BUTIN["commun"], "rare": POIDS_BUTIN["rare"] + fo * 0.8, "epique": POIDS_BUTIN["epique"] + fo * 0.12}
	var total := 0.0
	for k in poids:
		total += poids[k]
	var x := rng.randf() * total
	var palier := "commun"
	for k in ["commun", "rare", "epique"]:
		x -= poids[k]
		if x <= 0.0:
			palier = k
			break
	var b: Array = ZONES[zone]["butin"][palier]
	var objet: String = str(b[0]).replace("{e}", RESSOURCE_ELEMENT.get(d["element"], "sang"))
	var mult := multiplicateur(int(e["heros"]), f, zone)
	if palier != "commun":
		mult = sqrt(mult)
	var q := rng.randf_range(float(b[1]), float(b[2])) * mult
	if objet == "or":
		q *= 1.0 + 0.05 * Sauvegarde.get_niveau_compte()
		if d["talent"] == "or":
			q *= 1.0 + FamiliersData.valeur_talent(f["id"], int(f["etoiles"])) / 100.0
	var n := int(q) + (1 if rng.randf() < q - int(q) else 0)
	n = maxi(1, n)
	if d["talent"] == "double" and rng.randf() * 100.0 < FamiliersData.valeur_talent(f["id"], int(f["etoiles"])):
		n *= 2
	_stocker(e, objet, n)
	if d["talent"] == "sceau" and rng.randf() * 100.0 < FamiliersData.valeur_talent(f["id"], int(f["etoiles"])):
		_stocker(e, SCEAU, 1)
	if d["talent"] == "or" and objet != "or":
		_stocker(e, "or", int(2.0 * FamiliersData.valeur_talent(f["id"], int(f["etoiles"]))))


static func _stocker(e: Dictionary, objet: String, n: int) -> void:
	e["stock"][objet] = int(e["stock"].get(objet, 0)) + n


## Récolte le butin d'une équipe (index). Renvoie les lignes à afficher.
static func recolter(index: int) -> Array:
	maj()
	var l: Array = []
	if index < 0 or index >= equipes().size():
		return l
	var e: Dictionary = equipes()[index]
	var nb := int(e["butins"])
	if nb <= 0:
		return l
	var t := maintenant()
	if int(e["butins"]) >= plafond(e):
		e["dernier"] = t
	l.append_array(Reliquaire.donner(e["stock"]))
	var f := get_fam(int(e["familier"]))
	if not f.is_empty():
		f["xp"] = int(f["xp"]) + nb
		var nf := _monter(f)
		if nf > 0:
			l.append("%s passe niveau %d !" % [FamiliersData.get_familier(f["id"])["nom"], int(f["niveau"])])
	var h := Sauvegarde.get_heros(int(e["heros"]))
	if not h.is_empty():
		var xp := int(nb * Sauvegarde.xp_heros_pour_niveau(int(h["niveau"])) / 12.0)
		if not f.is_empty() and FamiliersData.get_familier(f["id"])["talent"] == "mentor":
			xp = int(xp * (1.0 + FamiliersData.valeur_talent(f["id"], int(f["etoiles"])) / 100.0))
		var nh := Sauvegarde.ajouter_xp_heros(int(e["heros"]), xp)
		var txt := "%s : +%d XP" % [UnitesData.get_unite(h["id"])["nom"], xp]
		if nh > 0:
			txt += "   NIVEAU %d !" % int(h["niveau"])
		l.append(txt)
	Sauvegarde._stat("butins_familiers", nb)
	e["stock"] = {}
	e["butins"] = 0
	Sauvegarde.sauvegarder()
	return l


## Rappelle une équipe (le butin en cours est récolté). Renvoie les lignes.
static func rappeler(index: int) -> Array:
	var l := recolter(index)
	if index >= 0 and index < equipes().size():
		equipes().remove_at(index)
		Sauvegarde.sauvegarder()
	return l


## Secondes avant le prochain butin d'une équipe (-1 si le stock est plein).
static func secondes_avant_butin(e: Dictionary) -> int:
	var f := get_fam(int(e["familier"]))
	if f.is_empty() or int(e["butins"]) >= plafond(e):
		return -1
	var intervalle := int(minutes(f, e["zone"]) * 60.0)
	return maxi(0, int(e["dernier"]) + intervalle - maintenant())


## Nombre d'équipes dont le stock est plein (pastille).
static func a_recolter() -> int:
	var n := 0
	for e in equipes():
		if int(e["butins"]) > 0:
			n += 1
	return n


## Estimation du butin moyen sur 12 h (affichée avant le départ) : {objet: quantité}.
static func estimation(heros_uid: int, fam: Dictionary, zone: String) -> Dictionary:
	var e := {"heros": heros_uid, "familier": fam["uid"], "zone": zone, "stock": {}}
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var n := maxi(1, int(PLAFOND_SECONDES / (minutes(fam, zone) * 60.0)))
	var essais := 20
	for i in n * essais:
		_ajouter_butin(e, fam, rng)
	var r := {}
	for o in e["stock"]:
		r[o] = float(e["stock"][o]) / essais
	return r
