class_name EcranCompagnie
extends Control
## LA COMPAGNIE : tableau des 6 missions du jour, composition de l'escouade, missions en cours.
##  - en haut : les 3 escouades (en mission, terminées, libres) ;
##  - à gauche : le tableau des missions du jour ;
##  - à droite : la mission choisie, l'escouade à former et la collection.

const SCENE := "res://scenes/compagnie.tscn"
const C_BLEU := Color("7ab8ff")
const C_OK := Color("8affa0")
const C_NON := Color("ff7a6a")

static var scene_retour := ""

var _mission := -1              # index de la mission choisie dans le tableau du jour
var _escouade: Array = []       # uids choisis
var _haut: HBoxContainer
var _tableau: VBoxContainer
var _fiche: VBoxContainer
var _missions: Array = []


func _ready() -> void:
	Sauvegarde.charger()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var noir := ColorRect.new()
	noir.color = Color("070a0f")
	noir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(noir)
	if not UiCommun.fond_image(self, "res://assets/expedition/compagnie_bg.png", Color(0.4, 0.42, 0.48)):
		UiCommun.fond_degrade(self, Color("10202e"), Color("040507"))

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for c in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + c, 18)
	add_child(marge)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	marge.add_child(col)

	var tete := HBoxContainer.new()
	tete.add_theme_constant_override("separation", 16)
	col.add_child(tete)
	var retour := UiCommun.bouton("← Expéditions")
	retour.pressed.connect(_retour)
	tete.add_child(retour)
	tete.add_child(UiCommun.label("LA COMPAGNIE", 32, C_BLEU))
	var info := UiCommun.label("Nouveau tableau dans %s" % Calendrier.texte_duree(Calendrier.secondes_avant_demain()), 15, UiCommun.C_DOUX)
	info.name = "Renouvellement"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tete.add_child(info)

	_haut = HBoxContainer.new()
	_haut.add_theme_constant_override("separation", 12)
	col.add_child(_haut)

	var corps := HBoxContainer.new()
	corps.size_flags_vertical = Control.SIZE_EXPAND_FILL
	corps.add_theme_constant_override("separation", 14)
	col.add_child(corps)

	var pg := PanelContainer.new()
	pg.custom_minimum_size = Vector2(640, 0)
	pg.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_BLEU.darkened(0.45), Color(0.03, 0.05, 0.08, 0.92)))
	corps.add_child(pg)
	var dg := ScrollContainer.new()
	dg.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pg.add_child(dg)
	_tableau = VBoxContainer.new()
	_tableau.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tableau.add_theme_constant_override("separation", 8)
	dg.add_child(_tableau)

	var pd := PanelContainer.new()
	pd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pd.add_theme_stylebox_override("panel", UiCommun.style_panneau(C_BLEU.darkened(0.45), Color(0.03, 0.05, 0.08, 0.92)))
	corps.add_child(pd)
	var dd := ScrollContainer.new()
	dd.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pd.add_child(dd)
	_fiche = VBoxContainer.new()
	_fiche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fiche.add_theme_constant_override("separation", 8)
	dd.add_child(_fiche)

	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(_tic)
	add_child(t)
	_tout_rafraichir()


func _tic() -> void:
	var r := find_child("Renouvellement", true, false) as Label
	if r != null:
		r.text = "Nouveau tableau dans %s" % Calendrier.texte_duree(Calendrier.secondes_avant_demain())
	_remplir_haut()


func _tout_rafraichir() -> void:
	_missions = Compagnie.missions_du_jour()
	_remplir_haut()
	_remplir_tableau()
	_remplir_fiche()


# =====================================================================
# Escouades en cours
# =====================================================================

