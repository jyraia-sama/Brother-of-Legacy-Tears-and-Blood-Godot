class_name ThemeJeu
extends RefCounted
## THÈME DU JEU : habille TOUS les menus d'un coup (boutons, onglets, champs, listes, barres de
## défilement, glissières, info-bulles, fenêtres...). Appliqué au démarrage sur le thème par défaut
## de Godot (Polices._init) : chaque contrôle qui n'a pas son propre style en profite.
##
## Les images viennent de assets/ui/kit/ : le kit dessiné en code (outils/generer_kit_ui.py),
## remplacé fichier par fichier par le kit peint (PROMPTS_KIT_UI.md, outils/decouper_kit_ui.py).
## Police des titres : assets/polices/titres.ttf (Gloock, licence OFL ; UiCommun.label l'utilise à partir de 24 px).

const KIT := "res://assets/ui/kit/"
const POLICE_TITRES := "res://assets/polices/titres.ttf"

const C_OR := Color(0.91, 0.74, 0.42)
const C_TEXTE := Color(0.95, 0.9, 0.84)
const C_SURVOL := Color(1.0, 0.95, 0.82)
const C_INACTIF := Color(0.55, 0.52, 0.5)

static var police_titres: Font = null
static var _fait := false


static func appliquer() -> void:
	if _fait:
		return
	_fait = true
	if ResourceLoader.exists(POLICE_TITRES):
		var f := load(POLICE_TITRES) as FontFile
		if f != null:
			var v := FontVariation.new()
			v.base_font = f
			v.fallbacks = ThemeDB.fallback_font.fallbacks if ThemeDB.fallback_font else []
			police_titres = v
	var th := ThemeDB.get_default_theme()
	if th == null:
		return
	_boutons(th)
	_onglets(th)
	_champs(th)
	_listes(th)
	_defilement(th)
	_divers(th)


static func _tex(nom: String, marge: float, contenu := Vector4(14, 8, 14, 8)) -> StyleBox:
	var ch := KIT + nom + ".png"
	if not ResourceLoader.exists(ch):
		return null
	var s := StyleBoxTexture.new()
	s.texture = load(ch)
	s.set_texture_margin_all(marge)
	s.content_margin_left = contenu.x
	s.content_margin_top = contenu.y
	s.content_margin_right = contenu.z
	s.content_margin_bottom = contenu.w
	return s


static func _poser(th: Theme, type: String, styles: Dictionary) -> void:
	for etat in styles:
		if styles[etat] != null:
			th.set_stylebox(etat, type, styles[etat])


static func _couleurs_texte(th: Theme, type: String) -> void:
	th.set_color("font_color", type, C_TEXTE)
	th.set_color("font_hover_color", type, C_SURVOL)
	th.set_color("font_pressed_color", type, C_OR)
	th.set_color("font_hover_pressed_color", type, C_SURVOL)
	th.set_color("font_focus_color", type, C_TEXTE)
	th.set_color("font_disabled_color", type, C_INACTIF)
	th.set_color("font_outline_color", type, Color(0, 0, 0, 0.7))
	th.set_constant("outline_size", type, 3)


static func _boutons(th: Theme) -> void:
	var n := _tex("bouton", 12)
	var h := _tex("bouton_survol", 18, Vector4(14, 8, 14, 8))
	if h is StyleBoxTexture:
		# l'image de survol a une marge de lueur de 6 px tout autour
		h.expand_margin_left = 6
		h.expand_margin_right = 6
		h.expand_margin_top = 6
		h.expand_margin_bottom = 6
	var p := _tex("bouton_appui", 12, Vector4(14, 9, 14, 7))
	var d := _tex("bouton_inactif", 12)
	var vide := StyleBoxEmpty.new()
	for type in ["Button", "OptionButton", "MenuButton"]:
		_poser(th, type, {"normal": n, "hover": h, "pressed": p, "hover_pressed": h, "disabled": d, "focus": vide})
		_couleurs_texte(th, type)
	# Boutons à bascule (cases à cocher, interrupteurs) : pas de fond
	for type in ["CheckBox", "CheckButton"]:
		_poser(th, type, {"normal": vide, "hover": vide, "pressed": vide, "hover_pressed": vide, "disabled": vide, "focus": vide})
		_couleurs_texte(th, type)


