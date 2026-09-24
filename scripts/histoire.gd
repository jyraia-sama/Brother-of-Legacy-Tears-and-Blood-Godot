extends Control
## Histoire principale - Brothers of Legacy : Tears and Blood
## 12 actes cliquables ; au survol, un panneau affiche le titre et l'ambiance de l'acte.
## F1 : affiche / masque les zones cliquables.  Échap : retour à l'écran Aventure.

const BG_PATH := "res://assets/ui/histoire_bg.png"
const SCENE_RETOUR := "res://scenes/aventure.tscn"

# Positions mesurées sur l'image en 1672x941
const REF := Vector2(1672, 941)

# Grille des cartes : 4 colonnes x 3 lignes
const COLONNES_X := [155, 503, 850, 1198]
const LIGNES_Y := [125, 390, 655]
const TAILLE_CARTE := Vector2(320, 235)

const ACTES := [
	{"num": "I",    "titre": "Les Cendres du Serment",       "partie": "L'Aube et les Cendres",
	 "ambiance": "Le point de départ : la fin d'une ère pacifique, la promesse brisée qui lance les héros sur les routes."},
	{"num": "II",   "titre": "L'Étreinte du Deuil",          "partie": "L'Aube et les Cendres",
	 "ambiance": "L'acceptation de la tragédie et la découverte de l'étendue des dégâts dans les terres natales."},
	{"num": "III",  "titre": "Sous les Drapeaux Noirs",      "partie": "L'Aube et les Cendres",
	 "ambiance": "L'affrontement avec les premières factions corrompues et les mercenaires sans foi ni loi."},
	{"num": "IV",   "titre": "Le Sépulcre des Oubliés",      "partie": "L'Aube et les Cendres",
	 "ambiance": "Une exploration souterraine, dans des ruines anciennes où gisent les secrets des ancêtres."},
	{"num": "V",    "titre": "L'Aiguillon de la Souffrance", "partie": "La Descente et le Sang",
	 "ambiance": "Un tournant psychologique et physique difficile, où les héros frôlent la rupture."},
	{"num": "VI",   "titre": "Les Larmes de Pierre",         "partie": "La Descente et le Sang",
	 "ambiance": "Une région aride, maudite, pétrifiée par une ancienne malédiction."},
	{"num": "VII",  "titre": "Le Pacte des Ronces",          "partie": "La Descente et le Sang",
	 "ambiance": "Des alliances douteuses conclues dans l'ombre avec des créatures ou des seigneurs peu recommandables."},
	{"num": "VIII", "titre": "L'Éclipse du Sang",            "partie": "La Descente et le Sang",
	 "ambiance": "Un climax intermédiaire : une victoire amère ou un bouleversement cosmique et politique."},
	{"num": "IX",   "titre": "Là où Meurent les Légendes",   "partie": "Le Crépuscule et l'Héritage",
	 "ambiance": "Sur les traces des figures du passé, face à des mythes déchus."},
	{"num": "X",    "titre": "Les Chemins de la Désolation", "partie": "Le Crépuscule et l'Héritage",
	 "ambiance": "La marche vers le cœur du mal, à travers des terres ravagées par la guerre et la peste."},
	{"num": "XI",   "titre": "Le Jugement des Frères",       "partie": "Le Crépuscule et l'Héritage",
	 "ambiance": "Révélations, trahisons internes et face-à-face inévitable entre des destins liés."},
	{"num": "XII",  "titre": "L'Éternité en Héritage",       "partie": "Le Crépuscule et l'Héritage",
	 "ambiance": "L'affrontement final : le sang versé scelle le nouveau visage du monde."},
]

const RETOUR_RECT := Rect2(22, 8, 98, 94)
const PARAM_RECT := Rect2(1565, 10, 82, 85)

# Données de test (plus tard : une sauvegarde partagée entre tous les écrans)
var joueur := {"stamina": 30, "stamina_max": 30, "or": 1250, "gemmes": 50, "niveau": 1}

var _zones: Array[Button] = []
var _debug := false

# Panneau d'info affiché au survol d'un acte
var _info: PanelContainer
var _info_partie: Label
var _info_titre: Label
var _info_texte: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_creer_fond()

	for i in ACTES.size():
		var acte: Dictionary = ACTES[i]
		var b := _creer_zone(_rect_acte(i), "acte_%d" % (i + 1), "Acte %s" % acte["num"])
		b.mouse_entered.connect(_montrer_info.bind(i))
		b.mouse_exited.connect(_cacher_info)

	_creer_zone(RETOUR_RECT, "retour", "Retour")
	_creer_zone(PARAM_RECT, "parametres", "Paramètres")

	# Barre de ressources (même ordre que le menu principal)
	_creer_texte("%d/%d" % [joueur["stamina"], joueur["stamina_max"]], Rect2(452, 30, 100, 30), 22)
	_creer_texte(str(joueur["or"]), Rect2(645, 30, 108, 30), 22)
	_creer_texte("Niv. %d" % joueur["niveau"], Rect2(880, 30, 190, 30), 22)
	_creer_texte(str(joueur["gemmes"]), Rect2(1142, 30, 100, 30), 22)

	_creer_panneau_info()


