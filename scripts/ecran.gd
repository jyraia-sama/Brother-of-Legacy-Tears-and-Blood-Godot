extends Node
## ÉCRAN ET TACTILE : tout ce qui rend le jeu jouable sur téléphone et tablette.
## Chargé automatiquement au démarrage (Projet > Paramètres > Autoload : « Ecran »).
##
##  - TAILLE DE L'INTERFACE : le jeu est dessiné pour 1920 x 1080. Sur un téléphone, tout
##    paraît minuscule ; on dessine alors le jeu sur une surface plus petite (1280 x 720),
##    ce qui agrandit tout de 50 %. Réglable dans les Paramètres (Normale / Grande / Très grande).
##  - DÉFILEMENT AU DOIGT : glisser le doigt fait défiler les listes (Deck, Bestiaire…),
##    même en commençant sur une carte ou un bouton, avec de l'élan. Un glissement
##    n'appuie jamais sur le bouton de départ.
##  - PAYSAGE : en portrait, un message demande de tourner le téléphone.
##  - PLEIN ÉCRAN : dans le navigateur (téléphone ou ordinateur), le jeu passe en plein écran au premier
##    appui ou clic (le navigateur l'interdit sans geste du joueur) et se verrouille en paysage sur Android.
##  - ORDINATEUR (application Windows / Mac) : plein écran par défaut ; réglable dans les Paramètres ou touche F11.
##  - AJUSTEMENT : si un écran est trop large ou trop haut pour la taille choisie, il est
##    réduit juste assez pour tenir entièrement (rien n'est jamais coupé sur le bord).

const TAILLES := {
	"normale": Vector2i(1920, 1080),
	"grande": Vector2i(1600, 900),
	"tres_grande": Vector2i(1280, 720),
}
const NOMS_TAILLES := {"auto": "Automatique", "normale": "Normale", "grande": "Grande", "tres_grande": "Très grande"}

## Distance (en pixels de l'écran du jeu) au-delà de laquelle un appui devient un glissement.
const SEUIL_GLISSER := 14.0
## Freinage de l'élan après un glissement (plus petit = s'arrête plus vite).
const FROTTEMENT := 0.9

var _conteneur: ScrollContainer = null
var _depart := Vector2.ZERO
var _total := 0.0
var _glisse := false
var _vitesse := Vector2.ZERO
var _elan: ScrollContainer = null
var _elan_vitesse := Vector2.ZERO
var _annuler_clic := false
var _plein_ecran_demande := false
var _calque_portrait: CanvasLayer
var _scene_suivie: Node = null
var _prochain_ajustement := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -100
	appliquer_taille()
	appliquer_langue()
	_creer_calque_portrait()
	get_tree().root.size_changed.connect(_maj_portrait)
	_maj_portrait()
	if est_application_pc():
		appliquer_plein_ecran_pc()
		_appliquer_icone()
	# Application Android : paysage, dans un sens ou dans l'autre selon la façon de tenir le téléphone
	if OS.has_feature("android"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)


# =====================================================================
# Appareil
# =====================================================================

## Téléphone ou tablette (appli, ou navigateur sur mobile).
func est_mobile() -> bool:
	if OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	return OS.has_feature("web") and DisplayServer.is_touchscreen_available()


func tactile() -> bool:
	return DisplayServer.is_touchscreen_available()


# =====================================================================
# Taille de l'interface
# =====================================================================

## LANGUE DU JEU : "fr" (texte d'origine) ou "en" (langues/en.po). Sans choix enregistré :
## anglais si l'appareil est en anglais, sinon français.
const LANGUES := {"fr": "Français", "en": "English"}

func langue() -> String:
	var l := str(Sauvegarde.get_parametre("langue", ""))
	if LANGUES.has(l):
		return l
	return "en" if OS.get_locale_language() == "en" else "fr"


## Les textes anglais sont dans scripts/traduction_en.gd (copie de langues/en.po) : un script part
## toujours avec la mise à jour, et rien n'est à régler dans le projet (sinon il faudrait réinstaller).
## (La traduction n'est branchée qu'en anglais : en français, Godot prendrait sinon l'anglais
## comme langue de secours.)
var _anglais: Translation = null

func appliquer_langue() -> void:
	if _anglais == null:
		_anglais = Translation.new()
		_anglais.locale = "en"
		var textes: Dictionary = TraductionEn.TEXTES
		for fr in textes:
			_anglais.add_message(fr, textes[fr])
	var l := langue()
	if l == "en":
		TranslationServer.add_translation(_anglais)
	else:
		TranslationServer.remove_translation(_anglais)
	TranslationServer.set_locale(l)


## Change la langue et recharge l'écran en cours pour que tous les textes suivent.
func changer_langue(l: String) -> void:
	if not LANGUES.has(l) or l == langue():
		return
	Sauvegarde.definir_parametre("langue", l)
	appliquer_langue()
	redemarrer()


