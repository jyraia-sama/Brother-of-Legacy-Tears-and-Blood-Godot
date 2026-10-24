extends Node
## (Pas de class_name : voir ecran_chargement.gd, qui le précharge par son chemin.)
## PAQUETS D'ILLUSTRATIONS (depuis la v0.61.0).
##
## Le jeu est découpé en plusieurs fichiers pour rester sous la limite de 100 Mo par fichier de GitHub
## et pour que chaque mise à jour ne fasse télécharger que ce qui a changé :
##   - le contenu de base (scripts, écrans, sons, interface…) : docs/index.pck (web) et docs/maj/jeu.pck
##     (applications installées) ;
##   - les gros dossiers d'images, rangés dans docs/paquets/<nom>.pck, décrits par docs/paquets/liste.json
##     (nom, fichier, taille, empreinte). Les figurines et les portraits sont répartis en plusieurs
##     « seaux » : ajouter une créature ne modifie qu'un seul petit paquet.
##
## Au lancement (écran de chargement, avant le menu), le jeu lit la liste en ligne, télécharge les paquets
## nouveaux ou modifiés dans user://paquets/, vérifie leur empreinte, puis les charge tous.
## Hors connexion : on charge ceux déjà téléchargés. Dans l'éditeur, rien à faire (les images sont là).
## Les paquets sont fabriqués par outils/publier_pc.gd (voir PAQUETS ci-dessous dans ce même outil).

signal progression_changee(fait: int, total: int)

const URL_SITE := "https://jyraia-sama.github.io/Brother-of-Legacy-Tears-and-Blood-Godot/"
const DOSSIER := "user://paquets"
const FICHIER_ETAT := "user://paquets/etat.json"
const FICHIER_TEMP := "user://paquets/telechargement.part"

## Paquets déjà chargés pendant ce lancement (on ne charge qu'une fois par lancement).
static var charges := false
## Au moins un paquet a été chargé : le menu doit être réaffiché pour profiter des images.
static var nouveaux := false

var octets_faits := 0
var octets_total := 0
var erreur := ""

var _etat: Dictionary = {}       # nom -> {fichier, sha256, taille}
var _requete: HTTPRequest = null
var _octets_avant := 0


## Faut-il gérer les paquets ? (pas dans l'éditeur : les images sont déjà dans le projet)
static func actif() -> bool:
	if OS.get_environment("BOL_PAQUETS_TEST") != "":
		return true
	return not OS.has_feature("editor")


## Adresse du dossier des paquets en ligne.
static func url_dossier() -> String:
	var autre := OS.get_environment("BOL_PAQUETS_URL")
	if autre != "":
		return autre.trim_suffix("/") + "/"
	if OS.has_feature("web"):
		# Même site que la page du jeu (marche aussi pour un test local)
		var page = JavaScriptBridge.eval("window.location.href.split('?')[0].split('#')[0]", true)
		if page is String and str(page).begins_with("http"):
			return str(page).get_base_dir() + "/paquets/"
	return URL_SITE + "paquets/"


## Télécharge ce qui manque puis charge tous les paquets. À attendre avec « await ».
## Renvoie true si tout est chargé (ou rien à faire), false s'il manque des paquets (erreur = message).
func preparer() -> bool:
	if charges or not actif():
		charges = true
		return true
	DirAccess.make_dir_recursive_absolute(DOSSIER)
	_etat = _lire_json(FICHIER_ETAT)
	var liste := await _lire_liste_en_ligne()
	var ok := true
	if liste.is_empty():
		# Hors connexion : on charge ce qu'on a (même ancien)
		if _etat.is_empty():
			erreur = UiCommun.t("Impossible de télécharger les illustrations du jeu. Vérifie ta connexion Internet.")
			ok = false
	else:
		var a_telecharger: Array = []
		for p in liste:
			var nom := str(p.get("nom", ""))
			var local: Dictionary = _etat.get(nom, {})
			if str(local.get("sha256", "")) != str(p.get("sha256", "")) or not FileAccess.file_exists(str(local.get("fichier", ""))):
				a_telecharger.append(p)
				octets_total += int(p.get("taille", 0))
		for p in a_telecharger:
			if not await _telecharger(p):
				ok = false
				break
		if ok:
			_ranger(liste)
	_charger_tout()
	charges = ok
	return ok


## Avancement du téléchargement entre 0 et 1 (1 si rien à télécharger).
func avancement() -> float:
	if octets_total <= 0:
		return 1.0
	var en_cours := _requete.get_downloaded_bytes() if _requete else 0
	return clampf(float(octets_faits + en_cours) / octets_total, 0.0, 1.0)


func octets_recus() -> int:
	return octets_faits + (_requete.get_downloaded_bytes() if _requete else 0)


# ---------------------------------------------------------------------

