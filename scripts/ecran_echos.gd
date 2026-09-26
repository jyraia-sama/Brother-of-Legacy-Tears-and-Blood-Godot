class_name EcranEchos
extends Control
## ÉCHOS SANGUINS : équiper, améliorer et vendre les Échos de chaque héros.
##
## Gauche  : choix du héros.
## Centre  : ses 6 emplacements, les sets actifs et ses stats (base -> avec Échos).
## Droite  : l'inventaire (filtres emplacement / set / tri) et la fiche de l'Écho choisi.
## Cliquer un emplacement du héros filtre l'inventaire sur cet emplacement.

const SCENE := "res://scenes/echos.tscn"
const FOND := "res://assets/ui/menu_bg.png"

static var scene_retour := ""

var _heros := -1           # uid du héros sélectionné
var _echo := -1            # uid de l'Écho sélectionné
var _filtre_emplacement := 0
var _filtre_set := ""
var _tri := "etoiles"
var _rng := RandomNumberGenerator.new()

var _lbl_or: Label
var _liste_heros: VBoxContainer
var _centre: VBoxContainer
var _grille: GridContainer
var _fiche: VBoxContainer
var _opt_emplacement: OptionButton
var _opt_set: OptionButton
var _opt_tri: OptionButton
var _lbl_inventaire: Label


func _ready() -> void:
	Sauvegarde.charger()
	_rng.randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = UiCommun.C_FOND
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if ResourceLoader.exists(FOND):
		var img := TextureRect.new()
		img.texture = load(FOND)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		img.modulate = Color(0.2, 0.15, 0.16)
		add_child(img)

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 16)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 16)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Retour")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	var titre := UiCommun.label("ÉCHOS SANGUINS", 30, Color("d0453a"))
	titre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tete.add_child(titre)
	_lbl_or = UiCommun.label("", 20, Color("ffd060"))
	tete.add_child(_lbl_or)

	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 12)
	col.add_child(corps)

	# --- Héros ---
	var ph := _panneau(250)
	corps.add_child(ph)
	var vh := VBoxContainer.new()
	ph.add_child(vh)
	vh.add_child(UiCommun.label("HÉROS", 17, UiCommun.C_OR))
	var dh := ScrollContainer.new()
	dh.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dh.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vh.add_child(dh)
	_liste_heros = VBoxContainer.new()
	_liste_heros.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_liste_heros.add_theme_constant_override("separation", 4)
	dh.add_child(_liste_heros)

	# --- Héros choisi ---
	var pc := _panneau(0)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	corps.add_child(pc)
	var dc := ScrollContainer.new()
	dc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(dc)
	_centre = VBoxContainer.new()
	_centre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_centre.add_theme_constant_override("separation", 10)
	dc.add_child(_centre)

	# --- Inventaire ---
	var pi := _panneau(560)
	corps.add_child(pi)
	var vi := VBoxContainer.new()
	vi.add_theme_constant_override("separation", 8)
	pi.add_child(vi)
	var hi := HBoxContainer.new()
	hi.add_theme_constant_override("separation", 6)
	vi.add_child(hi)
	_lbl_inventaire = UiCommun.label("INVENTAIRE", 17, UiCommun.C_OR)
	_lbl_inventaire.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hi.add_child(_lbl_inventaire)
	var rapide := UiCommun.bouton("Vente rapide", 13)
	rapide.custom_minimum_size = Vector2(0, 30)
	rapide.tooltip_text = "Vend tous les Échos Normaux et Magiques non équipés et non verrouillés."
	rapide.pressed.connect(_vente_rapide)
	hi.add_child(rapide)

	var filtres := HBoxContainer.new()
	filtres.add_theme_constant_override("separation", 6)
	vi.add_child(filtres)
	_opt_emplacement = OptionButton.new()
	_opt_emplacement.add_item("Tous les emplacements", 0)
	for i in range(1, 7):
		_opt_emplacement.add_item("%d · %s" % [i, Echos.EMPLACEMENTS[i]["nom"].trim_prefix("Écho ")], i)
	_opt_emplacement.item_selected.connect(func(idx):
		_filtre_emplacement = _opt_emplacement.get_item_id(idx)
		_remplir_inventaire())
	filtres.add_child(_opt_emplacement)
	_opt_set = OptionButton.new()
	_opt_set.add_item("Tous les sets")
	for sid in Echos.SETS:
		_opt_set.add_item(Echos.SETS[sid]["nom"])
		_opt_set.set_item_metadata(_opt_set.item_count - 1, sid)
	_opt_set.item_selected.connect(func(idx):
		_filtre_set = "" if idx == 0 else str(_opt_set.get_item_metadata(idx))
		_remplir_inventaire())
	filtres.add_child(_opt_set)
	_opt_tri = OptionButton.new()
	for t in [["etoiles", "Tri : étoiles"], ["niveau", "Tri : niveau"], ["rarete", "Tri : rareté"]]:
		_opt_tri.add_item(t[1])
		_opt_tri.set_item_metadata(_opt_tri.item_count - 1, t[0])
	_opt_tri.item_selected.connect(func(idx):
		_tri = str(_opt_tri.get_item_metadata(idx))
		_remplir_inventaire())
	filtres.add_child(_opt_tri)

	var di := ScrollContainer.new()
	di.size_flags_vertical = Control.SIZE_EXPAND_FILL
	di.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vi.add_child(di)
	_grille = GridContainer.new()
	_grille.columns = 3
	_grille.add_theme_constant_override("h_separation", 6)
	_grille.add_theme_constant_override("v_separation", 6)
	di.add_child(_grille)

	var pf := PanelContainer.new()
	pf.add_theme_stylebox_override("panel", UiCommun.style_panneau(Color(0.5, 0.35, 0.25), Color(0.05, 0.02, 0.02, 0.9)))
	pf.custom_minimum_size = Vector2(0, 270)
	vi.add_child(pf)
	_fiche = VBoxContainer.new()
	_fiche.add_theme_constant_override("separation", 5)
	pf.add_child(_fiche)

	var equipe := Sauvegarde.get_equipe()
	_heros = equipe[0] if not equipe.is_empty() else -1
	_tout()