func _remplir_haut() -> void:
	for e in _haut.get_children():
		e.queue_free()
	var cours := Compagnie.en_cours()
	for i in Compagnie.ESCOUADES_MAX:
		var p := PanelContainer.new()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.custom_minimum_size = Vector2(0, 118)
		var fini: bool = i < cours.size() and Compagnie.terminee(cours[i])
		var st := UiCommun.style_panneau((C_OK if fini else C_BLEU).darkened(0.35 if i < cours.size() else 0.7), Color(0.03, 0.05, 0.08, 0.9))
		st.set_content_margin_all(10)
		p.add_theme_stylebox_override("panel", st)
		_haut.add_child(p)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		p.add_child(h)
		if i >= cours.size():
			var l := UiCommun.label("Escouade %d : libre\nChoisis une mission à gauche." % (i + 1), 15, UiCommun.C_DOUX)
			l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			h.add_child(l)
			continue
		var m: Dictionary = cours[i]
		var portraits := HBoxContainer.new()
		portraits.add_theme_constant_override("separation", -10)
		for uid in m["uids"]:
			var hh := Sauvegarde.get_heros(int(uid))
			if not hh.is_empty():
				portraits.add_child(UiCommun.portrait(hh["id"], 52))
		h.add_child(portraits)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(vb)
		vb.add_child(UiCommun.label(m["mission"]["nom"], 16, UiCommun.C_TEXTE))
		var reste := Compagnie.secondes_restantes(m)
		var total := int(m["mission"]["heures"]) * 3600
		var barre := UiCommun.barre(C_OK if fini else C_BLEU, 200, 8)
		barre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barre.max_value = total
		barre.value = total if fini else total - reste
		vb.add_child(barre)
		vb.add_child(UiCommun.label("Terminée !" if fini else "Retour dans %s" % Calendrier.texte_duree(reste), 14, C_OK if fini else UiCommun.C_DOUX))
		if m.get("bonus", false):
			vb.add_child(UiCommun.label("Objectif bonus rempli : butin +50 %", 12, UiCommun.C_OR))
		var b: Button
		if fini:
			b = UiCommun.bouton("Récupérer", 16)
			b.pressed.connect(_recuperer.bind(i))
		else:
			b = UiCommun.bouton("Rappeler", 14)
			b.tooltip_text = "Les unités reviennent tout de suite, sans butin."
			b.pressed.connect(_rappeler.bind(i))
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(b)


func _recuperer(i: int) -> void:
	var lignes := Compagnie.recuperer(i)
	if lignes.is_empty():
		return
	Audio.son("coffre")
	_message("Mission accomplie", "Butin rapporté par l'escouade :\n\n" + "\n".join(lignes))
	_tout_rafraichir()


func _rappeler(i: int) -> void:
	var d := ConfirmationDialog.new()
	d.title = "Rappeler l'escouade"
	d.dialog_text = "Rappeler cette escouade ?\nLes unités reviennent tout de suite, mais la mission est perdue (pas de butin)."
	d.ok_button_text = "Rappeler"
	d.cancel_button_text = "Annuler"
	d.confirmed.connect(func():
		Compagnie.rappeler(i)
		d.queue_free()
		_tout_rafraichir())
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(480, 0))


# =====================================================================
# Tableau des missions
# =====================================================================

func _remplir_tableau() -> void:
	for e in _tableau.get_children():
		e.queue_free()
	_tableau.add_child(UiCommun.label("TABLEAU DES MISSIONS DU JOUR", 18, UiCommun.C_OR))
	var lancees: Array = Compagnie._etat()["lancees"].map(func(x): return int(x))
	for m in _missions:
		var i: int = m["index"]
		var deja: bool = i in lancees
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.custom_minimum_size = Vector2(0, 112)
		var c := Color("e0a0ff") if m["epique"] else C_BLEU
		var st := UiCommun.style_carte(c if i == _mission else c.darkened(0.55), 0.0, 3 if i == _mission else 2)
		st.bg_color = c.darkened(0.8 if i == _mission else 0.9)
		b.add_theme_stylebox_override("normal", st)
		var sh := st.duplicate() as StyleBoxFlat
		sh.border_color = c
		b.add_theme_stylebox_override("hover", sh)
		b.add_theme_stylebox_override("pressed", sh)
		if deja:
			b.modulate = Color(1, 1, 1, 0.45)
		b.pressed.connect(func():
			Audio.son("clic")
			_mission = i
			_escouade.clear()
			_remplir_tableau()
			_remplir_fiche())
		var vb := VBoxContainer.new()
		vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vb.offset_left = 14
		vb.offset_right = -14
		vb.offset_top = 8
		vb.add_theme_constant_override("separation", 2)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(vb)
		var titre := "%s%s   ·   %d h   ·   %d unité%s" % ["✦ ÉPIQUE — " if m["epique"] else "", m["nom"], int(m["heures"]),
			int(m["taille"]), "s" if int(m["taille"]) > 1 else ""]
		vb.add_child(UiCommun.label(titre + ("   ·   lancée ✔" if deja else ""), 17, c.lightened(0.35)))
		var d := UiCommun.label(m["texte"], 13, UiCommun.C_DOUX)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(d)
		var conds: Array = []
		for cd in m["conditions"]:
			conds.append(Compagnie.texte_condition(cd))
		var lc := UiCommun.label("Conditions : " + " · ".join(conds), 13, UiCommun.C_TEXTE)
		lc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(lc)
		_tableau.add_child(b)


