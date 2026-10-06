class_name EcranCarte
extends Control
## CARTE DU MONDE : « Les Terres des Valcendre ». L'Histoire principale se lit sur une carte,
## du sud (le domaine en flammes) au nord (le Trône de Cendres). Ouverte par le bouton Aventure.
##
##  - Chaque Acte est un lieu de la carte, relié aux autres par la route : dorée quand elle est
##    parcourue, en pointillés pour la suite. La figurine du grand frère se tient sur l'Acte en cours.
##  - Les terres pas encore atteintes restent dans la brume, qui se lève au fil des Actes.
##  - Toucher un Acte ouvre sa fiche à droite : partie, lieu, boss, set d'Échos et ses 6 chapitres.
##    Toucher un chapitre (ou « Continuer ») ouvre sa fenêtre d'informations : niveau conseillé,
##    ennemis de l'Acte (cachés tant qu'ils ne sont pas au Bestiaire), boss, plateau, butin, stamina,
##    sur l'illustration de l'Acte ; « Jouer » lance le plateau.
##  - L'Acte XIII (caché) apparaît au-dessus du Trône une fois l'Acte XII terminé.
##
## IMAGE DE LA CARTE : assets/ui/carte_monde.png (peinte, 3:2) remplace le relief dessiné.
## Les lieux sont alors aux positions de POS_IMAGE ; sans image, à celles de LIEUX (surface 1280 x 720).

const SCENE := "res://scenes/carte_monde.tscn"
const BG_PATH := "res://assets/ui/carte_monde.png"
const IMG_PION := "res://assets/plateaux/pion_aine.png"
const SCENE_PLATEAU := "res://scenes/plateau.tscn"
const BASE := Vector2(1280, 720)

static var scene_retour := ""
## Dernier Acte joué : la carte s'ouvre dessus au retour d'un plateau.
static var acte_choisi := 0

const C_OR := Color("c9a45c")
const C_TEXTE := Color("ede4d8")
const C_DOUX := Color("b3a597")
const C_ROUGE := Color("a3242f")
const C_VIOLET := Color("a98aff")

const ROMAINS := ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII"]

## Un lieu par Acte : nom sur la carte, boss de l'Acte (scénario) et position sur la surface 1280 x 720.
const LIEUX := [
	{"lieu": "Domaine Valcendre",       "boss": "Le Seigneur des Cendres",      "pos": Vector2(110, 640)},
	{"lieu": "La Cité en Deuil",        "boss": "La Veuve aux Lanternes",       "pos": Vector2(240, 580)},
	{"lieu": "Camps du Drapeau Noir",   "boss": "Le Capitaine au Drapeau Noir", "pos": Vector2(380, 632)},
	{"lieu": "Sépulcre des Rois",       "boss": "Le Seigneur du Donjon Maudit", "pos": Vector2(500, 545)},
	{"lieu": "Terres Brûlées",          "boss": "L'Inquisiteur Implacable",     "pos": Vector2(345, 470)},
	{"lieu": "Forêt Pétrifiée",         "boss": "Le Reflet de l'Âme",           "pos": Vector2(175, 395)},
	{"lieu": "Marais aux Murmures",     "boss": "La Dame des Ronciers",         "pos": Vector2(300, 305)},
	{"lieu": "Bastion de l'Éclipse",    "boss": "L'Avatar de l'Éclipse",        "pos": Vector2(465, 360)},
	{"lieu": "Val des Héros Déchus",    "boss": "L'Ombre du Premier Roi",       "pos": Vector2(575, 265)},
	{"lieu": "Citadelle des Supplices", "boss": "Le Maître des Supplices",      "pos": Vector2(705, 330)},
	{"lieu": "Champs du Jugement",      "boss": "Le Frère Masqué",              "pos": Vector2(790, 232)},
	{"lieu": "Trône de Cendres",        "boss": "L'Héritier Maudit",            "pos": Vector2(812, 128)},
	{"lieu": "Le Sceau des Frères",     "boss": "Morvaël, la Soif Première",    "pos": Vector2(640, 118)},
]

## Positions des lieux sur la carte PEINTE (assets/ui/carte_monde.png, surface 1280 x 720) :
## l'image 3:2 est montrée sur toute la hauteur, calée à gauche et descendue de IMAGE_DECALAGE_Y.
const IMAGE_DECALAGE_Y := 50.0
const POS_IMAGE := [
	Vector2(162, 605), Vector2(232, 486), Vector2(450, 648), Vector2(534, 542),
	Vector2(506, 430), Vector2(211, 352), Vector2(260, 261), Vector2(541, 303),
	Vector2(295, 141), Vector2(682, 141), Vector2(548, 184), Vector2(485, 78),
	Vector2(394, 96),
]

const COULEURS_PARTIE := {
	"L'Aube et les Cendres": Color("d8a46a"),
	"La Descente et le Sang": Color("e06a6a"),
	"Le Crépuscule et l'Héritage": Color("b8a8c8"),
	"L'Acte Caché": Color("a98aff"),
}

