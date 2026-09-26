class_name FenetreChangelog
extends CanvasLayer
## Fenêtre « Journal des mises à jour » : toutes les versions du jeu (voir version.gd).
##
##   FenetreChangelog.ouvrir(self)               -> tout le journal
##   FenetreChangelog.ouvrir(self, true)         -> « Nouveautés » après une mise à jour
## À la fermeture, la version actuelle est notée comme « vue » dans la sauvegarde.

const C_OR := Color(0.85, 0.65, 0.3)

var nouveautes := false


static func ouvrir(parent: Node, seulement_nouveautes := false) -> void:
	var f := FenetreChangelog.new()
	f.nouveautes = seulement_nouveautes
	parent.add_child(f)


## À appeler depuis le menu principal : ouvre les nouveautés si le jeu a été mis à jour.
static func verifier_mise_a_jour(parent: Node) -> void:
	Sauvegarde.charger()
	if str(Sauvegarde.donnees.get("version_vue", "")) != Version.NUMERO:
		ouvrir(parent, true)


func _ready() -> void:
	layer = 60
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.7)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var panneau := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.02, 0.03, 0.97)
	style.border_color = C_OR
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(22)
	panneau.add_theme_stylebox_override("panel", style)
	panneau.custom_minimum_size = Vector2(900, 700)
	centre.add_child(panneau)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panneau.add_child(vb)

	var vue := str(Sauvegarde.donnees.get("version_vue", ""))
	var liste: Array = Version.HISTORIQUE
	var titre := "JOURNAL DES MISES À JOUR"
	if nouveautes:
		liste = Version.nouveautes_depuis(vue)
		titre = "NOUVEAUTÉS — VERSION %s" % Version.NUMERO
		if liste.is_empty():
			liste = [Version.HISTORIQUE[0]]
	vb.add_child(_label(titre, 28, Color(1.0, 0.85, 0.55), true))
	vb.add_child(_label("%s  ·  version actuelle %s (%s)" % [Version.NOM_JEU, Version.texte(), Version.DATE], 15, Color(0.7, 0.62, 0.58), true))
	vb.add_child(HSeparator.new())

	var defil := ScrollContainer.new()
	defil.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(defil)
	var contenu := VBoxContainer.new()
	contenu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenu.add_theme_constant_override("separation", 6)
	defil.add_child(contenu)
	for v in liste:
		var actuelle: bool = v["version"] == Version.NUMERO
		var entete := _label("v%s — %s%s" % [v["version"], v["titre"], "   (actuelle)" if actuelle else ""], 21,
			Color("ffd27a") if actuelle else C_OR)
		contenu.add_child(entete)
		contenu.add_child(_label(_date_fr(v["date"]), 13, Color(0.66, 0.59, 0.55)))
		for c in v["changements"]:
			contenu.add_child(_label("•  " + str(c), 16, Color(0.93, 0.88, 0.83)))
		var esp := Control.new()
		esp.custom_minimum_size = Vector2(0, 10)
		contenu.add_child(esp)

	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 10)
	bas.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(bas)
	if nouveautes:
		bas.add_child(_bouton("Voir tout le journal", func():
			FenetreChangelog.ouvrir(get_parent())
			queue_free()))
	bas.add_child(_bouton("Fermer", queue_free))
	# La version actuelle est maintenant « vue »
	Sauvegarde.donnees["version_vue"] = Version.NUMERO
	Sauvegarde.sauvegarder()


func _date_fr(iso: String) -> String:
	var p := iso.split("-")
	if p.size() != 3:
		return iso
	var mois := ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
	return "%d %s %s" % [int(p[2]), mois[clampi(int(p[1]) - 1, 0, 11)], p[0]]


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
	b.custom_minimum_size = Vector2(200, 42)
	b.pressed.connect(action)
	return b


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
