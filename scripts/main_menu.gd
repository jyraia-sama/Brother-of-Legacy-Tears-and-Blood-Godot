extends Control
## MENU PRINCIPAL « Les Deux Frères » - Brothers of Legacy : Tears and Blood
##
## L'écran est coupé en deux par une fente dorée :
##   - à gauche LA LARME (combattre, le grand frère) : Aventure, Arène, Boss de Monde, Tours, Donjons, Expédition, Ménagerie ;
##   - à droite LE SANG (l'armée) : Deck, Invocation, Fusion, Échos, Reliquaire, Bestiaire ;
##   - en haut : le compte (blason = Mon héros, nom = Compte, titre, XP de compte),
##     les ressources (stamina, or, gemmes, Éclats) et Aide / Nouveautés / Menu ;
##   - au centre : l'emblème et le guide Premiers pas ;
##   - en bas : le Royaume (Quêtes, Succès, Boutique, Guilde, Social, Courrier).
##
## Tout est dessiné sur une surface de 1280 x 720 agrandie pour remplir l'écran.
## IMAGE DE FOND : dépose l'illustration ChatGPT (16:9) dans assets/ui/menu_freres.png.
## Sans elle, le jeu dessine le fond lui-même (deux couleurs, le grand frère et Kaël).
## Garde dans l'image une LUNE ROUGE en haut côté grand frère et un BLASON au centre :
## ce sont les deux secrets (RECT_LUNE et RECT_EMBLEME ci-dessous).
## F1 : affiche les zones des secrets (pour les recaler sur l'image).

const BG_PATH := "res://assets/ui/menu_freres.png"
const IMG_GRAND_FRERE := "res://assets/plateaux/pion_aine.png"
const IMG_KAEL := "res://assets/personnages/kael_valcendre.png"
const IMG_BLASON := "res://assets/personnages/aine.png"

const BASE := Vector2(1280, 720)

const C_LARME := Color("f0c2a0")
const C_SANG := Color("c8c2f0")
const C_OR := Color("c9a45c")
const C_TEXTE := Color("ede4d8")
const C_DOUX := Color("b3a597")
const C_ROUGE := Color("a3242f")
const C_PASTILLE := Color("d23a46")
const C_BARRE := Color(0.03, 0.02, 0.024, 0.8)
const C_CASE := Color(0.04, 0.024, 0.027, 0.74)

const LARME := [
	{"id": "aventure",   "titre": "Aventure"},
	{"id": "arene",      "titre": "Arène"},
	{"id": "boss_monde", "titre": "Boss de Monde"},
	{"id": "tours",      "titre": "Tours"},
	{"id": "donjon",     "titre": "Donjons"},
	{"id": "expedition", "titre": "Expédition"},
	{"id": "menagerie",  "titre": "Ménagerie"},
]
const SANG := [
	{"id": "deck",       "titre": "Deck & Équipe"},
	{"id": "invocation", "titre": "Autel d'Invocation"},
	{"id": "fusion",     "titre": "Autel de Fusion"},
	{"id": "echos",      "titre": "Échos Sanguins"},
	{"id": "reliquaire", "titre": "Le Reliquaire"},
	{"id": "bestiaire",  "titre": "Bestiaire"},
]
const ROYAUME_GAUCHE := [
	{"id": "quetes",   "titre": "Quêtes",   "icone": "✔"},
	{"id": "succes",   "titre": "Succès",   "icone": "★"},
	{"id": "boutique", "titre": "Boutique", "icone": "♦"},
]
const ROYAUME_DROITE := [
	{"id": "guilde",   "titre": "Guilde",   "icone": "⚑"},
	{"id": "social",   "titre": "Social",   "icone": "❤"},
	{"id": "courrier", "titre": "Courrier", "icone": "✉"},
]

# Secrets (coordonnées sur la surface 1280 x 720)
const RECT_LUNE := Rect2(470, 84, 54, 54)
const RECT_EMBLEME := Rect2(565, 262, 150, 150)

const ROMAINS := ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII"]

## Masque doux (portrait de Kaël) et masque rond (emblème).
const SHADER_FONDU := "shader_type canvas_item;
uniform float bord = 0.5;
uniform float douceur = 0.2;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float d = distance(UV, vec2(0.5));
	c.a *= smoothstep(bord, bord - douceur, d);
	COLOR = c * COLOR;
}"

var _ui: Control
var _image_fond := false
var _boutons := {}
var _zones_secretes: Array[Button] = []
var _debug := false

var _lbl_stamina: Label
var _lbl_recharge: Label
var _barre_stamina: ProgressBar
var _lbl_or: Label
var _lbl_gemmes: Label
var _lbl_eclats: Label
var _lbl_niveau: Label
var _lbl_xp: Label
var _barre_xp: ProgressBar
var _bouton_compte: Button
var _fenetre_compte: FenetreCompte


