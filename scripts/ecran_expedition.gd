class_name EcranExpedition
extends Control
## EXPÉDITIONS : le point de départ de la Marche Maudite et de la Compagnie,
## avec la boutique des Sceaux de Marche.

const SCENE := "res://scenes/expedition.tscn"
const C_SANG := Color("d04a3a")
const C_BLEU := Color("7ab8ff")

static var scene_retour := ""

var _boutique: VBoxContainer
var _lbl_sceaux: Label
var _lbl_marche: Label
var _lbl_compagnie: Label


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = Color("0a0708")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if not UiCommun.fond_image(self, "res://assets/expedition/expedition_bg.png", Color(0.45, 0.42, 0.42)):
		UiCommun.fond_degrade(self, Color("2a1210"), Color("050304"))
	UiCommun.particules(self, Color("ff7a4a"), true, 30)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 22)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 16)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Aventure")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	tete.add_child(UiCommun.label("EXPÉDITIONS", 34, UiCommun.C_OR))
	var pousse := Control.new()
	pousse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(pousse)
	_lbl_sceaux = UiCommun.label("", 20, C_SANG.lightened(0.3))
	tete.add_child(_lbl_sceaux)

	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 18)
	col.add_child(corps)

	var cartes := VBoxContainer.new()
	cartes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cartes.add_theme_constant_override("separation", 18)
	corps.add_child(cartes)
	_lbl_marche = UiCommun.label("", 16, UiCommun.C_TEXTE)
	cartes.add_child(_grande_carte("LA MARCHE MAUDITE", "Traverse trois régions maudites sur une carte à embranchements.\n"
		+ "Bénédictions, Pactes de Sang, recrues et événements : chaque choix compte.\nUne marche par jour, la même pour tous : vise le meilleur score !",
		C_SANG, "marche_bg", _lbl_marche, func():
			EcranMarche.scene_retour = SCENE
			get_tree().change_scene_to_file(Marche.SCENE)))
	_lbl_compagnie = UiCommun.label("", 16, UiCommun.C_TEXTE)
	cartes.add_child(_grande_carte("LA COMPAGNIE", "Envoie les unités qui ne combattent pas en missions de 1 h à 12 h.\n"
		+ "Remplis les conditions, vise l'objectif bonus, et récupère le butin à leur retour — même jeu fermé.",
		C_BLEU, "compagnie_bg", _lbl_compagnie, func():
			EcranCompagnie.scene_retour = SCENE
			get_tree().change_scene_to_file(Compagnie.SCENE)))

	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(620, 0)
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_SANG.darkened(0.3)))
	corps.add_child(p)
	var defil := ScrollContainer.new()
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(defil)
	_boutique = VBoxContainer.new()
	_boutique.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boutique.add_theme_constant_override("separation", 8)
	defil.add_child(_boutique)

	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(_maj_etats)
	add_child(t)
	_maj_etats()
	_remplir_boutique()


func _grande_carte(titre: String, texte: String, c: Color, image: String, etat: Label, action: Callable) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var st := UiCommun.style_carte(c.darkened(0.2), 0.0, 3)
	st.bg_color = c.darkened(0.85)
	var sh := st.duplicate() as StyleBoxFlat
	sh.border_color = c
	sh.shadow_color = Color(c, 0.45)
	sh.shadow_size = 14
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", sh)
	b.add_theme_stylebox_override("pressed", sh)
	b.pressed.connect(func():
		Audio.son("clic")
		action.call())
	var chemin := "res://assets/expedition/%s.png" % image
	if ResourceLoader.exists(chemin):
		var img := TextureRect.new()
		img.texture = load(chemin)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.modulate = Color(0.55, 0.5, 0.5)
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.offset_left = 3
		img.offset_top = 3
		img.offset_right = -3
		img.offset_bottom = -3
		b.add_child(img)
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 30
	vb.offset_right = -30
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	var t := UiCommun.label(titre, 40, c.lightened(0.3))
	t.add_theme_color_override("font_outline_color", Color.BLACK)
	t.add_theme_constant_override("outline_size", 8)
	vb.add_child(t)
	var d := UiCommun.label(texte, 17, UiCommun.C_TEXTE)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_color_override("font_outline_color", Color.BLACK)
	d.add_theme_constant_override("outline_size", 4)
	vb.add_child(d)
	etat.add_theme_color_override("font_outline_color", Color.BLACK)
	etat.add_theme_constant_override("outline_size", 4)
	etat.add_theme_font_size_override("font_size", 18)
	etat.add_theme_color_override("font_color", c.lightened(0.45))
	vb.add_child(etat)
	return b


func _maj_etats() -> void:
	_lbl_sceaux.text = "Sceaux de Marche : %d" % Sauvegarde.get_objet("sceau_marche")
	var p := Marche.partie()
	if Marche.en_cours():
		_lbl_marche.text = "▶ Marche en cours — %s, score %d" % [Marche.nom_region(int(p["region"])), int(p["score"])]
	elif Marche.deja_jouee():
		_lbl_marche.text = "✔ Marche du jour terminée : %d points. Nouvelle marche dans %s." % [
			int(p["resultat"].get("score", 0)), Calendrier.texte_duree(Calendrier.secondes_avant_demain())]
	else:
		_lbl_marche.text = "La Marche du jour t'attend.   Record : %d" % Marche.record()
	var n := Compagnie.en_cours().size()
	var prets := Compagnie.nombre_a_recuperer()
	_lbl_compagnie.text = "Escouades en mission : %d / %d%s" % [n, Compagnie.ESCOUADES_MAX,
		("   ·   %d mission%s terminée%s à récupérer !" % [prets, "s" if prets > 1 else "", "s" if prets > 1 else ""]) if prets > 0 else ""]


# =====================================================================
# Boutique
# =====================================================================

func _remplir_boutique() -> void:
	for e in _boutique.get_children():
		e.queue_free()
	_boutique.add_child(UiCommun.label("BOUTIQUE DES EXPÉDITIONS", 20, UiCommun.C_OR))
	var s := UiCommun.label("Les Sceaux de Marche se gagnent dans la Marche Maudite (selon le score) et dans les missions épiques de la Compagnie. Les limites d'achat reviennent chaque lundi.", 13, UiCommun.C_DOUX)
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_boutique.add_child(s)
	_boutique.add_child(HSeparator.new())
	for i in Marche.BOUTIQUE.size():
		var a: Dictionary = Marche.BOUTIQUE[i]
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 10)
		ligne.add_child(UiCommun.icone_objet(a["id"], 44))
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ligne.add_child(vb)
		vb.add_child(UiCommun.label("%s  x%d" % [Reliquaire.nom(a["id"]), int(a["quantite"])], 16, UiCommun.C_TEXTE))
		var reste := Marche.achats_restants(a)
		vb.add_child(UiCommun.label("Encore %d cette semaine" % reste, 12, UiCommun.C_DOUX))
		var b := UiCommun.bouton("%d Sceaux" % int(a["prix"]), 15)
		b.custom_minimum_size = Vector2(130, 40)
		b.disabled = reste <= 0 or Sauvegarde.get_objet("sceau_marche") < int(a["prix"])
		b.pressed.connect(func():
			var r := Marche.acheter_boutique(i)
			if r != "":
				Audio.son("erreur")
			else:
				Audio.son("or")
			_maj_etats()
			_remplir_boutique())
		ligne.add_child(b)
		_boutique.add_child(ligne)


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour if scene_retour != "" else "res://scenes/aventure.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