static func _onglets(th: Theme) -> void:
	var a := _tex("onglet_actif", 10, Vector4(16, 7, 16, 7))
	var i := _tex("onglet", 10, Vector4(16, 7, 16, 7))
	var s := _tex("onglet_survol", 10, Vector4(16, 7, 16, 7))
	for type in ["TabBar", "TabContainer"]:
		_poser(th, type, {"tab_selected": a, "tab_unselected": i, "tab_hovered": s, "tab_disabled": i, "tab_focus": StyleBoxEmpty.new()})
		th.set_color("font_selected_color", type, C_OR)
		th.set_color("font_unselected_color", type, Color(0.78, 0.72, 0.66))
		th.set_color("font_hovered_color", type, C_SURVOL)
		th.set_color("font_outline_color", type, Color(0, 0, 0, 0.7))
		th.set_constant("outline_size", type, 3)
		th.set_constant("h_separation", type, 4)
	th.set_stylebox("panel", "TabContainer", UiCommun.style_panneau())


static func _champs(th: Theme) -> void:
	var n := _tex("champ", 10, Vector4(12, 8, 12, 8))
	var f := _tex("champ_actif", 10, Vector4(12, 8, 12, 8))
	for type in ["LineEdit", "TextEdit", "SpinBox"]:
		_poser(th, type, {"normal": n, "focus": f, "read_only": n})
		th.set_color("font_color", type, C_TEXTE)
		th.set_color("font_placeholder_color", type, Color(0.6, 0.55, 0.5, 0.7))
		th.set_color("caret_color", type, C_OR)
		th.set_color("selection_color", type, Color(0.85, 0.6, 0.25, 0.35))


static func _listes(th: Theme) -> void:
	var fond := UiCommun.style_panneau(Color(0.75, 0.55, 0.28), Color(0.06, 0.02, 0.03, 0.97))
	fond.orne = false
	fond.set_content_margin_all(8)
	var survol := StyleBoxFlat.new()
	survol.bg_color = Color(0.85, 0.55, 0.2, 0.25)
	survol.set_corner_radius_all(5)
	survol.border_color = Color(0.95, 0.75, 0.4, 0.6)
	survol.border_width_left = 2
	for type in ["PopupMenu"]:
		th.set_stylebox("panel", type, fond)
		th.set_stylebox("hover", type, survol)
		th.set_color("font_color", type, C_TEXTE)
		th.set_color("font_hover_color", type, C_SURVOL)
		th.set_color("font_disabled_color", type, C_INACTIF)
		th.set_constant("v_separation", type, 8)
		var sep := StyleBoxLine.new()
		sep.color = Color(0.85, 0.65, 0.3, 0.4)
		sep.thickness = 1
		th.set_stylebox("separator", type, sep)
	var liste := UiCommun.style_panneau(Color(0.6, 0.45, 0.25, 0.8), Color(0.05, 0.02, 0.03, 0.9))
	liste.orne = false
	th.set_stylebox("panel", "ItemList", liste)
	th.set_stylebox("hovered", "ItemList", survol)
	th.set_stylebox("selected", "ItemList", survol)
	th.set_stylebox("selected_focus", "ItemList", survol)
	th.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	th.set_color("font_color", "ItemList", C_TEXTE)
	th.set_color("font_selected_color", "ItemList", C_OR)
	# Info-bulles
	var bulle := UiCommun.style_panneau(C_OR, Color(0.07, 0.03, 0.04, 0.98))
	bulle.orne = false
	bulle.set_content_margin_all(10)
	th.set_stylebox("panel", "TooltipPanel", bulle)
	th.set_color("font_color", "TooltipLabel", C_TEXTE)
	th.set_font_size("font_size", "TooltipLabel", 16)


