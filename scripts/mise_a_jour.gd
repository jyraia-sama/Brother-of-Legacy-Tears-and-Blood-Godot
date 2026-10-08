extends Node
## MISE À JOUR AUTOMATIQUE (applications installées : Windows, Mac et Android).
## Chargé automatiquement au démarrage, EN PREMIER (Projet > Paramètres > Globals : « MiseAJour »).
##
## Comment ça marche :
##  - L'application installée (.exe / .app) contient une version de base du jeu.
##  - Chaque nouvelle version est publiée sur le site du jeu (docs/maj/) sous forme d'un fichier
##    de contenu « jeu.pck » + une fiche « version.json » (numéro, nouveautés, taille, empreinte).
##  - Au lancement, le jeu lit la fiche. S'il y a plus récent, une fenêtre propose la mise à jour :
##    le fichier est téléchargé dans le dossier du joueur (user://maj/), vérifié, puis le jeu redémarre.
##  - Au démarrage suivant, ce script charge le contenu téléchargé AVANT tout le reste du jeu :
##    tous les écrans, scripts et images sont alors ceux de la nouvelle version.
##  - Si le moteur Godot ou les réglages du projet ont changé, une simple mise à jour ne suffit pas :
##    la fenêtre propose alors de télécharger l'installation complète.
##  - Sécurité : si une version téléchargée empêche le jeu de démarrer 3 fois de suite,
##    elle est ignorée et le jeu repart sur la version de base.
##
## IMPORTANT : ce script ne doit utiliser AUCUNE classe du jeu (Version, Sauvegarde, UiCommun…).
## Il est lu avant le chargement de la mise à jour ; s'il chargeait un script du jeu à ce moment-là,
## c'est l'ancienne version de ce script qui resterait en mémoire.
## Ce fichier lui-même ne se met pas à jour par ce système (il faut une installation complète).
## Si une modification de ce fichier doit atteindre TOUS les joueurs, augmente VERSION_SYSTEME :
## l'outil de publication refera alors les installations complètes.

const VERSION_SYSTEME := 1

signal verification_terminee(resultat: String)   # "a_jour", "maj", "installation", "erreur"
signal telechargement_termine(ok: bool, message: String)

## Fiche de la dernière version, publiée avec le jeu web (GitHub Pages).
const URL_FICHE := "https://jyraia-sama.github.io/Brother-of-Legacy-Tears-and-Blood-Godot/maj/version.json"
## Installations complètes (GitHub Releases : toujours la dernière version publiée).
const URL_INSTALL := {
	"windows": "https://github.com/jyraia-sama/Brother-of-Legacy-Tears-and-Blood-Godot/releases/latest/download/BrothersOfLegacy-Windows.zip",
	"macos": "https://github.com/jyraia-sama/Brother-of-Legacy-Tears-and-Blood-Godot/releases/latest/download/BrothersOfLegacy-Mac.zip",
	"android": "https://github.com/jyraia-sama/Brother-of-Legacy-Tears-and-Blood-Godot/releases/latest/download/BrothersOfLegacy-Android.apk",
}
const PAGE_TELECHARGEMENT := "https://github.com/jyraia-sama/Brother-of-Legacy-Tears-and-Blood-Godot/releases/latest"

const DOSSIER := "user://maj"
const FICHIER_ETAT := "user://maj/installee.json"
const FICHIER_TEMP := "user://maj/telechargement.part"
const SCRIPT_FENETRE := "res://scripts/fenetre_mise_a_jour.gd"
const ESSAIS_MAX := 3            # démarrages ratés avant d'abandonner une version téléchargée
const DELAI_DEMARRAGE_OK := 20.0 # secondes de jeu après lesquelles le démarrage est réussi

## Version de l'application installée (sans mise à jour).
var version_base := ""
## Version réellement jouée (celle de la mise à jour chargée, sinon la version de base).
var version_actuelle := ""
var pack_charge := ""
## Dernière fiche lue en ligne ({} tant qu'elle n'est pas lue).
var fiche: Dictionary = {}
var en_cours := false
var _etat: Dictionary = {}
var _requete_dl: HTTPRequest = null
var _taille_attendue := 0
var _fenetre_ouverte := false


