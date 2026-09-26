class_name EcranArmee
extends Control
## ARMÉE DU BOSS DE MONDE : 4 escouades de 5 unités (20 places).
## Dans chaque escouade : places 1-2 = AVANT, places 3-5 = ARRIÈRE.
## Clique une unité de la collection, puis une place (échange si occupée).
## Chaque exemplaire ne peut être placé qu'une fois (les doublons, eux, peuvent tous venir).

const SCENE := "res://scenes/armee.tscn"
const C_SANG := Color("d0453a")

static var scene_retour := ""

var _places: Array = []        # 20 uids (-1 = vide)
var _selection := -1
var _boites: Array = []        # 20 conteneurs
var _grille: GridContainer
var _lbl_info: Label


func _ready() -> void:
	Sauvegarde.charger()
	_places = Sauvegarde.get_escouades()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = UiCommun.C_FOND
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	UiCommun.fond_degrade(self, Color("1a0608"), Color("060203"))

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 16)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 12)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Retour")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	tete.add_child(UiCommun.label("ARMÉE — 4 ESCOUADES", 28, C_SANG))
	_lbl_info = UiCommun.label("", 16, UiCommun.C_DOUX)
	_lbl_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_lbl_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tete.add_child(_lbl_info)
	for a in [["Remplir auto", _remplir_auto], ["Équipe du Deck → Escouade 1", _copier_deck], ["Tout vider", _vider]]:
		var b := UiCommun.bouton(a[0], 15)
		b.pressed.connect(a[1])
		tete.add_child(b)

	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 12)
	col.add_child(corps)

	var gauche := PanelContainer.new()
	gauche.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_SANG))
	corps.add_child(gauche)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	gauche.add_child(vb)
	for k in 4:
		var ligne := HBoxContainer.new()
		ligne.add_theme_constant_override("separation", 6)
		var l := UiCommun.label("Escouade %d" % (k + 1), 14, UiCommun.C_OR)
		l.custom_minimum_size = Vector2(88, 0)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ligne.add_child(l)
		for i in 5:
			if i == 2:
				var sep := VSeparator.new()
				sep.custom_minimum_size = Vector2(10, 0)
				ligne.add_child(sep)
			var boite := Control.new()
			boite.custom_minimum_size = Vector2(98, 136)
			ligne.add_child(boite)
			_boites.append(boite)
		vb.add_child(ligne)
	vb.add_child(UiCommun.label("Dans chaque escouade : 2 places AVANT (gauche), 3 places ARRIÈRE (droite).", 13, UiCommun.C_DOUX))

	var droite := PanelContainer.new()
	droite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	droite.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	corps.add_child(droite)
	var v2 := VBoxContainer.new()
	droite.add_child(v2)
	v2.add_child(UiCommun.label("COLLECTION  (clique une unité puis une place)", 16, UiCommun.C_OR))
	var defil := ScrollContainer.new()
	defil.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v2.add_child(defil)
	_grille = GridContainer.new()
	_grille.columns = 5
	_grille.add_theme_constant_override("h_separation", 6)
	_grille.add_theme_constant_override("v_separation", 6)
	defil.add_child(_grille)
	_rafraichir()


func _rafraichir() -> void:
	for i in 20:
		var boite: Control = _boites[i]
		for e in boite.get_children():
			e.queue_free()
		var uid: int = _places[i]
		var carte: Button
		if uid >= 0:
			carte = UiCommun.carte_heros(Sauvegarde.get_heros(uid), 98, 136)
			carte.tooltip_text = "Clique pour retirer (ou pour échanger avec l'unité choisie)"
		else:
			carte = Button.new()
			carte.custom_minimum_size = Vector2(98, 136)
			carte.focus_mode = Control.FOCUS_NONE
			carte.text = "+\n%s" % ("Avant" if i % 5 < 2 else "Arrière")
			carte.add_theme_stylebox_override("normal", UiCommun.style_carte(Color(1, 1, 1, 0.15)))
			carte.add_theme_stylebox_override("hover", UiCommun.style_carte(UiCommun.C_OR, 0.05))
			carte.add_theme_color_override("font_color", UiCommun.C_DOUX)
		carte.pressed.connect(_clic_place.bind(i))
		boite.add_child(carte)

	for e in _grille.get_children():
		e.queue_free()
	var liste: Array = Sauvegarde.liste_heros().duplicate()
	liste.sort_custom(func(a, b): return _force(int(a["uid"])) > _force(int(b["uid"])))
	for h in liste:
		var uid := int(h["uid"])
		var carte := UiCommun.carte_heros(h, 112, 150)
		if uid in _places:
			carte.modulate = Color(1, 1, 1, 0.35)
			UiCommun.badge(carte, "Escouade %d" % (int(_places.find(uid) / 5.0) + 1), C_SANG)
		if uid == _selection:
			carte.add_theme_stylebox_override("normal", UiCommun.style_carte(Color.WHITE, 0.08, 3))
		carte.pressed.connect(_clic_collection.bind(uid))
		_grille.add_child(carte)

	var n := 0
	var p := 0.0
	for uid in _places:
		if uid >= 0:
			n += 1
			p += _force(uid)
	_lbl_info.text = "%d / 20 unités  ·  puissance %d%s" % [n, int(p),
		"  ·  choisis une place" if _selection >= 0 else ""]


func _force(uid: int) -> float:
	var st := Sauvegarde.stats_heros(uid)
	if st.is_empty():
		return 0.0
	return st["pv"] * 0.25 + st["atk"] + st["def"] * 0.8 + st["agi"] * 0.5 + st["mag"] * 0.7


func _clic_collection(uid: int) -> void:
	_selection = -1 if _selection == uid else uid
	_rafraichir()


func _clic_place(i: int) -> void:
	if _selection >= 0:
		var ancienne := _places.find(_selection)
		if ancienne >= 0:
			_places[ancienne] = _places[i]
		_places[i] = _selection
		_selection = -1
	else:
		_places[i] = -1
	_enregistrer()


## Remplit les places vides avec les unités les plus fortes, corps à corps à l'Avant.
func _remplir_auto() -> void:
	var libres: Array = []
	for h in Sauvegarde.liste_heros():
		if not int(h["uid"]) in _places:
			libres.append(int(h["uid"]))
	libres.sort_custom(func(a, b): return _force(a) > _force(b))
	var melee: Array = []
	var distance: Array = []
	for uid in libres:
		var u := UnitesData.get_unite(Sauvegarde.get_heros(uid)["id"])
		if u["position"] == "avant":
			melee.append(uid)
		else:
			distance.append(uid)
	for i in 20:
		if _places[i] >= 0:
			continue
		var avant := i % 5 < 2
		var src: Array = melee if avant else distance
		if src.is_empty():
			src = distance if avant else melee
		if src.is_empty():
			break
		_places[i] = src.pop_front()
	_enregistrer()


func _copier_deck() -> void:
	var slots := Sauvegarde.get_slots()
	for i in 5:
		var uid: int = slots[i]
		if uid >= 0:
			var ancienne := _places.find(uid)
			if ancienne >= 0:
				_places[ancienne] = -1
		_places[i] = uid
	_enregistrer()


func _vider() -> void:
	for i in 20:
		_places[i] = -1
	_enregistrer()


func _enregistrer() -> void:
	Sauvegarde.definir_escouades(_places)
	_places = Sauvegarde.get_escouades()
	_rafraichir()


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour if scene_retour != "" else EcranBossMonde.SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
