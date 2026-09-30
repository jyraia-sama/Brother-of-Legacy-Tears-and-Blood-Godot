class_name EcranInvocation
extends Control
## AUTEL D'INVOCATION
##   Pacte Doré      : x1 / x10 avec de l'or           -> N, R, SR
##   Pacte Supérieur : x1 / x10 avec des Éclats de Pacte Supérieur (lâchés par les boss)
##                     -> SR, SSR, UR, et très rarement un Héros de Légende
## Les taux et la garantie sont affichés. Les résultats se révèlent avec un effet
## d'invocation (plus impressionnant selon la rareté, voir effet_invocation.gd) ;
## clique une carte pour voir la fiche de l'unité.
## BANDEAU DU BAS : invocation spéciale d'un événement ponctuel (voir evenements.gd).

const SCENE := "res://scenes/invocation.tscn"
const FOND := "res://assets/ui/menu_bg.png"

static var scene_retour := ""

var _lbl_or: Label
var _lbl_eclats: Label
var _lbl_garantie: Label
var _boutons := {}              # "pacte-nombre" -> Button
var _calque: Control
var _occupe := false
var _lbl_evenement: Label
var _voile_evenement: Control
var _boutons_sauvage := {}
var _lbl_sceaux: Label
var _lbl_garantie_sauvage: Label


func _ready() -> void:
	Tutoriel.astuce("invocation", self)      # astuce à la première visite
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = UiCommun.C_FOND
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if ResourceLoader.exists(FOND):
		var img := TextureRect.new()
		img.texture = load(FOND)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.modulate = Color(0.24, 0.18, 0.2)
		add_child(img)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 22)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 18)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Retour")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	var titre := UiCommun.label("AUTEL D'INVOCATION", 32, UiCommun.C_OR)
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(titre)
	_lbl_or = UiCommun.label("", 20, Color("ffd060"))
	tete.add_child(_lbl_or)
	_lbl_eclats = UiCommun.label("", 20, Color("c8a0ff"))
	tete.add_child(_lbl_eclats)
	_lbl_sceaux = UiCommun.label("", 20, Color("8ad05a"))
	tete.add_child(_lbl_sceaux)

	var pactes := HBoxContainer.new()
	pactes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pactes.add_theme_constant_override("separation", 24)
	col.add_child(pactes)
	pactes.add_child(_panneau_pacte("dore", Color("d9a93f"),
		"Invocation avec de l'or.\nIdéal pour renforcer ta réserve et remplir ton équipe.",
		"Or", "x10 : au moins un SR garanti."))
	pactes.add_child(_panneau_pacte("superieur", Color("b07ae0"),
		"Invocation avec des Éclats de Pacte Supérieur,\nlâchés par les boss des chapitres.",
		"Éclat", ""))
	pactes.add_child(_panneau_sauvage())

	col.add_child(_creer_banniere())

	_calque = Control.new()
	_calque.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_calque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_calque)
	_maj()


func _panneau_pacte(pacte: String, couleur: Color, texte: String, monnaie: String, note: String) -> PanelContainer:
	var info: Dictionary = Invocation.infos(pacte)
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(couleur))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)
	var t := UiCommun.label(info["nom"].to_upper(), 28, couleur)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var d := UiCommun.label(texte, 16, UiCommun.C_DOUX)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(d)
	vb.add_child(HSeparator.new())

	# Taux de drop
	vb.add_child(UiCommun.label("TAUX D'OBTENTION", 15, UiCommun.C_OR))
	for tx in info["taux"]:
		var ligne := HBoxContainer.new()
		var nom := UiCommun.label(Invocation.NOMS_RARETE[tx[0]], 18, UiCommun.COULEURS_RARETE[tx[0]])
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ligne.add_child(nom)
		var nb := Invocation.pool(tx[0]).size()
		ligne.add_child(UiCommun.label("%s %%   (%d unités)" % [_pourcent(tx[1]), nb], 18))
		vb.add_child(ligne)
	if note != "":
		vb.add_child(UiCommun.label(note, 15, UiCommun.C_DOUX))
	if pacte == "evenement":
		var ev := Evenements.actif()
		var noms: Array = []
		for id in ev.get("vedettes", []):
			noms.append("%s (%s)" % [UnitesData.get_unite(id)["nom"], UiCommun.texte_rarete(id)])
		var v := UiCommun.label("VEDETTES : " + ", ".join(noms), 15, UiCommun.C_OR)
		v.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(v)
		vb.add_child(UiCommun.label("Quand tu obtiens la rareté d'une vedette : %d %% de chance que ce soit elle." % int(float(ev["chance_vedette"]) * 100), 14, UiCommun.C_DOUX))
		vb.add_child(UiCommun.label("La garantie SSR est partagée avec le Pacte Supérieur.", 14, UiCommun.C_DOUX))
	if pacte == "superieur":
		_lbl_garantie = UiCommun.label("", 15, Color("c8a0ff"))
		_lbl_garantie.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(_lbl_garantie)

	var espace := Control.new()
	espace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(espace)
	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 12)
	vb.add_child(boutons)
	for n in [1, 10]:
		var cout := Invocation.prix(pacte, n)
		var unite := "or" if monnaie == "Or" else ("Éclats" if cout > 1 else "Éclat")
		var b := UiCommun.bouton("Invoquer x%d\n%d %s" % [n, cout, unite], 18)
		b.custom_minimum_size = Vector2(0, 70)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_invoquer.bind(pacte, n))
		boutons.add_child(b)
		_boutons["%s-%d" % [pacte, n]] = b
	return p