func _panneau(largeur: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiCommun.style_panneau())
	if largeur > 0:
		p.custom_minimum_size = Vector2(largeur, 0)
	return p


# =====================================================================
# Rafraîchissement
# =====================================================================

func _tout() -> void:
	_lbl_or.text = "Or : %d" % Sauvegarde.get_or()
	_remplir_heros()
	_remplir_centre()
	_remplir_inventaire()
	_remplir_fiche()


func _remplir_heros() -> void:
	for e in _liste_heros.get_children():
		e.queue_free()
	var equipe := Sauvegarde.get_equipe()
	var liste: Array = Sauvegarde.liste_heros().duplicate()
	liste.sort_custom(func(a, b):
		var ea: bool = int(a["uid"]) in equipe
		var eb: bool = int(b["uid"]) in equipe
		if ea != eb:
			return ea
		return int(a["niveau"]) > int(b["niveau"]))
	for h in liste:
		var uid := int(h["uid"])
		var u := UnitesData.get_unite(h["id"])
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 52)
		b.focus_mode = Control.FOCUS_NONE
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var bord: Color = Color.WHITE if uid == _heros else UiCommun.couleur_rarete(h["id"]).darkened(0.3)
		b.add_theme_stylebox_override("normal", UiCommun.style_carte(bord, 0.05 if uid == _heros else 0.0, 2))
		b.add_theme_stylebox_override("hover", UiCommun.style_carte(UiCommun.C_OR, 0.06))
		var hb := HBoxContainer.new()
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 6
		hb.add_theme_constant_override("separation", 8)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(hb)
		var por := UiCommun.portrait(h["id"], 38)
		por.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(por)
		var t := UiCommun.label("%s\nNv %d  ·  %d/6 Échos%s" % [u["nom"], int(h["niveau"]), Sauvegarde.echos_de(uid).size(),
			"  ·  Équipe" if uid in equipe else ""], 13)
		t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hb.add_child(t)
		b.pressed.connect(func():
			_heros = uid
			_tout())
		_liste_heros.add_child(b)