func _init() -> void:
	version_base = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	version_actuelle = version_base
	if not actif():
		return
	_etat = _lire_json(FICHIER_ETAT)
	_charger_mise_a_jour()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not actif():
		return
	# Le démarrage est considéré comme réussi au bout de quelques secondes de jeu.
	get_tree().create_timer(DELAI_DEMARRAGE_OK, true).timeout.connect(_demarrage_reussi)
	_nettoyer_anciens_fichiers()
	# Petite pause : on laisse le menu s'afficher avant de chercher une mise à jour.
	get_tree().create_timer(2.0, true).timeout.connect(func(): verifier(false))


## Le système ne fonctionne que dans l'application installée sur ordinateur
## et dans l'application Android (pas dans le navigateur, pas quand on lance le jeu depuis l'éditeur).
func actif() -> bool:
	return (OS.has_feature("pc") or OS.has_feature("android")) and not OS.has_feature("web") and not OS.has_feature("editor")


func plateforme() -> String:
	if OS.has_feature("android"):
		return "android"
	return "macos" if OS.has_feature("macos") else "windows"


## Android ne permet pas à une application de se relancer elle-même : on la ferme
## et le joueur la rouvre.
func peut_redemarrer() -> bool:
	return plateforme() != "android"


# =====================================================================
# Démarrage : chargement de la mise à jour déjà téléchargée
# =====================================================================

func _charger_mise_a_jour() -> void:
	var v := str(_etat.get("version", ""))
	var fichier := str(_etat.get("fichier", ""))
	if v == "" or fichier == "" or not FileAccess.file_exists(fichier):
		return
	if comparer(v, version_base) <= 0:
		return   # l'application installée est déjà aussi récente (nouvelle installation complète)
	if str(_etat.get("godot", "")) != version_moteur():
		return   # téléchargée pour un autre moteur : inutilisable
	if comparer(version_base, str(_etat.get("installation_minimum", "0.0.0"))) < 0:
		return
	var essais := int(_etat.get("essais", 0))
	if essais >= ESSAIS_MAX:
		push_warning("Mise à jour %s ignorée : le jeu n'a pas pu démarrer avec." % v)
		return
	_etat["essais"] = essais + 1
	_ecrire_json(FICHIER_ETAT, _etat)
	if ProjectSettings.load_resource_pack(fichier, true):
		pack_charge = fichier
		version_actuelle = v
		print("Mise à jour chargée : v%s (application v%s)" % [v, version_base])
	else:
		push_error("Impossible de charger la mise à jour : " + fichier)


func _demarrage_reussi() -> void:
	if pack_charge != "" and int(_etat.get("essais", 0)) != 0:
		_etat["essais"] = 0
		_ecrire_json(FICHIER_ETAT, _etat)


## Efface les anciens fichiers téléchargés (sauf celui utilisé et celui prêt pour le prochain démarrage).
func _nettoyer_anciens_fichiers() -> void:
	var d := DirAccess.open(DOSSIER)
	if d == null:
		return
	var garder := [pack_charge.get_file(), str(_etat.get("fichier", "")).get_file()]
	for f in d.get_files():
		if f.ends_with(".pck") and not f in garder:
			d.remove(f)
	if d.file_exists(FICHIER_TEMP.get_file()) and not en_cours:
		d.remove(FICHIER_TEMP.get_file())


# =====================================================================
# Vérification en ligne
# =====================================================================

## Cherche une nouvelle version. manuel = demandé depuis les Paramètres
## (affiche aussi « le jeu est à jour » ou l'erreur).
func verifier(manuel := false) -> void:
	if not actif():
		return
	var r := HTTPRequest.new()
	r.timeout = 15.0
	add_child(r)
	# Le paramètre « t » évite de recevoir une ancienne fiche gardée en cache.
	var err := r.request(_url_fiche() + "?t=%d" % int(Time.get_unix_time_from_system()))
	if err != OK:
		r.queue_free()
		_fin_verification("erreur", manuel)
		return
	var rep: Array = await r.request_completed
	r.queue_free()
	if rep[0] != HTTPRequest.RESULT_SUCCESS or rep[1] != 200:
		_fin_verification("erreur", manuel)
		return
	var lu = JSON.parse_string((rep[3] as PackedByteArray).get_string_from_utf8())
	if not (lu is Dictionary) or str(lu.get("version", "")) == "":
		_fin_verification("erreur", manuel)
		return
	fiche = lu
	_fin_verification(etat_disponible(), manuel)


