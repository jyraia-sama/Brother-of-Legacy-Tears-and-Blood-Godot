class_name EcranBase
extends Control
## Base commune des écrans simples du menu principal (Quêtes, Succès, Boutique, Mon héros) :
## fond du menu assombri, en-tête (retour, titre, ressources) et une zone de contenu.
## Les écrans enfants remplissent _contenu dans _remplir() et appellent rafraichir() après un changement.

const FOND := "res://assets/ui/menu_bg.png"

static var scene_retour := ""

var _contenu: VBoxContainer
var _tete: HBoxContainer
var _lbl_ressources: Label
var _toast_parent: Control


func _titre_ecran() -> String:
	return ""


func _couleur() -> Color:
	return UiCommun.C_OR


## Fond peint propre à l'écran (assets/fonds/…) ; "" = fond commun du menu.
func _fond_ecran() -> String:
	return ""


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = Color("0b0607")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if not UiCommun.fond_image(self, _fond_ecran(), UiCommun.TEINTE_FOND):
		UiCommun.fond_image(self, FOND, Color(0.3, 0.26, 0.26))
	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 20)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	marge.add_child(col)
	_tete = HBoxContainer.new()
	_tete.add_theme_constant_override("separation", 16)
	col.add_child(_tete)
	var retour := UiCommun.bouton("← Menu")
	retour.pressed.connect(_retour)
	_tete.add_child(retour)
	_tete.add_child(UiCommun.label(_titre_ecran(), 32, _couleur()))
	var pousse := Control.new()
	pousse.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tete.add_child(pousse)
	_lbl_ressources = UiCommun.label("", 19, Color("ffd060"))
	_tete.add_child(_lbl_ressources)
	var p := PanelContainer.new()
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(_couleur().darkened(0.35)))
	col.add_child(p)
	var defil := ScrollContainer.new()
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	p.add_child(defil)
	_contenu = VBoxContainer.new()
	_contenu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contenu.add_theme_constant_override("separation", 10)
	defil.add_child(_contenu)
	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(_maj_ressources)
	add_child(t)
	_preparer()
	rafraichir()


## Pour ajouter des éléments à l'en-tête (onglets...) avant le premier affichage.
func _preparer() -> void:
	pass


func _remplir() -> void:
	pass


func rafraichir() -> void:
	for x in _contenu.get_children():
		x.queue_free()
	_remplir()
	_maj_ressources()


func _maj_ressources() -> void:
	_lbl_ressources.text = UiCommun.t("Or %s   ·   Gemmes %d   ·   Stamina %d/%d") % [_nombre(Sauvegarde.get_or()),
		Sauvegarde.get_gemmes(), Sauvegarde.get_stamina(), Sauvegarde.get_stamina_max()]


# ---------------------------------------------------------------------
# Outils
# ---------------------------------------------------------------------

func _titre(texte: String, couleur := UiCommun.C_OR) -> void:
	_contenu.add_child(UiCommun.label(texte, 20, couleur))


func _texte(texte: String, taille := 15, couleur := UiCommun.C_DOUX) -> Label:
	var l := UiCommun.label(texte, taille, couleur)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contenu.add_child(l)
	return l


## Une ligne « carte » : panneau horizontal, renvoie la HBox où ajouter le contenu.
func _ligne(couleur: Color, parent: Control = null) -> HBoxContainer:
	var p := PanelContainer.new()
	var st := UiCommun.style_panneau(couleur, Color(0.07, 0.03, 0.04, 0.92))
	st.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", st)
	(parent if parent != null else _contenu).add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	return h


func _barre(valeur: float, maxi: float, couleur: Color, largeur := 260.0) -> ProgressBar:
	var b := UiCommun.barre(couleur, largeur, 12)
	b.max_value = maxf(1.0, maxi)
	b.value = minf(valeur, maxi)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


## Petit message de récompense qui flotte au centre de l'écran.
func _annoncer(lignes: Array, couleur := Color("8affa0")) -> void:
	if lignes.is_empty():
		return
	Audio.son("coffre")
	var l := UiCommun.label("\n".join(lignes), 24, couleur)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	l.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 50, 1.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.8).set_delay(0.9)
	tw.tween_callback(l.queue_free)


func _erreur(texte: String) -> void:
	Audio.son("erreur")
	_annoncer([texte], Color("ff7a6a"))


func _nombre(n: int) -> String:
	var s := str(absi(n))
	var r := ""
	while s.length() > 3:
		r = " " + s.right(3) + r
		s = s.left(s.length() - 3)
	return ("-" if n < 0 else "") + s + r


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
