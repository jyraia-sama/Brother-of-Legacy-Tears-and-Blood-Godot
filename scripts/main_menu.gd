extends Control
## Menu principal - Brothers of Legacy : Tears and Blood
## Le fond est ton image ; par-dessus, on place des zones cliquables invisibles
## (elles s'illuminent au survol) et des textes (ressources, stats, titres).
## Astuce : appuie sur F1 pendant le jeu pour afficher toutes les zones et les recaler.

const BG_PATH := "res://assets/ui/menu_bg.png"

# Toutes les positions sont mesurées sur l'image en 1024x576.
# Elles sont converties en pourcentages : ça marche quelle que soit la résolution réelle.
const REF := Vector2(1024, 576)

# Les 6 grandes cartes (id, titre affiché, zone sur l'image)
const CARTES := [
	{"id": "aventure",   "titre": "AVENTURE",           "rect": Rect2(252, 124, 164, 146)},
	{"id": "deck",       "titre": "DECK",               "rect": Rect2(434, 124, 152, 146)},
	{"id": "invocation", "titre": "AUTEL D'INVOCATION", "rect": Rect2(604, 124, 154, 146)},
	{"id": "fusion",     "titre": "AUTEL DE FUSION",    "rect": Rect2(252, 294, 164, 146)},
	{"id": "echos",      "titre": "ÉCHOS SANGUINS",     "rect": Rect2(434, 294, 152, 146)},
	{"id": "reliquaire", "titre": "LE RELIQUAIRE",      "rect": Rect2(604, 294, 154, 146)},
]

# La barre du bas (5 icônes) - renomme-les comme tu veux
const BAS := [
	{"id": "quetes",    "titre": "Quêtes",      "rect": Rect2(276, 472, 72, 70)},
	{"id": "boutique",  "titre": "Boutique",    "rect": Rect2(374, 472, 72, 70)},
	{"id": "succes",    "titre": "Succès",      "rect": Rect2(474, 466, 72, 76)},
	{"id": "social",    "titre": "Social",      "rect": Rect2(574, 472, 72, 70)},
	{"id": "bestiaire", "titre": "Bestiaire",   "rect": Rect2(672, 472, 72, 70)},
]

# Boutons divers
const AUTRES := [
	{"id": "aide",       "titre": "Aide",       "rect": Rect2(10, 12, 50, 50)},
	{"id": "parametres", "titre": "Paramètres", "rect": Rect2(966, 12, 50, 50)},
	{"id": "heros",      "titre": "Mon héros",  "rect": Rect2(68, 110, 122, 120)},
]


# Textes de la barre de ressources (mis à jour depuis la sauvegarde)
var _lbl_stamina: Label
var _lbl_or: Label
var _lbl_niveau: Label
var _lbl_gemmes: Label
var _lbl_recharge: Label
var _lbl_xp: Label

var _zones: Array[Button] = []
var _debug := false


func _ready() -> void:
	# Tout premier lancement (ou après "Nouvelle partie") : choix du héros de départ
	if not Sauvegarde.a_choisi_heros_depart():
		get_tree().change_scene_to_file.call_deferred(EcranChoixHeros.SCENE)
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_creer_fond()

	for c in CARTES:
		_creer_zone(c.rect, c.id, c.titre)
		# Titre sur le bandeau rouge en bas de la carte
		var r: Rect2 = c.rect
		_creer_texte(c.titre, Rect2(r.position.x, r.end.y - 16, r.size.x, 14), 20)

	for c in BAS:
		_creer_zone(c.rect, c.id, c.titre)
	for c in AUTRES:
		_creer_zone(c.rect, c.id, c.titre)

	# Barre de ressources en haut (valeurs réelles de la sauvegarde)
	_lbl_stamina = _creer_texte("", Rect2(276, 20, 80, 20), 22)
	_lbl_or = _creer_texte("", Rect2(404, 20, 68, 20), 22)
	_lbl_niveau = _creer_texte("", Rect2(540, 20, 110, 20), 22)
	_lbl_gemmes = _creer_texte("", Rect2(702, 20, 68, 20), 22)
	# Petites lignes sous la barre : recharge de la stamina et XP du compte
	_lbl_recharge = _creer_texte("", Rect2(256, 40, 120, 12), 13)
	_lbl_xp = _creer_texte("", Rect2(520, 40, 150, 12), 13)
	# Numéro de version (clic = journal des mises à jour)
	var v := Button.new()
	v.text = "%s  ·  Nouveautés" % Version.texte()
	v.flat = true
	v.focus_mode = Control.FOCUS_NONE
	v.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	v.add_theme_font_size_override("font_size", 14)
	v.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 0.75))
	v.tooltip_text = "Journal des mises à jour"
	v.pressed.connect(func(): FenetreChangelog.ouvrir(self))
	add_child(v)
	_placer(v, Rect2(880, 552, 140, 20))
	_maj_ressources()
	# La stamina se recharge avec le temps : on rafraîchit l'affichage chaque seconde
	var minuterie := Timer.new()
	minuterie.wait_time = 1.0
	minuterie.autostart = true
	minuterie.timeout.connect(_maj_ressources)
	add_child(minuterie)

	# Stats du héros de départ (panneau de gauche)
	var h := Sauvegarde.get_heros_depart()
	var s := Sauvegarde.stats_heros(int(h.get("uid", -1)))
	if not s.is_empty():
		var u := UnitesData.get_unite(h["id"])
		_creer_texte("%s  Niv. %d" % [u["nom"], int(h["niveau"])], Rect2(60, 232, 140, 16), 15)
		_creer_texte("ATK %d" % s["atk"], Rect2(100, 256, 82, 16), 18)
		_creer_texte("DEF %d" % s["def"], Rect2(100, 277, 82, 16), 18)
		_creer_texte("PV %d" % s["pv"], Rect2(100, 297, 82, 16), 18)

	# Le jeu vient d'être mis à jour : on montre les nouveautés
	FenetreChangelog.verifier_mise_a_jour(self)


