class_name CaseStamina
extends PanelContainer
## Case STAMINA détaillée (la même que sur le menu principal) : « ⚡ 24 / 30 », une barre,
## et « Pleine » ou « +1 dans 3 min 12 s ». Se met à jour toute seule chaque seconde.
## Utilisation : tete.add_child(CaseStamina.new())  — appeler maj() après une dépense.

const C_STAMINA := Color("7fc2e8")

var _lbl: Label
var _barre: ProgressBar
var _recharge: Label


func _init(largeur := 190.0) -> void:
	custom_minimum_size = Vector2(largeur, 46)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tooltip_text = "Stamina : +1 point toutes les 5 minutes.\nLes Élixirs du Reliquaire et la Boutique la rechargent."
	mouse_filter = Control.MOUSE_FILTER_PASS
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.02, 0.024, 0.88)
	st.border_color = Color("4a3638")
	st.set_border_width_all(1)
	st.set_corner_radius_all(12)
	st.content_margin_left = 6
	st.content_margin_right = 10
	st.content_margin_top = 4
	st.content_margin_bottom = 4
	add_theme_stylebox_override("panel", st)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(h)
	var ic := Label.new()
	ic.text = "⚡"
	ic.custom_minimum_size = Vector2(30, 30)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ic.add_theme_font_size_override("font_size", 16)
	ic.add_theme_color_override("font_color", C_STAMINA)
	var sic := StyleBoxFlat.new()
	sic.bg_color = Color("163248")
	sic.set_corner_radius_all(15)
	ic.add_theme_stylebox_override("normal", sic)
	h.add_child(ic)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	_lbl = _texte(15, Color("ede4d8"))
	v.add_child(_lbl)
	_barre = ProgressBar.new()
	_barre.show_percentage = false
	_barre.custom_minimum_size = Vector2(0, 4)
	_barre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sf := StyleBoxFlat.new()
	sf.bg_color = Color("22303a")
	sf.set_corner_radius_all(2)
	var sr := StyleBoxFlat.new()
	sr.bg_color = C_STAMINA
	sr.set_corner_radius_all(2)
	_barre.add_theme_stylebox_override("background", sf)
	_barre.add_theme_stylebox_override("fill", sr)
	v.add_child(_barre)
	_recharge = _texte(11, Color("b3a597"))
	v.add_child(_recharge)

	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(maj)
	add_child(t)
	maj()


func maj() -> void:
	var st := Sauvegarde.get_stamina()
	var mx := Sauvegarde.get_stamina_max()
	_lbl.text = "%d / %d" % [st, mx]
	_barre.max_value = maxi(1, mx)
	_barre.value = mini(st, mx)
	_recharge.text = "Pleine" if st >= mx else UiCommun.t("+1 dans %s") % Calendrier.texte_duree(Sauvegarde.secondes_avant_stamina())


func _texte(taille: int, couleur: Color) -> Label:
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", taille)
	l.add_theme_color_override("font_color", couleur)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 3)
	return l
