class_name FenetreSimple
extends CanvasLayer
## Petite fenêtre par-dessus l'écran : titre, texte, contenu libre et boutons.
##
##   FenetreSimple.ouvrir(self, "Titre", "Texte")                         -> bouton « Fermer »
##   FenetreSimple.ouvrir(self, "Titre", "Texte", [["OK", func(): ...]])
##   FenetreSimple.confirmer(self, "Exclure ?", "Texte", "Exclure", func(): ...)
## Chaque bouton ferme la fenêtre puis lance son action (null = fermer seulement).

var titre := ""
var texte := ""
var boutons: Array = []
var contenu: Control = null
var largeur := 540.0


static func ouvrir(parent: Node, p_titre: String, p_texte: String, p_boutons: Array = [], p_contenu: Control = null) -> FenetreSimple:
	var f := FenetreSimple.new()
	f.titre = p_titre
	f.texte = p_texte
	f.boutons = p_boutons if not p_boutons.is_empty() else [["Fermer", null]]
	f.contenu = p_contenu
	parent.add_child(f)
	return f


static func confirmer(parent: Node, p_titre: String, p_texte: String, texte_ok: String, action: Callable) -> FenetreSimple:
	return ouvrir(parent, p_titre, p_texte, [["Annuler", null], [texte_ok, action]])


func _ready() -> void:
	layer = 55
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.65)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	var panneau := PanelContainer.new()
	var style := UiCommun.style_panneau()
	style.set_content_margin_all(22)
	panneau.add_theme_stylebox_override("panel", style)
	panneau.custom_minimum_size = Vector2(largeur, 0)
	centre.add_child(panneau)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panneau.add_child(vb)

	var t := UiCommun.label(titre, 26, Color(1.0, 0.85, 0.55))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	if texte != "":
		var l := UiCommun.label(texte, 18)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(largeur - 44, 0)
		vb.add_child(l)
	if contenu != null:
		vb.add_child(contenu)

	var ligne := HBoxContainer.new()
	ligne.add_theme_constant_override("separation", 10)
	ligne.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(ligne)
	for b in boutons:
		var bouton := UiCommun.bouton(str(b[0]))
		bouton.custom_minimum_size = Vector2(150, 42)
		var action = b[1] if b.size() > 1 else null
		bouton.pressed.connect(_clic.bind(action))
		ligne.add_child(bouton)


func _clic(action) -> void:
	queue_free()
	if action is Callable and action.is_valid():
		action.call()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