func _maj_ressources() -> void:
	var st := Sauvegarde.get_stamina()
	var mx := Sauvegarde.get_stamina_max()
	_lbl_stamina.text = "%d/%d" % [st, mx]
	_lbl_recharge.text = "" if st >= mx else "+1 dans %s" % Calendrier.texte_duree(Sauvegarde.secondes_avant_stamina())
	_lbl_or.text = str(Sauvegarde.get_or())
	var niv := Sauvegarde.get_niveau_compte()
	_lbl_niveau.text = "Niv. %d" % niv
	_lbl_gemmes.text = str(Sauvegarde.get_gemmes())
	if Sauvegarde.niveau_compte_max_atteint():
		_lbl_xp.text = "Niveau MAX"
	else:
		_lbl_xp.text = "XP %d / %d" % [Sauvegarde.get_xp_compte(), Sauvegarde.xp_pour_niveau(niv)]


# ---------- Construction ----------

func _creer_fond() -> void:
	var tex: Texture2D = load(BG_PATH)
	if tex == null:
		push_error("FOND : impossible de charger " + BG_PATH)
		return
	print("FOND : image chargée, taille = ", tex.get_size())
	var fond := TextureRect.new()
	fond.texture = tex
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _placer(ctrl: Control, r: Rect2) -> void:
	# Ancre le contrôle en pourcentage de l'écran => il suit le redimensionnement
	ctrl.anchor_left = r.position.x / REF.x
	ctrl.anchor_top = r.position.y / REF.y
	ctrl.anchor_right = r.end.x / REF.x
	ctrl.anchor_bottom = r.end.y / REF.y
	ctrl.offset_left = 0
	ctrl.offset_top = 0
	ctrl.offset_right = 0
	ctrl.offset_bottom = 0


func _creer_zone(r: Rect2, id: String, titre: String) -> void:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = titre
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var survol := StyleBoxFlat.new()
	survol.bg_color = Color(1.0, 0.85, 0.4, 0.12)
	survol.border_color = Color(1.0, 0.8, 0.3, 0.95)
	survol.set_border_width_all(3)
	survol.set_corner_radius_all(6)

	var appui := survol.duplicate() as StyleBoxFlat
	appui.bg_color = Color(1.0, 0.25, 0.15, 0.3)

	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", survol)
	b.add_theme_stylebox_override("pressed", appui)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.set_meta("style_survol", survol)

	add_child(b)
	_placer(b, r)
	b.pressed.connect(_on_bouton.bind(id, titre))
	_zones.append(b)


func _creer_texte(texte: String, r: Rect2, taille: int) -> Label:
	var l := Label.new()
	l.text = texte
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	_placer(l, r)
	return l


# ---------- Actions ----------

func _on_bouton(id: String, titre: String) -> void:
	print("Clic : ", id)
	match id:
		"aventure":
			# L'écran Aventure reviendra toujours ici (et pas à l'écran des Actes)
			ActesData.scene_menu = scene_file_path
			ActesData.scene_precedente = scene_file_path
			get_tree().change_scene_to_file("res://scenes/aventure.tscn")
		"fusion":
			EcranFusion.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranFusion.SCENE)
		"parametres":
			FenetreSauvegarde.ouvrir(self)
		"deck":
			EcranDeck.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranDeck.SCENE)
		"echos":
			EcranEchos.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranEchos.SCENE)
		"invocation":
			EcranInvocation.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranInvocation.SCENE)
		"reliquaire":
			EcranReliquaire.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranReliquaire.SCENE)
		"bestiaire":
			EcranBestiaire.scene_retour = scene_file_path
			get_tree().change_scene_to_file(EcranBestiaire.SCENE)
		_:
			_message("« %s » : écran pas encore créé." % titre)


func _message(texte: String) -> void:
	var d := AcceptDialog.new()
	d.title = "Brothers of Legacy"
	d.dialog_text = texte
	add_child(d)
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	d.popup_centered()


# F1 : affiche / masque toutes les zones cliquables (pour les recaler)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_debug = not _debug
		for b in _zones:
			var style: StyleBox = b.get_meta("style_survol") if _debug else StyleBoxEmpty.new()
			b.add_theme_stylebox_override("normal", style)