# =====================================================================
# Fiche de la mission et escouade
# =====================================================================

func _remplir_fiche() -> void:
	for e in _fiche.get_children():
		e.queue_free()
	if _mission < 0:
		_fiche.add_child(UiCommun.label("COMMENT ÇA MARCHE", 18, UiCommun.C_OR))
		for t in ["Choisis une mission dans le tableau du jour, puis forme l'escouade avec tes unités.",
			"Toutes les conditions doivent être remplies pour partir. L'objectif bonus (facultatif) donne +50 % de butin.",
			"Pendant la mission, les unités sont occupées : elles quittent l'équipe et ne peuvent pas combattre.",
			"Le temps passe même jeu fermé. Reviens récupérer le butin quand la mission est terminée.",
			"%d escouades peuvent partir en même temps. Le tableau change chaque jour à minuit." % Compagnie.ESCOUADES_MAX]:
			var l := UiCommun.label("•  " + t, 15, UiCommun.C_TEXTE)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_fiche.add_child(l)
		return
	var m: Dictionary = _missions[_mission]
	_fiche.add_child(UiCommun.label(("✦ " if m["epique"] else "") + str(m["nom"]).to_upper(), 24, C_BLEU.lightened(0.3)))
	_fiche.add_child(UiCommun.label("Durée : %d h   ·   Escouade de %d unité%s" % [int(m["heures"]), int(m["taille"]), "s" if int(m["taille"]) > 1 else ""], 15, UiCommun.C_DOUX))

	# Conditions
	_fiche.add_child(UiCommun.label("CONDITIONS", 16, UiCommun.C_OR))
	for cd in m["conditions"]:
		var ok := Compagnie.condition_remplie(cd, _escouade)
		_fiche.add_child(UiCommun.label(("✔ " if ok else "✘ ") + Compagnie.texte_condition(cd), 15, C_OK if ok else C_NON))
	if not m["bonus"].is_empty():
		var okb := Compagnie.condition_remplie(m["bonus"], _escouade)
		_fiche.add_child(UiCommun.label(("★ " if okb else "☆ ") + "Bonus (+50 % de butin) : " + Compagnie.texte_condition(m["bonus"]), 15,
			UiCommun.C_OR if okb else UiCommun.C_DOUX))

	# Butin
	var bonus_ok: bool = not m["bonus"].is_empty() and Compagnie.condition_remplie(m["bonus"], _escouade)
	var butin := Compagnie.butin_final(m, bonus_ok)
	_fiche.add_child(UiCommun.label("BUTIN" + ("  (avec bonus)" if bonus_ok else ""), 16, UiCommun.C_OR))
	var flux := HFlowContainer.new()
	flux.add_theme_constant_override("h_separation", 18)
	flux.add_theme_constant_override("v_separation", 4)
	_fiche.add_child(flux)
	for o in butin:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 5)
		if o != "or":
			hb.add_child(UiCommun.icone_objet(o, 26))
		hb.add_child(UiCommun.label(("%d or" % int(butin[o])) if o == "or" else "%s x%d" % [Reliquaire.nom(o), int(butin[o])], 14, UiCommun.C_TEXTE))
		flux.add_child(hb)

	# Escouade
	_fiche.add_child(HSeparator.new())
	_fiche.add_child(UiCommun.label("ESCOUADE  (%d / %d)" % [_escouade.size(), int(m["taille"])], 16, UiCommun.C_OR))
	var places := HBoxContainer.new()
	places.add_theme_constant_override("separation", 8)
	_fiche.add_child(places)
	for k in int(m["taille"]):
		if k < _escouade.size():
			var h := Sauvegarde.get_heros(int(_escouade[k]))
			var carte := UiCommun.carte_heros(h, 104, 138)
			carte.pressed.connect(_basculer.bind(int(_escouade[k])))
			places.add_child(carte)
		else:
			var vide := Button.new()
			vide.custom_minimum_size = Vector2(104, 138)
			vide.text = "+"
			vide.disabled = true
			vide.add_theme_font_size_override("font_size", 30)
			places.add_child(vide)

	var raison := Compagnie.raison_depart(m, _escouade)
	var go := UiCommun.bouton("ENVOYER L'ESCOUADE  (%d h)" % int(m["heures"]), 19)
	go.custom_minimum_size = Vector2(0, 52)
	go.disabled = raison != ""
	go.pressed.connect(_envoyer)
	_fiche.add_child(go)
	if raison != "" and not _escouade.is_empty():
		_fiche.add_child(UiCommun.label(raison, 14, Color("ffb070")))
	if Sauvegarde.get_equipe().any(func(u): return u in _escouade):
		var av := UiCommun.label("Attention : des unités de ton équipe partent en mission, elles la quitteront.", 13, Color("ffb070"))
		av.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_fiche.add_child(av)

	# Collection
	_fiche.add_child(HSeparator.new())
	_fiche.add_child(UiCommun.label("TES UNITÉS DISPONIBLES", 15, UiCommun.C_OR))
	var grille := GridContainer.new()
	grille.columns = 7
	grille.add_theme_constant_override("h_separation", 8)
	grille.add_theme_constant_override("v_separation", 8)
	_fiche.add_child(grille)
	var liste: Array = []
	for h in Sauvegarde.liste_heros():
		if not Sauvegarde.est_occupe(int(h["uid"])):
			liste.append(h)
	# Les unités utiles pour la mission d'abord
	liste.sort_custom(func(a, b): return _utilite(a, m) > _utilite(b, m))
	for h in liste:
		var uid := int(h["uid"])
		var carte := UiCommun.carte_heros(h, 104, 138)
		if uid in _escouade:
			carte.add_theme_stylebox_override("normal", UiCommun.style_carte(C_BLEU, 0.08, 4))
			UiCommun.badge(carte, "Choisie", C_BLEU)
		elif Sauvegarde.place_de(uid) >= 0:
			UiCommun.badge(carte, "Équipe", UiCommun.C_OR)
		carte.pressed.connect(_basculer.bind(uid))
		grille.add_child(carte)