# Relief dessiné (utilisé tant qu'il n'y a pas d'image de carte)
const MER := [0, 0, 78, 0, 82, 33, 82, 65, 80, 97, 78, 128, 74, 160, 72, 192, 70, 223, 71, 255, 76, 287, 84, 320, 92, 356, 94, 392, 92, 429, 87, 467, 80, 505, 73, 545, 67, 586, 64, 628, 64, 673, 70, 720, 0, 720]
const PARTIE_1 := [84, 720, 82, 685, 83, 653, 88, 624, 96, 598, 107, 575, 121, 556, 137, 541, 156, 529, 177, 522, 200, 520, 231, 514, 262, 507, 295, 501, 330, 496, 365, 491, 402, 488, 439, 487, 478, 489, 519, 493, 560, 500, 583, 508, 605, 519, 626, 534, 645, 552, 662, 572, 678, 596, 692, 623, 703, 653, 713, 685, 720, 720]
const PARTIE_2 := [100, 480, 98, 445, 99, 411, 103, 379, 110, 350, 120, 324, 134, 301, 152, 281, 173, 266, 199, 256, 230, 250, 260, 248, 289, 247, 318, 247, 346, 249, 375, 252, 404, 258, 432, 265, 461, 275, 490, 286, 520, 300, 542, 313, 561, 328, 575, 346, 586, 365, 592, 385, 595, 407, 593, 429, 587, 452, 576, 476, 560, 500, 519, 493, 478, 489, 439, 487, 402, 488, 365, 491, 330, 496, 295, 501, 262, 507, 231, 514, 200, 520, 183, 521, 167, 520, 153, 518, 140, 515, 129, 511, 120, 506, 112, 501, 107, 494, 102, 487]
const PARTIE_3 := [150, 250, 167, 221, 189, 195, 215, 171, 244, 149, 276, 130, 311, 113, 349, 99, 388, 87, 428, 77, 470, 70, 515, 64, 559, 59, 602, 55, 645, 52, 686, 50, 727, 49, 767, 50, 806, 51, 843, 55, 880, 60, 880, 420, 861, 419, 842, 418, 822, 415, 801, 412, 780, 408, 759, 403, 738, 397, 718, 392, 699, 386, 680, 380, 663, 374, 648, 367, 634, 360, 621, 352, 608, 344, 594, 335, 578, 327, 562, 318, 542, 309, 520, 300, 490, 286, 461, 275, 432, 265, 404, 258, 375, 252, 346, 249, 318, 247, 289, 247, 260, 248, 230, 250]
const FLEUVE := [700, 40, 688, 63, 676, 86, 663, 106, 651, 126, 638, 144, 624, 160, 609, 175, 594, 188, 577, 200, 560, 210, 534, 223, 511, 238, 489, 255, 469, 274, 451, 294, 435, 314, 420, 336, 405, 357, 392, 379, 380, 400, 367, 420, 350, 437, 332, 453, 311, 467, 288, 479, 263, 489, 236, 498, 208, 507, 180, 514, 150, 520, 139, 524, 128, 528, 119, 534, 111, 541, 103, 549, 97, 557, 91, 567, 85, 577, 80, 588, 76, 600]
const COTE := [78, 0, 82, 33, 82, 65, 80, 97, 78, 128, 74, 160, 72, 192, 70, 223, 71, 255, 76, 287, 84, 320, 92, 356, 94, 392, 92, 429, 87, 467, 80, 505, 73, 545, 67, 586, 64, 628, 64, 673, 70, 720]
# Montagnes et forêt : x, y (base gauche), demi-largeur, hauteur
const MONTAGNES := [[560, 170, 26, 46], [600, 180, 30, 54], [690, 150, 28, 50], [740, 120, 34, 62], [830, 190, 26, 46], [500, 140, 22, 40], [860, 100, 22, 40], [440, 110, 20, 36]]
const FORET := [[128, 360, 8, 18], [146, 372, 7, 16], [112, 382, 8, 18], [200, 358, 7, 16], [218, 372, 8, 18], [134, 412, 7, 16]]

var _ui: Control
var _image_fond := false
var _nb := 12
var _courant := 1
var _tout_fini := false
var _sel := 1
var _noeuds := {}
var _panneau: PanelContainer
var _fenetre: Control = null
var _lbl_stamina: CaseStamina
var _lbl_or: Label


func _ready() -> void:
	Sauvegarde.charger()
	ActesData.charger()
	FinHistoire.verifier_rattrapage()
	# Le plateau reviendra ici
	ActesData.scene_precedente = scene_file_path
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = Color("0b0708")
	noir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	_ui = Control.new()
	_ui.size = BASE
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui)
	_ajuster_ui()
	get_viewport().size_changed.connect(_ajuster_ui)

	_nb = 13 if ActesData.acte_debloque(13) else 12
	_courant = _acte_en_cours()
	_sel = _courant
	if acte_choisi >= 1 and acte_choisi <= _nb:
		_sel = acte_choisi
	_image_fond = ResourceLoader.exists(BG_PATH)

	_creer_fond()
	_creer_brume()
	_creer_route()
	_creer_noeuds()
	_creer_hud()
	_creer_legende()
	_panneau = PanelContainer.new()
	_placer(_panneau, Rect2(904, 76, 356, 628))
	_afficher_acte(_sel)

	var minuterie := Timer.new()
	minuterie.wait_time = 1.0
	minuterie.autostart = true
	minuterie.timeout.connect(_maj_ressources)
	add_child(minuterie)
	_maj_ressources()


func _ajuster_ui() -> void:
	if not is_instance_valid(_ui):
		return
	var vp := get_viewport_rect().size
	var e := minf(vp.x / BASE.x, vp.y / BASE.y)
	_ui.scale = Vector2(e, e)
	_ui.position = ((vp - BASE * e) / 2.0).floor()


# =====================================================================
# Progression
# =====================================================================

## Premier Acte ouvert et pas encore terminé (le dernier s'ils le sont tous).
func _acte_en_cours() -> int:
	for a in range(1, _nb + 1):
		if ActesData.acte_debloque(a) and not ActesData.est_termine(a, 6):
			return a
	_tout_fini = true
	return _nb


## Premier chapitre pas encore terminé de l'Acte (0 si tout est terminé).
func _chapitre_en_cours(a: int) -> int:
	for c in range(1, 7):
		if not ActesData.est_termine(a, c):
			return c
	return 0


func _chapitres_termines() -> int:
	var n := 0
	for a in range(1, _nb + 1):
		for c in range(1, 7):
			if ActesData.est_termine(a, c):
				n += 1
	return n


# =====================================================================
# Fond : relief dessiné (ou image de carte)
# =====================================================================

