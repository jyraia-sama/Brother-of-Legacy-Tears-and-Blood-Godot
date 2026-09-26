class_name FenetreSauvegarde
extends CanvasLayer
## Fenêtre "Sauvegarde" : infos de la partie, export/import par code, nouvelle partie.
##
## Pour l'ouvrir depuis n'importe quel écran :
##   FenetreSauvegarde.ouvrir(self)

var _zone_code: TextEdit
var _etat: Label


static func ouvrir(parent: Node) -> void:
	var f := FenetreSauvegarde.new()
	parent.add_child(f)


func _ready() -> void:
	layer = 50

	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.65)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var panneau := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.02, 0.03, 0.97)
	style.border_color = Color(0.85, 0.65, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(22)
	panneau.add_theme_stylebox_override("panel", style)
	panneau.custom_minimum_size = Vector2(620, 0)
	centre.add_child(panneau)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panneau.add_child(vb)

	vb.add_child(_label("SAUVEGARDE", 28, Color(1.0, 0.85, 0.55), true))
	vb.add_child(_label(_resume(), 18, Color(0.92, 0.88, 0.85)))
	vb.add_child(HSeparator.new())

	vb.add_child(_label("Code de sauvegarde (pour transférer ta partie ou la garder de côté) :", 16, Color(0.85, 0.7, 0.6)))
	_zone_code = TextEdit.new()
	_zone_code.custom_minimum_size = Vector2(0, 90)
	_zone_code.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_zone_code.placeholder_text = "Colle ici un code pour l'importer…"
	vb.add_child(_zone_code)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	vb.add_child(ligne)
	ligne.add_child(_bouton("Copier mon code", _copier))
	ligne.add_child(_bouton("Importer ce code", _importer))
	ligne.add_child(_bouton("Nouvelle partie", _demander_reset))

	_etat = _label("", 16, Color(1.0, 0.8, 0.5))
	vb.add_child(_etat)

	vb.add_child(HSeparator.new())
	var lv := HBoxContainer.new()
	lv.add_theme_constant_override("separation", 10)
	vb.add_child(lv)
	var t_version := _label("Version du jeu : %s  (%s)" % [Version.texte(), Version.DATE], 16, Color(0.85, 0.7, 0.6))
	t_version.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_child(t_version)
	var journal := _bouton("Journal des mises à jour", func(): FenetreChangelog.ouvrir(get_parent()))
	journal.size_flags_horizontal = Control.SIZE_SHRINK_END
	journal.custom_minimum_size = Vector2(240, 40)
	lv.add_child(journal)

	var fermer := _bouton("Fermer", queue_free)
	fermer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(fermer)


func _resume() -> String:
	var d: Dictionary = Sauvegarde.donnees
	var date := Time.get_datetime_string_from_unix_time(int(d.get("sauvegarde_le", 0)) + _decalage_horaire(), true)
	return "Niveau de compte : %d / %d   (XP %d / %d)\nOr : %d     Gemmes : %d     Stamina : %d / %d\nChapitres terminés : %d / 72\nDernière sauvegarde : %s" % [
		Sauvegarde.get_niveau_compte(), Sauvegarde.NIVEAU_COMPTE_MAX, Sauvegarde.get_xp_compte(), Sauvegarde.xp_pour_niveau(Sauvegarde.get_niveau_compte()),
		Sauvegarde.get_or(), Sauvegarde.get_gemmes(), Sauvegarde.get_stamina(), Sauvegarde.get_stamina_max(),
		Sauvegarde.nombre_chapitres_termines(), date]


func _decalage_horaire() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


func _copier() -> void:
	var code := Sauvegarde.exporter_code()
	_zone_code.text = code
	DisplayServer.clipboard_set(code)
	_etat.text = "Code copié ! Garde-le précieusement (dans un fichier texte par exemple)."


func _importer() -> void:
	if _zone_code.text.strip_edges() == "":
		_etat.text = "Colle d'abord un code dans la zone ci-dessus."
		return
	if Sauvegarde.importer_code(_zone_code.text):
		_etat.text = "Partie importée !"
		get_tree().reload_current_scene()
	else:
		_etat.text = "Ce code n'est pas valide."


func _demander_reset() -> void:
	var d := ConfirmationDialog.new()
	d.title = "Nouvelle partie"
	d.dialog_text = "Effacer TOUTE la progression et recommencer depuis l'Acte I ?\nTu pourras choisir à nouveau ton héros de départ.\n\nConseil : copie d'abord ton code de sauvegarde."
	d.ok_button_text = "Tout effacer"
	d.cancel_button_text = "Annuler"
	d.confirmed.connect(func():
		Sauvegarde.reinitialiser()
		get_tree().change_scene_to_file(EcranChoixHeros.SCENE))
	add_child(d)
	d.popup_centered(Vector2i(460, 0))


func _label(texte: String, taille: int, couleur: Color, centre := false) -> Label:
	var l := Label.new()
	l.text = texte
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	if centre:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _bouton(texte: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = texte
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 40)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	return b


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
