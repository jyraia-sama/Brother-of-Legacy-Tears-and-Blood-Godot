extends Node
## JEU EN LIGNE (Supabase) : compte, sauvegarde en ligne, appels au serveur.
## Chargé automatiquement au lancement (Projet > Paramètres > Globals : « EnLigne »).
##
## Utilisable depuis n'importe quel script :
##   EnLigne.est_connecte()                       -> true si un compte est ouvert
##   EnLigne.pseudo()                             -> pseudo du joueur connecté
##   var r = await EnLigne.connecter("Neo", "motdepasse")      -> {ok, erreur}
##   var r = await EnLigne.appeler("mes_amis", {})             -> {ok, data, erreur}
##
## SAUVEGARDE EN LIGNE : rien à faire. Toutes les 15 secondes, si la partie a changé,
## elle est envoyée sur le compte. À la connexion, si la partie du compte et celle de
## l'appareil sont différentes, le joueur choisit laquelle garder.

signal etat_change          ## connexion, déconnexion, session perdue
signal partie_remplacee     ## la partie de l'appareil vient d'être remplacée par celle du compte

const FICHIER_COMPTE := "user://compte.json"
const INTERVALLE_ENVOI := 15.0      # secondes
const INTERVALLE_PRESENCE := 120.0  # secondes
const EN_LIGNE_SI_VU_DEPUIS := 300  # un joueur est « en ligne » s'il a été vu il y a moins de 5 min
const PSEUDO_REGEX := "^[A-Za-z0-9_-]{3,16}$"

## Adresse et clé du serveur (lues dans config_en_ligne.gd ; modifiables pour les tests).
var url_serveur: String = ConfigEnLigne.URL
var cle_serveur: String = ConfigEnLigne.CLE
## Session ouverte : access_token, refresh_token, expire_le, id, pseudo
var session: Dictionary = {}
## Le joueur arrive par le lien « mot de passe oublié » : le menu lui demande le nouveau.
var lien_mot_de_passe := false
## Le joueur a choisi « Jouer hors ligne » : on ne lui redemande pas avant le prochain lancement.
var hors_ligne_choisi := false
## Dernière synchronisation : compte, maj (heure serveur), signature de la partie envoyée
var _sync: Dictionary = {"compte": "", "maj": "", "signature": ""}
var derniere_synchro := 0          # heure (unix) du dernier envoi réussi
var reseau_ok := true              # false quand le serveur ne répond pas

var _connexion_en_cours := false
var _refresh_en_cours := false
var _envoi_en_cours := false
signal _refresh_fini(ok: bool)


# ------------------------------------------------------------------
# État
# ------------------------------------------------------------------

func configure() -> bool:
	return url_serveur.strip_edges() != "" and cle_serveur.strip_edges() != ""


func est_connecte() -> bool:
	return session.has("refresh_token")


func pseudo() -> String:
	return str(session.get("pseudo", ""))


func id_joueur() -> String:
	return str(session.get("id", ""))


func connexion_en_cours() -> bool:
	return _connexion_en_cours


## Faut-il afficher la fenêtre de connexion au lancement ?
func doit_proposer_connexion() -> bool:
	return configure() and not est_connecte() and not hors_ligne_choisi and not _connexion_en_cours


# ------------------------------------------------------------------
# Démarrage
# ------------------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_lire_fichier_compte()

	var envoi := Timer.new()
	envoi.wait_time = INTERVALLE_ENVOI
	envoi.autostart = true
	envoi.timeout.connect(_envoyer_si_change)
	add_child(envoi)

	var presence := Timer.new()
	presence.wait_time = INTERVALLE_PRESENCE
	presence.autostart = true
	presence.timeout.connect(_signaler_presence)
	add_child(presence)

	var lien := _lire_lien_email() if configure() else ""
	if lien == "recovery":
		lien_mot_de_passe = true
	if configure() and est_connecte():
		_reprendre_session()


## Session mémorisée : on se reconnecte tout seul au lancement.
func _reprendre_session() -> void:
	_connexion_en_cours = true
	var ok: bool = await _rafraichir()
	_connexion_en_cours = false
	if ok:
		await _synchroniser_a_la_connexion()
		_signaler_presence()
	elif not est_connecte():
		push_warning("EnLigne : session expirée, il faut se reconnecter.")
	etat_change.emit()