func _pourcent(x: float) -> String:
	var v := x * 100.0
	return str(snappedf(v, 0.1)) if v < 10.0 else str(int(round(v)))


func _maj() -> void:
	_lbl_or.text = "Or : %d" % Sauvegarde.get_or()
	_lbl_eclats.text = "Éclats : %d" % Sauvegarde.get_objet(Sauvegarde.ECLAT)
	_lbl_garantie.text = "Garantie : un SSR (ou mieux) au plus tard dans %d invocation(s)." % Invocation.avant_garantie()
	for cle in _boutons.keys():
		if not is_instance_valid(_boutons[cle]):
			_boutons.erase(cle)
			continue
		var parts: PackedStringArray = cle.split("-")
		_boutons[cle].disabled = not Invocation.peut_payer(parts[0], int(parts[1]))
	_maj_banniere()
	_lbl_sceaux.text = "Sceaux Sauvages : %d" % Sauvegarde.get_objet(Menagerie.SCEAU)
	_lbl_garantie_sauvage.text = "Garantie : un SSR (ou mieux) au plus tard dans %d invocation(s)." % Menagerie.avant_garantie()
	for n in _boutons_sauvage:
		_boutons_sauvage[n].disabled = not Menagerie.peut_invoquer(n)


# =====================================================================
# Pacte Sauvage (familiers de la Ménagerie)
# =====================================================================

func _panneau_sauvage() -> PanelContainer:
	var couleur := Color("8ad05a")
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(couleur))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)
	var t := UiCommun.label(str(Menagerie.PACTE["nom"]).to_upper(), 28, couleur)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var d := UiCommun.label("Invocation de FAMILIERS avec des Sceaux Sauvages.\nIls partent en chasse avec tes héros N et R (Ménagerie).", 16, UiCommun.C_DOUX)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(d)
	vb.add_child(HSeparator.new())
	vb.add_child(UiCommun.label("TAUX D'OBTENTION", 15, UiCommun.C_OR))
	for tx in Menagerie.PACTE["taux"]:
		var ligne := HBoxContainer.new()
		var nom := UiCommun.label(tx[0], 18, UiCommun.COULEURS_RARETE[tx[0]])
		nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ligne.add_child(nom)
		ligne.add_child(UiCommun.label("%s %%   (%d familiers)" % [_pourcent(tx[1]), FamiliersData.ids(tx[0]).size()], 18))
		vb.add_child(ligne)
	vb.add_child(UiCommun.label("x10 : au moins un SR garanti.", 15, UiCommun.C_DOUX))
	_lbl_garantie_sauvage = UiCommun.label("", 15, couleur)
	_lbl_garantie_sauvage.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_lbl_garantie_sauvage)
	var espace := Control.new()
	espace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(espace)
	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 12)
	vb.add_child(boutons)
	for n in [1, 10]:
		var cout := Menagerie.prix(n)
		var b := UiCommun.bouton("Invoquer x%d\n%d Sceau%s" % [n, cout, "x" if cout > 1 else ""], 18)
		b.custom_minimum_size = Vector2(0, 70)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_invoquer_familiers.bind(n))
		boutons.add_child(b)
		_boutons_sauvage[n] = b
	return p