func _ready() -> void:
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
	_creer_fond()

	# Jeu en ligne configuré et pas encore de compte ouvert : on propose de se connecter
	# (ou de jouer hors ligne) avant tout le reste, y compris le choix du héros.
	if EnLigne.doit_proposer_connexion():
		FenetreCompte.ouvrir(self, true, _apres_connexion_demarrage)
		return
	# Tout premier lancement (ou après "Nouvelle partie") : choix du héros de départ
	if not Sauvegarde.a_choisi_heros_depart():
		get_tree().change_scene_to_file.call_deferred(EcranChoixHeros.SCENE)
		return

	Courrier.verifier()
	Tutoriel.preparer_etape()

	_creer_barre_haut()
	_creer_colonne(LARME, "LA LARME", "Combattre", C_LARME, true)
	_creer_colonne(SANG, "LE SANG", "L'armée", C_SANG, false)
	_creer_embleme()
	_creer_barre_bas()
	_creer_secrets()
	_creer_guide()
	_maj_pastilles()
	_maj_ressources()

	# La stamina se recharge avec le temps : on rafraîchit l'affichage chaque seconde
	var minuterie := Timer.new()
	minuterie.wait_time = 1.0
	minuterie.autostart = true
	minuterie.timeout.connect(_maj_ressources)
	add_child(minuterie)

	# Le jeu vient d'être mis à jour : on montre les nouveautés
	FenetreChangelog.verifier_mise_a_jour(self)
	EnLigne.etat_change.connect(_sur_etat_compte)
	_sur_etat_compte()


## Agrandit la surface 1280 x 720 pour remplir l'écran (centrée).
func _ajuster_ui() -> void:
	if not is_instance_valid(_ui):
		return
	var vp := get_viewport_rect().size
	var e := minf(vp.x / BASE.x, vp.y / BASE.y)
	_ui.scale = Vector2(e, e)
	_ui.position = ((vp - BASE * e) / 2.0).floor()


# =====================================================================
# Fond
# =====================================================================

func _creer_fond() -> void:
	if ResourceLoader.exists(BG_PATH):
		var fond := TextureRect.new()
		fond.texture = load(BG_PATH)
		fond.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fond.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fond.size = BASE
		_ui.add_child(fond)
		_image_fond = true
		return
	# Fond dessiné : la Larme (rouge) et le Sang (bleu nuit), séparés par une fente dorée
	_polygone([Vector2(0, 0), Vector2(742, 0), Vector2(538, 720), Vector2(0, 720)], Color("3a1014"))
	_polygone([Vector2(742, 0), Vector2(1280, 0), Vector2(1280, 720), Vector2(538, 720)], Color("1a1830"))
	# Lueurs douces vers la fente
	_polygone([Vector2(560, 0), Vector2(742, 0), Vector2(538, 720), Vector2(356, 720)], Color(0.55, 0.12, 0.12, 0.25))
	_polygone([Vector2(742, 0), Vector2(924, 0), Vector2(720, 720), Vector2(538, 720)], Color(0.25, 0.25, 0.6, 0.22))
	_polygone([Vector2(739, 0), Vector2(745, 0), Vector2(541, 720), Vector2(535, 720)], C_OR)
	# Braises qui montent côté Larme, lumières bleues côté Sang
	_particules(Rect2(0, 700, 560, 20), Color(1.0, 0.45, 0.25, 0.8), true)
	_particules(Rect2(720, 0, 560, 20), Color(0.55, 0.6, 1.0, 0.7), false)
	# Le grand frère (figurine) et Kaël
	if ResourceLoader.exists(IMG_GRAND_FRERE):
		var gf := TextureRect.new()
		gf.texture = load(IMG_GRAND_FRERE)
		gf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gf.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gf.position = Vector2(305, 150)
		gf.size = Vector2(250, 440)
		gf.modulate = Color(1, 1, 1, 0.92)
		_ui.add_child(gf)
	if ResourceLoader.exists(IMG_KAEL):
		var k := TextureRect.new()
		k.texture = load(IMG_KAEL)
		k.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		k.stretch_mode = TextureRect.STRETCH_SCALE
		k.mouse_filter = Control.MOUSE_FILTER_IGNORE
		k.position = Vector2(735, 165)
		k.size = Vector2(280, 280)
		k.material = _materiau_fondu(0.5, 0.22)
		k.modulate = Color(1, 1, 1, 0.85)
		_ui.add_child(k)
	# La lune rouge (secret)
	var lune := Panel.new()
	lune.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sl := StyleBoxFlat.new()
	sl.bg_color = Color("8e1e22")
	sl.set_corner_radius_all(27)
	sl.shadow_color = Color(0.8, 0.1, 0.1, 0.45)
	sl.shadow_size = 14
	lune.add_theme_stylebox_override("panel", sl)
	lune.position = RECT_LUNE.position
	lune.size = RECT_LUNE.size
	_ui.add_child(lune)