# ------------------------------------------------------------------
# Compte : inscription, connexion, déconnexion
# ------------------------------------------------------------------

func email_valide(e: String) -> bool:
	var re := RegEx.new()
	re.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]{2,}$")
	return re.search(e.strip_edges()) != null


func pseudo_valide(p: String) -> bool:
	var re := RegEx.new()
	re.compile(PSEUDO_REGEX)
	return re.search(p.strip_edges()) != null


## Crée un compte (pseudo + e-mail + mot de passe).
## Renvoie {ok, erreur, confirmation} : confirmation = true si Supabase a envoyé
## un e-mail à valider avant de pouvoir se connecter.
func inscrire(p: String, email: String, mot_de_passe: String) -> Dictionary:
	p = p.strip_edges()
	email = email.strip_edges().to_lower()
	if not configure():
		return _echec("Le jeu en ligne n'est pas configuré.")
	if not pseudo_valide(p):
		return _echec("Pseudo : 3 à 16 caractères, lettres sans accent, chiffres, _ ou -.")
	if not email_valide(email):
		return _echec("Adresse e-mail invalide.")
	if mot_de_passe.length() < 6:
		return _echec("Le mot de passe doit faire au moins 6 caractères.")
	var dispo := await _http(HTTPClient.METHOD_POST, "/rest/v1/rpc/pseudo_disponible", {"p_pseudo": p}, false)
	if dispo.ok and dispo.data == false:
		return _echec("Ce pseudo est déjà pris.")
	var r := await _http(HTTPClient.METHOD_POST, "/auth/v1/signup" + _redirection(),
		{"email": email, "password": mot_de_passe, "data": {"pseudo": p}}, false)
	if not r.ok:
		return _echec(_erreur_auth(r))
	if not (r.data is Dictionary and r.data.has("access_token")):
		# « Confirm email » activé : le joueur doit cliquer sur le lien reçu par e-mail.
		return {"ok": true, "erreur": "", "confirmation": true}
	await _ouvrir_session(r.data)
	return {"ok": true, "erreur": "", "confirmation": false}


## Ouvre un compte existant avec son e-mail. Renvoie {ok, erreur}.
func connecter(email: String, mot_de_passe: String) -> Dictionary:
	email = email.strip_edges().to_lower()
	if not configure():
		return _echec("Le jeu en ligne n'est pas configuré.")
	if email == "" or mot_de_passe == "":
		return _echec("Entre ton adresse e-mail et ton mot de passe.")
	if not email_valide(email):
		return _echec("Connecte-toi avec ton adresse e-mail (pas ton pseudo).")
	var r := await _http(HTTPClient.METHOD_POST, "/auth/v1/token?grant_type=password",
		{"email": email, "password": mot_de_passe}, false)
	if not r.ok:
		return _echec(_erreur_auth(r))
	await _ouvrir_session(r.data)
	return {"ok": true, "erreur": ""}


## Envoie l'e-mail « mot de passe oublié ». Le lien ramène sur le jeu web,
## qui demande alors le nouveau mot de passe. Renvoie {ok, erreur}.
func mot_de_passe_oublie(email: String) -> Dictionary:
	email = email.strip_edges().to_lower()
	if not email_valide(email):
		return _echec("Entre d'abord ton adresse e-mail.")
	var r := await _http(HTTPClient.METHOD_POST, "/auth/v1/recover" + _redirection(), {"email": email}, false)
	return {"ok": r.ok, "erreur": "" if r.ok else _erreur_auth(r)}


## Change le mot de passe du compte connecté. Renvoie {ok, erreur}.
func changer_mot_de_passe(mot_de_passe: String) -> Dictionary:
	if mot_de_passe.length() < 6:
		return _echec("Le mot de passe doit faire au moins 6 caractères.")
	var r := await api(HTTPClient.METHOD_PUT, "/auth/v1/user", {"password": mot_de_passe})
	return {"ok": r.ok, "erreur": "" if r.ok else _erreur_auth(r)}


## Adresse du jeu web où ramènent les liens des e-mails (confirmation, mot de passe).
func _redirection() -> String:
	var adresse := ConfigEnLigne.ADRESSE_JEU_WEB
	if OS.has_feature("web"):
		var ici = JavaScriptBridge.eval("window.location.origin + window.location.pathname", true)
		if ici is String and ici != "":
			adresse = ici
	return "" if adresse == "" else "?redirect_to=" + adresse.uri_encode()


