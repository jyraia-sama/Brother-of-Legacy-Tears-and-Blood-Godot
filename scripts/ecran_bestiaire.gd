class_name EcranBestiaire
extends Control
## BESTIAIRE (codex) : toutes les unités du jeu.
## Une unité reste cachée ("???") tant qu'elle n'a pas été découverte :
## rencontrée en combat sur un plateau, ou obtenue à l'Autel d'Invocation.
##   -> pour la découvrir depuis un autre script : Sauvegarde.decouvrir("chevalier")
##
## Commandes : clic sur une carte = fiche détaillée · molette = défiler · Échap = retour

const SCENE := "res://scenes/bestiaire.tscn"
const FOND := "res://assets/ui/menu_bg.png"

## Pour tester : true = toutes les unités sont visibles même non découvertes.
const TOUT_REVELER := false

## Écran à rouvrir avec le bouton Retour (rempli par l'écran qui ouvre le Bestiaire).
static var scene_retour := ""

const C_FOND := Color("130d0f")
const C_PANNEAU := Color(0.08, 0.02, 0.03, 0.94)
const C_OR := Color(0.85, 0.65, 0.3)
const C_TEXTE := Color(0.93, 0.88, 0.83)
const C_DOUX := Color(0.66, 0.59, 0.55)

const COULEURS_RARETE := {
	"N": Color("8f8a86"), "R": Color("4fa89a"), "SR": Color("9b72d0"),
	"SSR": Color("d9a93f"), "UR": Color("e0513f"),
}
const COULEURS_ELEMENT := {
	"feu": Color("e0743a"), "eau": Color("4f9fd6"), "nature": Color("62ad4f"),
	"tenebres": Color("a276d6"), "sacre": Color("e6c85a"),
}
const FILTRES := [["tous", "Tous"], ["legende", "Légendes"], ["heros", "Héros"], ["ennemi", "Ennemis"], ["boss", "Boss"], ["boss_monde", "Boss de Monde"]]
const C_LEGENDE := Color("ffd27a")

var _filtre := "tous"
var _grille: GridContainer
var _compteur: Label
var _boutons_filtre := {}
var _selection := ""
var _niveau := 1

# Fiche détaillée
var _fiche: VBoxContainer
var _f_nom: Label
var _f_infos: Label
var _f_niveau: Label
var _f_curseur: HSlider
var _f_stats: GridContainer
var _f_secondaires: Label
var _f_skills: VBoxContainer
var _f_vide: Label


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_creer_fond()

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for cote in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + cote, 20)
	add_child(marge)

	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 12)
	marge.add_child(colonne)

	# --- En-tête ---
	var entete := HBoxContainer.new()
	entete.add_theme_constant_override("separation", 16)
	colonne.add_child(entete)
	var retour := _bouton("← Retour")
	retour.pressed.connect(_retour)
	entete.add_child(retour)
	var titre := _label("BESTIAIRE", 34, C_OR)
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entete.add_child(titre)
	_compteur = _label("", 18, C_DOUX)
	entete.add_child(_compteur)

	# --- Filtres ---
	var filtres := HBoxContainer.new()
	filtres.add_theme_constant_override("separation", 8)
	colonne.add_child(filtres)
	for f in FILTRES:
		var b := _bouton(f[1])
		b.toggle_mode = true
		b.pressed.connect(_changer_filtre.bind(f[0]))
		filtres.add_child(b)
		_boutons_filtre[f[0]] = b

	# --- Grille + fiche ---
	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 16)
	colonne.add_child(corps)

	var defil := ScrollContainer.new()
	defil.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	corps.add_child(defil)
	_grille = GridContainer.new()
	_grille.columns = 5
	_grille.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grille.add_theme_constant_override("h_separation", 10)
	_grille.add_theme_constant_override("v_separation", 10)
	defil.add_child(_grille)

	corps.add_child(_creer_fiche())

	_changer_filtre("tous")
	resized.connect(_ajuster_colonnes)
	_ajuster_colonnes()


# ---------------------------------------------------------------
# Grille des unités
# ---------------------------------------------------------------

func _changer_filtre(f: String) -> void:
	_filtre = f
	for cle in _boutons_filtre:
		_boutons_filtre[cle].button_pressed = (cle == f)
	_remplir_grille()


func _visible(id: String) -> bool:
	return TOUT_REVELER or Sauvegarde.est_decouvert(id)


