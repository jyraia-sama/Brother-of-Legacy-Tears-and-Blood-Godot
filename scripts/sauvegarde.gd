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
const COUT_STAMINA_AVENTURE := {"combat": 1, "elite": 2, "gardien": 2, "boss_chapitre": 3, "boss_acte": 3, "mimic": 0}
## XP de compte gagnée à chaque combat gagné (Aventure, Tours, Boss de Monde).
const XP_COMPTE_VICTOIRE := {"combat": 10, "elite": 15, "mimic": 20, "gardien": 15, "boss_chapitre": 25, "boss_acte": 40,
	"boss": 25, "super": 40, "boss_monde": 30, "arene": 20, "donjon": 30}

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
		# Quêtes (progression du jour / de la semaine, connexion), Succès réclamés, titre, Boutique
		"quetes": {},
		# Guide des premiers pas : étapes réclamées, astuces déjà vues, guide masqué
		"tutoriel": {},
		"succes": {"reclames": {}, "titre": ""},
		"boutique": {},
		# Expéditions de la Compagnie : missions lancées aujourd'hui et escouades parties (voir compagnie.gd)
		"compagnie": {"jour": -1, "lancees": [], "en_cours": []},
		# Marche Maudite : partie en cours ou terminée du jour, records, achats de la boutique (voir marche.gd)
		"marche": {},
		# Donjons : plus haut niveau terminé et nombre de victoires, par donjon (voir donjons.gd)
		"donjons": {},
		# Arène : équipe de défense (5 places, uid du héros ou -1)
		"arene": {"defense": [-1, -1, -1, -1, -1]},
		# Options du menu Admin (tests) : id -> true/false
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
	Audio.demarrer()        # musique et bruitages (voir audio.gd)
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
	donnees.erase("admin")      # ancienne triche enregistrée : jamais conservée d'une session à l'autre
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


## ÉCRITURE GROUPÉE : un combat gagné appelle sauvegarder() une quinzaine de fois (or, XP de chaque
## héros, Écho, objets, statistiques...). Réécrire tout le fichier à chaque fois faisait ramer la version
## web. Maintenant, sauvegarder() note seulement qu'il faut écrire, et le fichier est écrit UNE fois,
## au plus tard DELAI_ECRITURE secondes après (et tout de suite quand le jeu passe en arrière-plan).
const DELAI_ECRITURE := 0.6
## La copie de secours n'est réécrite qu'une écriture sur ECRITURES_PAR_SECOURS.
const ECRITURES_PAR_SECOURS := 5
static var _ecriture_prevue := false
static var _nb_ecritures := 0
## Augmente à chaque modification : la synchronisation en ligne s'en sert pour ne rien recalculer
## tant que la partie n'a pas changé.
static var revision := 0


static func sauvegarder() -> void:
	charger()
	revision += 1
	if _ecriture_prevue:
		return
	var arbre := Engine.get_main_loop() as SceneTree
	if arbre == null or arbre.root == null:
		ecrire_maintenant()
		return
	_ecriture_prevue = true
	arbre.create_timer(DELAI_ECRITURE, true).timeout.connect(ecrire_maintenant)


## Écrit tout de suite la sauvegarde si une écriture est en attente (ou si `forcer`).
static func ecrire_maintenant(forcer := false) -> void:
	if not _ecriture_prevue and not forcer:
		return
	_ecriture_prevue = false
	if not _charge:
		return
	donnees["sauvegarde_le"] = int(Time.get_unix_time_from_system())
	donnees["version_jeu"] = Version.NUMERO
	var texte := JSON.stringify(donnees)
	# On écrit le fichier principal, puis (de temps en temps) la copie de secours.
	# Si le jeu plante pendant l'écriture de l'un, l'autre reste intact.
	if not _ecrire(FICHIER, texte):
		push_error("Impossible d'écrire la sauvegarde : " + FICHIER)
		return
	_nb_ecritures += 1
	if _nb_ecritures % ECRITURES_PAR_SECOURS == 1:
		_ecrire(SECOURS, texte)