## Version web : le joueur arrive depuis un lien reçu par e-mail
## (…/#access_token=…&refresh_token=…&type=signup ou type=recovery).
## Renvoie le type de lien ("signup", "recovery"...) ou "" s'il n'y en a pas.
func _lire_lien_email() -> String:
	if not OS.has_feature("web"):
		return ""
	var hash = JavaScriptBridge.eval("window.location.hash", true)
	if not (hash is String) or not hash.contains("access_token="):
		return ""
	JavaScriptBridge.eval("history.replaceState(null, '', window.location.pathname)", true)
	var p := {}
	for morceau in hash.trim_prefix("#").split("&"):
		var kv: PackedStringArray = morceau.split("=", true, 1)
		if kv.size() == 2:
			p[kv[0]] = kv[1].uri_decode()
	if not p.has("refresh_token"):
		return ""
	session = {"refresh_token": p["refresh_token"], "access_token": p.get("access_token", ""), "expire_le": 0}
	return str(p.get("type", "signup"))


## Ferme le compte sur cet appareil (la partie reste sur l'appareil ET sur le compte).
func deconnecter() -> void:
	if est_connecte():
		await envoyer_sauvegarde()
		_http(HTTPClient.METHOD_POST, "/auth/v1/logout", {}, true)   # sans attendre la réponse
	session = {}
	hors_ligne_choisi = true   # déconnexion volontaire : on ne repropose pas la connexion
	# Ce qui se passera sur l'appareil après la déconnexion n'appartient plus au compte :
	# à la prochaine connexion, si les deux parties diffèrent, le joueur choisira.
	_sync = {"compte": "", "maj": "", "signature": ""}
	_ecrire_fichier_compte()
	etat_change.emit()


func _ouvrir_session(d: Dictionary) -> void:
	hors_ligne_choisi = false
	_lire_session(d)
	_ecrire_fichier_compte()
	reseau_ok = true
	_connexion_en_cours = true
	await _synchroniser_a_la_connexion()
	_connexion_en_cours = false
	_signaler_presence()
	etat_change.emit()


func _lire_session(d: Dictionary) -> void:
	var user: Dictionary = d.get("user", {}) if d.get("user") is Dictionary else {}
	var meta: Dictionary = user.get("user_metadata", {}) if user.get("user_metadata") is Dictionary else {}
	session = {
		"access_token": str(d.get("access_token", "")),
		"refresh_token": str(d.get("refresh_token", "")),
		"expire_le": int(Time.get_unix_time_from_system()) + int(d.get("expires_in", 3600)),
		"id": str(user.get("id", session.get("id", ""))),
		"pseudo": str(meta.get("pseudo", session.get("pseudo", ""))),
	}


## Renouvelle le jeton d'accès (il expire au bout d'une heure).
func _rafraichir() -> bool:
	if _refresh_en_cours:
		return await _refresh_fini
	_refresh_en_cours = true
	var r := await _http(HTTPClient.METHOD_POST, "/auth/v1/token?grant_type=refresh_token",
		{"refresh_token": str(session.get("refresh_token", ""))}, false)
	var ok := false
	if r.ok and r.data is Dictionary and r.data.has("access_token"):
		_lire_session(r.data)
		_ecrire_fichier_compte()
		reseau_ok = true
		ok = true
	elif r.code >= 400 and r.code < 500:
		# Jeton refusé (compte supprimé, session révoquée...) : il faut se reconnecter.
		session = {}
		_ecrire_fichier_compte()
		etat_change.emit()
	else:
		reseau_ok = false
	_refresh_en_cours = false
	_refresh_fini.emit(ok)
	return ok


func _jeton_valide() -> bool:
	if not est_connecte():
		return false
	if int(Time.get_unix_time_from_system()) < int(session.get("expire_le", 0)) - 60:
		return true
	return await _rafraichir()


# ------------------------------------------------------------------
# Appels au serveur
# ------------------------------------------------------------------

## Appelle une fonction du serveur (voir supabase/*.sql). Renvoie {ok, data, erreur}.
func appeler(fonction: String, params: Dictionary = {}) -> Dictionary:
	return await api(HTTPClient.METHOD_POST, "/rest/v1/rpc/" + fonction, params)