func _creer_fond() -> void:
	if _image_fond:
		var tex: Texture2D = load(BG_PATH)
		# Derrière : la même carte assombrie (sous la fiche de droite)
		var arriere := TextureRect.new()
		arriere.texture = tex
		arriere.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arriere.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		arriere.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arriere.modulate = Color(0.3, 0.28, 0.3)
		arriere.size = BASE
		_ui.add_child(arriere)
		# Devant : la carte entière sur la hauteur, calée à gauche, bord droit fondu
		var largeur := BASE.y * tex.get_width() / float(tex.get_height())
		var fond := TextureRect.new()
		fond.texture = tex
		fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fond.stretch_mode = TextureRect.STRETCH_SCALE
		fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fond.position = Vector2(0, IMAGE_DECALAGE_Y)
		fond.size = Vector2(largeur, BASE.y)
		var sh := Shader.new()
		sh.code = "shader_type canvas_item;\nvoid fragment() {\n\tCOLOR.a *= smoothstep(1.0, 0.9, UV.x);\n}"
		var m := ShaderMaterial.new()
		m.shader = sh
		fond.material = m
		_ui.add_child(fond)
		return
	_boite(Rect2(Vector2.ZERO, BASE), Color("17110f"))
	_polygone(MER, Color("0f1a22"))
	_polygone(PARTIE_1, Color("2b1f15"))
	_polygone(PARTIE_2, Color("2a1518"))
	_polygone(PARTIE_3, Color("1f1719"))
	_ligne(COTE, Color("2c3e48"), 2.0)
	_ligne(FLEUVE, Color("1e3440"), 5.0)
	for f in FORET:
		_triangle(f, Color("5a5452"), Color(0, 0, 0, 0))
	_ellipse(Vector2(232, 440), Vector2(34, 14), Color("08080d"), Color("3a3a55"))
	_ellipse(Vector2(262, 292), Vector2(26, 9), Color("1a2a23"), Color("2c4136"))
	_ellipse(Vector2(338, 280), Vector2(20, 7), Color("1a2a23"), Color("2c4136"))
	_ellipse(Vector2(350, 320), Vector2(24, 8), Color("1a2a23"), Color("2c4136"))
	for m in MONTAGNES:
		_triangle(m, Color("2e2426"), Color("4d3d3f"))
	# Lueur rouge du Trône de Cendres
	for i in 4:
		_ellipse(_pos(12), Vector2.ONE * (90 - i * 20), Color(0.7, 0.14, 0.17, 0.09), Color(0, 0, 0, 0))
	_texte_partie("L'Aube et les Cendres", Vector2(565, 700), Color("8a6a4a"))
	_texte_partie("La Descente et le Sang", Vector2(600, 448), Color("8a4a50"))
	_texte_partie("Le Crépuscule et l'Héritage", Vector2(400, 196), Color("7a6a6c"))


## Brume sur les terres pas encore atteintes (elle recule au fil des Actes).
func _creer_brume() -> void:
	var bas := 0.0
	if _courant <= 4:
		bas = 460.0 if _image_fond else 480.0
	elif _courant <= 8:
		bas = 230.0 if _image_fond else 300.0
	if bas <= 0.0:
		return
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([Vector2(0, 0), Vector2(900, 0), Vector2(900, bas), Vector2(0, bas)])
	var haut := Color(0.047, 0.031, 0.035, 0.92)
	var fin := Color(0.047, 0.031, 0.035, 0.0)
	p.vertex_colors = PackedColorArray([haut, haut, fin, fin])
	_ui.add_child(p)


# =====================================================================
# Route et lieux
# =====================================================================

func _creer_route() -> void:
	var points: Array = []
	for i in 12:
		points.append(_pos(i + 1))
	# Route à venir : petits points
	var fin_faite := 12 if _tout_fini else mini(_courant, 12)
	for i in range(fin_faite - 1, 11):
		_pointilles(points[i], points[i + 1], Color("5a4a40"), 9.0)
	# Route parcourue : trait doré
	if fin_faite > 1:
		var l := Line2D.new()
		for i in fin_faite:
			l.add_point(points[i])
		l.width = 4.0
		l.default_color = C_OR
		l.joint_mode = Line2D.LINE_JOINT_ROUND
		l.begin_cap_mode = Line2D.LINE_CAP_ROUND
		l.end_cap_mode = Line2D.LINE_CAP_ROUND
		_ui.add_child(l)
	# Le chemin vers l'Acte caché, au-dessus du Trône
	if _nb == 13:
		for i in 3:
			_ellipse(_pos(13), Vector2.ONE * (80 - i * 22), Color(0.48, 0.36, 1.0, 0.1), Color(0, 0, 0, 0))
		_pointilles(_pos(12), _pos(13), Color("9a7aff"), 10.0)


## Position d'un lieu (carte peinte ou relief dessiné).
func _pos(a: int) -> Vector2:
	return POS_IMAGE[a - 1] if _image_fond else LIEUX[a - 1].pos


func _pointilles(a: Vector2, b: Vector2, couleur: Color, pas: float) -> void:
	var n := int(a.distance_to(b) / pas)
	for k in range(1, n):
		var p := a.lerp(b, float(k) / n)
		var d := ColorRect.new()
		d.color = couleur
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		d.position = p - Vector2(1.5, 1.5)
		d.size = Vector2(3, 3)
		_ui.add_child(d)