## Paramètres du joueur (volumes...). Voir "parametres" dans _defaut().
static func get_parametre(cle: String, defaut = null):
	charger()
	return donnees["parametres"].get(cle, defaut)


static func definir_parametre(cle: String, valeur) -> void:
	charger()
	donnees["parametres"][cle] = valeur
	sauvegarder()


static func reinitialiser() -> void:
	charger()
	var parametres: Dictionary = donnees.get("parametres", {}).duplicate()   # on garde les volumes
	donnees = _defaut()
	donnees["parametres"].merge(parametres, true)
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
	var parametres: Dictionary = donnees.get("parametres", {}).duplicate()   # on garde les volumes
	donnees = _fusionner(_defaut(), lu)
	donnees.erase("admin")
	donnees["parametres"].merge(parametres, true)
	_charge = true
	sauvegarder()
	return true


## Remplace toute la partie (utilisé par la sauvegarde en ligne, voir en_ligne.gd).
static func remplacer_par(d: Dictionary) -> void:
	donnees = _fusionner(_defaut(), d.duplicate(true))
	donnees.erase("admin")
	donnees["version"] = VERSION
	_charge = true
	sauvegarder()


## Résumé lisible d'une partie quelconque (pour choisir entre deux parties).
static func resume_partie(d: Dictionary) -> String:
	var compte: Dictionary = d.get("compte", {})
	var res: Dictionary = d.get("ressources", {})
	var prog: Dictionary = d.get("progression", {})
	var coll: Dictionary = d.get("collection", {})
	var heros := str(d.get("heros_depart", ""))
	var nom_heros := "—"
	if heros != "" and UnitesData.existe(heros):
		nom_heros = str(UnitesData.get_unite(heros)["nom"])
	return "Niveau de compte : %d\nHéros de départ : %s\nChapitres terminés : %d / 72\nUnités : %d\nOr : %d     Gemmes : %d" % [
		int(compte.get("niveau", 1)), nom_heros, (prog.get("termines", []) as Array).size(),
		(coll.get("heros", []) as Array).size(), int(res.get("or", 0)), int(res.get("gemmes", 0))]


# ------------------------------------------------------------------
# Ressources
# ------------------------------------------------------------------

static func get_or() -> int:
	charger()
	if admin("or_infini"):
		return VALEUR_INFINIE
	return int(donnees["ressources"]["or"])


static func ajouter_or(montant: int) -> void:
	charger()
	donnees["ressources"]["or"] = int(donnees["ressources"]["or"]) + montant
	if montant > 0:
		_stat("or_total_gagne", montant)
		Audio.son("or")
	sauvegarder()


## Retire de l'or si le joueur en a assez. Renvoie false sinon (rien n'est retiré).
static func depenser_or(montant: int) -> bool:
	if get_or() < montant:
		Audio.son("erreur")
		return false
	if admin("or_infini"):
		return true
	donnees["ressources"]["or"] = int(donnees["ressources"]["or"]) - montant
	sauvegarder()
	return true


static func get_gemmes() -> int:
	charger()
	if admin("gemmes_infinies"):
		return VALEUR_INFINIE
	return int(donnees["ressources"]["gemmes"])


static func ajouter_gemmes(montant: int) -> void:
	charger()
	donnees["ressources"]["gemmes"] = int(donnees["ressources"]["gemmes"]) + montant
	sauvegarder()


static func depenser_gemmes(montant: int) -> bool:
	if get_gemmes() < montant:
		Audio.son("erreur")
		return false
	if admin("gemmes_infinies"):
		return true
	donnees["ressources"]["gemmes"] = int(donnees["ressources"]["gemmes"]) - montant
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
	if admin("stamina_infinie"):
		return 999
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
		Audio.son("erreur")
		return false
	if admin("stamina_infinie"):
		return true
	var r: Dictionary = donnees["ressources"]
	if int(r["stamina"]) >= get_stamina_max():
		r["stamina_maj"] = int(Time.get_unix_time_from_system())   # la recharge démarre maintenant
	r["stamina"] = int(r["stamina"]) - montant
	_stat("stamina_depensee", montant)
	sauvegarder()
	return true