func _lire_liste_en_ligne() -> Array:
	var r := HTTPRequest.new()
	r.timeout = 12.0
	add_child(r)
	if r.request(url_dossier() + "liste.json?t=%d" % int(Time.get_unix_time_from_system())) != OK:
		r.queue_free()
		return []
	var rep: Array = await r.request_completed
	r.queue_free()
	if rep[0] != HTTPRequest.RESULT_SUCCESS or rep[1] != 200:
		return []
	var lu = JSON.parse_string((rep[3] as PackedByteArray).get_string_from_utf8())
	if lu is Dictionary and lu.get("paquets") is Array:
		return lu.paquets
	return []


func _telecharger(p: Dictionary) -> bool:
	var nom := str(p.get("nom", ""))
	var sha := str(p.get("sha256", ""))
	var taille := int(p.get("taille", 0))
	var url := url_dossier() + str(p.get("fichier", nom + ".pck")) + "?v=" + sha.left(12)
	if FileAccess.file_exists(FICHIER_TEMP):
		DirAccess.remove_absolute(FICHIER_TEMP)
	var web := OS.has_feature("web")
	_requete = HTTPRequest.new()
	_requete.use_threads = not web
	_requete.timeout = 0.0
	_requete.download_chunk_size = 1048576 if web else 262144
	if not web:
		_requete.download_file = FICHIER_TEMP     # (navigateur : reçu en mémoire puis écrit, plus fiable)
	add_child(_requete)
	var ok := _requete.request(url) == OK
	if ok:
		var rep: Array = await _requete.request_completed
		ok = rep[0] == HTTPRequest.RESULT_SUCCESS and rep[1] == 200
		if ok and web:
			var fw := FileAccess.open(FICHIER_TEMP, FileAccess.WRITE)
			if fw:
				fw.store_buffer(rep[3])
				fw.close()
		if not ok:
			erreur = UiCommun.t("Le téléchargement des illustrations a échoué (code %s). Vérifie ta connexion et réessaie.") % str(rep[1])
	else:
		erreur = UiCommun.t("Impossible de lancer le téléchargement des illustrations.")
	_requete.queue_free()
	_requete = null
	if ok:
		var f := FileAccess.open(FICHIER_TEMP, FileAccess.READ)
		var recu := f.get_length() if f else -1
		if f:
			f.close()
		if taille > 0 and recu != taille:
			ok = false
			erreur = UiCommun.t("Les illustrations reçues sont incomplètes. Réessaie dans quelques minutes.")
		elif sha != "" and FileAccess.get_sha256(FICHIER_TEMP) != sha:
			ok = false
			erreur = UiCommun.t("Les illustrations reçues ne correspondent pas (le site vient peut-être d'être mis à jour). Réessaie dans quelques minutes.")
	if not ok:
		if FileAccess.file_exists(FICHIER_TEMP):
			DirAccess.remove_absolute(FICHIER_TEMP)
		return false
	# Nom de fichier propre à cette empreinte : le paquet déjà chargé n'est jamais écrasé pendant le jeu
	var final := DOSSIER.path_join("%s_%s.pck" % [nom, sha.left(12)])
	if FileAccess.file_exists(final):
		DirAccess.remove_absolute(final)
	if DirAccess.rename_absolute(FICHIER_TEMP, final) != OK:
		erreur = UiCommun.t("Impossible d'enregistrer les illustrations sur cet appareil (place disque ?).")
		return false
	_etat[nom] = {"fichier": final, "sha256": sha, "taille": taille}
	_ecrire_json(FICHIER_ETAT, _etat)
	octets_faits += taille
	progression_changee.emit(octets_faits, octets_total)
	return true


## Oublie les paquets qui ne sont plus dans la liste et efface les fichiers inutiles.
func _ranger(liste: Array) -> void:
	var noms := {}
	for p in liste:
		noms[str(p.get("nom", ""))] = true
	for nom in _etat.keys():
		if not noms.has(nom):
			_etat.erase(nom)
	_ecrire_json(FICHIER_ETAT, _etat)
	var garder := {}
	for nom in _etat:
		garder[str(_etat[nom].get("fichier", "")).get_file()] = true
	var d := DirAccess.open(DOSSIER)
	if d:
		for f in d.get_files():
			if f.ends_with(".pck") and not garder.has(f):
				d.remove(f)


func _charger_tout() -> void:
	for nom in _etat:
		var fichier := str(_etat[nom].get("fichier", ""))
		if fichier != "" and FileAccess.file_exists(fichier):
			if ProjectSettings.load_resource_pack(fichier, true):
				nouveaux = true
			else:
				push_error("Paquet illisible : " + fichier)


static func _lire_json(chemin: String) -> Dictionary:
	if not FileAccess.file_exists(chemin):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(chemin))
	return d if d is Dictionary else {}


static func _ecrire_json(chemin: String, d: Dictionary) -> void:
	var f := FileAccess.open(chemin, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "\t"))
		f.close()