func _remplir_centre() -> void:
	for e in _centre.get_children():
		e.queue_free()
	var h := Sauvegarde.get_heros(_heros)
	if h.is_empty():
		_centre.add_child(UiCommun.label("Choisis un héros.", 16, UiCommun.C_DOUX))
		return
	var u := UnitesData.get_unite(h["id"])
	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 12)
	tete.add_child(UiCommun.portrait(h["id"], 64))
	var t := UiCommun.label("%s\nNv %d  ·  %s  ·  %s" % [u["nom"], int(h["niveau"]), UnitesData.ELEMENTS[u["element"]], UnitesData.ROLES[u["role"]]], 20, UiCommun.couleur_rarete(h["id"]))
	tete.add_child(t)
	_centre.add_child(tete)

	# Les 6 emplacements
	var portes := {}
	for e in Sauvegarde.echos_de(_heros):
		portes[int(e["emplacement"])] = e
	var grille := GridContainer.new()
	grille.columns = 3
	grille.add_theme_constant_override("h_separation", 8)
	grille.add_theme_constant_override("v_separation", 8)
	_centre.add_child(grille)
	for i in range(1, 7):
		var b := Button.new()
		b.custom_minimum_size = Vector2(190, 96)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.focus_mode = Control.FOCUS_NONE
		var vb := VBoxContainer.new()
		vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vb.offset_left = 8
		vb.offset_top = 6
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(vb)
		vb.add_child(UiCommun.label("%d · %s" % [i, Echos.EMPLACEMENTS[i]["nom"]], 13, UiCommun.C_DOUX))
		if portes.has(i):
			var e: Dictionary = portes[i]
			var coul: Color = Echos.RARETES[int(e["rarete"])]["couleur"]
			b.add_theme_stylebox_override("normal", UiCommun.style_carte(coul, 0.02 if int(e["uid"]) != _echo else 0.1, 2))
			vb.add_child(UiCommun.label("%s  %s  +%d" % [Echos.SETS[e["set"]]["nom"], _etoiles(e), int(e["niveau"])], 15, coul))
			vb.add_child(UiCommun.label(Echos.texte_stat(e["principale"], Echos.valeur_principale(e)), 14))
		else:
			b.add_theme_stylebox_override("normal", UiCommun.style_carte(Color(1, 1, 1, 0.15)))
			vb.add_child(UiCommun.label("Vide", 15, UiCommun.C_DOUX))
		b.add_theme_stylebox_override("hover", UiCommun.style_carte(UiCommun.C_OR, 0.06))
		b.pressed.connect(_clic_emplacement.bind(i, int(portes[i]["uid"]) if portes.has(i) else -1))
		grille.add_child(b)

	# Sets actifs
	var bonus := Sauvegarde.bonus_echos(_heros)
	_centre.add_child(UiCommun.label("SETS ACTIFS", 15, UiCommun.C_OR))
	var vus := {}
	if bonus["sets"].is_empty():
		_centre.add_child(UiCommun.label("Aucun (2 ou 4 Échos du même set sont nécessaires).", 14, UiCommun.C_DOUX))
	for nom in bonus["sets"]:
		vus[nom] = int(vus.get(nom, 0)) + 1
	for nom in vus:
		var sid := ""
		for k in Echos.SETS:
			if Echos.SETS[k]["nom"] == nom:
				sid = k
		var l := UiCommun.label(("x%d  " % vus[nom] if vus[nom] > 1 else "") + Echos.description_set(sid), 14, Color("ffb08a"))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_centre.add_child(l)

	# Stats base -> avec Échos
	_centre.add_child(UiCommun.label("STATS  (base → avec Échos)", 15, UiCommun.C_OR))
	var base := Sauvegarde.stats_base_heros(_heros)
	var fin := Sauvegarde.stats_heros(_heros)
	var gs := GridContainer.new()
	gs.columns = 3
	gs.add_theme_constant_override("h_separation", 26)
	_centre.add_child(gs)
	for p in [["pv", "PV"], ["atk", "ATK"], ["def", "DEF"], ["agi", "AGI"], ["mag", "MAG"], ["crit", "Crit %"],
			["degats_crit", "Dégâts crit %"], ["res", "RES"], ["preci", "Précision %"]]:
		var diff: int = int(fin[p[0]]) - int(base[p[0]])
		var l := UiCommun.label("%s : %d%s" % [p[1], int(fin[p[0]]), ("  (+%d)" % diff) if diff > 0 else ""], 14,
			Color("8aff9a") if diff > 0 else UiCommun.C_TEXTE)
		gs.add_child(l)