func _creer_noeuds() -> void:
	for a in range(1, _nb + 1):
		var pos: Vector2 = _pos(a)
		var b := Button.new()
		b.text = ROMAINS[a]
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.tooltip_text = "Acte %s — %s" % [ROMAINS[a], ActesData.get_acte(a).get("titre", "")]
		b.add_theme_font_size_override("font_size", 16 if a < 13 else 15)
		_placer(b, Rect2(pos - Vector2(28, 28), Vector2(56, 56)))
		b.pressed.connect(_choisir.bind(a))
		_noeuds[a] = b
		var ferme := not ActesData.acte_debloque(a)
		var nom := _label(LIEUX[a - 1].lieu, 12, C_DOUX if ferme else Color("e8dccf"), true)
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var sn := _style(Color(0.047, 0.031, 0.035, 0.78), Color(0, 0, 0, 0), 8, 0)
		sn.content_margin_left = 8
		sn.content_margin_right = 8
		nom.add_theme_stylebox_override("normal", sn)
		_placer(nom, Rect2(pos.x - 90, pos.y + 32, 180, 18))
		nom.size = Vector2(180, 18)
		# Recentrer l'étiquette sur sa largeur réelle
		var largeur := nom.get_minimum_size().x
		nom.position.x = pos.x - largeur / 2.0
		nom.size.x = largeur
	_maj_noeuds()
	# La figurine du grand frère sur l'Acte en cours
	if not _tout_fini and ResourceLoader.exists(IMG_PION):
		var pion := TextureRect.new()
		pion.texture = load(IMG_PION)
		pion.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pion.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pion.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var pos: Vector2 = _pos(_courant)
		# Au-dessus du lieu, ou à sa gauche s'il est trop près de la barre du haut
		var r_pion := Rect2(pos.x - 16, pos.y - 84, 32, 56)
		if r_pion.position.y < 66:
			r_pion = Rect2(pos.x - 70, pos.y - 40, 32, 56)
		_placer(pion, r_pion)
		var tw := pion.create_tween().set_loops()
		tw.tween_property(pion, "position:y", pion.position.y - 5, 0.8).set_trans(Tween.TRANS_SINE)
		tw.tween_property(pion, "position:y", pion.position.y, 0.8).set_trans(Tween.TRANS_SINE)


func _maj_noeuds() -> void:
	for cle in _noeuds:
		var a: int = cle
		var b: Button = _noeuds[a]
		var fait := ActesData.est_termine(a, 6)
		var ouvert := ActesData.acte_debloque(a)
		var en_cours := a == _courant and not fait
		var fond := Color("241c1d")
		var bord := Color("4a3e3c")
		var texte := Color("6e6260")
		if fait:
			fond = Color("5e1a20")
			bord = C_OR
			texte = Color("f3e2c0")
		elif en_cours:
			fond = C_ROUGE
			bord = Color("ffd27a")
			texte = Color.WHITE
		elif ouvert:
			fond = Color("3a2224")
			bord = Color("8a6a4a")
			texte = C_TEXTE
		if a == 13:
			fond = Color("2a1d4a")
			bord = C_VIOLET
			texte = Color.WHITE
		var choisi: bool = a == _sel
		var st := _style(fond, Color("ffd27a") if choisi else bord, 28, 3)
		if choisi:
			st.shadow_color = Color(1.0, 0.7, 0.35, 0.5)
			st.shadow_size = 14
		elif en_cours or a == 13:
			st.shadow_color = Color(1.0, 0.35, 0.35, 0.45) if a < 13 else Color(0.6, 0.45, 1.0, 0.5)
			st.shadow_size = 10
		var survol := st.duplicate() as StyleBoxFlat
		survol.bg_color = fond.lightened(0.12)
		for etat in ["normal", "pressed"]:
			b.add_theme_stylebox_override(etat, st)
		b.add_theme_stylebox_override("hover", survol)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		for c in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(c, texte)


func _choisir(a: int) -> void:
	Audio.son("clic")
	_sel = a
	_maj_noeuds()
	_afficher_acte(a)


# =====================================================================
# Fiche de l'Acte choisi
# =====================================================================

func _afficher_acte(a: int) -> void:
	for x in _panneau.get_children():
		x.queue_free()
	var acte := ActesData.get_acte(a)
	var partie := str(acte.get("partie", ""))
	var ouvert := ActesData.acte_debloque(a)
	var fait := ActesData.est_termine(a, 6)
	var bord := C_VIOLET if a == 13 else (C_ROUGE if a == _courant and not fait else Color("4a3638"))
	var st := _style(Color(0.055, 0.035, 0.04, 0.95), bord, 16, 1)
	st.set_content_margin_all(14)
	_panneau.add_theme_stylebox_override("panel", st)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	_panneau.add_child(vb)

	var entete_partie := partie.to_upper()
	if a < 13:
		entete_partie = "PARTIE %s · %s" % ["I" if a <= 4 else ("II" if a <= 8 else "III"), entete_partie]
	vb.add_child(_label(entete_partie, 11, COULEURS_PARTIE.get(partie, C_OR), true))
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 10)
	vb.add_child(tete)
	tete.add_child(_label("Acte " + ROMAINS[a], 28, C_OR, true))
	var lieu := _label(LIEUX[a - 1].lieu, 13, C_DOUX)
	lieu.size_flags_vertical = Control.SIZE_SHRINK_END
	tete.add_child(lieu)
	var titre := _label(str(acte.get("titre", "")), 19, C_TEXTE, true)
	titre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(titre)

	# Vignette de l'illustration de l'Acte
	var tex := ActesData.get_image(a)
	if tex != null:
		var cadre := Panel.new()
		cadre.custom_minimum_size = Vector2(0, 62)
		cadre.clip_contents = true
		cadre.add_theme_stylebox_override("panel", _style(Color("1e1416"), Color("4a3638"), 10, 1))
		var img := TextureRect.new()
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if not ouvert:
			img.modulate = Color(0.35, 0.32, 0.32)
		cadre.add_child(img)
		vb.add_child(cadre)

	# Boss et set d'Échos
	var grille := GridContainer.new()
	grille.columns = 2
	grille.add_theme_constant_override("h_separation", 8)
	vb.add_child(grille)
	var set_id: String = Echos.SET_PAR_ACTE.get(a, "")
	var nom_set := str(Echos.SETS[set_id]["nom"]) if Echos.SETS.has(set_id) else "?"
	grille.add_child(_case_info("BOSS", LIEUX[a - 1].boss))
	grille.add_child(_case_info("ÉCHOS", "Set " + nom_set))

	# Les 6 chapitres
	var n_faits := 0
	for c in range(1, 7):
		if ActesData.est_termine(a, c):
			n_faits += 1
	var entete := HBoxContainer.new()
	vb.add_child(entete)
	var lc := _label("Chapitres", 12, C_DOUX)
	lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entete.add_child(lc)
	entete.add_child(_label("%d / 6" % n_faits, 12, C_DOUX))
	var en_cours: int = _chapitre_en_cours(a) if ouvert else 0
	var chapitres: Array = acte.get("chapitres", [])
	for c in range(1, 7):
		var t := str(chapitres[c - 1].get("titre", "")) if c - 1 < chapitres.size() else ""
		vb.add_child(_ligne_chapitre(a, c, t, c == en_cours))

	var pousse := Control.new()
	pousse.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(pousse)

	if ouvert and en_cours > 0:
		var principal := _bouton("Continuer : chapitre %d" % en_cours, 16, true)
		principal.custom_minimum_size = Vector2(0, 44)
		principal.pressed.connect(_ouvrir_chapitre.bind(a, en_cours))
		vb.add_child(principal)
	elif ouvert:
		var fini := _label("Acte terminé : touche un chapitre pour le revoir ou le rejouer.", 13, C_OR)
		fini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fini.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(fini)
	else:
		var l := _label("Termine l'Acte %s pour ouvrir cette région" % ROMAINS[a - 1], 13, C_DOUX)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var p := PanelContainer.new()
		var sp := _style(Color(0, 0, 0, 0), Color("5a4245"), 22, 1)
		sp.set_content_margin_all(12)
		p.add_theme_stylebox_override("panel", sp)
		p.add_child(l)
		vb.add_child(p)


