class_name Enregistreur
extends Node
## ENREGISTREUR DE PARTIE (outil développeur, dans le Menu Admin).
## Quand il est activé, il note tout ce qui se passe pendant que l'on joue :
##   - les écrans ouverts, les boutons cliqués (avec leur texte) ;
##   - les combats (mode, équipe, ennemis, graine, victoire / défaite) ;
##   - TOUTES les erreurs et alertes du moteur et des scripts (même dans la version publiée) ;
##   - les messages écrits dans la console ;
##   - les notes ajoutées à la main (« bug ici ») et la touche F8 (marque + capture d'écran sur PC).
## Le journal est écrit au fur et à mesure dans user://enregistrement.txt (il survit à un plantage :
## au lancement suivant, l'ancien devient enregistrement_precedent.txt).
## On peut le copier, l'enregistrer ou le télécharger depuis FenetreEnregistreur pour le transmettre.
##
## API :  Enregistreur.note("texte")  ·  Enregistreur.actif()  ·  Enregistreur.activer(bool)
##        Enregistreur.texte()  ·  Enregistreur.effacer()
## Le nœud est créé par l'autoload Ecran (il suit les écrans et les boutons).

const FICHIER := "user://enregistrement.txt"
const FICHIER_PRECEDENT := "user://enregistrement_precedent.txt"
const DOSSIER_CAPTURES := "user://captures"
const MAX_LIGNES := 5000
const PARAMETRE := "enregistreur_partie"

static var _actif := false
static var _lignes: PackedStringArray = []
static var _entete := ""
static var _nb_erreurs := 0
static var _nb_alertes := 0
static var _mutex := Mutex.new()
static var _fichier: FileAccess
static var _logger: _Capteur
static var _debut_ms := 0
static var _instance: Enregistreur

var _scene_suivie: Node


# =====================================================================
# API
# =====================================================================

static func actif() -> bool:
	return _actif


static func nb_lignes() -> int:
	return _lignes.size()


static func nb_erreurs() -> int:
	return _nb_erreurs


static func nb_alertes() -> int:
	return _nb_alertes


## Active ou coupe l'enregistrement (le choix est mémorisé pour les prochains lancements).
static func activer(oui: bool) -> void:
	Sauvegarde.definir_parametre(PARAMETRE, oui)
	if oui and not _actif:
		_demarrer(false)
	elif not oui and _actif:
		note("=== Enregistrement arrêté ===")
		_arreter()


## Ajoute une ligne au journal (ne fait rien si l'enregistrement est coupé).
static func note(texte: String, type := "INFO") -> void:
	if not _actif:
		return
	_ajouter(type, texte)


## Journal complet (en-tête + lignes), prêt à copier.
static func texte() -> String:
	_mutex.lock()
	var t := _entete + "\n".join(_lignes) + "\n"
	_mutex.unlock()
	return t


## Les dernières lignes seulement (aperçu).
static func dernieres(n: int) -> PackedStringArray:
	_mutex.lock()
	var r := _lignes.slice(maxi(0, _lignes.size() - n))
	_mutex.unlock()
	return r


static func effacer() -> void:
	_mutex.lock()
	_lignes.clear()
	_nb_erreurs = 0
	_nb_alertes = 0
	_mutex.unlock()
	if _actif:
		_ouvrir_fichier(false)
		note("=== Journal effacé ===")


## Marque un bug : ligne bien visible + capture d'écran (PC). Renvoie le chemin de la capture ("" sinon).
static func marquer_bug(commentaire := "") -> String:
	if not _actif:
		return ""
	var chemin := ""
	if _instance != null and is_instance_valid(_instance) and not OS.has_feature("web"):
		var img := _instance.get_viewport().get_texture().get_image()
		if img != null:
			DirAccess.make_dir_recursive_absolute(DOSSIER_CAPTURES)
			chemin = "%s/bug_%s.png" % [DOSSIER_CAPTURES, Time.get_datetime_string_from_system().replace(":", "-")]
			if img.save_png(chemin) != OK:
				chemin = ""
	_ajouter("BUG", "########## BUG MARQUÉ ##########" + (("  " + commentaire) if commentaire != "" else "")
		+ (("  (capture : %s)" % ProjectSettings.globalize_path(chemin)) if chemin != "" else ""))
	return chemin


