class_name Sauvegarde
extends RefCounted
## SAUVEGARDE DU JEU : toutes les données du joueur, au même endroit.
##
## Utilisable depuis n'importe quel script, sans rien configurer :
##   Sauvegarde.get_or()                  -> or du joueur
##   Sauvegarde.ajouter_or(150)
##   if Sauvegarde.depenser_or(500): ...  -> false si pas assez d'or
##   Sauvegarde.get_stamina()             -> se recharge toute seule avec le temps
##   Sauvegarde.depenser_stamina(5)
##   Sauvegarde.get_niveau_compte()
##
## Chaque modification est enregistrée immédiatement (rien à faire).
## Fichier : user://sauvegarde.json  (+ copie de secours sauvegarde.bak)
##   - sur PC : %APPDATA%/Godot/app_userdata/<nom du projet>/
##   - sur le web (github.io) : dans le navigateur du joueur
##
## POUR AJOUTER UNE NOUVELLE DONNÉE PLUS TARD : ajoute-la dans _defaut().
## Les anciennes sauvegardes la recevront automatiquement (valeur par défaut).

const VERSION := 1
const FICHIER := "user://sauvegarde.json"
const SECOURS := "user://sauvegarde.bak"
const ANCIEN_FICHIER := "user://progression.json"   # ancien format (avant ce système)

## Recharge de stamina : 1 point toutes les X secondes
## STAMINA : 1 point toutes les 5 minutes (même jeu fermé).
const STAMINA_RECHARGE_SECONDES := 300
const STAMINA_MAX_BASE := 30
## +2 stamina max par niveau de compte : 30 au niveau 1, 88 au niveau 30.
const STAMINA_PAR_NIVEAU := 2
## NIVEAU DE COMPTE : plafond (à relever quand de nouveaux contenus arriveront).
const NIVEAU_COMPTE_MAX := 30
## Coût en stamina d'un combat de l'Aventure (les autres cases sont gratuites).
const COUT_STAMINA_AVENTURE := {"combat": 1, "elite": 2, "gardien": 2, "boss_chapitre": 3, "boss_acte": 3}
## XP de compte gagnée à chaque combat gagné (Aventure, Tours, Boss de Monde).
const XP_COMPTE_VICTOIRE := {"combat": 10, "elite": 15, "gardien": 15, "boss_chapitre": 25, "boss_acte": 40,
	"boss": 25, "super": 40, "boss_monde": 30}

static var donnees: Dictionary = {}
static var _charge := false


