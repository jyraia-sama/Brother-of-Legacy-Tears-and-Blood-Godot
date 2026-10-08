class_name FenetreAdmin
extends CanvasLayer
## MENU ADMIN (pour tester le jeu) : cases à cocher.
## Cocher une option active l'effet ; la décocher remet exactement comme avant
## (les vraies valeurs de la sauvegarde ne sont jamais modifiées par ces options).
##
##   FenetreAdmin.ouvrir(self)

const C_ADMIN := Color("ff5a4a")

var _cases := {}          # id -> CheckBox
var _change := false


static func ouvrir(parent: Node) -> void:
	if Sauvegarde.admin_deverrouille():
		parent.add_child(FenetreAdmin.new())
	else:
		_demander_code(parent)


## Petite fenêtre qui demande le code Admin avant d'ouvrir le menu.
static func _demander_code(parent: Node) -> void:
	var calque := CanvasLayer.new()
	calque.layer = 71
	parent.add_child(calque)
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.7)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	calque.add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	calque.add_child(centre)
	var panneau := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.02, 0.02, 0.97)
	style.border_color = C_ADMIN
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(22)
	panneau.add_theme_stylebox_override("panel", style)
	panneau.custom_minimum_size = Vector2(460, 0)
	centre.add_child(panneau)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panneau.add_child(vb)

	var titre := Label.new()
	titre.text = "MENU ADMIN"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_size_override("font_size", 26)
	titre.add_theme_color_override("font_color", C_ADMIN)
	vb.add_child(titre)
	var info := Label.new()
	info.text = "Entre le code Admin :"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 17)
	info.add_theme_color_override("font_color", Color(0.85, 0.7, 0.6))
	vb.add_child(info)

	var champ := LineEdit.new()
	champ.secret = true
	champ.placeholder_text = "Code"
	champ.alignment = HORIZONTAL_ALIGNMENT_CENTER
	champ.custom_minimum_size = Vector2(0, 44)
	champ.add_theme_font_size_override("font_size", 20)
	vb.add_child(champ)

	var erreur := Label.new()
	erreur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	erreur.add_theme_font_size_override("font_size", 15)
	erreur.add_theme_color_override("font_color", Color(1.0, 0.45, 0.4))
	vb.add_child(erreur)

	var valider := func():
		if Sauvegarde.verifier_code_admin(champ.text):
			calque.queue_free()
			parent.add_child(FenetreAdmin.new())
		else:
			erreur.text = "Code incorrect."
			champ.text = ""
			champ.grab_focus()

	var bas := HBoxContainer.new()
	bas.alignment = BoxContainer.ALIGNMENT_CENTER
	bas.add_theme_constant_override("separation", 10)
	vb.add_child(bas)
	for t in [["Valider", valider], ["Annuler", calque.queue_free]]:
		var b := Button.new()
		b.text = t[0]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(160, 42)
		b.pressed.connect(t[1])
		bas.add_child(b)
	champ.text_submitted.connect(func(_t: String): valider.call())
	champ.call_deferred("grab_focus")


func _ready() -> void:
	layer = 70
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
	style.bg_color = Color(0.06, 0.02, 0.02, 0.97)
	style.border_color = C_ADMIN
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(22)
	panneau.add_theme_stylebox_override("panel", style)
	panneau.custom_minimum_size = Vector2(820, 0)
	centre.add_child(panneau)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panneau.add_child(vb)

	vb.add_child(_label("MENU ADMIN  —  OPTIONS DE TEST", 26, C_ADMIN, true))
	vb.add_child(_label("Coche une option pour l'activer. Décoche-la pour revenir exactement comme avant :\nta vraie progression (or, objets, stamina, Bestiaire…) n'est jamais modifiée par ces options.", 15, Color(0.8, 0.7, 0.65), true))
	vb.add_child(HSeparator.new())

	var defil := ScrollContainer.new()
	defil.custom_minimum_size = Vector2(0, 520)
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(defil)
	var liste := VBoxContainer.new()
	liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	liste.add_theme_constant_override("separation", 4)
	defil.add_child(liste)
	for o in Sauvegarde.ADMIN_OPTIONS:
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 10)
		var c := CheckBox.new()
		UiCommun.habiller_case(c)
		c.text = o[1]
		c.focus_mode = Control.FOCUS_NONE
		c.custom_minimum_size = Vector2(360, 0)
		c.add_theme_font_size_override("font_size", 17)
		c.button_pressed = Sauvegarde.admin(o[0])
		c.toggled.connect(_basculer.bind(o[0]))
		ligne.add_child(c)
		var d := _label(o[2], 14, Color(0.7, 0.62, 0.58))
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		d.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ligne.add_child(d)
		liste.add_child(ligne)
		_cases[o[0]] = c

	vb.add_child(HSeparator.new())
	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 10)
	bas.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(bas)
	bas.add_child(_bouton("Tout cocher", func(): _tout(true)))
	bas.add_child(_bouton("Tout décocher", func(): _tout(false)))
	bas.add_child(_bouton("Fermer", _fermer))


func _basculer(actif: bool, id: String) -> void:
	Sauvegarde.definir_admin(id, actif)
	_change = true


func _tout(actif: bool) -> void:
	for id in _cases:
		_cases[id].button_pressed = actif      # déclenche _basculer


## En fermant, l'écran actuel est rechargé pour afficher les nouvelles valeurs.
func _fermer() -> void:
	queue_free()
	if _change:
		get_tree().reload_current_scene()


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
	b.custom_minimum_size = Vector2(180, 42)
	b.pressed.connect(action)
	return b


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_fermer()