## Écrit une copie du journal dans un fichier daté et renvoie son chemin.
static func exporter() -> String:
	var nom := "user://journal_%s.txt" % Time.get_datetime_string_from_system().replace(":", "-")
	var f := FileAccess.open(nom, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(texte())
	f.close()
	return nom


static func texte_precedent() -> String:
	if not FileAccess.file_exists(FICHIER_PRECEDENT):
		return ""
	return FileAccess.get_file_as_string(FICHIER_PRECEDENT)


# =====================================================================
# Fonctionnement
# =====================================================================

## Appelé par l'autoload Ecran au lancement du jeu.
static func installer(parent: Node) -> void:
	_instance = Enregistreur.new()
	_instance.name = "Enregistreur"
	parent.add_child(_instance)
	if bool(Sauvegarde.get_parametre(PARAMETRE, false)):
		_demarrer(true)


static func _demarrer(nouveau_lancement: bool) -> void:
	_actif = true
	_debut_ms = Time.get_ticks_msec()
	_entete = _construire_entete()
	_ouvrir_fichier(nouveau_lancement)
	if _logger == null:
		_logger = _Capteur.new()
		OS.add_logger(_logger)
	_ajouter("INFO", "=== Enregistrement démarré ===")
	if _instance != null and is_instance_valid(_instance) and _instance.is_inside_tree():
		_instance._scene_suivie = null      # réannonce l'écran courant


static func _arreter() -> void:
	_actif = false
	if _logger != null:
		OS.remove_logger(_logger)
		_logger = null
	if _fichier != null:
		_fichier.close()
		_fichier = null


## Au lancement, l'ancien journal est gardé à part (utile après un plantage).
static func _ouvrir_fichier(nouveau_lancement: bool) -> void:
	if _fichier != null:
		_fichier.close()
	if nouveau_lancement and FileAccess.file_exists(FICHIER):
		DirAccess.copy_absolute(FICHIER, FICHIER_PRECEDENT)
	_fichier = FileAccess.open(FICHIER, FileAccess.WRITE)
	if _fichier != null:
		_fichier.store_string(_entete)
		for l in _lignes:
			_fichier.store_line(l)
		_fichier.flush()


static func _construire_entete() -> String:
	var t := "===== BROTHERS OF LEGACY — ENREGISTREMENT DE PARTIE =====\n"
	t += "Version du jeu : v%s (%s)\n" % [Version.NUMERO, Version.DATE]
	t += "Date : %s\n" % Time.get_datetime_string_from_system(false, true)
	t += "Système : %s %s · %s · %s\n" % [OS.get_name(), OS.get_version(), OS.get_model_name(), Engine.get_version_info().get("string", "")]
	t += "Plateforme : %s\n" % ("web" if OS.has_feature("web") else ("mobile" if OS.has_feature("mobile") else "ordinateur"))
	t += "Écran : %s · fenêtre %s · langue %s\n" % [str(DisplayServer.screen_get_size()), str(DisplayServer.window_get_size()), OS.get_locale()]
	t += "Taille d'interface : %s · Combats en 3D : %s · Combat manuel : %s\n" % [str(Sauvegarde.get_parametre("taille_interface", "auto")),
		"oui" if bool(Sauvegarde.get_parametre("combats_3d", true)) else "NON (décoché)", "oui" if bool(Sauvegarde.get_parametre("combat_manuel", false)) else "non"]
	t += "Carte graphique : %s · %s · %s (%s)\n" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor(),
		RenderingServer.get_current_rendering_driver_name(), RenderingServer.get_video_adapter_api_version()]
	var equipe: Array = []
	for uid in Sauvegarde.get_equipe():
		var h := Sauvegarde.get_heros(uid)
		if not h.is_empty():
			equipe.append("%s Nv%d ★%d" % [h["id"], int(h["niveau"]), Fusion.etoiles(h)])
	t += "Équipe : %s\n" % ", ".join(equipe)
	t += "Unités : %d · Or : %d · Options admin actives : %s\n" % [Sauvegarde.liste_heros().size(), Sauvegarde.get_or(), "oui" if Sauvegarde.admin_actif() else "non"]
	t += "==========================================================\n"
	return t