func _polygone(points: Array, couleur: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array(points)
	p.color = couleur
	_ui.add_child(p)


func _particules(zone: Rect2, couleur: Color, vers_le_haut: bool) -> void:
	var p := CPUParticles2D.new()
	p.amount = 26
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = zone.size / 2.0
	p.position = zone.get_center()
	p.direction = Vector2(0, -1 if vers_le_haut else 1)
	p.spread = 18.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 70.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.5
	p.color = couleur
	var fondu := Gradient.new()
	fondu.set_color(0, Color(couleur, 0.0))
	fondu.add_point(0.2, couleur)
	fondu.set_color(fondu.get_point_count() - 1, Color(couleur, 0.0))
	p.color_ramp = fondu
	_ui.add_child(p)


func _materiau_fondu(bord: float, douceur: float) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = SHADER_FONDU
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("bord", bord)
	m.set_shader_parameter("douceur", douceur)
	return m


# =====================================================================
# Barre du haut : compte, ressources, Aide / Nouveautés / Menu
# =====================================================================

func _creer_barre_haut() -> void:
	var barre := _boite(Rect2(0, 0, 1280, 72), C_BARRE)
	barre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ligne := ColorRect.new()
	ligne.color = Color(C_OR, 0.35)
	ligne.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placer(ligne, Rect2(0, 72, 1280, 1))

	# --- Blason / héros : ouvre « Mon héros »
	var heros := Button.new()
	heros.focus_mode = Control.FOCUS_NONE
	heros.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	heros.tooltip_text = "Mon héros"
	var sh := _style(Color("2a1c1e"), C_OR, 28, 2)
	heros.add_theme_stylebox_override("normal", sh)
	var shh := _style(Color("3a2426"), Color("ffd27a"), 28, 2)
	heros.add_theme_stylebox_override("hover", shh)
	heros.add_theme_stylebox_override("pressed", shh)
	heros.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_placer(heros, Rect2(14, 8, 56, 56))
	heros.pressed.connect(_on_bouton.bind("heros"))
	_boutons["heros"] = heros
	if ResourceLoader.exists(IMG_BLASON):
		var b := TextureRect.new()
		b.texture = load(IMG_BLASON)
		b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		b.stretch_mode = TextureRect.STRETCH_SCALE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.material = _materiau_fondu(0.5, 0.02)
		b.position = Vector2(3, 3)
		b.size = Vector2(50, 50)
		heros.add_child(b)
	# Pastille du niveau de compte
	_lbl_niveau = _label("", 12, Color.WHITE, true)
	_lbl_niveau.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_niveau.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_niveau.add_theme_stylebox_override("normal", _style(C_ROUGE, C_OR, 9, 1))
	_placer(_lbl_niveau, Rect2(23, 54, 38, 18))

	# --- Nom (ouvre le compte), titre, XP de compte
	_bouton_compte = Button.new()
	_bouton_compte.flat = true
	_bouton_compte.focus_mode = Control.FOCUS_NONE
	_bouton_compte.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_bouton_compte.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_bouton_compte.add_theme_font_size_override("font_size", 16)
	_bouton_compte.add_theme_constant_override("outline_size", 4)
	_bouton_compte.add_theme_color_override("font_outline_color", Color.BLACK)
	_bouton_compte.pressed.connect(_ouvrir_compte)
	_placer(_bouton_compte, Rect2(78, 4, 300, 24))
	_maj_bouton_compte()
	var titre := Succes.titre_actuel()
	var lt := _label(titre if titre != "" else "Héritier des Valcendre", 12, C_OR)
	_placer(lt, Rect2(84, 27, 290, 16))
	_barre_xp = _barre(C_OR, Color("3a2a2c"))
	_placer(_barre_xp, Rect2(84, 48, 190, 8))
	_lbl_xp = _label("", 11, C_DOUX)
	_placer(_lbl_xp, Rect2(282, 43, 140, 16))

	# --- Ressources
	var x := 430.0
	# Stamina (avec barre et recharge)
	var st := _case_ressource(Rect2(x, 14, 182, 44), "⚡", Color("7fc2e8"), Color("163248"), "boutique", "Recharger la stamina")
	_lbl_stamina = _label("", 15, C_TEXTE, true)
	_placer(_lbl_stamina, Rect2(40, 3, 100, 18), st)
	_barre_stamina = _barre(Color("7fc2e8"), Color("22303a"))
	_placer(_barre_stamina, Rect2(40, 22, 98, 4), st)
	_lbl_recharge = _label("", 11, C_DOUX)
	_placer(_lbl_recharge, Rect2(40, 26, 104, 15), st)
	x += 190
	var orr := _case_ressource(Rect2(x, 14, 150, 44), "●", Color("e2be6a"), Color("3a2e14"), "boutique", "Obtenir de l'or")
	_lbl_or = _label("", 15, C_TEXTE, true)
	_placer(_lbl_or, Rect2(40, 4, 74, 18), orr)
	_placer(_label("Or", 11, C_DOUX), Rect2(40, 23, 74, 15), orr)
	x += 158
	var gem := _case_ressource(Rect2(x, 14, 136, 44), "◆", Color("c78be8"), Color("2e1a3a"), "boutique", "Boutique de gemmes")
	_lbl_gemmes = _label("", 15, C_TEXTE, true)
	_placer(_lbl_gemmes, Rect2(40, 4, 60, 18), gem)
	_placer(_label("Gemmes", 11, C_DOUX), Rect2(40, 23, 60, 15), gem)
	x += 144
	var ecl := _case_ressource(Rect2(x, 14, 104, 44), "✦", Color("f07a7a"), Color("3a1418"), "", "Éclats de Pacte Supérieur (lâchés par les boss)")
	_lbl_eclats = _label("", 15, C_TEXTE, true)
	_placer(_lbl_eclats, Rect2(40, 4, 60, 18), ecl)
	_placer(_label("Éclats", 11, C_DOUX), Rect2(40, 23, 60, 15), ecl)

	# --- Aide, Nouveautés, Menu
	var coins := [["aide", "?", "Aide"], ["nouveautes", "✎", "Nouveautés"], ["parametres", "☰", "Menu"]]
	for i in coins.size():
		var c: Array = coins[i]
		var r := Rect2(1100 + i * 58, 6, 48, 46)
		var b := _bouton_icone(c[1], r, c[2])
		b.pressed.connect(_on_bouton.bind(c[0]))
		_boutons[c[0]] = b
		var l := _label(c[2], 11, C_DOUX)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_placer(l, Rect2(r.position.x - 10, 53, 68, 15))

	if Sauvegarde.admin_actif():
		var adm := _label("MODE ADMIN ACTIF", 12, Color("ff5a4a"), true)
		adm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_placer(adm, Rect2(540, 612, 200, 16))


## Case de ressource : icône ronde + zone de texte (+ bouton « + » si une cible est donnée).
func _case_ressource(r: Rect2, icone: String, couleur: Color, fond_icone: Color, cible: String, aide: String) -> Panel:
	var p := Panel.new()
	p.tooltip_text = aide
	p.add_theme_stylebox_override("panel", _style(Color(0.03, 0.02, 0.024, 0.85), Color("4a3638"), 12, 1))
	_placer(p, r)
	var ic := _label(icone, 16, couleur)
	ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ic.add_theme_stylebox_override("normal", _style(fond_icone, Color(0, 0, 0, 0), 15, 0))
	_placer(ic, Rect2(6, 7, 30, 30), p)
	if cible != "":
		var plus := Button.new()
		plus.text = "+"
		plus.focus_mode = Control.FOCUS_NONE
		plus.tooltip_text = aide
		plus.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		plus.add_theme_font_size_override("font_size", 16)
		plus.add_theme_color_override("font_color", Color("f0d9b0"))
		plus.add_theme_stylebox_override("normal", _style(Color("3a1418"), C_OR, 8, 1))
		plus.add_theme_stylebox_override("hover", _style(Color("5a1e24"), Color("ffd27a"), 8, 1))
		plus.add_theme_stylebox_override("pressed", _style(Color("5a1e24"), Color("ffd27a"), 8, 1))
		plus.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		plus.pressed.connect(_on_bouton.bind(cible))
		_placer(plus, Rect2(r.size.x - 34, 8, 28, 28), p)
	return p


# =====================================================================
# Colonnes : la Larme et le Sang
# =====================================================================

func _creer_colonne(liste: Array, titre: String, sous_titre: String, couleur: Color, a_gauche: bool) -> void:
	var largeur := 262.0
	var x := 24.0 if a_gauche else BASE.x - 24.0 - largeur
	var y := 86.0
	var t := _label(titre, 26, couleur, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if a_gauche else HORIZONTAL_ALIGNMENT_RIGHT
	t.add_theme_constant_override("outline_size", 6)
	_placer(t, Rect2(x, y, largeur, 32))
	var st := _label(sous_titre, 12, couleur.darkened(0.15))
	st.horizontal_alignment = t.horizontal_alignment
	_placer(st, Rect2(x, y + 30, largeur, 16))
	y += 54
	for c in liste:
		var grand: bool = c["id"] == "aventure"
		var h := 64.0 if grand else 52.0
		_bouton_menu(c["id"], c["titre"], Rect2(x, y, largeur, h), a_gauche, grand)
		y += h + 8


func _bouton_menu(id: String, titre: String, r: Rect2, a_gauche: bool, grand: bool) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = titre
	var fond := Color(0.37, 0.08, 0.11, 0.9) if grand else C_CASE
	var bord := C_OR if grand else Color(1, 1, 1, 0.16)
	b.add_theme_stylebox_override("normal", _style(fond, bord, 12, 1 if not grand else 2))
	b.add_theme_stylebox_override("hover", _style(fond.lightened(0.12), Color("ffd27a"), 12, 2))
	b.add_theme_stylebox_override("pressed", _style(Color(0.55, 0.12, 0.1, 0.92), Color("ffd27a"), 12, 2))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_placer(b, r)
	b.pressed.connect(_on_bouton.bind(id))
	var alig := HORIZONTAL_ALIGNMENT_LEFT if a_gauche else HORIZONTAL_ALIGNMENT_RIGHT
	var nom := _label(titre, 22 if grand else 18, C_TEXTE if not grand else Color("fff0dc"), true)
	nom.horizontal_alignment = alig
	_placer(nom, Rect2(16, 6 if grand else 4, r.size.x - 32, 28 if grand else 24), b)
	var sous := _label(_sous_titre(id), 13, C_DOUX if not grand else Color("f0d9b0"))
	sous.horizontal_alignment = alig
	sous.clip_text = true
	sous.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_placer(sous, Rect2(16, 36 if grand else 28, r.size.x - 32, 18), b)
	_boutons[id] = b
	return b


## Petite ligne d'information sous le nom de chaque bouton.
func _sous_titre(id: String) -> String:
	match id:
		"aventure":
			return _prochain_chapitre()
		"arene":
			return "Combats JcJ et Arène classée"
		"boss_monde":
			if not BossMonde.est_debloque():
				return "Débloqué après l'Acte %s" % ROMAINS[BossMonde.DEBLOCAGE.x]
			var boss: Dictionary = BossMonde.BOSS[BossMonde.boss_du_jour()]
			return "%s · %d essai%s" % [boss["titre"], BossMonde.essais_restants(),
				"s" if BossMonde.essais_restants() > 1 else ""]
		"tours":
			return "Enfer et Paradis · reset %s" % _duree_courte(Calendrier.secondes_avant_semaine())
		"donjon":
			return "6 donjons · ressources d'évolution"
		"expedition":
			return "Marche Maudite et Compagnie"
		"menagerie":
			return "Familiers et terrains de chasse"
		"deck":
			return "Équipe %d / 5 · Avant et Arrière" % Sauvegarde.get_equipe().size()
		"invocation":
			return "Pactes Doré, Supérieur et Sauvage"
		"fusion":
			return "Éveil, Absorption, Évolution"
		"echos":
			return "Équiper et améliorer"
		"reliquaire":
			return "Forge, coffres et Atelier"
		"bestiaire":
			return "%d unités découvertes" % Sauvegarde.nombre_decouverts()
	return ""


func _duree_courte(s: int) -> String:
	if s >= 86400:
		return "%d j" % int(s / 86400)
	if s >= 3600:
		return "%d h" % int(s / 3600)
	return "%d min" % maxi(1, int(s / 60))


func _prochain_chapitre() -> String:
	var dernier := ActesData.NB_ACTES_NORMAUX + (1 if ActesData.acte_debloque(13) else 0)
	for a in range(1, dernier + 1):
		for c in range(1, 7):
			if not ActesData.est_termine(a, c):
				return "Acte %s · Chapitre %d — Continuer" % [ROMAINS[a], c]
	return "Histoire terminée · tous les modes"


# =====================================================================
# Centre : emblème (secret du Bélier) et Premiers pas
# =====================================================================

func _creer_embleme() -> void:
	if _image_fond:
		return
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := _style(Color("120b0d"), C_OR, 75, 3)
	s.shadow_color = Color(0, 0, 0, 0.6)
	s.shadow_size = 18
	p.add_theme_stylebox_override("panel", s)
	_placer(p, RECT_EMBLEME)
	if ResourceLoader.exists(IMG_BLASON):
		var b := TextureRect.new()
		b.texture = load(IMG_BLASON)
		b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		b.stretch_mode = TextureRect.STRETCH_SCALE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.material = _materiau_fondu(0.5, 0.02)
		b.position = Vector2(5, 5)
		b.size = RECT_EMBLEME.size - Vector2(10, 10)
		p.add_child(b)


func _creer_guide() -> void:
	if not Tutoriel.visible():
		return
	var i := Tutoriel.etape_courante()
	var e: Dictionary = Tutoriel.ETAPES[i]
	var fait := Tutoriel.faite(e["id"])
	var p := PanelContainer.new()
	var st := _style(Color(0.04, 0.024, 0.027, 0.92), C_OR if fait else Color("8a6a3a"), 12, 1)
	st.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", st)
	_placer(p, Rect2(500, 424, 280, 150))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 3)
	p.add_child(vb)
	var tete := HBoxContainer.new()
	vb.add_child(tete)
	var t := _label("PREMIERS PAS  %d / %d" % [i + 1, Tutoriel.ETAPES.size()], 12, C_OR, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	var x := Button.new()
	x.text = "×"
	x.flat = true
	x.focus_mode = Control.FOCUS_NONE
	x.tooltip_text = "Masquer le guide (réaffichable dans les Paramètres)"
	x.add_theme_font_size_override("font_size", 18)
	x.custom_minimum_size = Vector2(28, 22)
	x.pressed.connect(func():
		FenetreSimple.confirmer(self, "Masquer le guide ?", "Tu pourras le réafficher dans les Paramètres.", "Masquer", func():
			Tutoriel.masquer(true)
			get_tree().reload_current_scene()))
	tete.add_child(x)
	var progres := _barre(C_OR, Color("3a2a2c"))
	progres.custom_minimum_size = Vector2(0, 4)
	progres.max_value = Tutoriel.ETAPES.size()
	progres.value = i + (1 if fait else 0)
	vb.add_child(progres)
	vb.add_child(_label(str(e["titre"]) + ("  — fait !" if fait else ""), 15, Color("ffd27a"), true))
	var d := _label(e["texte"], 12, C_TEXTE)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(d)
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 8)
	vb.add_child(bas)
	var r := _label(Quetes.texte_recompense(e["recompense"]), 11, Color("ffb070"))
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bas.add_child(r)
	var b := Button.new()
	b.text = "Réclamer" if fait else "Y aller"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(96, 32)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_stylebox_override("normal", _style(C_ROUGE, C_OR, 16, 1))
	b.add_theme_stylebox_override("hover", _style(C_ROUGE.lightened(0.15), Color("ffd27a"), 16, 1))
	b.add_theme_stylebox_override("pressed", _style(C_ROUGE.lightened(0.15), Color("ffd27a"), 16, 1))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if fait:
		b.pressed.connect(_reclamer_guide)
	else:
		b.pressed.connect(_on_bouton.bind(str(e["zone"])))
	bas.add_child(b)
	if not fait:
		_mettre_en_avant(e["zone"])
	# Tout premier passage : mot d'accueil
	if i == 0 and not Tutoriel.faite("deck") and not "bienvenue" in Tutoriel._etat()["vus"]:
		Tutoriel._etat()["vus"].append("bienvenue")
		Sauvegarde.sauvegarder()
		FenetreSimple.ouvrir.call_deferred(self, "Bienvenue, héros !",
			"Le guide PREMIERS PAS (au centre) t'accompagne pour tes débuts : suis ses étapes, le bouton concerné brille dans le menu, et chaque étape rapporte une récompense.\n\nÀ gauche, LA LARME pour combattre ; à droite, LE SANG pour ton armée. Le bouton « ? » en haut à droite explique tout le jeu. N'oublie pas ta récompense de connexion dans les Quêtes !",
			[["C'est parti !", null]])


## Fait briller (contour doré pulsé) le bouton du menu vers lequel le guide envoie.
func _mettre_en_avant(zone: String) -> void:
	var b: Button = _boutons.get(zone)
	if b == null:
		return
	var cadre := Panel.new()
	cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = Color(1.0, 0.8, 0.3, 0.1)
	st.border_color = Color(1.0, 0.82, 0.35)
	st.set_border_width_all(3)
	st.set_corner_radius_all(14)
	st.expand_margin_left = 4
	st.expand_margin_right = 4
	st.expand_margin_top = 4
	st.expand_margin_bottom = 4
	cadre.add_theme_stylebox_override("panel", st)
	b.add_child(cadre)
	cadre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tw := create_tween().set_loops()
	tw.tween_property(cadre, "modulate:a", 0.25, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(cadre, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)


func _reclamer_guide() -> void:
	var l := Tutoriel.reclamer()
	if l.is_empty():
		return
	Audio.son("coffre")
	FenetreSimple.ouvrir(self, "Étape réussie !", "\n".join(l), [["Suite", get_tree().reload_current_scene]])


# =====================================================================
# Barre du bas : le Royaume
# =====================================================================

func _creer_barre_bas() -> void:
	var barre := _boite(Rect2(0, 648, 1280, 72), C_BARRE)
	barre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ligne := ColorRect.new()
	ligne.color = Color(C_OR, 0.35)
	ligne.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placer(ligne, Rect2(0, 648, 1280, 1))
	var x := 24.0
	for c in ROYAUME_GAUCHE:
		x += _bouton_royaume(c, x, true) + 8
	x = BASE.x - 24.0
	for i in range(ROYAUME_DROITE.size() - 1, -1, -1):
		x -= _bouton_royaume(ROYAUME_DROITE[i], x, false) + 8
	# Numéro de version (clic = journal des mises à jour)
	var v := Button.new()
	v.text = Version.texte()
	v.flat = true
	v.focus_mode = Control.FOCUS_NONE
	v.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	v.tooltip_text = "Journal des mises à jour"
	v.add_theme_font_size_override("font_size", 13)
	v.add_theme_color_override("font_color", C_DOUX)
	v.pressed.connect(_on_bouton.bind("nouveautes"))
	_placer(v, Rect2(560, 670, 160, 28))


## Bouton pilule de la barre du bas. Renvoie sa largeur.
func _bouton_royaume(c: Dictionary, x: float, depuis_gauche: bool) -> float:
	var largeur := 132.0
	var r := Rect2(x if depuis_gauche else x - largeur, 662, largeur, 44)
	var b := Button.new()
	b.text = "%s  %s" % [c["icone"], c["titre"]]
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", C_TEXTE)
	b.add_theme_color_override("font_hover_color", Color("ffd27a"))
	b.add_theme_stylebox_override("normal", _style(Color(0.03, 0.02, 0.024, 0.85), Color("4a3638"), 22, 1))
	b.add_theme_stylebox_override("hover", _style(Color(0.12, 0.06, 0.07, 0.9), C_OR, 22, 1))
	b.add_theme_stylebox_override("pressed", _style(Color(0.3, 0.08, 0.1, 0.9), C_OR, 22, 1))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_placer(b, r)
	b.pressed.connect(_on_bouton.bind(c["id"]))
	_boutons[c["id"]] = b
	return largeur


# =====================================================================
# Pastilles
# =====================================================================

func _maj_pastilles() -> void:
	_pastille("quetes", Quetes.a_reclamer())
	_pastille("succes", Succes.a_reclamer())
	_pastille("courrier", Courrier.a_lire())
	_pastille("expedition", Compagnie.nombre_a_recuperer())
	_pastille("menagerie", Menagerie.a_recolter())
	if BossMonde.est_debloque() and BossMonde.essais_restants() > 0:
		_pastille("boss_monde", -1)


## Pastille rouge en haut à droite d'un bouton (n = -1 : point d'exclamation).
func _pastille(id: String, n: int) -> void:
	if n == 0 or not _boutons.has(id):
		return
	var b: Button = _boutons[id]
	var l := _label("!" if n < 0 else str(mini(n, 99)), 11, Color.WHITE, true)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_stylebox_override("normal", _style(C_PASTILLE, Color("120b0d"), 10, 2))
	b.add_child(l)
	l.position = Vector2(b.size.x - 14, -7)
	l.size = Vector2(22, 20)


# =====================================================================
# Secrets
# =====================================================================

func _creer_secrets() -> void:
	# 5 touches rapides sur la lune rouge (ou taper ARNAUD) -> Donjon d'Arnaud
	_zone_secrete(RECT_LUNE, _toucher_lune)
	# 3 touches rapides sur l'emblème du centre (ou taper BELIER) -> le Sanctuaire du Bélier
	_zone_secrete(RECT_EMBLEME, _toucher_blason)


func _zone_secrete(r: Rect2, action: Callable) -> void:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	for etat in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(etat, StyleBoxEmpty.new())
	b.pressed.connect(action)
	_placer(b, r)
	_zones_secretes.append(b)


var _touches_lune := 0
var _derniere_touche := 0
var _saisie := ""


func _toucher_lune() -> void:
	var t := Time.get_ticks_msec()
	_touches_lune = _touches_lune + 1 if t - _derniere_touche < 1500 else 1
	_derniere_touche = t
	if _touches_lune >= 5:
		_ouvrir_donjon_arnaud()


var _touches_blason := 0
var _derniere_touche_blason := 0


func _toucher_blason() -> void:
	var t := Time.get_ticks_msec()
	_touches_blason = _touches_blason + 1 if t - _derniere_touche_blason < 1200 else 1
	_derniere_touche_blason = t
	if _touches_blason >= 3:
		_ouvrir_sanctuaire()


func _ouvrir_sanctuaire() -> void:
	Audio.son("coffre")
	get_tree().change_scene_to_file(Sanctuaire.SCENE)


func _ouvrir_donjon_arnaud() -> void:
	Audio.son("coffre")
	get_tree().change_scene_to_file(DonjonArnaud.SCENE)


func _apres_connexion_demarrage() -> void:
	get_tree().reload_current_scene()


# =====================================================================
# Compte et ressources
# =====================================================================

func _maj_bouton_compte() -> void:
	if not is_instance_valid(_bouton_compte):
		return
	if EnLigne.est_connecte():
		_bouton_compte.text = "● " + EnLigne.nom_complet()
		_bouton_compte.tooltip_text = "Mon compte"
		_bouton_compte.add_theme_color_override("font_color", Color("8fe07a") if EnLigne.reseau_ok else Color("e0b35a"))
	elif EnLigne.connexion_en_cours():
		_bouton_compte.text = "Connexion…"
		_bouton_compte.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7, 0.7))
	else:
		_bouton_compte.text = "Se connecter"
		_bouton_compte.tooltip_text = "Hors ligne : clique pour te connecter"
		_bouton_compte.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	_bouton_compte.add_theme_color_override("font_hover_color", Color("ffd27a"))