## Requête authentifiée (le jeton est renouvelé si besoin). Renvoie {ok, code, data, erreur}.
func api(methode: int, chemin: String, corps = null, entetes: PackedStringArray = PackedStringArray()) -> Dictionary:
	if not configure():
		return {"ok": false, "code": 0, "data": null, "erreur": "Le jeu en ligne n'est pas configuré."}
	if not await _jeton_valide():
		return {"ok": false, "code": 401, "data": null,
			"erreur": "Connexion au serveur impossible." if est_connecte() else "Tu n'es pas connecté."}
	var r := await _http(methode, chemin, corps, true, entetes)
	if r.code == 401 and await _rafraichir():
		r = await _http(methode, chemin, corps, true, entetes)
	return r


## Adresse de base du serveur, même si on a collé une URL avec un chemin
## (ex. « https://xxx.supabase.co/rest/v1/ » -> « https://xxx.supabase.co »).
func adresse_serveur() -> String:
	var u := url_serveur.strip_edges()
	var debut := u.find("://")
	if debut == -1:
		return u.trim_suffix("/")
	var fin := u.find("/", debut + 3)
	return u if fin == -1 else u.left(fin)


func _http(methode: int, chemin: String, corps = null, avec_jeton := true, entetes_sup: PackedStringArray = PackedStringArray()) -> Dictionary:
	var h := HTTPRequest.new()
	h.timeout = 20.0
	# Version web : le navigateur décompresse déjà les réponses du serveur. Si Godot le refait,
	# la requête échoue (RESULT_BODY_DECOMPRESS_FAILED) dès que la réponse est compressée,
	# ce qui donnait « Connexion au serveur impossible » dans l'Arène, le Social et le Compte.
	h.accept_gzip = not OS.has_feature("web")
	add_child(h)
	var entetes := PackedStringArray(["apikey: " + cle_serveur, "Content-Type: application/json"])
	if avec_jeton and session.has("access_token"):
		entetes.append("Authorization: Bearer " + str(session["access_token"]))
	entetes.append_array(entetes_sup)
	var texte := "" if corps == null else JSON.stringify(corps)
	var url := adresse_serveur() + chemin
	if h.request(url, entetes, methode, texte) != OK:
		h.queue_free()
		reseau_ok = false
		return {"ok": false, "code": 0, "data": null, "erreur": "Connexion au serveur impossible."}
	var res: Array = await h.request_completed
	h.queue_free()
	var code: int = res[1]
	var brut: String = (res[3] as PackedByteArray).get_string_from_utf8()
	var data = JSON.parse_string(brut) if brut.strip_edges() != "" else null
	if res[0] != HTTPRequest.RESULT_SUCCESS:
		reseau_ok = false
		push_warning("EnLigne %s : échec de la requête (résultat %d, code %d)" % [chemin, res[0], code])
		return {"ok": false, "code": 0, "data": null,
			"erreur": "Connexion au serveur impossible (erreur %d). Vérifie ta connexion internet." % res[0]}
	reseau_ok = true
	var ok := code >= 200 and code < 300
	var erreur := ""
	if not ok:
		erreur = "Erreur du serveur (%d)." % code
		if data is Dictionary:
			var msg := str(data.get("msg", data.get("message", data.get("error_description", ""))))
			if msg != "":
				erreur += " " + msg
		push_warning("EnLigne %s -> %d : %s" % [chemin, code, brut.left(300)])
	return {"ok": ok, "code": code, "data": data, "erreur": erreur}


func _erreur_auth(r: Dictionary) -> String:
	if r.code == 0:
		return r.erreur
	var d: Dictionary = r.data if r.data is Dictionary else {}
	var code := str(d.get("error_code", d.get("code", ""))).to_lower()
	var msg := str(d.get("msg", d.get("message", d.get("error_description", "")))).to_lower()
	if code == "invalid_credentials" or msg.contains("invalid login"):
		return "E-mail ou mot de passe incorrect."
	if code == "email_not_confirmed" or msg.contains("not confirmed"):
		return "Adresse e-mail pas encore confirmée : clique sur le lien reçu par e-mail (regarde aussi les spams)."
	if code in ["user_already_exists", "email_exists"] or msg.contains("already registered"):
		return "Un compte existe déjà avec cette adresse e-mail."
	if msg.contains("database error saving new user"):
		return "Ce pseudo est déjà pris."
	if code == "weak_password" or msg.contains("password should"):
		return "Mot de passe trop faible (au moins 6 caractères)."
	if code == "email_address_invalid" or msg.contains("email address") and msg.contains("invalid"):
		return "Adresse e-mail refusée par le serveur. Vérifie-la."
	if code == "over_email_send_rate_limit":
		return "Le serveur a envoyé trop d'e-mails pour l'instant. Réessaie dans une heure."
	if code == "over_request_rate_limit" or r.code == 429:
		return "Trop de tentatives. Réessaie dans quelques minutes."
	if code == "signup_disabled":
		return "Les inscriptions sont désactivées sur le serveur."
	return r.erreur