static func _ajouter(type: String, texte: String) -> void:
	var s := (Time.get_ticks_msec() - _debut_ms) / 1000.0
	var ligne := "[%02d:%02d:%04.1f] %-5s %s" % [int(s / 3600.0), int(fmod(s, 3600.0) / 60.0), fmod(s, 60.0), type, texte.strip_edges()]
	_mutex.lock()
	_lignes.append(ligne)
	if _lignes.size() > MAX_LIGNES:
		_lignes = _lignes.slice(_lignes.size() - MAX_LIGNES)
	if _fichier != null:
		_fichier.store_line(ligne)
		_fichier.flush()
	_mutex.unlock()


# =====================================================================
# Suivi des écrans et des boutons
# =====================================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_noeud_ajoute)


func _process(_delta: float) -> void:
	if not _actif:
		return
	var sc := get_tree().current_scene
	if sc != _scene_suivie:
		_scene_suivie = sc
		if sc != null:
			Enregistreur.note("Écran : %s" % (sc.scene_file_path if sc.scene_file_path != "" else sc.name), "ECRAN")


func _noeud_ajoute(n: Node) -> void:
	if n is BaseButton:
		(n as BaseButton).pressed.connect(_clic.bind(n))
	elif n is Window and n != get_tree().root:
		(n as Window).about_to_popup.connect(func():
			if _actif and is_instance_valid(n):
				var w := n as Window
				var txt := ""
				if w is AcceptDialog:
					txt = (w as AcceptDialog).dialog_text
				Enregistreur.note("Fenêtre « %s » %s" % [w.title, txt.replace("\n", " / ")], "FENET"))


func _clic(b: BaseButton) -> void:
	if not _actif or not is_instance_valid(b):
		return
	var nom := ""
	if b is Button:
		nom = (b as Button).text.replace("\n", " / ")
	if nom.strip_edges() == "":
		nom = b.tooltip_text if b.tooltip_text != "" else str(b.name)
	var etat := ""
	if b.toggle_mode:
		etat = " [activé]" if b.button_pressed else " [désactivé]"
	Enregistreur.note("Clic : « %s »%s" % [nom.left(80), etat], "CLIC")


func _unhandled_key_input(event: InputEvent) -> void:
	if _actif and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		Enregistreur.marquer_bug("(touche F8)")
		get_viewport().set_input_as_handled()


# =====================================================================
# Capteur des messages du moteur (erreurs, alertes, console)
# =====================================================================

class _Capteur extends Logger:
	func _log_message(message: String, error: bool) -> void:
		Enregistreur._ajouter("ERR" if error else "LOG", message)

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		var alerte := error_type == Logger.ERROR_TYPE_WARNING
		var texte := (rationale if rationale != "" else code) + "   (%s · %s:%d)" % [function, file, line]
		for bt in script_backtraces:
			if bt != null and not bt.is_empty():
				texte += "\n        " + bt.format(8, 2).strip_edges().replace("\n", "\n        ")
				break
		Enregistreur._mutex.lock()
		if alerte:
			Enregistreur._nb_alertes += 1
		else:
			Enregistreur._nb_erreurs += 1
		Enregistreur._mutex.unlock()
		Enregistreur._ajouter("ALERT" if alerte else "ERREUR", texte)