func _case_info(titre: String, valeur: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var st := _style(Color("1e1416"), Color(0, 0, 0, 0), 8, 0)
	st.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	v.add_child(_label(titre, 10, Color("8e7f72"), true))
	var l := _label(valeur, 13, C_TEXTE, true)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(140, 0)
	v.add_child(l)
	return p


func _ligne_chapitre(a: int, c: int, titre: String, courant: bool) -> Button:
	var fait := ActesData.est_termine(a, c)
	var ouvert := ActesData.chapitre_debloque(a, c)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.custom_minimum_size = Vector2(0, 28)
	var icone := "✔" if fait else ("▶" if courant else ("•" if ouvert else "✕"))
	b.text = "%s   %d   %s" % [icone, c, titre]
	b.add_theme_font_size_override("font_size", 13)
	var couleur := Color("d8ccbe") if fait else (Color.WHITE if courant else (C_TEXTE if ouvert else Color("7a6e68")))
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(k, couleur)
	var fond := Color("3a1418") if courant else Color(0, 0, 0, 0)
	var st := _style(fond, C_ROUGE if courant else Color(0, 0, 0, 0), 8, 1)
	st.content_margin_left = 10
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("disabled", st)
	var survol := _style(Color(0.2, 0.1, 0.11, 0.9), C_OR, 8, 1)
	survol.content_margin_left = 10
	b.add_theme_stylebox_override("hover", survol)
	b.add_theme_stylebox_override("pressed", survol)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "Voir le chapitre"
	b.pressed.connect(_ouvrir_chapitre.bind(a, c))
	return b


# =====================================================================
# Barre du haut et légende
# =====================================================================

func _creer_hud() -> void:
	var barre := _boite(Rect2(0, 0, 1280, 60), Color(0.04, 0.024, 0.027, 0.85))
	barre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boite(Rect2(0, 60, 1280, 1), Color(C_OR, 0.35)).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var retour := _bouton("←  Menu", 15, false)
	_placer(retour, Rect2(14, 10, 104, 40))
	retour.pressed.connect(_retour)
	var t := _label("LES TERRES DES VALCENDRE", 20, C_OR, true)
	_placer(t, Rect2(132, 6, 420, 26))
	var p := _label("Histoire principale · %d / %d chapitres" % [_chapitres_termines(), ActesData.nb_chapitres_visibles()], 12, C_DOUX)
	_placer(p, Rect2(132, 32, 420, 18))
	var journal := _bouton("✎  Journal", 15, false)
	journal.tooltip_text = "Revoir les scènes de l'histoire déjà vues"
	_placer(journal, Rect2(820, 10, 120, 40))
	journal.pressed.connect(func(): FenetreJournal.ouvrir(self))
	var st := _style(Color(0.03, 0.02, 0.024, 0.85), Color("4a3638"), 18, 1)
	st.content_margin_left = 12
	st.content_margin_right = 12
	_lbl_stamina = CaseStamina.new()
	_placer(_lbl_stamina, Rect2(950, 7, 190, 46))
	_lbl_or = _label("", 14, C_TEXTE, true)
	_lbl_or.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_or.add_theme_stylebox_override("normal", st)
	_placer(_lbl_or, Rect2(1148, 12, 118, 36))


func _creer_legende() -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var p := PanelContainer.new()
	var st := _style(Color(0.04, 0.024, 0.027, 0.75), Color(0, 0, 0, 0), 14, 0)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", st)
	p.add_child(h)
	_placer(p, Rect2(96, 72, 0, 0))
	for e in [["Terminé", Color("5e1a20"), C_OR], ["En cours", C_ROUGE, Color("ffd27a")], ["À découvrir", Color("241c1d"), Color("4a3e3c")]]:
		var pastille := Panel.new()
		pastille.custom_minimum_size = Vector2(12, 12)
		pastille.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pastille.add_theme_stylebox_override("panel", _style(e[1], e[2], 6, 2))
		h.add_child(pastille)
		h.add_child(_label(e[0], 12, C_DOUX))


func _maj_ressources() -> void:
	_lbl_stamina.maj()
	_lbl_or.text = "● " + _nombre(Sauvegarde.get_or())


func _nombre(n: int) -> String:
	var s := str(absi(n))
	var r := ""
	while s.length() > 3:
		r = " " + s.right(3) + r
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + r


# =====================================================================
# Actions
# =====================================================================

func _lancer(a: int, c: int) -> void:
	if not ActesData.chapitre_debloque(a, c):
		return
	ActesData.acte_courant = a
	ActesData.chapitre_courant = c
	ActesData.scene_precedente = scene_file_path
	acte_choisi = a
	get_tree().change_scene_to_file(SCENE_PLATEAU)


func _retour() -> void:
	var cible := scene_retour
	if cible == "":
		cible = ActesData.scene_menu
	if cible == "":
		cible = ProjectSettings.get_setting("application/run/main_scene", "")
	UiCommun.aller(get_tree(), cible)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if is_instance_valid(_fenetre):
			_fermer_chapitre()
		else:
			_retour()
		get_viewport().set_input_as_handled()


# =====================================================================
# Fenêtre d'informations d'un chapitre
# =====================================================================

func _ouvrir_chapitre(a: int, c: int) -> void:
	Audio.son("clic")
	_fermer_chapitre()
	var ouvert := ActesData.chapitre_debloque(a, c)
	var fait := ActesData.est_termine(a, c)
	var chap := ActesData.get_chapitre(a, c)

	# Voile sombre : un clic à côté de la fenêtre la ferme
	var voile := Button.new()
	voile.flat = true
	voile.focus_mode = Control.FOCUS_NONE
	voile.add_theme_stylebox_override("normal", _style(Color(0, 0, 0, 0.72), Color(0, 0, 0, 0), 0, 0))
	voile.add_theme_stylebox_override("hover", _style(Color(0, 0, 0, 0.72), Color(0, 0, 0, 0), 0, 0))
	voile.add_theme_stylebox_override("pressed", _style(Color(0, 0, 0, 0.72), Color(0, 0, 0, 0), 0, 0))
	voile.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	voile.pressed.connect(_fermer_chapitre)
	_placer(voile, Rect2(Vector2.ZERO, BASE))
	_fenetre = voile

	# Cadre avec l'illustration de l'Acte en fond
	var r := Rect2(150, 64, 980, 600)
	var cadre := Panel.new()
	cadre.clip_contents = true
	cadre.mouse_filter = Control.MOUSE_FILTER_STOP
	var bord := C_VIOLET if a == 13 else (C_OR if ouvert else Color("5a4245"))
	cadre.add_theme_stylebox_override("panel", _style(Color("0e0809"), bord, 18, 2))
	_placer(cadre, r, voile)
	var tex := ActesData.get_image(a)
	if tex != null:
		var img := TextureRect.new()
		img.texture = tex
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img.modulate = Color(0.95, 0.92, 0.92) if ouvert else Color(0.62, 0.58, 0.58)
		img.position = Vector2(2, 2)
		img.size = r.size - Vector2(4, 4)
		cadre.add_child(img)
	# Dégradé : sombre à gauche (texte lisible), l'image respire à droite
	var grad := Gradient.new()
	grad.set_color(0, Color(0.03, 0.018, 0.02, 0.94))
	grad.set_color(1, Color(0.03, 0.018, 0.02, 0.0))
	grad.add_point(0.5, Color(0.03, 0.018, 0.02, 0.78))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	var voile_img := TextureRect.new()
	voile_img.texture = gt
	voile_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	voile_img.stretch_mode = TextureRect.STRETCH_SCALE
	voile_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	voile_img.position = Vector2(2, 2)
	voile_img.size = r.size - Vector2(4, 4)
	cadre.add_child(voile_img)

	var marge := MarginContainer.new()
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		marge.add_theme_constant_override(k, 22)
	marge.position = Vector2.ZERO
	marge.size = r.size
	cadre.add_child(marge)
	var colonnes := HBoxContainer.new()
	colonnes.add_theme_constant_override("separation", 22)
	marge.add_child(colonnes)

	# ---------- Colonne gauche : récit, niveaux, ennemis ----------
	var g := VBoxContainer.new()
	g.add_theme_constant_override("separation", 8)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colonnes.add_child(g)
	g.add_child(_label("ACTE %s · %s  —  CHAPITRE %d" % [ROMAINS[a], LIEUX[a - 1].lieu.to_upper(), c], 12, COULEURS_PARTIE.get(str(ActesData.get_acte(a).get("partie", "")), C_OR), true))
	var titre := _label(str(chap.get("titre", "Chapitre %d" % c)), 26, C_TEXTE, true)
	titre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	g.add_child(titre)
	var statut := "✔  Terminé : tu peux le rejouer" if fait else ("▶  Disponible" if ouvert else "✕  Verrouillé")
	g.add_child(_label(statut, 13, C_OR if fait else (Color("ffd27a") if ouvert else Color("a08a84")), true))
	var desc := _label(str(chap.get("description", "")), 14, C_DOUX)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(520, 0)
	g.add_child(desc)

	var infos := _infos_plateau(a, c)
	var niv := Rencontres.niveau_attendu(a, c)
	var max_bonus := 0
	for v in Rencontres.BONUS_NIVEAU.values():
		max_bonus = maxi(max_bonus, int(v))
	var grille := GridContainer.new()
	grille.columns = 4
	grille.add_theme_constant_override("h_separation", 8)
	grille.add_theme_constant_override("v_separation", 8)
	g.add_child(grille)
	grille.add_child(_case_fenetre("NIVEAU CONSEILLÉ", "Niv. %d" % niv))
	var niv_max := mini(niv + max_bonus, UnitesData.NIVEAU_MAX)
	grille.add_child(_case_fenetre("ENNEMIS", "Niv. %d" % niv if niv_max <= niv else "Niv. %d à %d" % [niv, niv_max]))
	grille.add_child(_case_fenetre("STAMINA", "⚡ %d minimum" % int(infos["stamina"])))
	grille.add_child(_case_fenetre("PLATEAU", "%d cases" % int(infos["cases"])))

	g.add_child(_label("Créatures de la région", 12, C_DOUX, true))
	var pool: Dictionary = Rencontres.POOLS.get(a, {})
	var ligne := HFlowContainer.new()
	ligne.add_theme_constant_override("h_separation", 8)
	ligne.add_theme_constant_override("v_separation", 8)
	g.add_child(ligne)
	var vus: Array = []
	for id in pool.get("monstres", []) + pool.get("gardiens", []):
		var sid := str(id)
		if sid in vus or UnitesData.get_unite(sid).is_empty():
			continue
		vus.append(sid)
		ligne.add_child(_vignette_ennemi(sid, 46))
	var n_vus := 0
	for sid in vus:
		if Sauvegarde.est_decouvert(sid):
			n_vus += 1
	g.add_child(_label("%d / %d au Bestiaire · les créatures inconnues restent cachées" % [n_vus, vus.size()], 11, Color("8e7f72")))

	var pousse := Control.new()
	pousse.size_flags_vertical = Control.SIZE_EXPAND_FILL
	g.add_child(pousse)

	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 12)
	g.add_child(boutons)
	var fermer := _bouton("Fermer", 16, false)
	fermer.custom_minimum_size = Vector2(130, 46)
	fermer.pressed.connect(_fermer_chapitre)
	boutons.add_child(fermer)
	if ouvert:
		var jouer := _bouton("▶  Rejouer" if fait else "▶  Jouer", 18, true)
		jouer.custom_minimum_size = Vector2(220, 46)
		jouer.pressed.connect(_lancer.bind(a, c))
		boutons.add_child(jouer)
	else:
		var cond := "Termine le chapitre %d de l'Acte %s pour l'ouvrir." % [c - 1, ROMAINS[a]] if c > 1 \
			else "Termine l'Acte %s pour ouvrir cette région." % ROMAINS[a - 1]
		var lc := _label("🔒  " + cond, 13, C_DOUX)
		lc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		boutons.add_child(lc)

	# ---------- Colonne droite : boss, plateau, butin ----------
	var d := VBoxContainer.new()
	d.add_theme_constant_override("separation", 8)
	d.custom_minimum_size = Vector2(300, 0)
	colonnes.add_child(d)
	var boss_id := str(pool.get("boss", "")) if c == 6 else ""
	if c < 6 and not (pool.get("gardiens", []) as Array).is_empty():
		var gs: Array = pool["gardiens"]
		boss_id = str(gs[(c - 1) % gs.size()])
	d.add_child(_bloc_boss(boss_id, c == 6, LIEUX[a - 1].boss if c == 6 else ""))

	var bp := _bloc_fenetre("SUR LE PLATEAU")
	d.add_child(bp)
	var vp: VBoxContainer = bp.get_child(0)
	var types: Dictionary = infos["types"]
	for t in [PlateauGenerateur.Type.COMBAT, PlateauGenerateur.Type.ELITE, PlateauGenerateur.Type.GARDIEN,
			PlateauGenerateur.Type.COFFRE, PlateauGenerateur.Type.SOIN, PlateauGenerateur.Type.MYSTERE, PlateauGenerateur.Type.PIEGE]:
		if int(types.get(t, 0)) > 0:
			vp.add_child(_ligne_info(str(PlateauGenerateur.NOMS[t]), "× %d" % int(types[t])))
	vp.add_child(_ligne_info("Boss", "× 1"))

	var bl := _bloc_fenetre("BUTIN")
	d.add_child(bl)
	var vl: VBoxContainer = bl.get_child(0)
	var set_id: String = Echos.SET_PAR_ACTE.get(a, "")
	if Echos.SETS.has(set_id):
		var emp := clampi(c, 1, 6)
		vl.add_child(_ligne_info("Set d'Échos", str(Echos.SETS[set_id]["nom"])))
		vl.add_child(_ligne_info("Emplacement", str(Echos.EMPLACEMENTS[emp]["nom"])))
	vl.add_child(_ligne_info("Or et expérience", "à chaque combat"))

	if c in FinHistoire.CHAPITRES_INVITE.get(a, []):
		var bk := _bloc_fenetre("RENFORT")
		d.add_child(bk)
		var lk := _label("Kaël combat à tes côtés dans ce chapitre (invité).", 13, Color("ff9a9a"))
		lk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		(bk.get_child(0) as VBoxContainer).add_child(lk)


