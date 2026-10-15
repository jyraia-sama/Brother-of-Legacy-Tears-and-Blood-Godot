class_name FenetreDemantelement
extends CanvasLayer
## DÉMANTÈLEMENT AU CHOIX (Reliquaire → Atelier d'Échos → « Choisir les Échos à démanteler »).
## Affiche les Échos ni équipés ni verrouillés, avec filtres (rareté, set, emplacement).
## Un clic sur un Écho le coche / décoche ; en bas : total de Poussière et bouton Démanteler.
##
##   FenetreDemantelement.ouvrir(parent, callable_apres)   (callable_apres : rafraîchir l'écran appelant)

const C_VIOLET := Color("b06cff")
const C_SEL := Color("ff6a5a")
const TAILLE_CARTE := Vector2(200, 118)

var _apres: Callable
var _choisis := {}            # uid -> true
var _f_rarete := -1
var _f_set := ""
var _f_emp := 0
var _grille: GridContainer
var _total: Label
var _btn: Button
var _vide: Label


static func ouvrir(parent: Node, apres := Callable()) -> void:
	var f := FenetreDemantelement.new()
	f._apres = apres
	parent.add_child(f)


func _ready() -> void:
	layer = 50
	var voile := ColorRect.new()
	voile.color = Color(0, 0, 0, 0.72)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voile)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var p := PanelContainer.new()
	var vp := get_viewport().get_visible_rect().size
	p.custom_minimum_size = Vector2(minf(1400.0, vp.x - 40.0), minf(820.0, vp.y - 40.0))
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_VIOLET, Color(0.06, 0.02, 0.05, 0.98)))
	centre.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)

	var tete := HBoxContainer.new()
	vb.add_child(tete)
	var t := UiCommun.label("DÉMANTELER AU CHOIX", 26, C_VIOLET)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(t)
	var fermer := UiCommun.bouton("Fermer", 16)
	fermer.pressed.connect(_fermer)
	tete.add_child(fermer)
	var aide := UiCommun.label("Clique les Échos à démanteler (ils passent en rouge). Les Échos équipés ou verrouillés n'apparaissent pas.", 14, UiCommun.C_DOUX)
	aide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(aide)

	# Filtres
	var filtres := HFlowContainer.new()
	filtres.add_theme_constant_override("h_separation", 10)
	filtres.add_theme_constant_override("v_separation", 6)
	vb.add_child(filtres)
	filtres.add_child(UiCommun.label("Rareté :", 15, UiCommun.C_TEXTE))
	var o_r := OptionButton.new()
	o_r.add_item("Toutes", 0)
	for i in Echos.RARETES.size():
		o_r.add_item(Echos.RARETES[i]["nom"], i + 1)
	o_r.item_selected.connect(func(i: int):
		_f_rarete = i - 1
		_remplir())
	filtres.add_child(o_r)
	filtres.add_child(UiCommun.label("Set :", 15, UiCommun.C_TEXTE))
	var o_s := OptionButton.new()
	var ids_sets: Array = Echos.SETS.keys()
	o_s.add_item("Tous", 0)
	for i in ids_sets.size():
		o_s.add_item(Echos.SETS[ids_sets[i]]["nom"], i + 1)
	o_s.item_selected.connect(func(i: int):
		_f_set = "" if i == 0 else str(ids_sets[i - 1])
		_remplir())
	filtres.add_child(o_s)
	filtres.add_child(UiCommun.label("Emplacement :", 15, UiCommun.C_TEXTE))
	var o_e := OptionButton.new()
	o_e.add_item("Tous", 0)
	for e in range(1, 7):
		o_e.add_item("%d · %s" % [e, Echos.EMPLACEMENTS[e]["nom"]], e)
	o_e.item_selected.connect(func(i: int):
		_f_emp = i
		_remplir())
	filtres.add_child(o_e)
	var b_tout := UiCommun.bouton("Tout cocher (filtre)", 14)
	b_tout.pressed.connect(func():
		for e in _visibles():
			_choisis[int(e["uid"])] = true
		_remplir())
	filtres.add_child(b_tout)
	var b_rien := UiCommun.bouton("Tout décocher", 14)
	b_rien.pressed.connect(func():
		_choisis.clear()
		_remplir())
	filtres.add_child(b_rien)

	var defil := ScrollContainer.new()
	defil.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defil.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(defil)
	var cont := VBoxContainer.new()
	cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defil.add_child(cont)
	_vide = UiCommun.label("Aucun Écho ne correspond (les Échos équipés ou verrouillés ne peuvent pas être démantelés).", 16, UiCommun.C_DOUX)
	_vide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cont.add_child(_vide)
	_grille = GridContainer.new()
	_grille.columns = maxi(2, int((p.custom_minimum_size.x - 60.0) / (TAILLE_CARTE.x + 8.0)))
	_grille.add_theme_constant_override("h_separation", 8)
	_grille.add_theme_constant_override("v_separation", 8)
	cont.add_child(_grille)

	var bas := HBoxContainer.new()
	bas.add_theme_constant_override("separation", 12)
	vb.add_child(bas)
	_total = UiCommun.label("", 17, Color("ffd060"))
	_total.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_total.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bas.add_child(_total)
	_btn = UiCommun.bouton("Démanteler la sélection", 17)
	UiCommun.bouton_vif(_btn, Color("8a2a3a"))
	_btn.pressed.connect(_demanteler)
	bas.add_child(_btn)
	_remplir()