func _echec(texte: String) -> Dictionary:
	return {"ok": false, "erreur": texte}


# ------------------------------------------------------------------
# Sauvegarde en ligne
# ------------------------------------------------------------------

## Empreinte de la partie, sans ce qui bouge tout seul (stamina qui se recharge, dates...).
## Deux parties avec la même empreinte = même progression.
func signature_partie(d: Dictionary) -> String:
	var copie: Dictionary = d.duplicate(true)
	for cle in ["sauvegarde_le", "version_jeu", "version_vue", "admin"]:
		copie.erase(cle)
	if copie.get("ressources") is Dictionary:
		copie["ressources"].erase("stamina")
		copie["ressources"].erase("stamina_maj")
	return JSON.stringify(_normaliser(copie), "", true).md5_text()


## 5.0 et 5 doivent donner la même empreinte (un fichier relu contient des 5.0).
func _normaliser(v):
	if v is Dictionary:
		var d := {}
		for k in v:
			d[str(k)] = _normaliser(v[k])
		return d
	if v is Array:
		var a := []
		for x in v:
			a.append(_normaliser(x))
		return a
	if v is float and is_finite(v) and v == floorf(v) and absf(v) < 1e15:
		return int(v)
	return v


## Une partie « vierge » (nouvel appareil, héros de départ tout juste choisi) peut être
## remplacée sans rien demander.
func partie_vierge(d: Dictionary) -> bool:
	if str(d.get("heros_depart", "")) == "":
		return true
	var prog: Dictionary = d.get("progression", {})
	var compte: Dictionary = d.get("compte", {})
	var coll: Dictionary = d.get("collection", {})
	return (prog.get("termines", []) as Array).is_empty() and int(compte.get("niveau", 1)) <= 1 \
		and int(compte.get("xp", 0)) == 0 and (coll.get("heros", []) as Array).size() <= 4


func _synchroniser_a_la_connexion() -> void:
	Sauvegarde.charger()
	var r := await api(HTTPClient.METHOD_GET, "/rest/v1/sauvegardes?select=donnees,maj&joueur=eq." + id_joueur())
	if not r.ok or not (r.data is Array):
		return
	var locale: Dictionary = Sauvegarde.donnees
	var sig_locale := signature_partie(locale)
	var meme_compte: bool = _sync.get("compte", "") == id_joueur()

	if r.data.is_empty():
		# Nouveau compte : la partie de l'appareil devient celle du compte.
		await envoyer_sauvegarde(true)
		return

	var ligne: Dictionary = r.data[0]
	var cloud: Dictionary = ligne.get("donnees", {}) if ligne.get("donnees") is Dictionary else {}
	var maj := str(ligne.get("maj", ""))
	var sig_cloud := signature_partie(cloud)
	if sig_cloud == sig_locale:
		_noter_synchro(maj, sig_locale)
		return
	var cloud_a_change: bool = not meme_compte or maj != _sync.get("maj", "")
	var local_a_change: bool = not meme_compte or sig_locale != _sync.get("signature", "")

	if local_a_change and not cloud_a_change:
		await envoyer_sauvegarde(true)
	elif cloud_a_change and (not local_a_change or partie_vierge(locale)):
		_appliquer_partie_du_compte(cloud, maj)
	else:
		# Les deux ont changé : le joueur choisit.
		var fenetre := FenetreChoixPartie.creer(cloud, maj, locale)
		get_tree().root.add_child(fenetre)
		var garder_compte: bool = await fenetre.choisi
		if garder_compte:
			_appliquer_partie_du_compte(cloud, maj)
		else:
			await envoyer_sauvegarde(true)