static func _defilement(th: Theme) -> void:
	var rail := _tex("glissiere_rail", 7, Vector4(3, 3, 3, 3))
	var poi := _tex("glissiere_poignee", 7, Vector4(3, 3, 3, 3))
	var poi_h := _tex("glissiere_poignee_survol", 7, Vector4(3, 3, 3, 3))
	for type in ["VScrollBar", "HScrollBar"]:
		_poser(th, type, {"scroll": rail, "scroll_focus": rail, "grabber": poi, "grabber_highlight": poi_h, "grabber_pressed": poi_h})
	# Glissières (volumes...) : rail sombre, partie remplie dorée
	var r := StyleBoxFlat.new()
	r.bg_color = Color(0.05, 0.02, 0.02, 0.9)
	r.border_color = Color(0.5, 0.36, 0.2)
	r.set_border_width_all(1)
	r.set_corner_radius_all(4)
	r.content_margin_top = 4
	r.content_margin_bottom = 4
	var rempli := StyleBoxFlat.new()
	rempli.bg_color = Color(0.85, 0.6, 0.25)
	rempli.set_corner_radius_all(4)
	rempli.content_margin_top = 4
	rempli.content_margin_bottom = 4
	th.set_stylebox("slider", "HSlider", r)
	th.set_stylebox("grabber_area", "HSlider", rempli)
	th.set_stylebox("grabber_area_highlight", "HSlider", rempli)


static func _divers(th: Theme) -> void:
	# Panneaux par défaut (PanelContainer / Panel sans style propre) : panneau orné
	th.set_stylebox("panel", "PanelContainer", UiCommun.style_panneau())
	# Fenêtres (AcceptDialog, ConfirmationDialog...)
	var fond_fen := StyleBoxFlat.new()
	fond_fen.bg_color = Color(0.09, 0.03, 0.04, 1.0)
	fond_fen.set_content_margin_all(18)
	th.set_stylebox("panel", "AcceptDialog", fond_fen)
	# Cadre de fenêtre : englobe la barre de titre (au-dessus du contenu)
	var fen := UiCommun.style_panneau(C_OR, Color(0.07, 0.02, 0.03, 0.98))
	fen.bg_color.a = 0.97
	fen.expand_margin_top = 40
	fen.expand_margin_left = 6
	fen.expand_margin_right = 6
	fen.expand_margin_bottom = 6
	for e in ["embedded_border", "embedded_unfocused_border"]:
		th.set_stylebox(e, "Window", fen)
	th.set_constant("title_height", "Window", 40)
	th.set_font_size("title_font_size", "Window", 20)
	th.set_color("title_color", "Window", C_OR)
	th.set_color("title_outline_modulate", "Window", Color(0, 0, 0, 0.8))
	th.set_constant("title_outline_size", "Window", 4)
	th.set_constant("buttons_min_width", "AcceptDialog", 130)
	th.set_constant("buttons_separation", "AcceptDialog", 24)
	if police_titres != null:
		th.set_font("title_font", "Window", police_titres)
	# Séparateurs : filet doré avec losange
	var ch := KIT + "separateur.png"
	if ResourceLoader.exists(ch):
		var sep := StyleBoxTexture.new()
		sep.texture = load(ch)
		sep.texture_margin_left = 240
		sep.texture_margin_right = 240
		sep.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
		sep.content_margin_top = 8
		sep.content_margin_bottom = 8
		th.set_stylebox("separator", "HSeparator", sep)
		th.set_constant("separation", "HSeparator", 16)
	# Barres de progression par défaut
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color(0, 0, 0, 0.65)
	fond.border_color = Color(0.45, 0.32, 0.18)
	fond.set_border_width_all(1)
	fond.set_corner_radius_all(4)
	var plein := StyleBoxFlat.new()
	plein.bg_color = Color(0.85, 0.6, 0.25)
	plein.set_corner_radius_all(4)
	th.set_stylebox("background", "ProgressBar", fond)
	th.set_stylebox("fill", "ProgressBar", plein)
	th.set_color("font_color", "Label", C_TEXTE)