func _rect_acte(i: int) -> Rect2:
	var col: int = i % 4
	var ligne: int = int(i / 4.0)
	return Rect2(Vector2(COLONNES_X[col], LIGNES_Y[ligne]), TAILLE_CARTE)


# ---------- Actions ----------

func _on_bouton(id: String, titre: String) -> void:
	print("Clic : ", id)
	if id == "retour":
		get_tree().change_scene_to_file(SCENE_RETOUR)
	elif id.begins_with("acte_"):
		var n := int(id.trim_prefix("acte_"))
		var acte: Dictionary = ACTES[n - 1]
		# Plus tard : ouvrir la carte des chapitres de cet acte
		_message("Acte %s : %s\n\nLes chapitres arrivent bientôt." % [acte["num"], acte["titre"]])
	else:
		_message("« %s » : pas encore créé." % titre)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file(SCENE_RETOUR)
		elif event.keycode == KEY_F1:
			_debug = not _debug
			for b in _zones:
				var style: StyleBox = b.get_meta("style_survol") if _debug else StyleBoxEmpty.new()
				b.add_theme_stylebox_override("normal", style)


# ---------- Panneau d'info ----------

func _creer_panneau_info() -> void:
	_info = PanelContainer.new()
	_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.02, 0.03, 0.94)
	style.border_color = Color(0.85, 0.65, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(14)
	_info.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 6)
	_info.add_child(vbox)

	_info_partie = _label_info(15, Color(0.8, 0.55, 0.55))
	_info_titre = _label_info(24, Color(1.0, 0.85, 0.55))
	_info_texte = _label_info(18, Color(0.92, 0.88, 0.85))
	vbox.add_child(_info_partie)
	vbox.add_child(_info_titre)
	vbox.add_child(_info_texte)

	add_child(_info)
	_info.visible = false


func _label_info(taille: int, couleur: Color) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	return l


func _montrer_info(i: int) -> void:
	var acte: Dictionary = ACTES[i]
	_info_partie.text = String(acte["partie"]).to_upper()
	_info_titre.text = "Acte %s : %s" % [acte["num"], acte["titre"]]
	_info_texte.text = acte["ambiance"]

	# À droite de la carte, sauf pour la dernière colonne (à gauche)
	var r := _rect_acte(i)
	var largeur := 330.0
	var x: float = r.end.x + 8.0
	if i % 4 == 3:
		x = r.position.x - largeur - 8.0
	_placer(_info, Rect2(x, r.position.y + 15.0, largeur, 190.0))
	_info.visible = true


func _cacher_info() -> void:
	_info.visible = false


# ---------- Construction (identique aux autres écrans) ----------

func _creer_fond() -> void:
	var tex: Texture2D = load(BG_PATH)
	if tex == null:
		push_error("FOND : impossible de charger " + BG_PATH)
		return
	var fond := TextureRect.new()
	fond.texture = tex
	fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fond.stretch_mode = TextureRect.STRETCH_SCALE
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fond)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _placer(ctrl: Control, r: Rect2) -> void:
	ctrl.anchor_left = r.position.x / REF.x
	ctrl.anchor_top = r.position.y / REF.y
	ctrl.anchor_right = r.end.x / REF.x
	ctrl.anchor_bottom = r.end.y / REF.y
	ctrl.offset_left = 0
	ctrl.offset_top = 0
	ctrl.offset_right = 0
	ctrl.offset_bottom = 0


func _creer_zone(r: Rect2, id: String, titre: String) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var survol := StyleBoxFlat.new()
	survol.bg_color = Color(1.0, 0.3, 0.2, 0.10)
	survol.border_color = Color(1.0, 0.75, 0.35, 0.95)
	survol.set_border_width_all(3)
	survol.set_corner_radius_all(8)

	var appui := survol.duplicate() as StyleBoxFlat
	appui.bg_color = Color(1.0, 0.2, 0.1, 0.3)

	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", survol)
	b.add_theme_stylebox_override("pressed", appui)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.set_meta("style_survol", survol)

	add_child(b)
	_placer(b, r)
	b.pressed.connect(_on_bouton.bind(id, titre))
	_zones.append(b)
	return b


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


func _message(texte: String) -> void:
	var d := AcceptDialog.new()
	d.title = "Histoire principale"
	d.dialog_text = texte
	add_child(d)
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	d.popup_centered()