static func _defaut() -> Dictionary:
	var maintenant := int(Time.get_unix_time_from_system())
	return {
		"version": VERSION,
		"cree_le": maintenant,
		"sauvegarde_le": maintenant,
		"compte": {
			"niveau": 1,
			"xp": 0,
		},
		"ressources": {
			"or": 0,
			"gemmes": 50,
			"stamina": STAMINA_MAX_BASE,
			"stamina_maj": maintenant,   # dernière mise à jour (pour la recharge)
		},
		"progression": {
			"termines": [],              # ex : ["1-1", "1-2"]
		},
		# Chapitre en cours : permet de reprendre un plateau là où on l'a quitté
		"plateau_en_cours": {},
		# Héros de départ choisi au premier lancement ("" = pas encore choisi)
		"heros_depart": "",
		# Héros possédés : liste d'exemplaires {uid, id, niveau, xp, echos, depart}
		# (on peut posséder plusieurs fois le même héros)
		"collection": {
			"heros": [],
			"prochain_uid": 1,
			"objets": {},
		},
		# Équipe : 5 places (uid du héros, ou -1 si vide). Places 1-2 = Avant, 3-5 = Arrière.
		"equipe": [-1, -1, -1, -1, -1],
		# Échos Sanguins possédés (voir echos.gd)
		"echos": [],
		"prochain_uid_echo": 1,
		# Autel d'Invocation : compteur de garantie et statistiques
		"invocation": {"pity_superieur": 0, "total_dore": 0, "total_superieur": 0},
		# Bestiaire : id des unités découvertes (rencontrées en combat ou obtenues)
		"bestiaire": [],
		# Tours de l'Enfer et du Paradis : dernier étage vaincu cette semaine, record absolu
		"tours": {
			"enfer": {"semaine": -1, "etage": 0, "record": 0},
			"paradis": {"semaine": -1, "etage": 0, "record": 0},
		},
		# Boss de Monde : essais du jour, records (% de PV infligés), 4 escouades de 5 (uid ou -1)
		"boss_monde": {
			"jour": -1, "essais": 0, "records": {}, "records_jour": {},
			"escouades": [-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
		},
		# Dernière version du jeu dont le joueur a vu les nouveautés
		"version_vue": "",
		"version_jeu": "",
		"parametres": {
			"volume_musique": 0.8,
			"volume_sons": 0.8,
		},
		"statistiques": {
			"combats_gagnes": 0,
			"combats_perdus": 0,
			"coffres_ouverts": 0,
			"or_total_gagne": 0,
		},
	}


# ------------------------------------------------------------------
# Chargement / enregistrement
# ------------------------------------------------------------------

static func charger() -> void:
	if _charge:
		return
	_charge = true
	var lu = _lire(FICHIER)
	if lu == null:
		lu = _lire(SECOURS)
		if lu != null:
			push_warning("Sauvegarde principale illisible : copie de secours utilisée.")
	if lu == null:
		donnees = _defaut()
		_migrer_ancienne_progression()
		sauvegarder()
		return
	donnees = _fusionner(_defaut(), lu)
	donnees["version"] = VERSION
	# Niveau de compte plafonné (anciennes parties)
	if int(donnees["compte"]["niveau"]) > NIVEAU_COMPTE_MAX:
		donnees["compte"]["niveau"] = NIVEAU_COMPTE_MAX
		donnees["compte"]["xp"] = 0
	# Anciennes parties : le héros de départ était seul -> on ajoute les unités de départ
	if str(donnees["heros_depart"]) != "" and donnees["collection"]["heros"].size() == 1:
		var equipe: Array = get_equipe()
		for autre in UNITES_DE_DEPART:
			equipe.append(ajouter_heros(autre))
		equipe.sort_custom(func(x, y): return _ordre_place(get_heros(x)["id"]) < _ordre_place(get_heros(y)["id"]))
		donnees["equipe"] = _liste_vers_slots(equipe)
		sauvegarder()


static func sauvegarder() -> void:
	charger()
	donnees["sauvegarde_le"] = int(Time.get_unix_time_from_system())
	donnees["version_jeu"] = Version.NUMERO
	var texte := JSON.stringify(donnees, "\t")
	# On écrit le fichier principal, puis la copie de secours (identique).
	# Si le jeu plante pendant l'écriture de l'un, l'autre reste intact.
	if not _ecrire(FICHIER, texte):
		push_error("Impossible d'écrire la sauvegarde : " + FICHIER)
		return
	_ecrire(SECOURS, texte)


static func reinitialiser() -> void:
	donnees = _defaut()
	_charge = true
	sauvegarder()


static func _lire(chemin: String):
	if not FileAccess.file_exists(chemin):
		return null
	var texte := FileAccess.get_file_as_string(chemin)
	if texte == "":
		return null
	var resultat = JSON.parse_string(texte)
	if resultat is Dictionary:
		return resultat
	return null


static func _ecrire(chemin: String, texte: String) -> bool:
	var f := FileAccess.open(chemin, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(texte)
	f.close()
	return true


## Ajoute les champs manquants (nouvelle version du jeu) sans perdre les données existantes.
static func _fusionner(base: Dictionary, lu: Dictionary) -> Dictionary:
	var resultat := base.duplicate(true)
	for cle in lu:
		if resultat.has(cle) and resultat[cle] is Dictionary and lu[cle] is Dictionary and not resultat[cle].is_empty():
			resultat[cle] = _fusionner(resultat[cle], lu[cle])
		else:
			resultat[cle] = lu[cle]
	return resultat


static func _migrer_ancienne_progression() -> void:
	var ancien = _lire(ANCIEN_FICHIER)
	if ancien == null:
		return
	donnees["ressources"]["or"] = int(ancien.get("or", 0))
	donnees["progression"]["termines"] = ancien.get("termines", [])
	DirAccess.remove_absolute(ANCIEN_FICHIER)


# ------------------------------------------------------------------
# Export / import (transférer sa partie, ou la mettre de côté)
# ------------------------------------------------------------------

## Renvoie un code texte contenant toute la sauvegarde.
static func exporter_code() -> String:
	charger()
	return Marshalls.utf8_to_base64(JSON.stringify(donnees))


## Remplace la sauvegarde par celle contenue dans le code. Renvoie false si le code est invalide.
static func importer_code(code: String) -> bool:
	var texte := Marshalls.base64_to_utf8(code.strip_edges())
	var lu = JSON.parse_string(texte)
	if not (lu is Dictionary) or not lu.has("ressources") or not lu.has("progression"):
		return false
	donnees = _fusionner(_defaut(), lu)
	_charge = true
	sauvegarder()
	return true


# ------------------------------------------------------------------
# Ressources
# ------------------------------------------------------------------

static func get_or() -> int:
	charger()
	return int(donnees["ressources"]["or"])


static func ajouter_or(montant: int) -> void:
	charger()
	donnees["ressources"]["or"] = get_or() + montant
	if montant > 0:
		_stat("or_total_gagne", montant)
	sauvegarder()


## Retire de l'or si le joueur en a assez. Renvoie false sinon (rien n'est retiré).
static func depenser_or(montant: int) -> bool:
	if get_or() < montant:
		return false
	donnees["ressources"]["or"] = get_or() - montant
	sauvegarder()
	return true


static func get_gemmes() -> int:
	charger()
	return int(donnees["ressources"]["gemmes"])


static func ajouter_gemmes(montant: int) -> void:
	charger()
	donnees["ressources"]["gemmes"] = get_gemmes() + montant
	sauvegarder()


static func depenser_gemmes(montant: int) -> bool:
	if get_gemmes() < montant:
		return false
	donnees["ressources"]["gemmes"] = get_gemmes() - montant
	sauvegarder()
	return true


# ------------------------------------------------------------------
# Stamina (se recharge avec le temps, même jeu fermé)
# ------------------------------------------------------------------

static func get_stamina_max() -> int:
	return stamina_max_niveau(get_niveau_compte())


static func stamina_max_niveau(niveau: int) -> int:
	return STAMINA_MAX_BASE + (niveau - 1) * STAMINA_PAR_NIVEAU


static func get_stamina() -> int:
	charger()
	_recharger_stamina()
	return int(donnees["ressources"]["stamina"])


## Secondes avant le prochain point de stamina (0 si pleine).
static func secondes_avant_stamina() -> int:
	charger()
	_recharger_stamina()
	if int(donnees["ressources"]["stamina"]) >= get_stamina_max():
		return 0
	var ecoule := int(Time.get_unix_time_from_system()) - int(donnees["ressources"]["stamina_maj"])
	return maxi(0, STAMINA_RECHARGE_SECONDES - ecoule)


static func depenser_stamina(montant: int) -> bool:
	if get_stamina() < montant:
		return false
	var r: Dictionary = donnees["ressources"]
	if int(r["stamina"]) >= get_stamina_max():
		r["stamina_maj"] = int(Time.get_unix_time_from_system())   # la recharge démarre maintenant
	r["stamina"] = int(r["stamina"]) - montant
	sauvegarder()
	return true


## Ajoute de la stamina (élixir, montée de niveau...). Peut dépasser le maximum.
static func ajouter_stamina(montant: int) -> void:
	charger()
	donnees["ressources"]["stamina"] = get_stamina() + montant
	sauvegarder()


static func _recharger_stamina() -> void:
	var r: Dictionary = donnees["ressources"]
	var maximum := get_stamina_max()
	var maintenant := int(Time.get_unix_time_from_system())
	if int(r["stamina"]) >= maximum:
		r["stamina_maj"] = maintenant
		return
	var gagne := (maintenant - int(r["stamina_maj"])) / STAMINA_RECHARGE_SECONDES
	if gagne <= 0:
		return
	r["stamina"] = mini(maximum, int(r["stamina"]) + gagne)
	r["stamina_maj"] = int(r["stamina_maj"]) + gagne * STAMINA_RECHARGE_SECONDES


# ------------------------------------------------------------------
# Compte (niveau du joueur)
# ------------------------------------------------------------------

static func get_niveau_compte() -> int:
	charger()
	return int(donnees["compte"]["niveau"])


static func get_xp_compte() -> int:
	charger()
	return int(donnees["compte"]["xp"])


## XP nécessaire pour passer du niveau `niveau` au suivant.
## Réglé pour atteindre ~niveau 27 à la fin de l'Acte XII, puis 30 avec les Tours et Boss de Monde.
static func xp_pour_niveau(niveau: int) -> int:
	return 100 + niveau * 44


static func niveau_compte_max_atteint() -> bool:
	return get_niveau_compte() >= NIVEAU_COMPTE_MAX


## Ajoute de l'XP de compte. Renvoie le nombre de niveaux gagnés.
## Chaque niveau : stamina max en hausse et la stamina est ENTIÈREMENT rechargée.
static func ajouter_xp_compte(montant: int) -> int:
	charger()
	var c: Dictionary = donnees["compte"]
	if int(c["niveau"]) >= NIVEAU_COMPTE_MAX:
		c["niveau"] = NIVEAU_COMPTE_MAX
		c["xp"] = 0
		return 0
	c["xp"] = int(c["xp"]) + montant
	var gagnes := 0
	while int(c["niveau"]) < NIVEAU_COMPTE_MAX and int(c["xp"]) >= xp_pour_niveau(int(c["niveau"])):
		c["xp"] = int(c["xp"]) - xp_pour_niveau(int(c["niveau"]))
		c["niveau"] = int(c["niveau"]) + 1
		gagnes += 1
	if int(c["niveau"]) >= NIVEAU_COMPTE_MAX:
		c["xp"] = 0
	if gagnes > 0:
		var r: Dictionary = donnees["ressources"]
		r["stamina"] = maxi(int(r["stamina"]), get_stamina_max())
		r["stamina_maj"] = int(Time.get_unix_time_from_system())
		_stat("niveaux_compte", gagnes)
	sauvegarder()
	return gagnes


# ------------------------------------------------------------------
# Progression de l'Histoire
# ------------------------------------------------------------------

static func est_termine(acte: int, chapitre: int) -> bool:
	charger()
	return ("%d-%d" % [acte, chapitre]) in donnees["progression"]["termines"]


static func marquer_termine(acte: int, chapitre: int) -> void:
	charger()
	var cle := "%d-%d" % [acte, chapitre]
	if not cle in donnees["progression"]["termines"]:
		donnees["progression"]["termines"].append(cle)
	sauvegarder()


static func nombre_chapitres_termines() -> int:
	charger()
	return donnees["progression"]["termines"].size()


# ------------------------------------------------------------------
# Plateau en cours (reprise d'un chapitre quitté en route)
# ------------------------------------------------------------------

static func get_plateau_en_cours(acte: int, chapitre: int) -> Dictionary:
	charger()
	var p: Dictionary = donnees["plateau_en_cours"]
	if p.is_empty() or int(p.get("acte", 0)) != acte or int(p.get("chapitre", 0)) != chapitre:
		return {}
	return p


static func enregistrer_plateau(etat: Dictionary) -> void:
	charger()
	donnees["plateau_en_cours"] = etat
	sauvegarder()


static func effacer_plateau() -> void:
	charger()
	donnees["plateau_en_cours"] = {}
	sauvegarder()


# ------------------------------------------------------------------
# Héros : collection, équipe, héros de départ
# ------------------------------------------------------------------

const TAILLE_EQUIPE_MAX := 5

static func a_choisi_heros_depart() -> bool:
	charger()
	return str(donnees["heros_depart"]) != ""


## Unités offertes au début de l'aventure, en plus du héros choisi.
const UNITES_DE_DEPART := ["chevalier", "archer", "clerc"]

## Choix du héros de départ (premier lancement ou après "Nouvelle partie").
static func choisir_heros_depart(id_unite: String) -> void:
	charger()
	donnees["heros_depart"] = id_unite
	var uid := ajouter_heros(id_unite)
	get_heros(uid)["depart"] = true      # protégé : ne pourra pas être vendu
	var equipe: Array = [uid]
	for autre in UNITES_DE_DEPART:
		equipe.append(ajouter_heros(autre))
	# Placement automatique : corps à corps à l'Avant (places 1-2), distance à l'Arrière
	equipe.sort_custom(func(a, b): return _ordre_place(get_heros(a)["id"]) < _ordre_place(get_heros(b)["id"]))
	definir_slots(_liste_vers_slots(equipe))


static func _ordre_place(id_unite: String) -> int:
	var role: String = UnitesData.get_unite(id_unite)["role"]
	return {"tank": 0, "guerrier": 1, "assassin": 2, "tireur": 3, "mage": 4, "soutien": 5}.get(role, 3)


## XP nécessaire à un héros pour passer du niveau n au suivant.
static func xp_heros_pour_niveau(n: int) -> int:
	return 100 + 30 * n


## Ajoute de l'XP à un héros. Renvoie le nombre de niveaux gagnés (plafond : niveau 30).
static func ajouter_xp_heros(uid: int, xp: int) -> int:
	var h := get_heros(uid)
	if h.is_empty():
		return 0
	var gagnes := 0
	h["xp"] = int(h["xp"]) + xp
	while int(h["niveau"]) < UnitesData.NIVEAU_MAX and int(h["xp"]) >= xp_heros_pour_niveau(int(h["niveau"])):
		h["xp"] = int(h["xp"]) - xp_heros_pour_niveau(int(h["niveau"]))
		h["niveau"] = int(h["niveau"]) + 1
		gagnes += 1
	if int(h["niveau"]) >= UnitesData.NIVEAU_MAX:
		h["xp"] = 0
	sauvegarder()
	return gagnes


## Ajoute un exemplaire d'un héros à la collection. Renvoie son uid (numéro unique).
static func ajouter_heros(id_unite: String) -> int:
	charger()
	var c: Dictionary = donnees["collection"]
	var uid := int(c["prochain_uid"])
	c["prochain_uid"] = uid + 1
	c["heros"].append({"uid": uid, "id": id_unite, "niveau": 1, "xp": 0, "etoiles": 1, "echos": {}, "depart": false})
	if not id_unite in donnees["bestiaire"]:
		donnees["bestiaire"].append(id_unite)
	sauvegarder()
	return uid


static func liste_heros() -> Array:
	charger()
	return donnees["collection"]["heros"]


## Renvoie l'exemplaire correspondant à cet uid ({} s'il n'existe pas).
static func get_heros(uid: int) -> Dictionary:
	for h in liste_heros():
		if int(h["uid"]) == uid:
			return h
	return {}


## Héros de l'équipe dans l'ordre des places (sans les places vides).
static func get_equipe() -> Array:
	var e: Array = []
	for uid in get_slots():
		if uid >= 0:
			e.append(uid)
	return e


## Les 5 places de l'équipe : uid, ou -1 si la place est vide.
static func get_slots() -> Array:
	charger()
	var brut: Array = donnees["equipe"]
	var s: Array = []
	for i in TAILLE_EQUIPE_MAX:
		var uid := int(brut[i]) if i < brut.size() else -1
		s.append(uid if (uid >= 0 and not get_heros(uid).is_empty() and not uid in s) else -1)
	return s


## Place d'un héros dans l'équipe (0 à 4), ou -1 s'il est en réserve.
static func place_de(uid: int) -> int:
	return get_slots().find(uid)


static func definir_slots(slots: Array) -> void:
	charger()
	var s: Array = []
	for i in TAILLE_EQUIPE_MAX:
		s.append(int(slots[i]) if i < slots.size() else -1)
	donnees["equipe"] = s
	sauvegarder()


## Met un héros à une place. S'il était déjà dans l'équipe, il échange sa place.
static func placer(uid: int, place: int) -> void:
	var s := get_slots()
	var ancienne := s.find(uid)
	if ancienne >= 0:
		s[ancienne] = s[place]
	s[place] = uid
	definir_slots(s)


## Retire un héros de l'équipe (impossible s'il est le dernier).
static func retirer_de_equipe(uid: int) -> bool:
	var s := get_slots()
	if get_equipe().size() <= 1:
		return false
	var i := s.find(uid)
	if i >= 0:
		s[i] = -1
		definir_slots(s)
	return true


static func _liste_vers_slots(uids: Array) -> Array:
	var s: Array = [-1, -1, -1, -1, -1]
	for i in mini(uids.size(), TAILLE_EQUIPE_MAX):
		s[i] = uids[i]
	return s


# ------------------------------------------------------------------
# Boss de Monde : 4 escouades de 5 (20 places)
# ------------------------------------------------------------------

const TAILLE_ARMEE := 20

static func get_escouades() -> Array:
	charger()
	var brut: Array = donnees["boss_monde"]["escouades"]
	var s: Array = []
	for i in TAILLE_ARMEE:
		var uid := int(brut[i]) if i < brut.size() else -1
		s.append(uid if (uid >= 0 and not get_heros(uid).is_empty() and not uid in s) else -1)
	return s


static func definir_escouades(places: Array) -> void:
	charger()
	var s: Array = []
	for i in TAILLE_ARMEE:
		s.append(int(places[i]) if i < places.size() else -1)
	donnees["boss_monde"]["escouades"] = s
	sauvegarder()


# ------------------------------------------------------------------
# Vente et verrouillage
# ------------------------------------------------------------------

const PRIX_VENTE := {"N": 50, "R": 150, "SR": 500, "SSR": 1500, "UR": 4000}
const PRIX_VENTE_LEGENDE := 3000

static func prix_vente(uid: int) -> int:
	var h := get_heros(uid)
	if h.is_empty():
		return 0
	var u := UnitesData.get_unite(h["id"])
	var base: int = PRIX_VENTE_LEGENDE if u.get("legende", false) else PRIX_VENTE[u["rarete"]]
	return int(base * (1.0 + (int(h["niveau"]) - 1) * 0.05) * (1.0 + (Fusion.etoiles(h) - 1) * 0.5))


## Raison pour laquelle un héros ne peut pas être vendu ("" = vendable).
static func raison_invendable(uid: int) -> String:
	var h := get_heros(uid)
	if h.is_empty():
		return "Introuvable"
	if h.get("depart", false):
		return "Ton héros de départ ne peut pas être vendu."
	if h.get("verrou", false):
		return "Ce héros est verrouillé."
	if place_de(uid) >= 0:
		return "Retire-le d'abord de l'équipe."
	return ""


## Vend plusieurs héros d'un coup. Renvoie l'or gagné (les invendables sont ignorés).
static func vendre(uids: Array) -> int:
	charger()
	var total := 0
	for uid in uids:
		if raison_invendable(int(uid)) != "":
			continue
		total += prix_vente(int(uid))
		_retirer_heros(int(uid))
	if total > 0:
		donnees["ressources"]["or"] = get_or() + total
		_stat("unites_vendues", uids.size())
	sauvegarder()
	return total


## Retire définitivement des héros de la collection (fusion). Leurs Échos retournent dans l'inventaire.
static func supprimer_heros(uids: Array) -> void:
	charger()
	for uid in uids:
		_retirer_heros(int(uid))
	sauvegarder()


static func _retirer_heros(uid: int) -> void:
	for e in donnees["echos"]:          # ses Échos retournent dans l'inventaire
		if int(e["porteur"]) == uid:
			e["porteur"] = -1
	var liste: Array = donnees["collection"]["heros"]
	for i in liste.size():
		if int(liste[i]["uid"]) == uid:
			liste.remove_at(i)
			break
	var esc: Array = donnees["boss_monde"]["escouades"]
	for i in esc.size():
		if int(esc[i]) == uid:
			esc[i] = -1
	var s := get_slots()                # sécurité : jamais d'uid fantôme dans l'équipe
	if uid in s:
		s[s.find(uid)] = -1
		donnees["equipe"] = s


static func basculer_verrou(uid: int) -> void:
	var h := get_heros(uid)
	if not h.is_empty():
		h["verrou"] = not h.get("verrou", false)
		sauvegarder()


# ------------------------------------------------------------------
# Échos Sanguins
# ------------------------------------------------------------------

static func liste_echos() -> Array:
	charger()
	return donnees["echos"]


static func get_echo(uid: int) -> Dictionary:
	for e in liste_echos():
		if int(e["uid"]) == uid:
			return e
	return {}


## Ajoute un Écho (créé par Echos.creer ou Echos.tirer_drop). Renvoie son uid.
static func ajouter_echo(e: Dictionary) -> int:
	charger()
	var uid := int(donnees["prochain_uid_echo"])
	donnees["prochain_uid_echo"] = uid + 1
	e["uid"] = uid
	e["porteur"] = -1
	donnees["echos"].append(e)
	sauvegarder()
	return uid


## Échos portés par un héros.
static func echos_de(uid_heros: int) -> Array:
	return liste_echos().filter(func(e): return int(e["porteur"]) == uid_heros)


## Équipe un Écho sur un héros (remplace celui du même emplacement ; s'il était porté
## par un autre héros, il change de porteur).
static func equiper_echo(uid_echo: int, uid_heros: int) -> void:
	var e := get_echo(uid_echo)
	if e.is_empty() or get_heros(uid_heros).is_empty():
		return
	for autre in echos_de(uid_heros):
		if int(autre["emplacement"]) == int(e["emplacement"]):
			autre["porteur"] = -1
	e["porteur"] = uid_heros
	sauvegarder()


static func retirer_echo(uid_echo: int) -> void:
	var e := get_echo(uid_echo)
	if not e.is_empty():
		e["porteur"] = -1
		sauvegarder()


## Vend des Échos (les verrouillés et ceux portés par un héros sont ignorés). Renvoie l'or gagné.
## Supprime définitivement des Échos (démantèlement au Reliquaire).
static func supprimer_echos(uids: Array) -> void:
	charger()
	var cibles := {}
	for u in uids:
		cibles[int(u)] = true
	donnees["echos"] = (donnees["echos"] as Array).filter(func(e): return not cibles.has(int(e["uid"])))
	sauvegarder()


static func vendre_echos(uids: Array) -> int:
	charger()
	var total := 0
	var liste: Array = donnees["echos"]
	for uid in uids:
		for i in liste.size():
			var e: Dictionary = liste[i]
			if int(e["uid"]) == int(uid):
				if not e.get("verrou", false) and int(e["porteur"]) < 0:
					total += Echos.prix_vente(e)
					liste.remove_at(i)
				break
	donnees["ressources"]["or"] = get_or() + total
	sauvegarder()
	return total


static func basculer_verrou_echo(uid_echo: int) -> void:
	var e := get_echo(uid_echo)
	if not e.is_empty():
		e["verrou"] = not e.get("verrou", false)
		sauvegarder()


## Bonus totaux des Échos portés par un héros (pour le combat).
static func bonus_echos(uid_heros: int) -> Dictionary:
	return Echos.bonus(echos_de(uid_heros))


## Stats finales d'un héros : niveau + étoiles + Échos.
static func stats_heros(uid_heros: int) -> Dictionary:
	var h := get_heros(uid_heros)
	if h.is_empty():
		return {}
	return Echos.appliquer(stats_base_heros(uid_heros), bonus_echos(uid_heros))


## Stats d'un héros sans les Échos : niveau + étoiles (Autel de Fusion).
static func stats_base_heros(uid_heros: int) -> Dictionary:
	var h := get_heros(uid_heros)
	if h.is_empty():
		return {}
	return Fusion.appliquer_etoiles(UnitesData.stats(h["id"], int(h["niveau"])), Fusion.etoiles(h))


# ------------------------------------------------------------------
# Objets (Éclats de Pacte Supérieur, etc.)
# ------------------------------------------------------------------

const ECLAT := "eclat_superieur"

static func get_objet(nom: String) -> int:
	charger()
	return int(donnees["collection"]["objets"].get(nom, 0))


static func ajouter_objet(nom: String, n: int) -> void:
	charger()
	donnees["collection"]["objets"][nom] = get_objet(nom) + n
	sauvegarder()


static func retirer_objet(nom: String, n: int) -> bool:
	if get_objet(nom) < n:
		return false
	donnees["collection"]["objets"][nom] = get_objet(nom) - n
	sauvegarder()
	return true


## Exemplaire du héros de départ ({} si pas encore choisi).
static func get_heros_depart() -> Dictionary:
	for h in liste_heros():
		if h.get("depart", false):
			return h
	return {}


# ------------------------------------------------------------------
# Bestiaire (codex)
# ------------------------------------------------------------------

## Marque une unité comme découverte. Renvoie true si c'est une nouvelle découverte.
static func decouvrir(id_unite: String) -> bool:
	charger()
	if id_unite in donnees["bestiaire"]:
		return false
	donnees["bestiaire"].append(id_unite)
	sauvegarder()
	return true


static func est_decouvert(id_unite: String) -> bool:
	charger()
	return id_unite in donnees["bestiaire"]


static func nombre_decouverts() -> int:
	charger()
	return donnees["bestiaire"].size()


# ------------------------------------------------------------------
# Statistiques
# ------------------------------------------------------------------

static func _stat(nom: String, montant := 1) -> void:
	var s: Dictionary = donnees["statistiques"]
	s[nom] = int(s.get(nom, 0)) + montant


static func ajouter_stat(nom: String, montant := 1) -> void:
	charger()
	_stat(nom, montant)
	sauvegarder()