func _invoquer_familiers(nombre: int) -> void:
	if _occupe:
		return
	var res := Menagerie.invoquer(nombre)
	if res.is_empty():
		return
	Audio.son("coffre")
	_maj()
	var g := GridContainer.new()
	g.columns = mini(5, res.size())
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 12)
	var i := 0
	for r in res:
		var d := FamiliersData.get_familier(r["id"])
		var v := VBoxContainer.new()
		v.custom_minimum_size = Vector2(140, 0)
		v.add_theme_constant_override("separation", 2)
		var m := EcranMenagerie.medaillon(r["id"], 96)
		m.pivot_offset = Vector2(48, 48)
		m.scale = Vector2.ZERO
		v.add_child(m)
		var tw := m.create_tween()
		tw.tween_interval(0.12 * i)
		tw.tween_property(m, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		var n := UiCommun.label(d["nom"], 14, UiCommun.COULEURS_RARETE[d["rarete"]])
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(n)
		var ra := UiCommun.label(d["rarete"] + ("  · NOUVEAU" if r["nouveau"] else ""), 13, Color("ffd060") if r["nouveau"] else UiCommun.C_DOUX)
		ra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(ra)
		g.add_child(v)
		i += 1
	var f := FenetreSimple.new()
	f.largeur = 780.0 if res.size() > 1 else 420.0
	f.titre = "Pacte Sauvage"
	f.contenu = g
	f.boutons = [["Fermer", null], ["Voir la Ménagerie", func():
		EcranBase.scene_retour = SCENE
		get_tree().change_scene_to_file(EcranMenagerie.SCENE)]]
	add_child(f)


# =====================================================================
# Invocation et révélation
# =====================================================================

func _invoquer(pacte: String, nombre: int) -> void:
	if _occupe:
		return
	var res := Invocation.invoquer(pacte, nombre)
	if res.is_empty():
		return
	_occupe = true
	_maj()
	await _reveler(res)
	_occupe = false


func _reveler(res: Array) -> void:
	var effet := EffetInvocation.new()
	effet.resultats = res
	effet.voir_fiche.connect(_fiche_unite)
	_calque.add_child(effet)
	await effet.termine
	_maj()


func _fiche_unite(id: String) -> void:
	var u := UnitesData.get_unite(id)
	var s := UnitesData.stats(id, 1)
	var txt := "%s · %s · %s\n\nPV %d  ATK %d  DEF %d  AGI %d  MAG %d\n\n" % [
		UiCommun.texte_rarete(id), UnitesData.ELEMENTS[u["element"]], UnitesData.ROLES[u["role"]],
		s["pv"], s["atk"], s["def"], s["agi"], s["mag"]]
	for sk in u["skills"]:
		txt += "Niv. %d · %s : %s\n" % [sk["niveau"], sk["nom"], sk["description"]]
	var d := AcceptDialog.new()
	d.title = u["nom"]
	d.dialog_text = txt
	d.dialog_autowrap = true
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(560, 0))


# =====================================================================
# Bandeau d'événement (en bas de l'écran)
# =====================================================================

