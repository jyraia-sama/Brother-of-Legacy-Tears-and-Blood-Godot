class_name FenetreGuide
extends CanvasLayer
## FENÊTRE DE GUIDE générique (même présentation que le guide des Échos Sanguins) :
## un menu de sections à gauche, le texte (BBCode) à droite, Précédent / Suivant en bas.
##
##   FenetreGuide.ouvrir(parent, "GUIDE DES DONJONS", couleur, sections)
## sections : [[nom de la section, texte BBCode], ...]
## Les guides : guide_donjons.gd, guide_fusion.gd, guide_sorts.gd.
##
## Aussi : FenetreGuide.bouton_aide(parent, tooltip, action) — le bouton « ? » doré qui pulse.

const C_TITRE := "#ffd27a"
const C_BON := "#8aff9a"
const C_ALERTE := "#ffb08a"
const C_DOUX := "#a8968c"

var _titre := ""
var _couleur := Color("ffd27a")
var _sections: Array = []
var _section := 0
var _texte: RichTextLabel
var _boutons: Array[Button] = []


static func ouvrir(parent: Node, titre: String, couleur: Color, sections: Array, section := 0) -> FenetreGuide:
	var f := FenetreGuide.new()
	f._titre = titre
	f._couleur = couleur
	f._sections = sections
	f._section = section
	parent.add_child(f)
	return f


## Bouton « ? » doré, lumineux et qui pulse (à poser dans la barre du haut d'un écran).
static func bouton_aide(tooltip: String, action: Callable) -> Button:
	var b := UiCommun.bouton("?", 26)
	b.custom_minimum_size = Vector2(52, 46)
	b.tooltip_text = tooltip
	UiCommun.bouton_vif(b, Color("c8871e"))
	b.pressed.connect(action)
	b.resized.connect(func(): b.pivot_offset = b.size / 2.0)
	b.ready.connect(func():
		var tw := b.create_tween().set_loops()
		tw.tween_property(b, "scale", Vector2(1.12, 1.12), 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(b, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE))
	return b


func _ready() -> void:
	layer = 50
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.72)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var p := PanelContainer.new()
	var vp := get_viewport().get_visible_rect().size
	p.custom_minimum_size = Vector2(minf(1400.0, vp.x - 40.0), minf(800.0, vp.y - 40.0))
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(_couleur, Color(0.07, 0.02, 0.03, 0.98)))
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)

	var tete := HBoxContainer.new()
	vb.add_child(tete)
	var t := UiCommun.label(_titre, 28, _couleur)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	var fermer := UiCommun.bouton(UiCommun.t("Fermer"), 16)
	fermer.pressed.connect(queue_free)
	tete.add_child(fermer)

	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 16)
	vb.add_child(corps)
	var dm := ScrollContainer.new()
	dm.custom_minimum_size = Vector2(290, 0)
	dm.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	corps.add_child(dm)
	var menu := VBoxContainer.new()
	menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu.add_theme_constant_override("separation", 6)
	dm.add_child(menu)
	for i in _sections.size():
		var b := UiCommun.bouton("%d. %s" % [i + 1, _sections[i][0]], 15)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(_afficher.bind(i))
		menu.add_child(b)
		_boutons.append(b)

	var droite := VBoxContainer.new()
	droite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	droite.add_theme_constant_override("separation", 8)
	corps.add_child(droite)
	_texte = RichTextLabel.new()
	_texte.bbcode_enabled = true
	_texte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texte.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texte.add_theme_font_size_override("normal_font_size", 18)
	_texte.add_theme_font_size_override("bold_font_size", 18)
	_texte.add_theme_color_override("default_color", UiCommun.C_TEXTE)
	_texte.add_theme_constant_override("table_h_separation", 18)
	_texte.add_theme_constant_override("table_v_separation", 4)
	_texte.scroll_active = true
	droite.add_child(_texte)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	droite.add_child(nav)
	var prec := UiCommun.bouton(UiCommun.t("← Précédent"), 15)
	prec.pressed.connect(func(): _afficher(maxi(_section - 1, 0)))
	nav.add_child(prec)
	var esp := Control.new()
	esp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(esp)
	var suiv := UiCommun.bouton(UiCommun.t("Suivant →"), 15)
	suiv.pressed.connect(func(): _afficher(mini(_section + 1, _sections.size() - 1)))
	nav.add_child(suiv)
	_afficher(clampi(_section, 0, _sections.size() - 1))


func _afficher(i: int) -> void:
	_section = i
	for k in _boutons.size():
		_boutons[k].button_pressed = k == i
		_boutons[k].add_theme_color_override("font_color", Color(C_TITRE) if k == i else UiCommun.C_TEXTE)
		_boutons[k].add_theme_stylebox_override("normal", UiCommun.style_carte(Color(C_TITRE) if k == i else Color(1, 1, 1, 0.12), 0.08 if k == i else 0.0, 2))
	_texte.text = str(_sections[i][1])
	_texte.scroll_to_line(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()


# =====================================================================
# Outils de mise en forme (BBCode), partagés par les guides
# =====================================================================

static func titre(t: String) -> String:
	return "[font_size=24][color=%s][b]%s[/b][/color][/font_size]\n\n" % [C_TITRE, t]


static func sous_titre(t: String) -> String:
	return "\n[color=%s][b]%s[/b][/color]\n" % [C_TITRE, t]


static func couleur(t: String, c: String) -> String:
	return "[color=%s]%s[/color]" % [c, t]


static func puce(t: String) -> String:
	return "  •  " + t + "\n"


static func cellule(t: String, c := "") -> String:
	if c != "":
		t = "[color=%s]%s[/color]" % [c, t]
	return "[cell padding=4,2,4,2]%s[/cell]" % t


## Tableau BBCode : entete = noms des colonnes, lignes = [[...], ...]
static func tableau(entete: Array, lignes: Array) -> String:
	var s := "[table=%d]" % entete.size()
	for c in entete:
		s += cellule("[b]%s[/b]" % c, C_TITRE)
	for l in lignes:
		for c in l:
			s += cellule(str(c))
	return s + "[/table]\n"