func _remplir_inventaire() -> void:
	for e in _grille.get_children():
		e.queue_free()
	var liste: Array = Sauvegarde.liste_echos().filter(func(e):
		return (_filtre_emplacement == 0 or int(e["emplacement"]) == _filtre_emplacement) \
			and (_filtre_set == "" or e["set"] == _filtre_set))
	liste.sort_custom(func(a, b):
		var ka: Array = [int(a["etoiles"]), int(a["niveau"]), int(a["rarete"])]
		var kb: Array = [int(b["etoiles"]), int(b["niveau"]), int(b["rarete"])]
		if _tri == "niveau":
			ka = [ka[1], ka[0], ka[2]]
			kb = [kb[1], kb[0], kb[2]]
		elif _tri == "rarete":
			ka = [ka[2], ka[0], ka[1]]
			kb = [kb[2], kb[0], kb[1]]
		return ka > kb)
	_lbl_inventaire.text = "INVENTAIRE  (%d / %d)" % [liste.size(), Sauvegarde.liste_echos().size()]
	for e in liste:
		_grille.add_child(_carte_echo(e))
	if liste.is_empty():
		var vide := UiCommun.label("Aucun Écho ici.\nLes Échos tombent en combat : le set dépend\nde l'Acte, l'emplacement du numéro de chapitre.", 14, UiCommun.C_DOUX)
		_grille.add_child(vide)