## Plus une unité aide à remplir les conditions, plus elle est proposée tôt.
func _utilite(h: Dictionary, m: Dictionary) -> int:
	var u := UnitesData.get_unite(h["id"])
	var score := int(h["niveau"])
	for cd in m["conditions"] + ([m["bonus"]] if not m["bonus"].is_empty() else []):
		if (cd["type"] == "role" and u["role"] == cd["valeur"]) or (cd["type"] == "element" and u["element"] == cd["valeur"]):
			score += 100
	if Sauvegarde.place_de(int(h["uid"])) >= 0:
		score -= 50
	return score


func _basculer(uid: int) -> void:
	if _mission < 0:
		return
	if uid in _escouade:
		_escouade.erase(uid)
	elif _escouade.size() < int(_missions[_mission]["taille"]):
		_escouade.append(uid)
	else:
		Audio.son("erreur")
		return
	Audio.son("clic")
	_remplir_fiche()


func _envoyer() -> void:
	var m: Dictionary = _missions[_mission]
	var r := Compagnie.partir(m, _escouade)
	if r != "":
		Audio.son("erreur")
		_message("Impossible de partir", r)
		return
	Audio.son("carte")
	_mission = -1
	_escouade.clear()
	_tout_rafraichir()


func _message(titre: String, texte: String) -> void:
	var d := AcceptDialog.new()
	d.title = titre
	d.dialog_text = texte
	d.confirmed.connect(d.queue_free)
	d.canceled.connect(d.queue_free)
	add_child(d)
	d.popup_centered(Vector2i(480, 0))


func _retour() -> void:
	UiCommun.aller(get_tree(), scene_retour if scene_retour != "" else EcranExpedition.SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_retour()