func _fermer_chapitre() -> void:
	if is_instance_valid(_fenetre):
		_fenetre.queue_free()
	_fenetre = null


## Cases du plateau par type et stamina minimale (chemin le moins coûteux du départ au boss).
func _infos_plateau(a: int, c: int) -> Dictionary:
	var plateau := PlateauGenerateur.generer(a, c)
	var noeuds: Array = plateau.get("noeuds", [])
	var types := {}
	var par_id := {}
	for n in noeuds:
		par_id[int(n["id"])] = n
		var t := int(n["type"])
		types[t] = int(types.get(t, 0)) + 1
	var cout := func(id: int) -> int:
		var n: Dictionary = par_id[id]
		if not PlateauGenerateur.est_combat(int(n["type"])):
			return 0
		return int(Sauvegarde.COUT_STAMINA_AVENTURE[Rencontres.type_rencontre(n, c)])
	var depart := int(plateau.get("depart", -1))
	var boss := int(plateau.get("boss", -1))
	var stamina := 0
	if par_id.has(depart) and par_id.has(boss):
		var dist := {depart: 0}
		var a_voir := [depart]
		while not a_voir.is_empty():
			var meilleur := 0
			for i in a_voir.size():
				if int(dist[a_voir[i]]) < int(dist[a_voir[meilleur]]):
					meilleur = i
			var u: int = a_voir[meilleur]
			a_voir.remove_at(meilleur)
			if u == boss:
				break
			for v in par_id[u].get("voisins", []):
				var vid := int(v)
				if not par_id.has(vid):
					continue
				var nd: int = int(dist[u]) + int(cout.call(vid))
				if not dist.has(vid) or nd < int(dist[vid]):
					dist[vid] = nd
					if not vid in a_voir:
						a_voir.append(vid)
		stamina = int(dist.get(boss, 0))
	return {"types": types, "cases": noeuds.size(), "stamina": stamina}