## "a_jour", "maj" (mise à jour rapide possible) ou "installation" (installation complète nécessaire).
func etat_disponible() -> String:
	if fiche.is_empty():
		return "a_jour"
	var v := str(fiche.get("version", ""))
	if comparer(v, version_actuelle) <= 0:
		return "a_jour"
	# Cette version a déjà été téléchargée mais le jeu n'a pas pu démarrer avec : on ne la reprend pas.
	if str(_etat.get("version", "")) == v and int(_etat.get("essais", 0)) >= ESSAIS_MAX:
		return "installation"
	# Déjà téléchargée, en attente du redémarrage
	if str(_etat.get("version", "")) == v and pack_charge != str(_etat.get("fichier", "")) \
			and FileAccess.file_exists(str(_etat.get("fichier", ""))) and int(_etat.get("essais", 0)) == 0:
		return "pret"
	if str(fiche.get("godot", "")) != version_moteur():
		return "installation"
	if comparer(version_base, str(fiche.get("installation_minimum", "0.0.0"))) < 0:
		return "installation"
	if not (fiche.get("pck") is Dictionary) or str(fiche.pck.get("url", "")) == "":
		return "installation"
	return "maj"


## Mise à jour obligatoire (la version jouée est trop ancienne pour l'Arène, etc.).
func obligatoire() -> bool:
	var mini := str(fiche.get("version_minimum", ""))
	return mini != "" and comparer(version_actuelle, mini) < 0


func _fin_verification(resultat: String, manuel: bool) -> void:
	verification_terminee.emit(resultat)
	# Test automatique (variable d'environnement BOL_MAJ_TEST=auto) : met à jour et redémarre sans fenêtre.
	if OS.get_environment("BOL_MAJ_TEST") == "auto":
		print("Test mise à jour : ", resultat, " (jouée v%s, en ligne v%s)" % [version_actuelle, fiche.get("version", "?")])
		if resultat == "maj":
			telechargement_termine.connect(_fin_test, CONNECT_ONE_SHOT)
			telecharger()
		return
	if resultat in ["maj", "installation", "pret"] or manuel:
		ouvrir_fenetre(resultat)


func _fin_test(ok: bool, message: String) -> void:
	print("Test mise à jour : téléchargement ", ok, " ", message)
	if ok:
		redemarrer()


func ouvrir_fenetre(resultat: String) -> void:
	if _fenetre_ouverte:
		return
	var script = load(SCRIPT_FENETRE)
	if script == null or not (script as Script).can_instantiate():
		push_error("Fenêtre de mise à jour illisible : " + SCRIPT_FENETRE)
		return
	_fenetre_ouverte = true
	var f: Node = script.new()
	f.tree_exited.connect(func(): _fenetre_ouverte = false)
	f.set("resultat", resultat)
	get_tree().root.add_child(f)


# =====================================================================
# Téléchargement
# =====================================================================