func _appliquer_partie_du_compte(cloud: Dictionary, maj: String) -> void:
	Sauvegarde.remplacer_par(cloud)
	_noter_synchro(maj, signature_partie(Sauvegarde.donnees))
	partie_remplacee.emit()
	# Sur le menu principal (ou le choix du héros), on réaffiche tout avec la nouvelle partie.
	var scene := get_tree().current_scene
	if scene != null and scene.scene_file_path in [ProjectSettings.get_setting("application/run/main_scene", ""),
			"res://scenes/main_menu.tscn", EcranChoixHeros.SCENE]:
		get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu.tscn")


func _noter_synchro(maj: String, signature: String) -> void:
	_sync = {"compte": id_joueur(), "maj": maj, "signature": signature}
	derniere_synchro = int(Time.get_unix_time_from_system())
	_ecrire_fichier_compte()


func _envoyer_si_change() -> void:
	if est_connecte() and not _connexion_en_cours:
		envoyer_sauvegarde()


## Envoie la partie sur le compte (seulement si elle a changé, sauf forcer = true).
## Renvoie true si le compte est à jour.
func envoyer_sauvegarde(forcer := false) -> bool:
	if not est_connecte() or _envoi_en_cours:
		return false
	Sauvegarde.charger()
	if not Sauvegarde.a_choisi_heros_depart():
		return false   # partie pas encore commencée : rien à envoyer
	var sig := signature_partie(Sauvegarde.donnees)
	if not forcer and sig == _sync.get("signature", "") and _sync.get("compte", "") == id_joueur():
		return true
	_envoi_en_cours = true
	var r := await api(HTTPClient.METHOD_POST, "/rest/v1/sauvegardes?on_conflict=joueur",
		{"joueur": id_joueur(), "donnees": Sauvegarde.donnees, "version_jeu": Version.NUMERO},
		PackedStringArray(["Prefer: resolution=merge-duplicates,return=representation"]))
	_envoi_en_cours = false
	if r.ok and r.data is Array and not r.data.is_empty():
		_noter_synchro(str(r.data[0].get("maj", "")), sig)
		_maj_profil()
		return true
	return false


## Met à jour ce que les autres joueurs voient : niveau, héros vitrine, « vu il y a... ».
func _maj_profil() -> void:
	if not est_connecte():
		return
	var h := Sauvegarde.get_heros_depart()
	api(HTTPClient.METHOD_PATCH, "/rest/v1/profils?id=eq." + id_joueur(), {
		"niveau": Sauvegarde.get_niveau_compte(),
		"heros_vitrine": str(h.get("id", "")),
		"vu_le": Time.get_datetime_string_from_system(true) + "Z",
	})


func _signaler_presence() -> void:
	if est_connecte() and not _connexion_en_cours:
		_maj_profil()


# ------------------------------------------------------------------
# Fichier local du compte (session mémorisée)
# ------------------------------------------------------------------

func _lire_fichier_compte() -> void:
	if not FileAccess.file_exists(FICHIER_COMPTE):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(FICHIER_COMPTE))
	if not (d is Dictionary):
		return
	session = d.get("session", {}) if d.get("session") is Dictionary else {}
	if d.get("sync") is Dictionary:
		_sync = d["sync"]
	derniere_synchro = int(d.get("derniere_synchro", 0))


func _ecrire_fichier_compte() -> void:
	var f := FileAccess.open(FICHIER_COMPTE, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"session": session, "sync": _sync, "derniere_synchro": derniere_synchro}))
	f.close()


# ------------------------------------------------------------------
# Petits outils d'affichage
# ------------------------------------------------------------------

## "2026-09-27T08:34:23.22+00:00" -> secondes unix
func date_vers_unix(texte: String) -> int:
	if texte.length() < 19:
		return 0
	return int(Time.get_unix_time_from_datetime_string(texte.left(19)))


func est_en_ligne(vu_le: String) -> bool:
	return int(Time.get_unix_time_from_system()) - date_vers_unix(vu_le) < EN_LIGNE_SI_VU_DEPUIS


## "En ligne", "Vu il y a 12 min", "Vu il y a 3 j"
func texte_presence(vu_le: String) -> String:
	var s := int(Time.get_unix_time_from_system()) - date_vers_unix(vu_le)
	if s < EN_LIGNE_SI_VU_DEPUIS:
		return "En ligne"
	if s < 3600:
		return "Vu il y a %d min" % int(s / 60.0)
	if s < 86400:
		return "Vu il y a %d h" % int(s / 3600.0)
	return "Vu il y a %d j" % int(s / 86400.0)