func _creer_banniere() -> Button:
	var ev := Evenements.actif()
	var couleur := Color("#" + str(ev.get("couleur", "5a4a4a")))
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 150)
	b.focus_mode = Control.FOCUS_NONE
	b.clip_contents = true
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not ev.is_empty() else Control.CURSOR_ARROW
	for etat in ["normal", "hover", "pressed", "disabled"]:
		var st := StyleBoxFlat.new()
		st.bg_color = couleur.darkened(0.8) if etat != "hover" else couleur.darkened(0.7)
		st.border_color = couleur if etat == "hover" else couleur.darkened(0.2)
		st.set_border_width_all(3)
		st.set_corner_radius_all(10)
		b.add_theme_stylebox_override(etat, st)
	if not ev.is_empty():
		var fond := Control.new()
		fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(fond)
		if not UiCommun.fond_image(fond, "res://assets/invocation/evenements/%s.png" % ev["id"], Color.WHITE):
			var g := Gradient.new()
			g.set_color(0, couleur.darkened(0.3))
			g.set_color(1, Color(0.05, 0.0, 0.02))
			var tex := GradientTexture2D.new()
			tex.gradient = g
			tex.width = 256
			tex.height = 8
			var r := TextureRect.new()
			r.texture = tex
			r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			r.stretch_mode = TextureRect.STRETCH_SCALE
			r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fond.add_child(r)
			var p := UiCommun.particules(fond, couleur.lightened(0.3), true, 25)
			p.position = Vector2(800, 170)
			p.emission_rect_extents = Vector2(800, 5)
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 24
	h.offset_right = -24
	h.add_theme_constant_override("separation", 20)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var textes := VBoxContainer.new()
	textes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textes.alignment = BoxContainer.ALIGNMENT_CENTER
	textes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(textes)
	if ev.is_empty():
		textes.add_child(UiCommun.label("INVOCATION SPÉCIALE", 16, UiCommun.C_DOUX))
		textes.add_child(UiCommun.label("Aucun événement en ce moment", 26, UiCommun.C_DOUX))
		_lbl_evenement = UiCommun.label("", 16, UiCommun.C_DOUX)
		textes.add_child(_lbl_evenement)
		return b
	textes.add_child(UiCommun.label("ÉVÉNEMENT · INVOCATION SPÉCIALE", 15, couleur.lightened(0.4)))
	var t := UiCommun.label(ev["titre"], 36, couleur.lightened(0.25))
	t.add_theme_color_override("font_outline_color", Color.BLACK)
	t.add_theme_constant_override("outline_size", 8)
	textes.add_child(t)
	var st2 := UiCommun.label(ev["sous_titre"], 15, UiCommun.C_TEXTE)
	st2.add_theme_color_override("font_outline_color", Color.BLACK)
	st2.add_theme_constant_override("outline_size", 4)
	textes.add_child(st2)
	_lbl_evenement = UiCommun.label("", 16, Color("ffb070"))
	_lbl_evenement.add_theme_color_override("font_outline_color", Color.BLACK)
	_lbl_evenement.add_theme_constant_override("outline_size", 4)
	textes.add_child(_lbl_evenement)
	for id in ev["vedettes"]:
		var v := VBoxContainer.new()
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(UiCommun.portrait(id, 70))
		var n := UiCommun.label(UnitesData.get_unite(id)["nom"], 13, UiCommun.couleur_rarete(id))
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.add_theme_color_override("font_outline_color", Color.BLACK)
		n.add_theme_constant_override("outline_size", 4)
		v.add_child(n)
		h.add_child(v)
	var go := UiCommun.label("▶  INVOQUER", 24, couleur.lightened(0.4))
	go.add_theme_color_override("font_outline_color", Color.BLACK)
	go.add_theme_constant_override("outline_size", 6)
	go.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(go)
	b.pressed.connect(_ouvrir_evenement)
	var minuterie := Timer.new()
	minuterie.wait_time = 1.0
	minuterie.autostart = true
	minuterie.timeout.connect(_maj_banniere)
	b.add_child(minuterie)
	return b


func _maj_banniere() -> void:
	if _lbl_evenement == null:
		return
	var ev := Evenements.actif()
	if not ev.is_empty():
		_lbl_evenement.text = "Se termine dans %s" % Calendrier.texte_duree(Evenements.secondes_restantes(ev))
	else:
		var pr := Evenements.prochain()
		_lbl_evenement.text = "" if pr.is_empty() else "Prochain : %s dans %s" % [pr["titre"], Calendrier.texte_duree(Evenements.secondes_avant_debut(pr))]


func _ouvrir_evenement() -> void:
	var ev := Evenements.actif()
	if ev.is_empty() or _occupe:
		return
	_voile_evenement = ColorRect.new()
	(_voile_evenement as ColorRect).color = Color(0, 0, 0, 0.75)
	_voile_evenement.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_voile_evenement)
	move_child(_voile_evenement, _calque.get_index())
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_voile_evenement.add_child(centre)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	centre.add_child(vb)
	var panneau := _panneau_pacte("evenement", Color("#" + str(ev["couleur"])).lightened(0.2), ev["sous_titre"], "Éclat", "")
	panneau.custom_minimum_size = Vector2(760, 560)
	vb.add_child(panneau)
	var fermer := UiCommun.bouton("Fermer", 17)
	fermer.custom_minimum_size = Vector2(200, 44)
	fermer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fermer.pressed.connect(func():
		_voile_evenement.queue_free()
		_voile_evenement = null)
	vb.add_child(fermer)
	_maj()


func _retour() -> void:
	var cible := scene_retour
	if cible == "":
		cible = ProjectSettings.get_setting("application/run/main_scene", "")
	if cible != "":
		get_tree().change_scene_to_file(cible)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and not _occupe:
		_retour()
