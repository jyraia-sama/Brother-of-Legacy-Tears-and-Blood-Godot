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
	"tenebres": Color("a276d6"), "sacre": Color("e6c85a"), "neutre": Color("c8b8b0"),
}


static func couleur_rarete(id: String) -> Color:
	var u := UnitesData.get_unite(id)
	return C_LEGENDE if u.get("legende", false) else COULEURS_RARETE[u["rarete"]]


static func texte_rarete(id: String) -> String:
	var u := UnitesData.get_unite(id)
	var t: String = UiCommun.t("%s · Légende") % u["rarete"] if u.get("legende", false) else u["rarete"]
	return t + (" · Évolué" if UnitesData.est_evolue(id) else "")


## Opacité des grands panneaux : un peu transparents pour laisser voir le décor peint derrière.
const OPACITE_PANNEAUX := 0.6

static func style_panneau(bord := C_OR, fond := Color(0.08, 0.02, 0.03, 0.94)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(fond, fond.a * OPACITE_PANNEAUX)
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


## TRADUCTION d'un texte à trous (« %d unités ») avant de le remplir : "…" % [...] devient
## UiCommun.t("…") % [...]. Les textes simples des Label / Button se traduisent tout seuls
## (fichier langues/en.po, voir LANGUES.md).
static func t(texte: String) -> String:
	return str(TranslationServer.translate(texte))


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


## CASES À COCHER bien visibles : grande case cerclée d'or ; cochée = fond vert vif et coche blanche.
static var _icones_case := {}

static func _icone_case(cochee: bool, inactive := false) -> ImageTexture:
	var cle := "%s_%s" % [cochee, inactive]
	if _icones_case.has(cle):
		return _icones_case[cle]
	const T := 30
	var img := Image.create(T, T, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var bord := Color("e8b54a") if not inactive else Color(0.45, 0.42, 0.4)
	var fond := (Color("2f9e44") if cochee else Color(0.08, 0.05, 0.05)) if not inactive else Color(0.15, 0.14, 0.14)
	for y in T:
		for x in T:
			var dans_bord := x < 3 or y < 3 or x >= T - 3 or y >= T - 3
			var coin := (x < 2 or x >= T - 2) and (y < 2 or y >= T - 2)
			if coin:
				continue
			img.set_pixel(x, y, bord if dans_bord else fond)
	if cochee:
		# Coche blanche épaisse : de (7,15) à (12,21) puis jusqu'à (23,8)
		var traits := [[Vector2(7, 15), Vector2(12, 21)], [Vector2(12, 21), Vector2(23, 8)]]
		for t in traits:
			for i in 41:
				var p: Vector2 = t[0].lerp(t[1], i / 40.0)
				for dy in range(-2, 2):
					for dx in range(-2, 2):
						var q := Vector2i(int(p.x) + dx, int(p.y) + dy)
						if q.x >= 3 and q.y >= 3 and q.x < T - 3 and q.y < T - 3:
							img.set_pixelv(q, Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	_icones_case[cle] = tex
	return tex


## Rend une CheckBox bien lisible (grande case, texte doré quand elle est cochée).
static func habiller_case(c: CheckBox, taille_texte := 18) -> void:
	c.add_theme_icon_override("checked", _icone_case(true))
	c.add_theme_icon_override("unchecked", _icone_case(false))
	c.add_theme_icon_override("checked_disabled", _icone_case(true, true))
	c.add_theme_icon_override("unchecked_disabled", _icone_case(false, true))
	c.add_theme_constant_override("h_separation", 10)
	c.add_theme_font_size_override("font_size", taille_texte)
	c.add_theme_color_override("font_color", C_TEXTE)
	c.add_theme_color_override("font_pressed_color", C_LEGENDE)
	c.add_theme_color_override("font_hover_color", Color.WHITE)
	c.add_theme_color_override("font_hover_pressed_color", C_LEGENDE)
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if c.custom_minimum_size.y < 40:
		c.custom_minimum_size.y = 40


## Bouton d'action à ne pas rater (« Réclamer », « Ouvrir le coffre »...) : fond vif, halo et
## léger battement. Ne change rien s'il est désactivé (il reste gris).
static func bouton_vif(b: Button, couleur := Color("2f9e44")) -> void:
	if b.disabled:
		return
	var etats := {"normal": couleur, "hover": couleur.lightened(0.18), "pressed": couleur.darkened(0.15)}
	for e in etats:
		var st := StyleBoxFlat.new()
		st.bg_color = etats[e]
		st.border_color = couleur.lightened(0.5)
		st.set_border_width_all(2)
		st.set_corner_radius_all(8)
		st.shadow_color = Color(couleur, 0.55)
		st.shadow_size = 8
		st.set_content_margin_all(8)
		b.add_theme_stylebox_override(e, st)
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	b.add_theme_constant_override("outline_size", 4)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# Léger battement lumineux pour attirer l'œil
	b.ready.connect(func():
		var tw := b.create_tween().set_loops()
		tw.tween_property(b, "modulate", Color(1.18, 1.18, 1.18), 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_property(b, "modulate", Color.WHITE, 0.7).set_trans(Tween.TRANS_SINE))


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
## Dossier des portraits d'unités (un PNG par identifiant : assets/unites/<id>.png).
const DOSSIER_PORTRAITS := "res://assets/unites/"
## Zone de l'image montrée dans les portraits ronds (en fraction de l'image) :
## on zoome sur le haut du corps pour que le visage reste lisible en petit.
const CADRAGE_PORTRAIT := Rect2(0.13, 0.0, 0.74, 0.74)


## Chemin du portrait d'une unité, ou "" si l'image n'existe pas encore.
## Une évolution sans image propre montre celle de son unité de base (en attendant son skin).
static func chemin_portrait(id: String) -> String:
	if FamiliersData.existe(id):              # familier de la Ménagerie
		return FamiliersData.chemin_image(id)
	var chemin := DOSSIER_PORTRAITS + id + ".png"
	if ResourceLoader.exists(chemin):
		return chemin
	if UnitesData.est_evolue(id):
		return chemin_portrait(UnitesData.lignee(id))
	return ""


## FIGURINES (pions de combat) : une figurine en pied, fond transparent, tournée vers la DROITE,
## dans assets/figurines/<id>.png. Quand elle existe, elle remplace le portrait rond en combat
## (héros comme ennemis). Une évolution sans figurine reprend celle de son unité de base.
const DOSSIER_FIGURINES := "res://assets/figurines/"

static func chemin_figurine(id: String) -> String:
	var chemin := DOSSIER_FIGURINES + id + ".png"
	if ResourceLoader.exists(chemin):
		return chemin
	if UnitesData.est_evolue(id):
		return chemin_figurine(UnitesData.lignee(id))
	return ""


## CADRES DE CARTE PAR RARETÉ : un cadre orné par rareté, dans assets/cadres/<clé>.png
## (n, r, sr, ssr, ur, leg), fond et centre transparents. Le cadre est posé par-dessus les cartes
## et les grandes illustrations (Deck, Fusion, Invocation, Bestiaire, Galerie...). Tant que
## l'image d'une rareté n'existe pas, la carte garde son simple contour coloré.
## Les ornements doivent rester dans les COINS : les côtés sont étirés selon la taille de la carte.
const DOSSIER_CADRES := "res://assets/cadres/"
## Taille d'un coin orné, en fraction de la largeur de l'image du cadre.
const MARGE_CADRE := 0.3

static var _cadres := {}


## Clé de rareté d'une unité ou d'un familier : "N", "R", "SR", "SSR", "UR" ou "LEG".
static func cle_rarete(id: String) -> String:
	if FamiliersData.existe(id):
		return str(FamiliersData.get_familier(id).get("rarete", "N"))
	if not UnitesData.existe(id):
		return ""
	var u := UnitesData.get_unite(id)
	return "LEG" if u.get("legende", false) else str(u.get("rarete", "N"))


## Texture du cadre d'une rareté (null si l'image n'existe pas encore).
static func texture_cadre(cle: String) -> Texture2D:
	return _info_cadre(cle).get("tex", null)


## Cadre d'une rareté : {tex, debord} (vide sans image). debord = Rect2 des marges (px de l'image)
## entre le bord de l'image et la baguette du cadre (les coins ornés dépassent de la baguette) :
## gauche/haut dans position, droite/bas dans size.
static func _info_cadre(cle: String) -> Dictionary:
	if cle == "":
		return {}
	if _cadres.has(cle):
		return _cadres[cle]
	var info := {}
	var chemin := DOSSIER_CADRES + cle.to_lower() + ".png"
	if ResourceLoader.exists(chemin):
		var tex: Texture2D = load(chemin)
		info["tex"] = tex
		var img := tex.get_image()
		if img != null and img.is_compressed():
			img.decompress()
		var w := tex.get_width()
		var h := tex.get_height()
		var g := 0
		var d := 0
		var hh := 0
		var b := 0
		if img != null:
			while g < w / 3 and img.get_pixel(g, h / 2).a < 0.5:
				g += 1
			while d < w / 3 and img.get_pixel(w - 1 - d, h / 2).a < 0.5:
				d += 1
			while hh < h / 3 and img.get_pixel(w / 2, hh).a < 0.5:
				hh += 1
			while b < h / 3 and img.get_pixel(w / 2, h - 1 - b).a < 0.5:
				b += 1
		info["debord"] = Rect2(g, hh, d, b)
	_cadres[cle] = info
	return info


## Pose le cadre de rareté de l'unité id par-dessus le contrôle c (retrait = marge depuis
## ses bords, pour laisser voir le contour de sélection). La BAGUETTE du cadre est calée sur le
## bord de la carte ; les coins ornés peuvent dépasser un peu. Renvoie false sans cadre.
static func encadrer(c: Control, id: String, retrait := 0.0) -> bool:
	var info := _info_cadre(cle_rarete(id))
	if info.is_empty():
		return false
	var tex: Texture2D = info["tex"]
	var deb: Rect2 = info["debord"]
	var zone := Control.new()
	zone.name = "Cadre"
	zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(zone)
	var cadre := NinePatchRect.new()
	cadre.texture = tex
	cadre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := int(round(tex.get_width() * MARGE_CADRE))
	cadre.patch_margin_left = m
	cadre.patch_margin_right = m
	cadre.patch_margin_top = m
	cadre.patch_margin_bottom = m
	zone.add_child(cadre)
	# Le cadre est mis à l'échelle de la carte (coins proportionnés), seuls les côtés s'étirent
	var ajuster := func():
		var t := zone.size - Vector2(2 * retrait, 2 * retrait)
		if t.x <= 1 or t.y <= 1:
			return
		var k := minf(t.x, t.y * 0.75) / float(tex.get_width() - deb.position.x - deb.size.x)
		cadre.scale = Vector2(k, k)
		cadre.position = Vector2(retrait, retrait) - deb.position * k
		cadre.size = (t + (deb.position + deb.size) * k) / k
	zone.resized.connect(ajuster)
	ajuster.call()
	return true


## Épaisseur du bord d'un cadre posé sur une carte de cette largeur (pour placer les textes).
static func bord_cadre(id: String, largeur: float) -> float:
	return largeur * 0.06 if texture_cadre(cle_rarete(id)) != null else 0.0


## Met l'image de l'unité dans un portrait rond (Panel), si elle existe.
## L'image est découpée en cercle par le Panel, l'initiale est cachée et le
## contour coloré (élément) est redessiné par-dessus l'image.
## Renvoie false (et ne change rien) quand l'image n'existe pas encore.
static func habiller_portrait(p: Panel, id: String, initiale: Control = null) -> bool:
	var chemin := chemin_portrait(id)
	if chemin == "":
		return false
	var style := p.get_theme_stylebox("panel") as StyleBoxFlat
	p.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var img := TextureRect.new()
	var tex: Texture2D = load(chemin)
	var zone := AtlasTexture.new()
	zone.atlas = tex
	zone.region = Rect2(CADRAGE_PORTRAIT.position * tex.get_size(), CADRAGE_PORTRAIT.size * tex.get_size())
	img.texture = zone
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_child(img)
	if style != null:
		var contour := Panel.new()
		contour.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contour.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var sc := style.duplicate() as StyleBoxFlat
		sc.draw_center = false
		contour.add_theme_stylebox_override("panel", sc)
		p.add_child(contour)
	if initiale != null:
		initiale.visible = false
	return true


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
	habiller_portrait(p, id, ini)
	return p


## Carte d'une unité possédée (bouton) : illustration pleine carte, nom, niveau,
## étoiles et barre d'XP. Sans image, on garde l'ancienne carte (portrait rond).
static func carte_heros(h: Dictionary, largeur := 132.0, hauteur := 168.0) -> Button:
	var b := _carte_heros(h, largeur, hauteur)
	# Unité partie en mission (Compagnie) : carte grisée avec un bandeau
	if Sauvegarde.est_occupe(int(h.get("uid", -1))):
		b.modulate = Color(0.75, 0.75, 0.8, 0.8)
		if Menagerie.heros_en_chasse(int(h.get("uid", -1))):
			badge(b, "En chasse", Color("8ad05a"), false)
		else:
			badge(b, "En mission", Color("7ab8ff"), false)
	return b


static func _carte_heros(h: Dictionary, largeur: float, hauteur: float) -> Button:
	var id: String = h["id"]
	if chemin_portrait(id) == "":
		return _carte_heros_simple(h, largeur, hauteur)
	var u := UnitesData.get_unite(id)
	var b := Button.new()
	b.custom_minimum_size = Vector2(largeur, hauteur)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var bord := couleur_rarete(id)
	b.add_theme_stylebox_override("normal", style_carte(bord))
	b.add_theme_stylebox_override("hover", style_carte(C_OR, 0.06))
	b.add_theme_stylebox_override("pressed", style_carte(C_OR, 0.12))

	var vb := habiller_carte(b, id, largeur)
	var petit := largeur < 120
	var nom := label(u["nom"], 12 if petit else 14)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nom.custom_minimum_size = Vector2(largeur - 12 - 2 * bord_cadre(id, largeur), 0)
	nom.add_theme_color_override("font_outline_color", Color.BLACK)
	nom.add_theme_constant_override("outline_size", 5)
	vb.add_child(nom)
	var niv := int(h["niveau"])
	var ligne := label(UiCommun.t("Nv %d  ·  %s") % [niv, "Légende" if u.get("legende", false) else u["rarete"]], 11 if petit else 12, bord)
	ligne.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ligne.add_theme_color_override("font_outline_color", Color.BLACK)
	ligne.add_theme_constant_override("outline_size", 4)
	vb.add_child(ligne)
	var nb_et := Fusion.etoiles(h)
	var et := label(("✦ " if UnitesData.est_evolue(id) else "") + Fusion.texte_etoiles(nb_et, false) + ("  ÉVEILLÉ" if nb_et >= Fusion.ETOILES_MAX else ""), 11,
		Color("ff9a5a") if nb_et >= Fusion.ETOILES_MAX else Color("ffd060"))
	et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	et.add_theme_color_override("font_outline_color", Color.BLACK)
	et.add_theme_constant_override("outline_size", 4)
	vb.add_child(et)
	var xp := barre(Color("7ab8ff"), largeur - 30 - 2 * bord_cadre(id, largeur), 5)
	xp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	xp.max_value = Sauvegarde.xp_heros_pour_niveau(niv)
	xp.value = int(h["xp"]) if niv < UnitesData.niveau_max(id) else xp.max_value
	vb.add_child(xp)
	return b


## Habille un bouton-carte avec l'illustration de l'unité (pleine carte), un voile
## sombre en bas et la pastille d'élément. Renvoie la colonne du bas où ajouter
## les textes (nom, niveau...). À n'appeler que si chemin_portrait(id) != "".
static func habiller_carte(b: Button, id: String, largeur: float) -> VBoxContainer:
	var u := FamiliersData.get_familier(id) if FamiliersData.existe(id) else UnitesData.get_unite(id)
	# Illustration qui remplit la carte (à l'intérieur du contour de rareté)
	var ill := illustration(id, Vector2.ZERO, 6)
	ill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ill.offset_left = 3
	ill.offset_top = 4
	ill.offset_right = -3
	ill.offset_bottom = -3
	b.add_child(ill)
	# Voile sombre en bas pour lire le texte
	var voile := fond_degrade(ill, Color(0, 0, 0, 0), Color(0, 0, 0, 0.92))
	voile.anchor_top = 0.52
	voile.offset_top = 0
	# Cadre de rareté par-dessus l'illustration
	encadrer(b, id, 2.0)
	var bord := bord_cadre(id, largeur)
	# Pastille d'élément en haut à droite
	var pastille := Panel.new()
	pastille.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pastille.size = Vector2(14, 14)
	pastille.position = Vector2(largeur - 22 - bord * 1.6, 9 + bord * 1.6)
	var sp := StyleBoxFlat.new()
	sp.bg_color = COULEURS_ELEMENT[u["element"]]
	sp.set_corner_radius_all(7)
	sp.border_color = Color.BLACK
	sp.set_border_width_all(2)
	pastille.add_theme_stylebox_override("panel", sp)
	pastille.tooltip_text = UnitesData.ELEMENTS[u["element"]]
	b.add_child(pastille)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	vb.grow_vertical = Control.GROW_DIRECTION_BEGIN
	vb.offset_left = 5 + bord
	vb.offset_right = -5 - bord
	vb.offset_bottom = -7 - bord
	vb.alignment = BoxContainer.ALIGNMENT_END
	vb.add_theme_constant_override("separation", 1)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	return vb


## Illustration rectangulaire d'une unité (coins arrondis), l'image couvre toute
## la zone. taille = Vector2.ZERO : la taille est donnée par le parent (ancres).
## Renvoie un Panel vide si l'image n'existe pas.
static func _caler_en_haut(zone: AtlasTexture, s: Vector2, cible: Vector2) -> void:
	if cible.x <= 0 or cible.y <= 0:
		return
	var ratio := cible.x / cible.y
	if ratio >= s.x / s.y:
		zone.region = Rect2(0, 0, s.x, s.x / ratio)
	else:
		var l := s.y * ratio
		zone.region = Rect2((s.x - l) / 2.0, 0, l, s.y)


static func illustration(id: String, taille: Vector2, arrondi := 10, bord := Color(0, 0, 0, 0), epais := 0) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.custom_minimum_size = taille
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.05, 0.03, 0.04)
	st.set_corner_radius_all(arrondi)
	st.border_color = bord
	st.set_border_width_all(epais)
	p.add_theme_stylebox_override("panel", st)
	var chemin := chemin_portrait(id)
	if chemin == "":
		return p
	# L'image est découpée par un masque arrondi (le cadre, lui, peut déborder des coins)
	var masque := Panel.new()
	masque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	masque.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sm := st.duplicate() as StyleBoxFlat
	sm.set_border_width_all(0)
	masque.add_theme_stylebox_override("panel", sm)
	masque.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	p.add_child(masque)
	var tex: Texture2D = load(chemin)
	var zone := AtlasTexture.new()
	zone.atlas = tex
	zone.region = Rect2(Vector2.ZERO, tex.get_size())
	var img := TextureRect.new()
	img.texture = zone
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_SCALE
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	masque.add_child(img)
	# L'image couvre la zone en restant calée EN HAUT (la tête n'est jamais coupée) :
	# si la zone est plus large que l'image, on ne coupe que le bas ;
	# si elle est plus haute, on coupe à gauche et à droite.
	p.resized.connect(func(): _caler_en_haut(zone, tex.get_size(), p.size))
	if epais > 0:
		var contour := Panel.new()
		contour.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contour.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var sc := st.duplicate() as StyleBoxFlat
		sc.draw_center = false
		contour.add_theme_stylebox_override("panel", sc)
		p.add_child(contour)
		# Grande illustration avec contour = on pose aussi le cadre de rareté
		encadrer(p, id)
	return p


## Ancienne carte (portrait rond + initiale), gardée pour les unités sans image.
static func _carte_heros_simple(h: Dictionary, largeur: float, hauteur: float) -> Button:
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
	encadrer(b, id, 2.0)
	vb.add_child(portrait(id, hauteur * 0.34))
	var nom := label(u["nom"], 13)
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nom.custom_minimum_size = Vector2(largeur - 12, 0)
	vb.add_child(nom)
	var niv := int(h["niveau"])
	var ligne := label(UiCommun.t("Nv %d  ·  %s") % [niv, "Légende" if u.get("legende", false) else u["rarete"]], 12, bord)
	ligne.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(ligne)
	var nb_et := Fusion.etoiles(h)
	var et := label(("✦ " if UnitesData.est_evolue(id) else "") + Fusion.texte_etoiles(nb_et, false) + ("  ÉVEILLÉ" if nb_et >= Fusion.ETOILES_MAX else ""), 11,
		Color("ff9a5a") if nb_et >= Fusion.ETOILES_MAX else Color("ffd060"))
	et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(et)
	var xp := barre(Color("7ab8ff"), largeur - 30, 5)
	xp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	xp.max_value = Sauvegarde.xp_heros_pour_niveau(niv)
	xp.value = int(h["xp"]) if niv < UnitesData.niveau_max(id) else xp.max_value
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


## Assombrissement des fonds d'écran peints (assets/fonds/) : assez sombre pour que les panneaux
## restent lisibles, assez clair pour que le décor se voie (1.0 = image d'origine).
const TEINTE_FOND := Color(0.72, 0.68, 0.68)

## Image de fond si elle existe (assombrie), sinon rien. Renvoie true si l'image a été mise.
static func fond_image(parent: Control, chemin: String, teinte := Color(0.6, 0.6, 0.6)) -> bool:
	if not ResourceLoader.exists(chemin):
		return false
	Sauvegarde.voir_image(chemin)      # débloque l'image dans la Galerie d'Art
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


## Avatar d'un joueur : portrait de son héros vitrine, sinon cercle gris avec l'initiale du pseudo.
static func avatar(id_unite: String, pseudo: String, diametre: float) -> Panel:
	if id_unite != "" and UnitesData.existe(id_unite):
		var pt := portrait(id_unite, diametre)
		pt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return pt
	var p := Panel.new()
	p.custom_minimum_size = Vector2(diametre, diametre)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sp := StyleBoxFlat.new()
	sp.set_corner_radius_all(int(diametre / 2))
	sp.bg_color = Color(0.22, 0.18, 0.2)
	sp.border_color = C_OR
	sp.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sp)
	var ini := label(pseudo.substr(0, 1).to_upper(), int(diametre * 0.42), Color.WHITE)
	ini.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ini.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ini.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(ini)
	return p