## Ajoute de la stamina (élixir, montée de niveau...). Peut dépasser le maximum.
static func ajouter_stamina(montant: int) -> void:
	charger()
	_recharger_stamina()
	donnees["ressources"]["stamina"] = int(donnees["ressources"]["stamina"]) + montant
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
	c["xp"] = int(c["xp"]) + montant * (10 if admin("xp_x10") else 1)
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
		Audio.son("niveau")
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
		_stat("chapitres_termines")
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
	h["xp"] = int(h["xp"]) + xp * (10 if admin("xp_x10") else 1)
	while int(h["niveau"]) < UnitesData.niveau_max(h["id"]) and int(h["xp"]) >= xp_heros_pour_niveau(int(h["niveau"])):
		h["xp"] = int(h["xp"]) - xp_heros_pour_niveau(int(h["niveau"]))
		h["niveau"] = int(h["niveau"]) + 1
		gagnes += 1
	if int(h["niveau"]) >= UnitesData.niveau_max(h["id"]):
		h["xp"] = 0
	if gagnes > 0:
		Audio.son("niveau")
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
		s.append(uid if (uid >= 0 and not get_heros(uid).is_empty() and not uid in s and not est_occupe(uid)) else -1)
	return s


## L'unité est-elle occupée (mission de la Compagnie, ou chasse à la Ménagerie) ?
static func est_occupe(uid: int) -> bool:
	return Compagnie.unite_en_mission(uid) or Menagerie.heros_en_chasse(uid)


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
	if est_occupe(uid):
		return
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
# Menu Admin (options de test)
# ------------------------------------------------------------------
## Les options ne modifient PAS les vraies valeurs de la sauvegarde : tant qu'une option
## est cochée, le jeu fait « comme si ». Décocher remet exactement la situation d'avant.

const VALEUR_INFINIE := 9999999
const ADMIN_OPTIONS := [
	["or_infini", "Or infini", "Or illimité : les achats ne coûtent rien."],
	["gemmes_infinies", "Gemmes infinies", "Gemmes illimitées."],
	["stamina_infinie", "Stamina infinie", "Les combats ne consomment plus de stamina."],
	["eclats_infinis", "Éclats infinis", "Éclats de Pacte Supérieur illimités (invocations et événements)."],
	["objets_infinis", "Objets du Reliquaire infinis", "Braises, Plumes, Fragments, Poussière, coffres, élixirs, tomes, Pierres d'Éveil, ressources des Donjons…"],
	["bestiaire_complet", "Bestiaire entièrement débloqué", "Toutes les unités et tous les familiers sont visibles dans le Bestiaire."],
	["tout_debloque", "Tous les Actes, chapitres et niveaux de Donjon débloqués", "Accès à tous les chapitres et à tous les niveaux des Donjons sans terminer les précédents."],
	["tours_libres", "Tous les étages des Tours accessibles", "Combattre n'importe quel étage, même sans avoir fini le précédent."],
	["boss_monde_libre", "Boss de Monde : tous disponibles", "Les 7 boss jouables tous les jours, essais illimités, sans condition de déblocage."],
	["heros_invincibles", "Héros invincibles", "Tes unités ne subissent aucun dégât en combat."],
	["ennemis_affaiblis", "Ennemis affaiblis", "Les ennemis n'ont que 10 % de leurs PV."],
	["xp_x10", "XP x10", "XP des unités et du compte multipliée par 10."],
	["compagnie_instantanee", "Missions de la Compagnie instantanées", "Les missions se terminent tout de suite (butin normal)."],
	["marche_illimitee", "Marche Maudite illimitée", "Rejouer la Marche du jour autant de fois qu'on veut (score non envoyé au classement)."],
	["echos_garantis", "Amélioration d'Échos toujours réussie", "Chaque amélioration d'Écho réussit (le coût en or reste dû, sauf avec Or infini)."],
]