func _remplir_grille() -> void:
	for enfant in _grille.get_children():
		enfant.queue_free()
	var total := 0
	var decouverts := 0
	for id in UnitesData.UNITES:
		var u: Dictionary = UnitesData.UNITES[id]
		if _filtre == "legende":
			if not u.get("legende", false):
				continue
		elif _filtre != "tous" and u["categorie"] != _filtre:
			continue
		total += 1
		if _visible(id):
			decouverts += 1
		_grille.add_child(_carte(id, u))
	_compteur.text = "Découverts : %d / %d" % [decouverts, total]


func _carte(id: String, u: Dictionary) -> Button:
	var connu := _visible(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(150, 176)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var bord: Color = COULEURS_RARETE[u["rarete"]] if connu else Color(0.3, 0.25, 0.25)
	if connu and u.get("legende", false):
		bord = C_LEGENDE
	b.add_theme_stylebox_override("normal", _style_carte(bord, 0.0))
	b.add_theme_stylebox_override("hover", _style_carte(C_OR, 0.06))
	b.add_theme_stylebox_override("pressed", _style_carte(C_OR, 0.12))
	b.pressed.connect(_selectionner.bind(id))

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_top = 12
	vb.offset_bottom = -10
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 6)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)

	# Portrait provisoire : cercle à la couleur de l'unité (remplacé plus tard par une image)
	var portrait := Panel.new()
	portrait.custom_minimum_size = Vector2(76, 76)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sp := StyleBoxFlat.new()
	sp.set_corner_radius_all(38)
	if connu:
		sp.bg_color = Color("#" + u["couleur"]).lerp(Color.BLACK, 0.15)
		sp.border_color = COULEURS_ELEMENT[u["element"]]
	else:
		sp.bg_color = Color(0.1, 0.08, 0.08)
		sp.border_color = Color(0.25, 0.2, 0.2)
	sp.set_border_width_all(3)
	portrait.add_theme_stylebox_override("panel", sp)
	vb.add_child(portrait)
	var nom_court: String = u["nom"].trim_prefix("La ").trim_prefix("Le ").trim_prefix("L'")
	var initiale := _label(nom_court.substr(0, 1) if connu else "?", 30, Color.WHITE if connu else C_DOUX)
	initiale.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	initiale.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initiale.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	initiale.add_theme_color_override("font_outline_color", Color.BLACK)
	initiale.add_theme_constant_override("outline_size", 6)
	portrait.add_child(initiale)

	var nom := _label(u["nom"] if connu else "???", 15, C_TEXTE if connu else C_DOUX)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nom.custom_minimum_size = Vector2(130, 0)
	vb.add_child(nom)
	var rar := _label(("%s · Légende" % u["rarete"] if u.get("legende", false) else u["rarete"]) if connu else "", 13, bord)
	rar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(rar)
	return b


func _ajuster_colonnes() -> void:
	if _grille == null:
		return
	var largeur := size.x - 40 - 460 - 16
	_grille.columns = maxi(1, int(largeur / 160.0))


# ---------------------------------------------------------------
# Fiche détaillée
# ---------------------------------------------------------------

func _creer_fiche() -> PanelContainer:
	var panneau := PanelContainer.new()
	panneau.custom_minimum_size = Vector2(460, 0)
	var st := StyleBoxFlat.new()
	st.bg_color = C_PANNEAU
	st.border_color = C_OR
	st.set_border_width_all(2)
	st.set_corner_radius_all(8)
	st.set_content_margin_all(18)
	panneau.add_theme_stylebox_override("panel", st)

	var defil := ScrollContainer.new()
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panneau.add_child(defil)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 10)
	defil.add_child(vb)

	_f_vide = _label("Choisis une unité pour voir sa fiche.", 17, C_DOUX)
	_f_vide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_f_vide)

	_fiche = VBoxContainer.new()
	_fiche.add_theme_constant_override("separation", 10)
	_fiche.visible = false
	vb.add_child(_fiche)

	_f_nom = _label("", 28, C_OR)
	_f_nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fiche.add_child(_f_nom)
	_f_infos = _label("", 16, C_DOUX)
	_f_infos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fiche.add_child(_f_infos)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	_fiche.add_child(ligne)
	_f_niveau = _label("Niveau 1", 17, C_TEXTE)
	_f_niveau.custom_minimum_size = Vector2(100, 0)
	ligne.add_child(_f_niveau)
	_f_curseur = HSlider.new()
	_f_curseur.min_value = 1
	_f_curseur.max_value = UnitesData.NIVEAU_MAX
	_f_curseur.value = 1
	_f_curseur.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_f_curseur.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_f_curseur.focus_mode = Control.FOCUS_NONE
	_f_curseur.value_changed.connect(func(v: float):
		_niveau = int(v)
		_maj_fiche())
	ligne.add_child(_f_curseur)

	_f_stats = GridContainer.new()
	_f_stats.columns = 5
	_f_stats.add_theme_constant_override("h_separation", 6)
	_fiche.add_child(_f_stats)
	_f_secondaires = _label("", 15, C_DOUX)
	_f_secondaires.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fiche.add_child(_f_secondaires)
	_fiche.add_child(HSeparator.new())
	_fiche.add_child(_label("SKILLS", 16, C_OR))
	_f_skills = VBoxContainer.new()
	_f_skills.add_theme_constant_override("separation", 10)
	_fiche.add_child(_f_skills)
	return panneau