func _case_fenetre(titre: String, valeur: String) -> PanelContainer:
	var p := PanelContainer.new()
	var st := _style(Color(0.08, 0.05, 0.055, 0.85), Color("4a3638"), 8, 1)
	st.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", st)
	p.custom_minimum_size = Vector2(124, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	v.add_child(_label(titre, 10, Color("8e7f72"), true))
	v.add_child(_label(valeur, 15, C_TEXTE, true))
	return p


func _bloc_fenetre(titre: String) -> PanelContainer:
	var p := PanelContainer.new()
	var st := _style(Color(0.05, 0.03, 0.035, 0.62), Color("4a3638"), 10, 1)
	st.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	v.add_child(_label(titre, 11, C_OR, true))
	return p


func _ligne_info(nom: String, valeur: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := _label(nom, 13, C_DOUX)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(_label(valeur, 13, C_TEXTE, true))
	return h


## Portrait d'un ennemi : « ? » tant qu'il n'est pas au Bestiaire.
func _vignette_ennemi(id: String, d: float) -> Control:
	if Sauvegarde.est_decouvert(id):
		var p := UiCommun.portrait(id, d)
		p.mouse_filter = Control.MOUSE_FILTER_PASS
		p.tooltip_text = str(UnitesData.get_unite(id).get("nom", id))
		return p
	var inconnu := Panel.new()
	inconnu.custom_minimum_size = Vector2(d, d)
	inconnu.mouse_filter = Control.MOUSE_FILTER_PASS
	inconnu.tooltip_text = "Créature inconnue"
	inconnu.add_theme_stylebox_override("panel", _style(Color("1a1213"), Color("4a3e3c"), int(d / 2), 2))
	var q := _label("?", int(d * 0.45), Color("7a6e68"), true)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	q.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inconnu.add_child(q)
	return inconnu


func _bloc_boss(id: String, boss_acte: bool, nom_scenario := "") -> PanelContainer:
	var p := _bloc_fenetre("BOSS DE L'ACTE" if boss_acte else "CHEF DU CHAPITRE")
	var v: VBoxContainer = p.get_child(0)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	if id == "" or UnitesData.get_unite(id).is_empty():
		h.add_child(_label("?", 20, C_DOUX, true))
		return p
	var connu := Sauvegarde.est_decouvert(id)
	h.add_child(_vignette_ennemi(id, 72))
	var t := VBoxContainer.new()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(t)
	var nom := _label(str(UnitesData.get_unite(id).get("nom", id)) if connu else (nom_scenario if nom_scenario != "" else "Inconnu"), 16, Color("ff9a9a") if boss_acte else C_TEXTE, true)
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nom.custom_minimum_size = Vector2(180, 0)
	t.add_child(nom)
	var sous := "Le vaincre achève l'Acte." if boss_acte else "Attend au bout du plateau."
	t.add_child(_label(sous, 12, C_DOUX))
	return p


# =====================================================================
# Outils de dessin
# =====================================================================

func _placer(ctrl: Control, r: Rect2, parent: Control = null) -> void:
	(parent if parent != null else _ui).add_child(ctrl)
	ctrl.position = r.position
	ctrl.size = r.size


func _boite(r: Rect2, couleur: Color) -> ColorRect:
	var c := ColorRect.new()
	c.color = couleur
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placer(c, r)
	return c


func _points(liste: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in range(0, liste.size() - 1, 2):
		p.append(Vector2(liste[i], liste[i + 1]))
	return p


func _polygone(liste: Array, couleur: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = _points(liste)
	p.color = couleur
	_ui.add_child(p)
	return p


func _ligne(liste: Array, couleur: Color, largeur: float) -> void:
	var l := Line2D.new()
	l.points = _points(liste)
	l.width = largeur
	l.default_color = couleur
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	_ui.add_child(l)


func _triangle(t: Array, fond: Color, bord: Color) -> void:
	var x := float(t[0])
	var y := float(t[1])
	var pts := [x, y, x + t[2], y - t[3], x + t[2] * 2, y]
	_polygone(pts, fond)
	if bord.a > 0.0:
		_ligne(pts + [x, y], bord, 1.5)


func _ellipse(c: Vector2, r: Vector2, fond: Color, bord: Color) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var ang := TAU * i / 32.0
		pts.append(c + Vector2(cos(ang) * r.x, sin(ang) * r.y))
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = fond
	_ui.add_child(p)
	if bord.a > 0.0:
		var l := Line2D.new()
		l.points = pts
		l.add_point(pts[0])
		l.width = 2.0
		l.default_color = bord
		_ui.add_child(l)


func _texte_partie(texte: String, centre: Vector2, couleur: Color) -> void:
	var l := _label(texte, 17, couleur)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placer(l, Rect2(centre.x - 200, centre.y - 18, 400, 24))


func _style(fond: Color, bord: Color, rayon: int, epais: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fond
	s.border_color = bord
	s.set_border_width_all(epais)
	s.set_corner_radius_all(rayon)
	s.anti_aliasing = true
	return s


func _label(texte: String, taille: int, couleur: Color, gras := false) -> Label:
	var l := Label.new()
	l.text = texte
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 4 if gras else 2)
	return l


func _bouton(texte: String, taille: int, principal: bool) -> Button:
	var b := Button.new()
	b.text = texte
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", taille)
	b.add_theme_color_override("font_color", Color.WHITE if principal else C_TEXTE)
	b.add_theme_color_override("font_hover_color", Color("ffd27a") if not principal else Color.WHITE)
	var fond := C_ROUGE if principal else Color(0.12, 0.08, 0.086, 0.95)
	var bord := C_OR if principal else Color("4a3638")
	b.add_theme_stylebox_override("normal", _style(fond, bord, 22, 1))
	b.add_theme_stylebox_override("hover", _style(fond.lightened(0.12), Color("ffd27a"), 22, 1))
	b.add_theme_stylebox_override("pressed", _style(fond.lightened(0.18), Color("ffd27a"), 22, 1))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return b