func _ouvrir_compte() -> void:
	if is_instance_valid(_fenetre_compte):
		return
	_fenetre_compte = FenetreCompte.ouvrir(self)


func _sur_etat_compte() -> void:
	_maj_bouton_compte()
	# Session perdue au lancement (mot de passe changé, compte supprimé...) : on redemande.
	if EnLigne.doit_proposer_connexion() and not is_instance_valid(_fenetre_compte):
		_fenetre_compte = FenetreCompte.ouvrir(self, true)
	# Arrivée par le lien « mot de passe oublié » : on demande le nouveau mot de passe.
	elif EnLigne.lien_mot_de_passe and EnLigne.est_connecte() and not EnLigne.connexion_en_cours() \
			and not is_instance_valid(_fenetre_compte):
		_fenetre_compte = FenetreCompte.ouvrir(self)


func _maj_ressources() -> void:
	if not is_instance_valid(_lbl_stamina):
		return
	var st := Sauvegarde.get_stamina()
	var mx := Sauvegarde.get_stamina_max()
	_lbl_stamina.text = "%d / %d" % [st, mx]
	_barre_stamina.max_value = maxi(1, mx)
	_barre_stamina.value = mini(st, mx)
	_lbl_recharge.text = "Pleine" if st >= mx else "+1 dans %s" % Calendrier.texte_duree(Sauvegarde.secondes_avant_stamina())
	_lbl_or.text = _nombre(Sauvegarde.get_or())
	_lbl_gemmes.text = _nombre(Sauvegarde.get_gemmes())
	_lbl_eclats.text = _nombre(Sauvegarde.get_objet(Sauvegarde.ECLAT))
	var niv := Sauvegarde.get_niveau_compte()
	_lbl_niveau.text = str(niv)
	if Sauvegarde.niveau_compte_max_atteint():
		_lbl_xp.text = "Niveau MAX"
		_barre_xp.max_value = 1
		_barre_xp.value = 1
	else:
		var besoin := Sauvegarde.xp_pour_niveau(niv)
		_lbl_xp.text = "XP %s / %s" % [_nombre(Sauvegarde.get_xp_compte()), _nombre(besoin)]
		_barre_xp.max_value = maxi(1, besoin)
		_barre_xp.value = Sauvegarde.get_xp_compte()


