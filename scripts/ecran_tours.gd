class_name EcranTours
extends Control
## TOURS INFINIES : choix entre la Tour de l'Enfer et la Tour du Paradis.
## Affiche l'étage atteint, le record et le compte à rebours avant la réinitialisation (lundi 00:00).

const SCENE := "res://scenes/tours.tscn"
const FOND := "res://assets/tours/tours_bg.png"

static var scene_retour := ""

var _lbl_decompte: Label
var _lbl_stamina: Label


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = Color("0c0708")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if not UiCommun.fond_image(self, FOND, Color(0.55, 0.55, 0.55)):
		# Moitié gauche infernale, moitié droite céleste
		var g := Gradient.new()
		g.set_color(0, Color("3a0804"))
		g.add_point(0.5, Color("120a10"))
		g.set_color(g.get_point_count() - 1, Color("3a3a50"))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.width = 256
		tex.height = 8
		var r := TextureRect.new()
		r.texture = tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(r)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 22)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 16)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Retour")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	var titre := UiCommun.label("TOURS INFINIES", 34, UiCommun.C_OR)
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(titre)
	_lbl_stamina = UiCommun.label("", 20, Color("7ad0ff"))
	tete.add_child(_lbl_stamina)

	_lbl_decompte = UiCommun.label("", 20, Color("ffb070"))
	_lbl_decompte.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_lbl_decompte)

	var ligne := HBoxContainer.new()
	ligne.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ligne.add_theme_constant_override("separation", 30)
	col.add_child(ligne)
	ligne.add_child(_carte_tour("enfer", Color("ff4a2a"), Color("2a0503"), Color("080102")))
	ligne.add_child(_carte_tour("paradis", Color("ffe08a"), Color("f0ecff"), Color("5a6a9a")))

	var aide := UiCommun.label("Chaque étage = 1 combat (stamina). Élite tous les 5 étages, BOSS tous les 10, SUPER BOSS à l'étage 100.\nLe butin spécial de chaque étage se gagne une fois par semaine. Chaque lundi à 00:00, les tours se réinitialisent.", 15, UiCommun.C_DOUX)
	aide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(aide)

	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(_maj)
	add_child(t)
	_maj()


func _carte_tour(tour: String, accent: Color, haut: Color, bas: Color) -> Button:
	var d: Dictionary = Tours.TOURS[tour]
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.clip_contents = true
	for etat in ["normal", "hover", "pressed"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0, 0, 0, 0)
		st.border_color = accent if etat != "normal" else accent.darkened(0.35)
		st.set_border_width_all(4 if etat != "normal" else 3)
		st.set_corner_radius_all(14)
		b.add_theme_stylebox_override(etat, st)
	# Fond de la carte : image si fournie, sinon dégradé
	var fond := Control.new()
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fond.show_behind_parent = true
	b.add_child(fond)
	if not UiCommun.fond_image(fond, "res://assets/tours/%s_carte.png" % tour, Color(0.85, 0.85, 0.85)):
		UiCommun.fond_degrade(fond, haut if tour == "paradis" else bas, bas if tour == "paradis" else haut)
		var p := UiCommun.particules(fond, accent, tour == "enfer", 30)
		p.position = Vector2(380, 760 if tour == "enfer" else -10)
		p.emission_rect_extents = Vector2(380, 10)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 10)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	var sombre := tour == "enfer"
	var c_txt := Color("ffe0d0") if sombre else Color("2a2440")
	var nom := UiCommun.label(str(d["nom"]).to_upper(), 40, accent if sombre else Color("8a6a10"))
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.add_theme_color_override("font_outline_color", Color.BLACK if sombre else Color.WHITE)
	nom.add_theme_constant_override("outline_size", 8)
	vb.add_child(nom)
	var st := UiCommun.label(d["sous_titre"], 18, c_txt)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(st)
	vb.add_child(HSeparator.new())
	var atteint := Tours.etage_atteint(tour)
	var info := UiCommun.label("Étage atteint cette semaine : %d / %d\nRecord absolu : %d\n%s : %d" % [
		atteint, Tours.ETAGES, Tours.record(tour), Reliquaire.nom(d["monnaie"]), Sauvegarde.get_objet(d["monnaie"])], 20, c_txt)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(info)
	var prochain := UiCommun.label("TOUR CONQUISE !" if Tours.tour_terminee(tour) else "Prochain : étage %d — %s" % [
		Tours.prochain_etage(tour), Tours.palier(tour, Tours.prochain_etage(tour))["nom"]], 17,
		accent if sombre else Color("6a4a00"))
	prochain.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(prochain)
	var entrer := UiCommun.label("▶  ENTRER", 26, accent if sombre else Color("8a6a10"))
	entrer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entrer.add_theme_color_override("font_outline_color", Color.BLACK if sombre else Color.WHITE)
	entrer.add_theme_constant_override("outline_size", 6)
	vb.add_child(entrer)
	b.pressed.connect(_entrer.bind(tour))
	return b


func _maj() -> void:
	_lbl_decompte.text = "Réinitialisation des tours dans  %s" % Calendrier.texte_duree(Calendrier.secondes_avant_semaine())
	_lbl_stamina.text = "Stamina : %d / %d" % [Sauvegarde.get_stamina(), Sauvegarde.get_stamina_max()]


func _entrer(tour: String) -> void:
	EcranTour.tour_courante = tour
	EcranTour.scene_retour = SCENE
	get_tree().change_scene_to_file(EcranTour.SCENE)


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
