class_name UiCommun
extends RefCounted
## Petits outils d'interface partagés (couleurs, panneaux, cartes d'unités).

const C_OR := Color(0.85, 0.65, 0.3)
const C_TEXTE := Color(0.93, 0.88, 0.83)
const C_DOUX := Color(0.66, 0.59, 0.55)
const C_LEGENDE := Color("ffd27a")
const C_FOND := Color("130d0f")
const COULEURS_RARETE := {
	"N": Color("8f8a86"), "R": Color("4fa89a"), "SR": Color("9b72d0"),
	"SSR": Color("d9a93f"), "UR": Color("e0513f"), "LEG": Color("ffd27a"),
}
const COULEURS_ELEMENT := {
	"feu": Color("e0743a"), "eau": Color("4f9fd6"), "nature": Color("62ad4f"),
	"tenebres": Color("a276d6"), "sacre": Color("e6c85a"),
}


static func couleur_rarete(id: String) -> Color:
	var u := UnitesData.get_unite(id)
	return C_LEGENDE if u.get("legende", false) else COULEURS_RARETE[u["rarete"]]


static func texte_rarete(id: String) -> String:
	var u := UnitesData.get_unite(id)
	return "%s · Légende" % u["rarete"] if u.get("legende", false) else u["rarete"]


static func style_panneau(bord := C_OR, fond := Color(0.08, 0.02, 0.03, 0.94)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fond
	s.border_color = bord
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(14)
	return s


static func style_carte(bord: Color, eclat := 0.0, epais := 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.11 + eclat, 0.07 + eclat, 0.08 + eclat, 0.96)
	s.border_color = bord
	s.set_border_width_all(epais)
	s.border_width_top = epais + 2
	s.set_corner_radius_all(8)
	return s


static func label(texte: String, taille: int, couleur := C_TEXTE) -> Label:
	var l := Label.new()
	l.text = texte
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	return l


static func bouton(texte: String, taille := 17) -> Button:
	var b := Button.new()
	b.text = texte
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", taille)
	return b


static func barre(couleur: Color, largeur: float, hauteur: float) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(largeur, hauteur)
	b.show_percentage = false
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color(0, 0, 0, 0.6)
	fond.set_corner_radius_all(3)
	var plein := StyleBoxFlat.new()
	plein.bg_color = couleur
	plein.set_corner_radius_all(3)
	b.add_theme_stylebox_override("background", fond)
	b.add_theme_stylebox_override("fill", plein)
	return b


## Portrait provisoire : cercle à la couleur de l'unité avec son initiale.
static func portrait(id: String, diametre: float) -> Panel:
	var u := UnitesData.get_unite(id)
	var p := Panel.new()
	p.custom_minimum_size = Vector2(diametre, diametre)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sp := StyleBoxFlat.new()
	sp.set_corner_radius_all(int(diametre / 2))
	sp.bg_color = Color("#" + u["couleur"]).lerp(Color.BLACK, 0.15)
	sp.border_color = COULEURS_ELEMENT[u["element"]]
	sp.set_border_width_all(3)
	p.add_theme_stylebox_override("panel", sp)
	var nom_court: String = u["nom"].trim_prefix("La ").trim_prefix("Le ").trim_prefix("L'")
	var ini := label(nom_court.substr(0, 1), int(diametre * 0.4), Color.WHITE)
	ini.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ini.add_theme_color_override("font_outline_color", Color.BLACK)
	ini.add_theme_constant_override("outline_size", 6)
	p.add_child(ini)
	return p


## Carte d'une unité possédée (bouton) : portrait, nom, niveau, barre d'XP.
static func carte_heros(h: Dictionary, largeur := 132.0, hauteur := 168.0) -> Button:
	var id: String = h["id"]
	var u := UnitesData.get_unite(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(largeur, hauteur)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var bord := couleur_rarete(id)
	b.add_theme_stylebox_override("normal", style_carte(bord))
	b.add_theme_stylebox_override("hover", style_carte(C_OR, 0.06))
	b.add_theme_stylebox_override("pressed", style_carte(C_OR, 0.12))

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_top = 8
	vb.offset_bottom = -6
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 3)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	vb.add_child(portrait(id, hauteur * 0.34))
	var nom := label(u["nom"], 13)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nom.custom_minimum_size = Vector2(largeur - 12, 0)
	vb.add_child(nom)
	var niv := int(h["niveau"])
	var ligne := label("Nv %d  ·  %s" % [niv, "Légende" if u.get("legende", false) else u["rarete"]], 12, bord)
	ligne.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(ligne)
	var nb_et := Fusion.etoiles(h)
	var et := label(Fusion.texte_etoiles(nb_et, false) + ("  ÉVEILLÉ" if nb_et >= Fusion.ETOILES_MAX else ""), 11,
		Color("ff9a5a") if nb_et >= Fusion.ETOILES_MAX else Color("ffd060"))
	et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(et)
	var xp := barre(Color("7ab8ff"), largeur - 30, 5)
	xp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	xp.max_value = Sauvegarde.xp_heros_pour_niveau(niv)
	xp.value = int(h["xp"]) if niv < UnitesData.NIVEAU_MAX else xp.max_value
	vb.add_child(xp)
	return b


## Petit badge en coin (ex : "Équipe", "Verrouillé", "NOUVEAU").
static func badge(parent: Control, texte: String, couleur: Color, en_haut := true) -> void:
	var l := label(texte, 11, Color.BLACK)
	var st := StyleBoxFlat.new()
	st.bg_color = couleur
	st.set_corner_radius_all(4)
	st.content_margin_left = 5
	st.content_margin_right = 5
	l.add_theme_stylebox_override("normal", st)
	l.position = Vector2(6, 5) if en_haut else Vector2(6, parent.custom_minimum_size.y - 22)
	parent.add_child(l)


## Fond en dégradé vertical (utilisé quand aucune image n'est fournie).
static func fond_degrade(parent: Control, haut: Color, bas: Color) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, haut)
	g.set_color(1, bas)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(r)
	return r