func _selectionner(id: String) -> void:
	_selection = id
	_maj_fiche()


func _maj_fiche() -> void:
	if _selection == "":
		return
	var u := UnitesData.get_unite(_selection)
	var connu := _visible(_selection)
	_f_vide.visible = not connu
	_fiche.visible = connu
	if not connu:
		_f_vide.text = "???\n\nUnité encore inconnue.\nRencontre-la en combat, obtiens-la à l'Autel d'Invocation ou forge-la au Reliquaire pour la découvrir."
		return

	var cat := {"heros": "Héros invocable", "ennemi": "Ennemi", "boss": "Boss", "boss_monde": "Boss de Monde"}
	_f_nom.text = u["nom"]
	_f_nom.add_theme_color_override("font_color", COULEURS_RARETE[u["rarete"]])
	var type_txt: String = "Héros de Légende" if u.get("legende", false) else ("Héros de Forge (Reliquaire)" if u.get("forge", false) else cat[u["categorie"]])
	if u.get("race", "") != "":
		type_txt += "  ·  Race : " + u["race"]
	_f_infos.text = "%s  ·  %s  ·  %s  ·  %s\n%s" % [
		u["rarete"], UnitesData.ELEMENTS[u["element"]], UnitesData.ROLES[u["role"]],
		"Avant" if u["position"] == "avant" else "Arrière", type_txt]
	_f_niveau.text = "Niveau %d" % _niveau

	var s := UnitesData.stats(_selection, _niveau)
	for enfant in _f_stats.get_children():
		enfant.queue_free()
	for paire in [["pv", "PV"], ["atk", "ATK"], ["def", "DEF"], ["agi", "AGI"], ["mag", "MAG"]]:
		var case := VBoxContainer.new()
		case.custom_minimum_size = Vector2(76, 0)
		var dominante: bool = paire[0] in u.get("dominantes", [])
		var valeur := _label(str(s[paire[0]]), 20, C_LEGENDE if dominante else C_TEXTE)
		valeur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var nom := _label(paire[1], 12, C_DOUX)
		nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		case.add_child(valeur)
		case.add_child(nom)
		_f_stats.add_child(case)
	_f_secondaires.text = "Crit %d %%   ·   Dégâts crit %d %%   ·   RES %d   ·   Précision %d %%" % [
		s["crit"], s["degats_crit"], s["res"], s["preci"]]

	for enfant in _f_skills.get_children():
		enfant.queue_free()
	for sk in u["skills"]:
		var debloque: bool = sk["niveau"] <= _niveau
		var bloc := VBoxContainer.new()
		bloc.add_theme_constant_override("separation", 2)
		var entete := _label("Niv. %d  ·  %s  (%s)" % [sk["niveau"], sk["nom"], sk["type"]], 17,
			C_OR if debloque else C_DOUX)
		bloc.add_child(entete)
		var d := _label(sk["description"], 15, C_TEXTE if debloque else C_DOUX)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bloc.add_child(d)
		_f_skills.add_child(bloc)


# ---------------------------------------------------------------
# Outils
# ---------------------------------------------------------------

func _creer_fond() -> void:
	var noir := ColorRect.new()
	noir.color = C_FOND
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	noir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(noir)
	if ResourceLoader.exists(FOND):
		var img := TextureRect.new()
		img.texture = load(FOND)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.modulate = Color(0.22, 0.18, 0.18)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(img)


func _style_carte(bord: Color, eclat: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.11 + eclat, 0.07 + eclat, 0.08 + eclat, 0.95)
	s.border_color = bord
	s.set_border_width_all(2)
	s.border_width_top = 4
	s.set_corner_radius_all(8)
	return s


func _label(texte: String, taille: int, couleur: Color) -> Label:
	var l := Label.new()
	l.text = texte
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	return l


func _bouton(texte: String) -> Button:
	var b := Button.new()
	b.text = texte
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 38)
	b.add_theme_font_size_override("font_size", 17)
	return b


func _retour() -> void:
	var cible := scene_retour
	if cible == "":
		cible = ProjectSettings.get_setting("application/run/main_scene", "")
	if cible != "":
		get_tree().change_scene_to_file(cible)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