func _carte_echo(e: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(172, 84)
	b.focus_mode = Control.FOCUS_NONE
	var coul: Color = Echos.RARETES[int(e["rarete"])]["couleur"]
	var choisi := int(e["uid"]) == _echo
	b.add_theme_stylebox_override("normal", UiCommun.style_carte(Color.WHITE if choisi else coul, 0.1 if choisi else 0.0, 3 if choisi else 2))
	b.add_theme_stylebox_override("hover", UiCommun.style_carte(UiCommun.C_OR, 0.06))
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 7
	vb.offset_top = 4
	vb.add_theme_constant_override("separation", 0)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	vb.add_child(UiCommun.label("%d · %s" % [int(e["emplacement"]), Echos.SETS[e["set"]]["nom"]], 14, coul))
	vb.add_child(UiCommun.label("%s  +%d" % [_etoiles(e), int(e["niveau"])], 13, Color("ffd060")))
	vb.add_child(UiCommun.label(Echos.texte_stat(e["principale"], Echos.valeur_principale(e)), 13))
	var porteur := int(e["porteur"])
	if porteur >= 0:
		var h := Sauvegarde.get_heros(porteur)
		var nom_p: String = UnitesData.get_unite(h["id"])["nom"] if not h.is_empty() else "?"
		vb.add_child(UiCommun.label("Porté : " + nom_p, 11, UiCommun.C_DOUX))
	elif e.get("verrou", false):
		vb.add_child(UiCommun.label("Verrouillé", 11, Color("8ab0d0")))
	b.pressed.connect(func():
		_echo = int(e["uid"])
		_remplir_centre()
		_remplir_inventaire()
		_remplir_fiche())
	return b


func _remplir_fiche() -> void:
	for x in _fiche.get_children():
		x.queue_free()
	var e := Sauvegarde.get_echo(_echo)
	if e.is_empty():
		var l := UiCommun.label("Choisis un Écho dans l'inventaire (ou un emplacement du héros).\n\nChaque chapitre donne l'emplacement de même numéro ; chaque Acte a son set. Les boss en lâchent plus souvent et de meilleure qualité.", 14, UiCommun.C_DOUX)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_fiche.add_child(l)
		return
	var coul: Color = Echos.RARETES[int(e["rarete"])]["couleur"]
	_fiche.add_child(UiCommun.label("%s  +%d" % [Echos.nom(e), int(e["niveau"])], 18, coul))
	_fiche.add_child(UiCommun.label("%s   ·   %s" % [_etoiles(e), Echos.RARETES[int(e["rarete"])]["nom"]], 14, Color("ffd060")))
	_fiche.add_child(UiCommun.label("Principale : " + Echos.texte_stat(e["principale"], Echos.valeur_principale(e)), 15))
	for s in e["secondaires"]:
		_fiche.add_child(UiCommun.label("   " + Echos.texte_stat(s["stat"], s["valeur"]), 14, Color("b8d8ff")))
	var d := UiCommun.label(Echos.description_set(e["set"]), 13, Color("ffb08a"))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fiche.add_child(d)

	var boutons := HBoxContainer.new()
	boutons.add_theme_constant_override("separation", 6)
	_fiche.add_child(boutons)
	var porteur := int(e["porteur"])
	if porteur == _heros:
		var r := UiCommun.bouton("Retirer", 14)
		r.pressed.connect(func():
			Sauvegarde.retirer_echo(_echo)
			_tout())
		boutons.add_child(r)
	elif _heros >= 0:
		var h := Sauvegarde.get_heros(_heros)
		var eq := UiCommun.bouton("Équiper sur " + UnitesData.get_unite(h["id"])["nom"].trim_prefix("Le ").trim_prefix("La "), 14)
		eq.pressed.connect(func():
			Sauvegarde.equiper_echo(_echo, _heros)
			_tout())
		boutons.add_child(eq)
	if int(e["niveau"]) < Echos.NIVEAU_MAX:
		var am := UiCommun.bouton("Améliorer : %d or (%d %%)" % [Echos.cout_amelioration(e), int(Echos.chance_amelioration(e) * 100)], 14)
		am.disabled = Sauvegarde.get_or() < Echos.cout_amelioration(e)
		am.pressed.connect(_ameliorer)
		boutons.add_child(am)
	var b2 := HBoxContainer.new()
	b2.add_theme_constant_override("separation", 6)
	_fiche.add_child(b2)
	var v := UiCommun.bouton("Vendre (%d or)" % Echos.prix_vente(e), 14)
	v.disabled = porteur >= 0 or e.get("verrou", false)
	v.tooltip_text = "Retire-le d'abord du héros." if porteur >= 0 else ("Écho verrouillé." if e.get("verrou", false) else "")
	v.pressed.connect(func():
		Sauvegarde.vendre_echos([_echo])
		_echo = -1
		_tout())
	b2.add_child(v)
	var ver := UiCommun.bouton("Déverrouiller" if e.get("verrou", false) else "Verrouiller", 14)
	ver.pressed.connect(func():
		Sauvegarde.basculer_verrou_echo(_echo)
		_tout())
	b2.add_child(ver)


func _clic_emplacement(i: int, uid_echo: int) -> void:
	_filtre_emplacement = i
	_opt_emplacement.select(i)
	if uid_echo >= 0:
		_echo = uid_echo
	_tout()


func _ameliorer() -> void:
	var e := Sauvegarde.get_echo(_echo)
	var cout := Echos.cout_amelioration(e)
	if not Sauvegarde.depenser_or(cout):
		return
	var r := Echos.ameliorer(e, _rng)
	Sauvegarde.sauvegarder()
	_tout()
	_flash(r["texte"], Color("8aff9a") if r["reussi"] else Color("ff7a6a"))


func _vente_rapide() -> void:
	var cibles: Array = []
	var total := 0
	for e in Sauvegarde.liste_echos():
		if int(e["rarete"]) <= 1 and int(e["porteur"]) < 0 and not e.get("verrou", false):
			cibles.append(int(e["uid"]))
			total += Echos.prix_vente(e)
	if cibles.is_empty():
		_flash("Rien à vendre (Normaux/Magiques non équipés).", UiCommun.C_DOUX)
		return
	var d := ConfirmationDialog.new()
	d.title = "Vente rapide"
	d.dialog_text = "Vendre %d Échos Normaux et Magiques non équipés pour %d or ?" % [cibles.size(), total]
	d.ok_button_text = "Vendre"
	d.cancel_button_text = "Annuler"
	d.confirmed.connect(func():
		d.queue_free()
		Sauvegarde.vendre_echos(cibles)
		_echo = -1
		_tout())
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(440, 0))


func _flash(texte: String, couleur: Color) -> void:
	var l := UiCommun.label(texte, 22, couleur)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 40, 1.4)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.4).set_delay(0.6)
	tw.tween_callback(l.queue_free)


func _etoiles(e: Dictionary) -> String:
	return "★".repeat(int(e["etoiles"]))


func _retour() -> void:
	var cible := scene_retour
	if cible == "":
		cible = ProjectSettings.get_setting("application/run/main_scene", "")
	if cible != "":
		get_tree().change_scene_to_file(cible)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