func _nombre(n: int) -> String:
	if n >= 1000000000:
		return "∞" if n >= 999999999 else str(n)
	var s := str(absi(n))
	var r := ""
	while s.length() > 3:
		r = " " + s.right(3) + r
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + r


# =====================================================================
# Outils de construction
# =====================================================================

## Place un contrôle sur la surface 1280 x 720 (ou dans un parent donné).
func _placer(ctrl: Control, r: Rect2, parent: Control = null) -> void:
	(parent if parent != null else _ui).add_child(ctrl)
	ctrl.position = r.position
	ctrl.size = r.size


func _boite(r: Rect2, couleur: Color) -> ColorRect:
	var c := ColorRect.new()
	c.color = couleur
	_placer(c, r)
	return c


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


func _barre(couleur: Color, fond: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sf := _style(fond, Color(0, 0, 0, 0), 4, 0)
	var sr := _style(couleur, Color(0, 0, 0, 0), 4, 0)
	b.add_theme_stylebox_override("background", sf)
	b.add_theme_stylebox_override("fill", sr)
	return b


func _bouton_icone(icone: String, r: Rect2, aide: String) -> Button:
	var b := Button.new()
	b.text = icone
	b.tooltip_text = aide
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_color_override("font_color", C_TEXTE)
	b.add_theme_color_override("font_hover_color", Color("ffd27a"))
	b.add_theme_stylebox_override("normal", _style(Color(0.03, 0.02, 0.024, 0.85), Color("4a3638"), 12, 1))
	b.add_theme_stylebox_override("hover", _style(Color(0.12, 0.06, 0.07, 0.9), C_OR, 12, 1))
	b.add_theme_stylebox_override("pressed", _style(Color(0.3, 0.08, 0.1, 0.9), C_OR, 12, 1))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_placer(b, r)
	return b


# =====================================================================
# Actions
# =====================================================================

func _on_bouton(id: String) -> void:
	var ici := scene_file_path
	match id:
		"aventure":
			# La carte du monde (Histoire principale) reviendra toujours ici
			ActesData.scene_menu = ici
			ActesData.scene_precedente = ici
			EcranCarte.scene_retour = ici
			get_tree().change_scene_to_file(EcranCarte.SCENE)
		"arene":
			ActesData.scene_menu = ici
			EcranArene.scene_retour = ici
			get_tree().change_scene_to_file(EcranArene.SCENE)
		"boss_monde":
			ActesData.scene_menu = ici
			EcranBossMonde.scene_retour = ici
			get_tree().change_scene_to_file(EcranBossMonde.SCENE)
		"tours":
			ActesData.scene_menu = ici
			EcranTours.scene_retour = ici
			get_tree().change_scene_to_file(EcranTours.SCENE)
		"donjon":
			ActesData.scene_menu = ici
			EcranDonjon.scene_retour = ici
			get_tree().change_scene_to_file(EcranDonjon.SCENE)
		"expedition":
			ActesData.scene_menu = ici
			EcranExpedition.scene_retour = ici
			get_tree().change_scene_to_file(EcranExpedition.SCENE)
		"menagerie":
			EcranBase.scene_retour = ici
			get_tree().change_scene_to_file(EcranMenagerie.SCENE)
		"fusion":
			EcranFusion.scene_retour = ici
			get_tree().change_scene_to_file(EcranFusion.SCENE)
		"deck":
			EcranDeck.scene_retour = ici
			get_tree().change_scene_to_file(EcranDeck.SCENE)
		"echos":
			EcranEchos.scene_retour = ici
			get_tree().change_scene_to_file(EcranEchos.SCENE)
		"invocation":
			EcranInvocation.scene_retour = ici
			get_tree().change_scene_to_file(EcranInvocation.SCENE)
		"reliquaire":
			EcranReliquaire.scene_retour = ici
			get_tree().change_scene_to_file(EcranReliquaire.SCENE)
		"bestiaire":
			EcranBestiaire.scene_retour = ici
			get_tree().change_scene_to_file(EcranBestiaire.SCENE)
		"social":
			EcranSocial.scene_retour = ici
			get_tree().change_scene_to_file(EcranSocial.SCENE)
		"guilde":
			EcranGuilde.scene_retour = ici
			get_tree().change_scene_to_file(EcranGuilde.SCENE)
		"quetes":
			EcranBase.scene_retour = ici
			get_tree().change_scene_to_file(EcranQuetes.SCENE)
		"succes":
			EcranBase.scene_retour = ici
			get_tree().change_scene_to_file(EcranSucces.SCENE)
		"boutique":
			EcranBase.scene_retour = ici
			get_tree().change_scene_to_file(EcranBoutique.SCENE)
		"courrier":
			EcranBase.scene_retour = ici
			get_tree().change_scene_to_file(EcranCourrier.SCENE)
		"heros":
			EcranBase.scene_retour = ici
			get_tree().change_scene_to_file(EcranHeros.SCENE)
		"aide":
			FenetreAide.ouvrir(self)
		"nouveautes":
			FenetreChangelog.ouvrir(self)
		"parametres":
			FenetreSauvegarde.ouvrir(self)
		_:
			push_warning("Menu : bouton inconnu « %s »" % id)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.unicode > 0:
		_saisie = (_saisie + char(event.unicode).to_lower()).right(6)
		if _saisie == "arnaud":
			_ouvrir_donjon_arnaud()
			return
		if _saisie == "belier" or _saisie.ends_with("bélier".right(6)):
			_ouvrir_sanctuaire()
			return
	# F1 : affiche / masque les zones des secrets (pour les recaler sur l'image)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		_debug = not _debug
		for b in _zones_secretes:
			var st: StyleBox = StyleBoxEmpty.new()
			if _debug:
				st = _style(Color(1, 0.8, 0.3, 0.15), Color(1, 0.8, 0.3), 6, 2)
			b.add_theme_stylebox_override("normal", st)
