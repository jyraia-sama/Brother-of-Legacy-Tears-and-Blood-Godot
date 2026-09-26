class_name EcranInvocation
extends Control
## AUTEL D'INVOCATION
##   Pacte Doré      : x1 / x10 avec de l'or           -> N, R, SR
##   Pacte Supérieur : x1 / x10 avec des Éclats de Pacte Supérieur (lâchés par les boss)
##                     -> SR, SSR, UR, et très rarement un Héros de Légende
## Les taux et la garantie sont affichés. Les résultats se révèlent un par un ;
## clique une carte pour voir la fiche de l'unité.

const SCENE := "res://scenes/invocation.tscn"
const FOND := "res://assets/ui/menu_bg.png"

static var scene_retour := ""

var _lbl_or: Label
var _lbl_eclats: Label
var _lbl_garantie: Label
var _boutons := {}              # "pacte-nombre" -> Button
var _calque: Control
var _occupe := false


func _ready() -> void:
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

	_calque = Control.new()
	_calque.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_calque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_calque)
	_maj()


func _panneau_pacte(pacte: String, couleur: Color, texte: String, monnaie: String, note: String) -> PanelContainer:
	var info: Dictionary = Invocation.PACTES[pacte]
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
	for cle in _boutons:
		var parts: PackedStringArray = cle.split("-")
		_boutons[cle].disabled = not Invocation.peut_payer(parts[0], int(parts[1]))


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
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.8)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	_calque.add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.add_child(centre)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	centre.add_child(vb)
	var titre := UiCommun.label("INVOCATION", 30, UiCommun.C_OR)
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(titre)
	var grille := GridContainer.new()
	grille.columns = mini(5, res.size())
	grille.add_theme_constant_override("h_separation", 12)
	grille.add_theme_constant_override("v_separation", 12)
	vb.add_child(grille)

	var cartes: Array = []
	for r in res:
		var h := Sauvegarde.get_heros(int(r["uid"]))
		var c := UiCommun.carte_heros(h, 150, 190)
		var couleur: Color = UiCommun.COULEURS_RARETE[r["rarete"]]
		c.add_theme_stylebox_override("normal", UiCommun.style_carte(couleur, 0.0, 3))
		if r["nouveau"]:
			UiCommun.badge(c, "NOUVEAU", Color("8aff9a"))
		c.pressed.connect(_fiche_unite.bind(r["id"]))
		c.pivot_offset = Vector2(75, 95)
		c.scale = Vector2(0.0, 1.0)
		c.modulate.a = 0.0
		grille.add_child(c)
		cartes.append([c, r["rarete"]])

	var fermer := UiCommun.bouton("Continuer", 18)
	fermer.custom_minimum_size = Vector2(220, 46)
	fermer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fermer.disabled = true
	fermer.pressed.connect(func():
		voile.queue_free()
		_maj())
	vb.add_child(fermer)

	# Révélation une par une (les plus rares avec un éclat lumineux)
	for x in cartes:
		var c: Button = x[0]
		var rare: bool = x[1] in ["SSR", "UR", "LEG"]
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(c, "scale", Vector2(1.12 if rare else 1.0, 1.0), 0.22)
		tw.tween_property(c, "modulate:a", 1.0, 0.18)
		if rare:
			tw.chain().tween_property(c, "scale", Vector2.ONE, 0.15)
			var eclat := create_tween()
			c.modulate = Color(2.2, 2.0, 1.6, 1.0)
			eclat.tween_property(c, "modulate", Color.WHITE, 0.6)
		await get_tree().create_timer(0.32 if rare else 0.14).timeout
	fermer.disabled = false


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


func _retour() -> void:
	var cible := scene_retour
	if cible == "":
		cible = ProjectSettings.get_setting("application/run/main_scene", "")
	if cible != "":
		get_tree().change_scene_to_file(cible)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and not _occupe:
		_retour()