func telecharger() -> void:
	if en_cours or etat_disponible() != "maj":
		return
	en_cours = true
	DirAccess.make_dir_recursive_absolute(DOSSIER)
	var infos: Dictionary = fiche.pck
	_taille_attendue = int(infos.get("taille", 0))
	var url := str(infos.url)
	if not url.begins_with("http"):
		url = _url_fiche().get_base_dir().path_join(url)
	url += ("&" if "?" in url else "?") + "v=" + str(fiche.version)
	_requete_dl = HTTPRequest.new()
	_requete_dl.use_threads = true
	_requete_dl.timeout = 0.0
	_requete_dl.download_chunk_size = 262144
	_requete_dl.download_file = FICHIER_TEMP
	add_child(_requete_dl)
	if _requete_dl.request(url) != OK:
		_fin_telechargement(false, "Impossible de lancer le téléchargement.")
		return
	var rep: Array = await _requete_dl.request_completed
	if rep[0] != HTTPRequest.RESULT_SUCCESS or rep[1] != 200:
		_fin_telechargement(false, "Le téléchargement a échoué (code %s). Vérifie ta connexion et réessaie." % str(rep[1]))
		return
	# Vérifications : taille et empreinte identiques à celles de la fiche
	var taille := 0
	var f := FileAccess.open(FICHIER_TEMP, FileAccess.READ)
	if f:
		taille = f.get_length()
		f.close()
	if _taille_attendue > 0 and taille != _taille_attendue:
		_fin_telechargement(false, "Le fichier reçu est incomplet. Réessaie dans quelques minutes.")
		return
	var empreinte := str(infos.get("sha256", ""))
	if empreinte != "" and FileAccess.get_sha256(FICHIER_TEMP) != empreinte:
		_fin_telechargement(false, "Le fichier reçu ne correspond pas à la version annoncée (le site vient peut-être d'être mis à jour). Réessaie dans quelques minutes.")
		return
	var final := DOSSIER.path_join("jeu_%s.pck" % str(fiche.version))
	if FileAccess.file_exists(final):
		DirAccess.remove_absolute(final)
	if DirAccess.rename_absolute(FICHIER_TEMP, final) != OK:
		_fin_telechargement(false, "Impossible d'enregistrer la mise à jour sur cet ordinateur.")
		return
	_etat = {
		"version": str(fiche.version),
		"fichier": final,
		"godot": version_moteur(),
		"installation_minimum": str(fiche.get("installation_minimum", "0.0.0")),
		"essais": 0,
		"installee_le": int(Time.get_unix_time_from_system()),
	}
	_ecrire_json(FICHIER_ETAT, _etat)
	_fin_telechargement(true, "")


func _fin_telechargement(ok: bool, message: String) -> void:
	en_cours = false
	if _requete_dl:
		_requete_dl.queue_free()
		_requete_dl = null
	if not ok and FileAccess.file_exists(FICHIER_TEMP):
		DirAccess.remove_absolute(FICHIER_TEMP)
	telechargement_termine.emit(ok, message)


## Avancement du téléchargement entre 0 et 1 (-1 si la taille est inconnue).
func progression() -> float:
	if _requete_dl == null:
		return 0.0
	var total := _taille_attendue if _taille_attendue > 0 else _requete_dl.get_body_size()
	if total <= 0:
		return -1.0
	return clampf(float(_requete_dl.get_downloaded_bytes()) / total, 0.0, 1.0)


func octets_recus() -> int:
	return _requete_dl.get_downloaded_bytes() if _requete_dl else 0


## Ouvre le téléchargement de l'installation complète dans le navigateur.
func ouvrir_installation() -> void:
	var url := str((fiche.get("installations", {}) as Dictionary).get(plateforme(), URL_INSTALL.get(plateforme(), PAGE_TELECHARGEMENT)))
	OS.shell_open(url)


## Enregistre la partie puis relance le jeu (la nouvelle version est chargée au redémarrage).
## Sur Android, le jeu se ferme simplement : le joueur le rouvre.
func redemarrer() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	var s = load("res://scripts/sauvegarde.gd")
	if s:
		s.ecrire_maintenant(true)
	await get_tree().create_timer(1.5, true).timeout
	if peut_redemarrer():
		OS.set_restart_on_exit(true, OS.get_cmdline_args())
	get_tree().quit()


# =====================================================================
# Outils
# =====================================================================

## Adresse de la fiche (la variable d'environnement BOL_MAJ_FICHE la remplace, pour les tests).
func _url_fiche() -> String:
	var autre := OS.get_environment("BOL_MAJ_FICHE")
	return autre if autre != "" else URL_FICHE

## Version du moteur au format « 4.7 » (une mise à jour ne marche qu'avec le même moteur).
static func version_moteur() -> String:
	var e := Engine.get_version_info()
	return "%d.%d" % [e.major, e.minor]


## Compare deux numéros « 0.34.2 » : -1 si a < b, 0 si égaux, 1 si a > b.
static func comparer(a: String, b: String) -> int:
	var pa := a.split(".")
	var pb := b.split(".")
	for i in maxi(pa.size(), pb.size()):
		var x := pa[i].to_int() if i < pa.size() else 0
		var y := pb[i].to_int() if i < pb.size() else 0
		if x != y:
			return -1 if x < y else 1
	return 0


static func _lire_json(chemin: String) -> Dictionary:
	if not FileAccess.file_exists(chemin):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(chemin))
	return d if d is Dictionary else {}


static func _ecrire_json(chemin: String, d: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(chemin.get_base_dir())
	var f := FileAccess.open(chemin, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "\t"))
		f.close()