## REDÉMARRER LE JEU (bouton des Paramètres, changement de langue) après avoir sauvegardé.
##  - navigateur : la page est rechargée ;
##  - ordinateur : l'application se ferme et se relance toute seule ;
##  - téléphone (Android) : le jeu repart de l'écran de démarrage.
func redemarrer() -> void:
	Sauvegarde.ecrire_maintenant()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.reload()")
		return
	if est_application_pc():
		OS.set_restart_on_exit(true, OS.get_cmdline_user_args())
		get_tree().quit()
		return
	var depart := str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if depart != "":
		get_tree().change_scene_to_file.call_deferred(depart)
	else:
		get_tree().reload_current_scene.call_deferred()


func reglage_taille() -> String:
	return str(Sauvegarde.get_parametre("taille_interface", "auto"))


## Taille réellement utilisée ("auto" : très grande sur mobile, normale sur ordinateur).
func taille_effective() -> String:
	var t := reglage_taille()
	if not TAILLES.has(t):
		t = "tres_grande" if est_mobile() else "normale"
	return t


func appliquer_taille() -> void:
	var fenetre := get_tree().root
	fenetre.content_scale_size = TAILLES[taille_effective()]
	fenetre.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	fenetre.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP


func changer_taille(t: String) -> void:
	Sauvegarde.definir_parametre("taille_interface", t)
	appliquer_taille()


# =====================================================================
# Portrait : « tourne ton téléphone »
# =====================================================================

# =====================================================================
# Ajustement automatique des écrans trop grands
# =====================================================================

## Réduit l'écran courant s'il ne tient pas dans la surface de jeu (et le remet à 100 % sinon).
func ajuster_scene() -> void:
	var scene := get_tree().current_scene as Control
	if scene == null or not scene.is_inside_tree():
		return
	var vp := get_viewport().get_visible_rect().size
	var besoin := Vector2.ZERO
	for c in scene.get_children():
		if c is Control and c.visible and not c.top_level:
			besoin = besoin.max(c.get_combined_minimum_size())
	var echelle := 1.0
	if besoin.x > vp.x + 1.0:
		echelle = minf(echelle, vp.x / besoin.x)
	if besoin.y > vp.y + 1.0:
		echelle = minf(echelle, vp.y / besoin.y)
	echelle = snappedf(echelle, 0.01)
	if absf(scene.scale.x - echelle) < 0.005 and (echelle < 1.0 or scene.size.is_equal_approx(vp)):
		return
	scene.set_anchors_preset(Control.PRESET_TOP_LEFT)
	scene.position = Vector2.ZERO
	scene.scale = Vector2(echelle, echelle)
	scene.size = vp / echelle


func _creer_calque_portrait() -> void:
	_calque_portrait = CanvasLayer.new()
	_calque_portrait.layer = 128
	_calque_portrait.visible = false
	add_child(_calque_portrait)
	var fond := ColorRect.new()
	fond.color = Color("0b0607")
	fond.mouse_filter = Control.MOUSE_FILTER_STOP
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_calque_portrait.add_child(fond)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_calque_portrait.add_child(centre)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 30)
	centre.add_child(vb)
	var tel := Panel.new()
	tel.custom_minimum_size = Vector2(220, 120)
	tel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.2, 0.05, 0.05)
	st.border_color = Color(0.85, 0.65, 0.3)
	st.set_border_width_all(6)
	st.set_corner_radius_all(18)
	tel.add_theme_stylebox_override("panel", st)
	vb.add_child(tel)
	var fleche := Label.new()
	fleche.text = "↻"
	fleche.add_theme_font_size_override("font_size", 70)
	fleche.add_theme_color_override("font_color", Color(0.85, 0.65, 0.3))
	fleche.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fleche.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fleche.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tel.add_child(fleche)
	var t := Label.new()
	t.text = "Tourne ton téléphone\npour jouer en paysage"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 64)
	t.add_theme_color_override("font_color", Color(0.93, 0.88, 0.83))
	vb.add_child(t)


func _maj_portrait() -> void:
	if _calque_portrait == null:
		return
	var s := DisplayServer.window_get_size()
	_calque_portrait.visible = est_mobile() and s.y > s.x * 1.05


# =====================================================================
# Plein écran (navigateur sur mobile)
# =====================================================================

func _passer_plein_ecran() -> void:
	if _plein_ecran_demande or not OS.has_feature("web"):
		return
	if not bool(Sauvegarde.get_parametre("plein_ecran_auto", true)):
		return
	_plein_ecran_demande = true
	# Déjà installé comme appli (écran d'accueil) : rien à faire
	var appli = JavaScriptBridge.eval("window.matchMedia('(display-mode: fullscreen)').matches || window.matchMedia('(display-mode: standalone)').matches || navigator.standalone === true", true)
	if appli == true:
		return
	JavaScriptBridge.eval("""
		(function () {
			var d = document.documentElement;
			var f = d.requestFullscreen || d.webkitRequestFullscreen;
			if (!f) return;
			try {
				var p = f.call(d, {navigationUI: 'hide'});
				if (p && p.then) p.then(function () {
					if (screen.orientation && screen.orientation.lock) screen.orientation.lock('landscape').catch(function () {});
				}).catch(function () {});
			} catch (e) {}
		})();
	""", true)