## Image de fond si elle existe (assombrie), sinon rien. Renvoie true si l'image a été mise.
static func fond_image(parent: Control, chemin: String, teinte := Color(0.6, 0.6, 0.6)) -> bool:
	if not ResourceLoader.exists(chemin):
		return false
	var img := TextureRect.new()
	img.texture = load(chemin)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img.modulate = teinte
	parent.add_child(img)
	return true


## Petites particules qui flottent (braises qui montent / lumières qui tombent).
static func particules(parent: Control, couleur: Color, vers_le_haut: bool, nombre := 40) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = nombre
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(900, 10)
	p.position = Vector2(836, 960 if vers_le_haut else -20)
	p.direction = Vector2(0, -1 if vers_le_haut else 1)
	p.spread = 15.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = couleur
	var fondu := Gradient.new()
	fondu.set_color(0, Color(couleur, 0.0))
	fondu.add_point(0.2, couleur)
	fondu.set_color(fondu.get_point_count() - 1, Color(couleur, 0.0))
	p.color_ramp = fondu
	parent.add_child(p)
	return p


## Icône d'objet du Reliquaire : pastille de couleur avec l'initiale.
static func icone_objet(objet: String, taille := 44.0) -> Panel:
	var infos: Dictionary = Reliquaire.OBJETS.get(objet, {})
	var c := Color("#" + str(infos.get("couleur", "888888")))
	var p := Panel.new()
	p.custom_minimum_size = Vector2(taille, taille)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = c.darkened(0.55)
	st.border_color = c
	st.set_border_width_all(2)
	st.set_corner_radius_all(int(taille / 4))
	p.add_theme_stylebox_override("panel", st)
	var l := label(str(infos.get("nom", "?")).substr(0, 1), int(taille * 0.5), c.lightened(0.3))
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


## Retour générique : scène demandée, sinon scène principale.
static func aller(arbre: SceneTree, cible: String) -> void:
	if cible == "":
		cible = ProjectSettings.get_setting("application/run/main_scene", "")
	if cible != "":
		arbre.change_scene_to_file(cible)