## Échos démantelables qui passent les filtres (les meilleurs en premier).
func _visibles() -> Array:
	var r: Array = []
	for e in Sauvegarde.liste_echos():
		if int(e["porteur"]) >= 0 or e.get("verrou", false):
			continue
		if _f_rarete >= 0 and int(e["rarete"]) != _f_rarete:
			continue
		if _f_set != "" and str(e["set"]) != _f_set:
			continue
		if _f_emp > 0 and int(e["emplacement"]) != _f_emp:
			continue
		r.append(e)
	r.sort_custom(func(a, b):
		if int(a["rarete"]) != int(b["rarete"]):
			return int(a["rarete"]) > int(b["rarete"])
		if int(a["etoiles"]) != int(b["etoiles"]):
			return int(a["etoiles"]) > int(b["etoiles"])
		if int(a["emplacement"]) != int(b["emplacement"]):
			return int(a["emplacement"]) < int(b["emplacement"])
		return int(a["uid"]) < int(b["uid"]))
	return r


func _remplir() -> void:
	for c in _grille.get_children():
		c.queue_free()
	var liste := _visibles()
	_vide.visible = liste.is_empty()
	for e in liste:
		_grille.add_child(_carte(e))
	_maj_total()


func _carte(e: Dictionary) -> Button:
	var uid := int(e["uid"])
	var choisi := _choisis.has(uid)
	var coul: Color = Echos.RARETES[int(e["rarete"])]["couleur"]
	var b := Button.new()
	b.custom_minimum_size = TAILLE_CARTE
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", UiCommun.style_carte(C_SEL if choisi else coul, 0.16 if choisi else 0.0, 3 if choisi else 2))
	b.add_theme_stylebox_override("hover", UiCommun.style_carte(C_SEL if choisi else UiCommun.C_OR, 0.08))
	b.add_theme_stylebox_override("pressed", UiCommun.style_carte(C_SEL, 0.16, 3))
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 8
	vb.offset_top = 4
	vb.offset_right = -6
	vb.add_theme_constant_override("separation", 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	var titre := UiCommun.label("%d · %s" % [int(e["emplacement"]), Echos.SETS[e["set"]]["nom"]], 14, coul)
	titre.clip_text = true
	vb.add_child(titre)
	vb.add_child(UiCommun.label("%s  ·  %s  +%d" % [Echos.RARETES[int(e["rarete"])]["nom"], "★".repeat(int(e["etoiles"])), int(e.get("niveau", 0))], 13, Color("ffd060")))
	vb.add_child(UiCommun.label(Echos.texte_stat(e["principale"], Echos.valeur_principale(e)), 13))
	var subs: Array = []
	for s in e.get("secondaires", []):
		subs.append(Echos.texte_stat(s["stat"], float(s["valeur"])))
	if not subs.is_empty():
		var ls := UiCommun.label(" · ".join(subs), 11, UiCommun.C_DOUX)
		ls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ls.max_lines_visible = 2
		vb.add_child(ls)
	vb.add_child(UiCommun.label(("✕ À DÉMANTELER  " if choisi else "") + UiCommun.t("+%d Poussière") % Reliquaire.poussiere_demantelement(e),
		12, C_SEL if choisi else Color("c8a8ff")))
	b.pressed.connect(func():
		if _choisis.has(uid):
			_choisis.erase(uid)
		else:
			_choisis[uid] = true
		var i := b.get_index()
		var nouvelle := _carte(Sauvegarde.get_echo(uid))
		_grille.add_child(nouvelle)
		_grille.move_child(nouvelle, i)
		b.queue_free()
		_maj_total())
	return b


func _maj_total() -> void:
	var gain := 0
	var rares := 0
	var nb := 0
	for uid in _choisis:
		var e := Sauvegarde.get_echo(int(uid))
		if e.is_empty():
			continue
		nb += 1
		gain += Reliquaire.poussiere_demantelement(e)
		if int(e["rarete"]) >= 3:
			rares += 1
	_total.add_theme_color_override("font_color", Color("ffd060"))
	_total.text = UiCommun.t("%d Écho(s) sélectionné(s)   →   +%d Poussière d'Écho") % [nb, gain] if nb > 0 \
		else "Aucun Écho sélectionné."
	if rares > 0:
		_total.text += UiCommun.t("   (dont %d Héroïque(s) ou Légendaire(s))") % rares
	_btn.disabled = nb == 0


func _demanteler() -> void:
	var uids: Array = []
	var gain := 0
	var rares := 0
	for uid in _choisis:
		var e := Sauvegarde.get_echo(int(uid))
		if e.is_empty() or int(e["porteur"]) >= 0 or e.get("verrou", false):
			continue
		uids.append(int(uid))
		gain += Reliquaire.poussiere_demantelement(e)
		if int(e["rarete"]) >= 3:
			rares += 1
	if uids.is_empty():
		return
	var txt := UiCommun.t("Démanteler %d Échos pour %d Poussière d'Écho ?") % [uids.size(), gain]
	if rares > 0:
		txt += "\n\n" + UiCommun.t("⚠ Attention : %d d'entre eux sont Héroïques ou Légendaires. Un Écho démantelé est perdu pour toujours.") % rares
	var d := ConfirmationDialog.new()
	d.title = "Démantèlement"
	d.dialog_text = txt
	d.ok_button_text = "Démanteler"
	d.cancel_button_text = "Annuler"
	d.confirmed.connect(func():
		d.queue_free()
		var g := Reliquaire.demanteler(uids)
		_choisis.clear()
		_remplir()
		_total.text = UiCommun.t("Démantèlement : +%d Poussière d'Écho") % g
		_total.add_theme_color_override("font_color", Color("8aff9a")))
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered()


func _fermer() -> void:
	if _apres.is_valid():
		_apres.call()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_fermer()