# =====================================================================
# Plein écran (application ordinateur)
# =====================================================================

## Application installée sur ordinateur (Windows / Mac / Linux), pas le navigateur.
func est_application_pc() -> bool:
	return OS.has_feature("pc") and not OS.has_feature("web")


## Icône de la fenêtre et de la barre des tâches (les deux frères), même avec une ancienne installation.
func _appliquer_icone() -> void:
	var tex := load("res://assets/pwa/icone_512.png") as Texture2D
	if tex:
		var img := tex.get_image()
		if img:
			img.resize(256, 256, Image.INTERPOLATE_LANCZOS)
			DisplayServer.set_icon(img)


func plein_ecran_pc() -> bool:
	return bool(Sauvegarde.get_parametre("plein_ecran_pc", true))      # plein écran par défaut


func changer_plein_ecran_pc(actif: bool) -> void:
	Sauvegarde.definir_parametre("plein_ecran_pc", actif)
	appliquer_plein_ecran_pc()


func appliquer_plein_ecran_pc() -> void:
	if not est_application_pc():
		return
	var voulu := DisplayServer.WINDOW_MODE_FULLSCREEN if plein_ecran_pc() else DisplayServer.WINDOW_MODE_WINDOWED
	var actuel := DisplayServer.window_get_mode()
	var plein := actuel in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	if plein != plein_ecran_pc():
		DisplayServer.window_set_mode(voulu)


# =====================================================================
# Défilement au doigt
# =====================================================================

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11 and est_application_pc():
		changer_plein_ecran_pc(not plein_ecran_pc())
		get_viewport().set_input_as_handled()
		return
	# Navigateur sur ordinateur : plein écran au premier clic
	if event is InputEventMouseButton and not event.pressed and OS.has_feature("web") and not est_mobile():
		_passer_plein_ecran()
	if event is InputEventScreenTouch:
		if event.index != 0:
			return
		if event.pressed:
			_elan = null
			_conteneur = null
			_depart = event.position
			_total = 0.0
			_glisse = false
			_vitesse = Vector2.ZERO
			_annuler_clic = false
		else:
			if _glisse and is_instance_valid(_conteneur):
				_elan = _conteneur
				_elan_vitesse = _vitesse
			_annuler_clic = _glisse
			_glisse = false
			_passer_plein_ecran()
		return

	if event is InputEventScreenDrag:
		if event.index != 0:
			return
		if _conteneur == null:
			_conteneur = _trouver_conteneur()
			if _conteneur == null:
				return
		_total += event.relative.length()
		if not _glisse and _total > SEUIL_GLISSER:
			_glisse = true
		if _glisse:
			_defiler(_conteneur, event.relative)
			_vitesse = _vitesse.lerp(event.relative, 0.5)
		return

	# Souris simulée à partir du doigt : pendant un glissement, les listes ne doivent pas
	# recevoir de mouvement (sinon double défilement) et le bouton de départ ne doit pas
	# être « cliqué » au moment où l'on lève le doigt.
	if event is InputEventMouseMotion and _glisse and event.device == InputEvent.DEVICE_ID_EMULATION:
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION \
			and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and (_annuler_clic or _glisse):
		_annuler_clic = false
		# On remplace le relâchement par un relâchement très loin : le bouton se relâche
		# sans se déclencher.
		get_viewport().set_input_as_handled()
		var faux := InputEventMouseButton.new()
		faux.button_index = MOUSE_BUTTON_LEFT
		faux.pressed = false
		faux.position = Vector2(-10000, -10000)
		faux.global_position = faux.position
		get_viewport().push_input.call_deferred(faux, true)


func _trouver_conteneur() -> ScrollContainer:
	var c := get_viewport().gui_get_hovered_control()
	while c != null:
		if c is ScrollContainer and _peut_defiler(c):
			return c
		c = c.get_parent() as Control
	return null


func _peut_defiler(sc: ScrollContainer) -> bool:
	var v := sc.get_v_scroll_bar()
	var h := sc.get_h_scroll_bar()
	return (v != null and v.max_value > v.page + 1.0) or (h != null and h.max_value > h.page + 1.0)


func _defiler(sc: ScrollContainer, delta: Vector2) -> void:
	if sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		sc.scroll_vertical = int(sc.scroll_vertical - delta.y)
	if sc.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		sc.scroll_horizontal = int(sc.scroll_horizontal - delta.x)


func _process(delta: float) -> void:
	_prochain_ajustement -= delta
	var scene := get_tree().current_scene
	if scene != _scene_suivie or _prochain_ajustement <= 0.0:
		_scene_suivie = scene
		_prochain_ajustement = 0.4
		ajuster_scene()
	if _elan == null:
		return
	if not is_instance_valid(_elan) or _elan_vitesse.length() < 0.5:
		_elan = null
		return
	_defiler(_elan, _elan_vitesse)
	_elan_vitesse *= FROTTEMENT
