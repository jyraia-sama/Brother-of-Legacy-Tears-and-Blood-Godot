class_name FenetreJournal
extends CanvasLayer
## JOURNAL DE L'HISTOIRE : liste des scènes déjà vues, Acte par Acte, pour les revoir.

var _liste: VBoxContainer


static func ouvrir(parent: Node) -> void:
	parent.add_child(FenetreJournal.new())


func _ready() -> void:
	layer = 50
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.7)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var p := PanelContainer.new()
	var vp := get_viewport().get_visible_rect().size
	p.custom_minimum_size = Vector2(minf(1100.0, vp.x - 40.0), minf(760.0, vp.y - 40.0))
	var st := UiCommun.style_panneau(UiCommun.C_OR, Color(0.07, 0.02, 0.03, 0.98))
	st.set_content_margin_all(18)
	p.add_theme_stylebox_override("panel", st)
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	var tete := HBoxContainer.new()
	vb.add_child(tete)
	var t := UiCommun.label("JOURNAL DE L'HISTOIRE", 28, UiCommun.C_OR)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	var fermer := UiCommun.bouton("Fermer", 16)
	fermer.pressed.connect(queue_free)
	tete.add_child(fermer)
	vb.add_child(UiCommun.label("Les scènes déjà vues peuvent être revues ici. Les autres se débloquent en avançant dans l'histoire.", 14, UiCommun.C_DOUX))
	var defil := ScrollContainer.new()
	defil.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(defil)
	_liste = VBoxContainer.new()
	_liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_liste.add_theme_constant_override("separation", 6)
	defil.add_child(_liste)
	_remplir()


func _remplir() -> void:
	var rien := true
	for a in ActesData.ACTES:
		var n := int(a["numero"])
		var lignes: Array = []
		for c in range(1, 7):
			for moment in ["debut", "fin"]:
				if DialoguesData.a_dialogue(n, c, moment) and DialoguesData.vu(n, c, moment):
					lignes.append([c, moment])
		if lignes.is_empty():
			continue
		rien = false
		_liste.add_child(UiCommun.label("ACTE %s — %s" % [a["romain"], a["titre"]], 19, UiCommun.C_OR))
		var g := GridContainer.new()
		g.columns = 2
		g.add_theme_constant_override("h_separation", 10)
		g.add_theme_constant_override("v_separation", 6)
		_liste.add_child(g)
		for l in lignes:
			var chap := ActesData.get_chapitre(n, int(l[0]))
			var b := UiCommun.bouton("%d. %s  (%s)" % [int(l[0]), chap.get("titre", ""), "début" if l[1] == "debut" else "fin"], 15)
			b.custom_minimum_size = Vector2(500, 38)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.pressed.connect(func(): FenetreDialogue.jouer(get_parent(), n, int(l[0]), l[1], true))
			g.add_child(b)
	if rien:
		_liste.add_child(UiCommun.label("Aucune scène vue pour l'instant : commence l'Acte I !", 17, UiCommun.C_TEXTE))


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