## Le bouton « Menu Admin » est visible partout (Paramètres).
## Depuis Godot (version de débogage), il s'ouvre directement ; dans la version publiée
## (web), il demande le code Admin. Le code n'est demandé qu'une fois par session.
## Code actuel : admin123. Pour le changer, remplace l'empreinte ci-dessous par
## l'empreinte SHA-256 du nouveau code (ex. site « sha256 online »).
const ADMIN_CODE_SHA256 := "240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9"
static var _admin_deverrouille := false


static func admin_visible() -> bool:
	return true


## Menu Admin utilisable sans code ? (lancé depuis Godot, ou code déjà saisi)
static func admin_deverrouille() -> bool:
	return _admin_deverrouille or OS.is_debug_build()


## Vérifie le code Admin ; s'il est bon, le menu reste ouvert jusqu'à la fermeture du jeu.
static func verifier_code_admin(code: String) -> bool:
	if code.strip_edges().sha256_text() == ADMIN_CODE_SHA256:
		_admin_deverrouille = true
	return _admin_deverrouille


## Options de triche : gardées en mémoire SEULEMENT (jamais dans la sauvegarde ni en ligne),
## donc toutes désactivées à chaque relance du jeu.
static var _admin_session := {}


static func admin(id: String) -> bool:
	return bool(_admin_session.get(id, false))


static func definir_admin(id: String, actif: bool) -> void:
	_admin_session[id] = actif


static func admin_actif() -> bool:
	for o in ADMIN_OPTIONS:
		if admin(o[0]):
			return true
	return false


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
		s.append(uid if (uid >= 0 and not get_heros(uid).is_empty() and not uid in s and not est_occupe(uid)) else -1)
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
	if UnitesData.est_evolue(h["id"]):
		base *= 3      # une unité évoluée vaut bien plus (ressources dépensées)
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
	if est_occupe(uid):
		return "Cette unité est occupée (mission ou chasse)."
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
		donnees["ressources"]["or"] = int(donnees["ressources"]["or"]) + total
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
	donnees["ressources"]["or"] = int(donnees["ressources"]["or"]) + total
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
	if objet_infini(nom):
		return 9999
	return int(donnees["collection"]["objets"].get(nom, 0))


## Objet rendu infini par le menu Admin ?
static func objet_infini(nom: String) -> bool:
	return admin("eclats_infinis") if nom == ECLAT else admin("objets_infinis")


static func ajouter_objet(nom: String, n: int) -> void:
	charger()
	donnees["collection"]["objets"][nom] = int(donnees["collection"]["objets"].get(nom, 0)) + n
	sauvegarder()


static func retirer_objet(nom: String, n: int) -> bool:
	if get_objet(nom) < n:
		return false
	if objet_infini(nom):
		return true
	donnees["collection"]["objets"][nom] = int(donnees["collection"]["objets"].get(nom, 0)) - n
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
	return admin("bestiaire_complet") or id_unite in donnees["bestiaire"]


static func nombre_decouverts() -> int:
	charger()
	if admin("bestiaire_complet"):
		return UnitesData.toutes().size()
	return donnees["bestiaire"].size()


# ------------------------------------------------------------------
# Statistiques
# ------------------------------------------------------------------

static func _stat(nom: String, montant := 1) -> void:
	var s: Dictionary = donnees["statistiques"]
	s[nom] = int(s.get(nom, 0)) + montant
	Quetes.noter(nom, montant)      # quêtes du jour et de la semaine


## Valeur d'une statistique (totaux depuis le début de la partie).
static func get_stat(nom: String) -> int:
	charger()
	return int(donnees["statistiques"].get(nom, 0))


static func ajouter_stat(nom: String, montant := 1) -> void:
	charger()
	_stat(nom, montant)
	sauvegarder()
